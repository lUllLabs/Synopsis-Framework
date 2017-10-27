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
@property (readwrite, strong) NSArray<id<MTLDevice>>* devices;

@property (readwrite, strong) CIContext* ciContext;

@property (readwrite, strong) id<MTLCommandQueue> commandQueue;
@property (readwrite, assign) BOOL initializedReusableMTLResources;

@property (readwrite, strong) MPSImageConversion* imageConversion;

@end

@implementation SynopsisVideoFrameConformHelperGPU

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.initializedReusableMTLResources = NO;
        self.conformQueue = [[NSOperationQueue alloc] init];
        self.conformQueue.maxConcurrentOperationCount = 1;
        self.conformQueue.qualityOfService = NSQualityOfServiceUserInitiated;

        // One device for now plz
        self.devices = @[ MTLCreateSystemDefaultDevice()];
        
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  NULL,
                                  self.devices[0],
                                  NULL,
                                  &textureCacheRef);
        
        // Current round robin device selection
        id<MTLDevice> device = self.devices[0];
        self.commandQueue = [device newCommandQueue];
        self.commandQueue.label = @"Conform Command Queue";

        // Reusable MTL resources;
        self.imageConversion = nil;
    }
    
    return self;
}



- (void) conformPixelBuffer:(CVPixelBufferRef)pixelBuffer
                  toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers
              withTransform:(CGAffineTransform)transform
                       rect:(CGRect)destinationRect
            completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;
{
    CVPixelBufferRetain(pixelBuffer);

    // Lax init of our re-usable kernels once
    // Because some resources depend on input texture size, orientation, etc
    // That info should not change during a session (ie: a source video track typically should not change size or orientation
    // Maybe we'll need to handle that one day..
    
    CGColorSpaceRef source = CVImageBufferGetColorSpace(pixelBuffer);
    source = CGColorSpaceRetain(source);
    BOOL deleteSource = NO;
    if(source == NULL)
    {
        // Assume video is HD color space if not otherwise marked
        source = CGColorSpaceCreateWithName(kCGColorSpaceITUR_709);
        deleteSource = YES;
    }
    
    id<MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;

    if(!self.initializedReusableMTLResources)
    {
        CGColorSpaceRef destination = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        
        NSDictionary* ciContextOptions = @{ kCIContextHighQualityDownsample : @NO,
                                            kCIContextOutputColorSpace : (id) CFBridgingRelease(destination),
                                            kCIContextWorkingColorSpace : (id) CFBridgingRelease(destination),
                                            };
        
        self.ciContext = [CIContext contextWithMTLDevice:self.commandQueue.device options:ciContextOptions];

        
        CGColorConversionInfoRef colorConversionInfo = CGColorConversionInfoCreate(source, destination);
        
        CGFloat background[4] = {0,0,0,0};
        self.imageConversion = [[MPSImageConversion alloc] initWithDevice:self.commandQueue.device
                                                                 srcAlpha:MPSAlphaTypeAlphaIsOne
                                                                destAlpha:MPSAlphaTypeAlphaIsOne
                                                          backgroundColor:background
                                                           conversionInfo:colorConversionInfo];
        
        CGColorSpaceRelease(destination);
    }

    CVMetalTextureCacheFlush(textureCacheRef, 0);
    
    // Create our metal texture from our CVPixelBuffer
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef linearColorSpaceRef = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    
    CVMetalTextureRef outTexture = NULL;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &outTexture);
    
    id<MTLTexture> inputMTLTexture = CVMetalTextureGetTexture(outTexture);
    
#pragma mark - Linearlize & Rotate
    
    // Rotate if necessary
    NSDictionary* ciImageOptions = @{ kCIImageColorSpace : (__bridge id) (source)};
    CIImage* linearCIImage = [CIImage imageWithMTLTexture:inputMTLTexture options:ciImageOptions];
    CIImage* transformedImage = [linearCIImage imageByApplyingTransform:transform];
    
    // Resize
    CGFloat aspect = inputMTLTexture.width / inputMTLTexture.height;
    CGFloat scale =  destinationRect.size.width / inputMTLTexture.width;
    
    CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [resizeFilter setValue:transformedImage forKey:@"inputImage"];
    [resizeFilter setValue:[NSNumber numberWithFloat:aspect] forKey:@"inputAspectRatio"];
    [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
    
    CIImage* resized = resizeFilter.outputImage;
    
    // MPS output image to our GPU Modules
    MPSImageDescriptor* toMPSImageDescriptor = [[MPSImageDescriptor alloc] init];
    toMPSImageDescriptor.width = destinationRect.size.width;
    toMPSImageDescriptor.height = destinationRect.size.height;
    toMPSImageDescriptor.featureChannels = 4;
    toMPSImageDescriptor.numberOfImages = 1;
    toMPSImageDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
    toMPSImageDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
    
    MPSImage* toMPSImage = [[MPSImage alloc] initWithDevice:self.commandQueue.device imageDescriptor:toMPSImageDescriptor];
    
    CGRect destinationNoOrigin = CGRectMake(0, 0, destinationRect.size.width, destinationRect.size.height);
    [self.ciContext render:resized toMTLTexture:toMPSImage.texture commandBuffer:commandBuffer bounds:destinationNoOrigin colorSpace:linearColorSpaceRef];
    
    // TODO: Convert to various formats we need to ingest
    
    //            MPSImage* inputImage = [[MPSImage alloc] initWithTexture:inputMTLTexture featureChannels:4];
    //
    //            MPSImageDescriptor* colorConvertTempDescriptor = [[MPSImageDescriptor alloc] init];
    //            colorConvertTempDescriptor.width = inputImage.width;
    //            colorConvertTempDescriptor.height = inputImage.height;
    //            colorConvertTempDescriptor.featureChannels = inputImage.featureChannels;
    //            colorConvertTempDescriptor.numberOfImages = 1;
    //            colorConvertTempDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
    //            colorConvertTempDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;
    //
    ////            MPSTemporaryImage* colorConvertTemp = [MPSTemporaryImage temporaryImageWithCommandBuffer:strongSelf.commandQueue.commandBuffer imageDescriptor:colorConvertTempDescriptor];
    //            MPSImage* colorConvert = [[MPSImage alloc] initWithDevice:strongSelf.commandQueue.device imageDescriptor:colorConvertTempDescriptor];
    //
    //            // Convert to linear color space
    //            [strongSelf.imageConversion encodeToCommandBuffer:commandBuffer sourceImage:inputImage destinationImage:colorConvert];
   
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
        
        if(completionBlock)
        {
            SynopsisVideoFrameCache* cache = [[SynopsisVideoFrameCache alloc] init];
            // TODO: Add images to our cache - asdf
            
            SynopsisVideoFormatSpecifier* resultFormat = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatBGR8 backing:SynopsisVideoBackingGPU];
            SynopsisVideoFrameMPImage* result = [[SynopsisVideoFrameMPImage alloc] initWithMPSImage:toMPSImage formatSpecifier:resultFormat];
            
            [cache cacheFrame:result];
            
            completionBlock(cache, nil);
            
            if(deleteSource)
                CGColorSpaceRelease(source);
            
            // Release our CVMetalTextureRef
            CFRelease(outTexture);
            CGColorSpaceRelease(linearColorSpaceRef);
            
            // We always have to release our pixel buffer
            CVPixelBufferRelease(pixelBuffer);
        }
    }];
    
    [commandBuffer commit];
    
}


@end
