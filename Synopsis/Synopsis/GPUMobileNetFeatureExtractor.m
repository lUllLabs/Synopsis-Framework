//
//  MPSMobileNetFeatureExtractor.m
//  Synopsis-macOS
//
//  Created by vade on 10/27/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Vision/Vision.h>
#import "MobileNet.h"
#import "GPUMobileNetFeatureExtractor.h"

@interface GPUMobileNetFeatureExtractor ()
{
    CGColorSpaceRef linear;
}
@property (readwrite, strong) CIContext* context;
@property (readwrite, strong) VNSequenceRequestHandler* sequenceRequestHandler;
@end

@implementation GPUMobileNetFeatureExtractor

// save on memory use / loading
+ (VNCoreMLModel*) sharedModel
{
    static VNCoreMLModel* sharedModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        MobileNet* mobileNet = [[MobileNet alloc] init];
        MLModel* mobileNetMLModel = [mobileNet model];
        
        NSError* error = nil;
        sharedModel = [VNCoreMLModel modelForMLModel:mobileNetMLModel error:&error];
        
        if(!sharedModel)
        {
            NSLog(@"Error loading ML Model: %@", error);
        }
    });
    
    return sharedModel;
}

// GPU backed modules init with an options dict for Metal Device bullshit
- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint device:(id<MTLDevice>)device
{
    self = [super initWithQualityHint:qualityHint device:device];
    if(self)
    {
        linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        
        NSDictionary* opt = @{ kCIContextWorkingColorSpace : (__bridge id)linear,
                               kCIContextOutputColorSpace : (__bridge id)linear,
                                };
        self.context = [CIContext contextWithMTLDevice:device options:opt];
        self.sequenceRequestHandler = [[VNSequenceRequestHandler alloc] init];

    }
    return self;
}

- (void)dealloc
{
    CGColorSpaceRelease(linear);
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataFeatureVectorDictKey;
}

+ (SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingGPU;
}

+ (SynopsisVideoFormat) requiredVideoFormat
{
    return SynopsisVideoFormatBGR8;
}

- (void) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame commandBuffer:(id<MTLCommandBuffer>)buffer completionBlock:(GPUModuleCompletionBlock)completionBlock;
{
    SynopsisVideoFrameMPImage* frameMPImage = (SynopsisVideoFrameMPImage*)frame;

    NSDictionary* opt = @{ kCIImageColorSpace : (__bridge id) linear };
    CIImage* imageForRequest = [CIImage imageWithMTLTexture:frameMPImage.mpsImage.texture options:nil];
    
    VNCoreMLRequest* mobileNetRequest = [[VNCoreMLRequest alloc] initWithModel:[GPUMobileNetFeatureExtractor sharedModel] completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        //specifically dispatch work away from encode thread - so we dont block enqueueing new work
        dispatch_async(self.completionQueue, ^{
            
            NSMutableDictionary* metadata = nil;
            
            if(request.results.count)
            {
                metadata = [NSMutableDictionary dictionary];;
                NSArray<VNClassificationObservation*>* observations = [request results];
                
                observations = [observations subarrayWithRange:NSMakeRange(0, 5)];
                
                for(VNClassificationObservation* observation in observations)
                {
                    metadata[observation.identifier] = @(observation.confidence);
                }
                
                if(completionBlock)
                {
//                    NSLog(@"Metadata: %@", metadata);
                    completionBlock( @{[self moduleName] : metadata} , error);
                }
            }
            else
            {
                if(completionBlock)
                {
                    completionBlock( nil , error);
                }
            }
        });
    }];
    
    mobileNetRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
    mobileNetRequest.preferBackgroundProcessing = NO;

    // Works fine:
     NSDictionary* requestOptions = nil;
    // Crashes on CIContext dealloc
    //    NSDictionary* requestOptions = @{ VNImageOptionCIContext : self.context };
//    VNImageRequestHandler* imageRequestHandler = [[VNImageRequestHandler alloc] initWithCIImage:imageForRequest options:requestOptions];
    
    NSError* submitError = nil;
//    if(![imageRequestHandler performRequests:@[mobileNetRequest] error:&submitError] )
    if(![self.sequenceRequestHandler performRequests:@[mobileNetRequest] onCIImage:imageForRequest error:&submitError])
    {
        NSLog(@"Error submitting request: %@", submitError);
    }
}

- (NSDictionary*) finaledAnalysisMetadata;
{
//    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

@end