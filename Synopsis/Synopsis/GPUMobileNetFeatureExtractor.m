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
@property (readwrite, strong) VNCoreMLModel* mobileNetVisionModel;
@property (readwrite, strong) CIContext* context;
@end

@implementation GPUMobileNetFeatureExtractor

// GPU backed modules init with an options dict for Metal Device bullshit
- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint device:(id<MTLDevice>)device
{
    self = [super initWithQualityHint:qualityHint device:device];
    if(self)
    {
        self.context = [CIContext contextWithMTLDevice:device];

        MobileNet* mobileNet = [[MobileNet alloc] init];
        MLModel* mobileNetMLModel = [mobileNet model];
        
        NSError* error = nil;
        
        self.mobileNetVisionModel = [VNCoreMLModel modelForMLModel:mobileNetMLModel error:&error];
        
        if(!self.mobileNetVisionModel)
        {
            NSLog(@"Error loading ML Model: %@", error);
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
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

    CIImage* imageForRequest = [CIImage imageWithMTLTexture:frameMPImage.mpsImage.texture options:nil];
    
    VNCoreMLRequest* mobileNetRequest = [[VNCoreMLRequest alloc] initWithModel:self.mobileNetVisionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        //specifically dispatch work away from encode thread - so we dont block enqueueing new work
        // by reading old work and doing dumb math
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
    mobileNetRequest.preferBackgroundProcessing = YES;

    NSError* submitError = nil;
//    NSDictionary* requestOptions = @{ VNImageOptionCIContext : self.context};
    NSDictionary* requestOptions = nil;

    VNImageRequestHandler* imageRequestHandler = [[VNImageRequestHandler alloc] initWithCIImage:imageForRequest options:requestOptions];
    
    if(![imageRequestHandler performRequests:@[mobileNetRequest] error:&submitError] )
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
