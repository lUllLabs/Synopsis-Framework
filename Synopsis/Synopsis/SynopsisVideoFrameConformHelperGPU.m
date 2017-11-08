//
//  SynopsisVideoFrameConformHelperGPU.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisVideoFrameConformHelperGPU.h"
#import "SynopsisVideoFrameMPImage.h"

#import <CoreImage/CoreImage.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <Metal/Metal.h>

@interface SynopsisVideoFrameConformHelperGPU ()
{
    CVMetalTextureCacheRef textureCacheRef;
}
@property (readwrite, strong) NSOperationQueue* conformQueue;

@property (readwrite, strong) id<MTLDevice> device;
@property (readwrite, strong) id<MTLCommandQueue> commandQueue;
@property (readwrite, strong) CIContext* ciContext;

@property (readwrite, strong) MPSImageConversion* imageConversion;
@property (readwrite, strong) MPSImageBilinearScale* scaleForCoreML;

@end

@implementation SynopsisVideoFrameConformHelperGPU

- (instancetype) initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if(self)
    {
        self.conformQueue = [[NSOperationQueue alloc] init];
        self.conformQueue.maxConcurrentOperationCount = 1;
        self.conformQueue.qualityOfService = NSQualityOfServiceUserInitiated;

        // One device for now plz
        self.device = device;
        self.commandQueue = [device newCommandQueue];
        
        CGColorSpaceRef destination = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        
        NSDictionary* ciContextOptions = @{ kCIContextHighQualityDownsample : @NO,
                                            kCIContextOutputColorSpace : (__bridge id) (destination),
                                            kCIContextWorkingColorSpace : (__bridge id)(destination),
                                            };

        self.ciContext = [CIContext contextWithMTLDevice:self.device options:ciContextOptions];

        CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, self.device, NULL, &textureCacheRef);

        self.scaleForCoreML = [[MPSImageBilinearScale alloc] initWithDevice:device];

        CGColorSpaceRelease(destination);

        // Reusable MTL resources;
//        self.imageConversion = nil;
    }
    
    return self;
}


static NSUInteger frameSubmit = 0;
static NSUInteger frameComplete = 0;

- (void) conformPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers
              withTransform:(CGAffineTransform)transform
                       rect:(CGRect)destinationRect
            completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;
{
    CVPixelBufferRetain(pixelBuffer);

    id<MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    
    frameSubmit++;
    
//    NSLog(@"Conform Submitted frame %lu", frameSubmit);
    
   
    
//    CVMetalTextureCacheFlush(textureCacheRef, 0);
    
    // Create our metal texture from our CVPixelBuffer
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef inputCVTexture = NULL;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &inputCVTexture);
    
    assert(inputCVTexture != NULL);
    
    id<MTLTexture> inputMTLTexture = CVMetalTextureGetTexture(inputCVTexture);

    assert(inputMTLTexture != NULL);

    MPSImage* sourceInput = [[MPSImage alloc] initWithTexture:inputMTLTexture featureChannels:4];
    sourceInput.label = [NSString stringWithFormat:@"%@, %lu", @"Source", (unsigned long)frameSubmit];

#pragma mark - Convert :

    if(self.imageConversion == nil)
    {
        CGColorSpaceRef source = CVImageBufferGetColorSpace(pixelBuffer);
        CGColorSpaceRef destination = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        source = CGColorSpaceRetain(source);
        BOOL deleteSource = NO;
        if(source == NULL)
        {
            // Assume video is HD color space if not otherwise marked
            source = CGColorSpaceCreateWithName(kCGColorSpaceITUR_709);
            deleteSource = YES;
        }

        CGColorConversionInfoRef colorConversionInfo = CGColorConversionInfoCreate(source, destination);

        CGFloat background[4] = {0,0,0,0};
        self.imageConversion = [[MPSImageConversion alloc] initWithDevice:self.device
                                                                 srcAlpha:MPSAlphaTypeAlphaIsOne
                                                                destAlpha:MPSAlphaTypeAlphaIsOne
                                                          backgroundColor:background
                                                           conversionInfo:colorConversionInfo];

        if(deleteSource)
            CGColorSpaceRelease(source);
    }

    MPSImageDescriptor* convertDescriptor = [[MPSImageDescriptor alloc] init];
    convertDescriptor.width = sourceInput.width;
    convertDescriptor.height = sourceInput.height;
    convertDescriptor.featureChannels = 4;
    convertDescriptor.numberOfImages = 1;
    convertDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
    convertDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;

    MPSImage* convertTarget = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:convertDescriptor];
    convertTarget.label = [NSString stringWithFormat:@"%@, %lu", @"Convert", (unsigned long)frameSubmit];

    [self.imageConversion encodeToCommandBuffer:commandBuffer sourceImage:sourceInput destinationImage:convertTarget];

#pragma mark - Resize :
//
//    MPSImageDescriptor* resizeDescriptor = [[MPSImageDescriptor alloc] init];
//    resizeDescriptor.width = destinationRect.size.width;
//    resizeDescriptor.height = destinationRect.size.height;
//    resizeDescriptor.featureChannels = 4;
//    resizeDescriptor.numberOfImages = 1;
//    resizeDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
//    resizeDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
//
//    MPSImage* resizeTarget = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:resizeDescriptor];
//    resizeTarget.label = [NSString stringWithFormat:@"%@, %lu", @"Resize", (unsigned long)frameSubmit];
//
//    [self.scaleForCoreML encodeToCommandBuffer:commandBuffer sourceImage:sourceInput destinationImage:resizeTarget];
//
//
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
        
        if(completionBlock)
        {
            frameComplete++;
//            NSLog(@"Conform Completed frame %lu", frameComplete);
            SynopsisVideoFrameCache* cache = [[SynopsisVideoFrameCache alloc] init];
            SynopsisVideoFormatSpecifier* resultFormat = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatBGR8 backing:SynopsisVideoBackingGPU];
            SynopsisVideoFrameMPImage* result = [[SynopsisVideoFrameMPImage alloc] initWithMPSImage:convertTarget formatSpecifier:resultFormat];
            
            [cache cacheFrame:result];
            
            completionBlock(cache, nil);
            
//            if(deleteSource)
//                CGColorSpaceRelease(source);
            
//            // Release our CVMetalTextureRef
//            CFRelease(inputCVTexture);

            // We always have to release our pixel buffer
            CVPixelBufferRelease(pixelBuffer);
        }
    }];
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}


@end
