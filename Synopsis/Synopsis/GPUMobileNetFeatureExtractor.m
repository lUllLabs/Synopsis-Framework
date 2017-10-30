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
@property (readwrite, strong) MPSImageBilinearScale* scaleForCoreML;
@property (readwrite, strong) VNCoreMLModel* mobileNetVisionModel;
@property (readwrite, strong) VNSequenceRequestHandler* sequenceRequestHandler;
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
        self.scaleForCoreML = [[MPSImageBilinearScale alloc] initWithDevice:device];

        MobileNet* mobileNet = [[MobileNet alloc] init];
        MLModel* mobileNetMLModel = [mobileNet model];
        
        NSError* error = nil;
        
        self.mobileNetVisionModel = [VNCoreMLModel modelForMLModel:mobileNetMLModel error:&error];
        
        if(!self.mobileNetVisionModel)
        {
            NSLog(@"Error loading ML Model: %@", error);
            return nil;
        }
        
        self.sequenceRequestHandler = [[VNSequenceRequestHandler alloc] init];
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

//    MPSScaleTransform* transform = malloc(sizeof(MPSScaleTransform));
//    transform->scaleX = (float)224.0 / (float)frameMPImage.mpsImage.width ;
//    transform->scaleY = (float)224.0 / (float)frameMPImage.mpsImage.height;
//    transform->translateX = 0;
//    transform->translateY = 0;
//    self.scaleForCoreML.scaleTransform = transform;
//
//    MPSImageDescriptor* resizeDescriptor = [[MPSImageDescriptor alloc] init];
//    resizeDescriptor.width = 224;
//    resizeDescriptor.height = 224;
//    resizeDescriptor.featureChannels = 3;
//    resizeDescriptor.numberOfImages = 1;
//    resizeDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
//    resizeDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
//
//    MPSImage* resizeTarget = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:resizeDescriptor];
//
//    [self.scaleForCoreML encodeToCommandBuffer:buffer sourceImage:frameMPImage.mpsImage destinationImage:resizeTarget];
//
//    // When the GPU completes the resize block, lets fire off our VISION request
//
//    [buffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    
//        CGColorSpaceRef linearCSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
//        NSDictionary* ciImageOptions = @{kCIImageColorSpace : (id) CFBridgingRelease(linearCSpace)};
        
//        CIImage* imageForRequest = [CIImage imageWithMTLTexture:resizeTarget.texture options:nil];
  
    
    CIImage* imageForRequest = [CIImage imageWithMTLTexture:frameMPImage.mpsImage.texture options:nil];

        //    NSDictionary<VNImageOption, id>* requestOptions = @{ VNImageOptionCIContext: self.context};
        
        VNCoreMLRequest* mobileNetRequest = [[VNCoreMLRequest alloc] initWithModel:self.mobileNetVisionModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            //specifically dispatch work away from encode thread - so we dont block enqueueing new work
            // by reading old work and doing dumb math
//            dispatch_async(self.completionQueue, ^{
            
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
                }
                
                if(completionBlock)
                {
                    completionBlock( @{[self moduleName] : metadata} , error);
                }
//            });
        }];
        
        mobileNetRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
        
        NSError* submitError = nil;
        if(![self.sequenceRequestHandler performRequests:@[mobileNetRequest] onCIImage:imageForRequest error:&submitError])
            NSLog(@"Error submitting request: %@", submitError);
//    }];
    
}

- (NSDictionary*) finaledAnalysisMetadata;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
