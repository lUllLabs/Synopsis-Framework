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
                       rect:(CGRect)rect
            completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;
{
    // Hold on to our pixel buffer before we
    CVPixelBufferRetain(pixelBuffer);

    // Laxy init of our re-usable kernels once
    // Because some resources depend on input texture size, orientation, etc
    // That info should not change during a session (ie: a source video track typically should not change size or orientation
    // Maybe we'll need to handle that one day..
    
    if(!self.initializedReusableMTLResources)
    {
        CGColorSpaceRef destination = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        CGColorSpaceRef source = CVImageBufferGetColorSpace(pixelBuffer);
        
        NSDictionary* ciContextOptions = @{ kCIContextHighQualityDownsample : @NO,
                                            kCIContextOutputColorSpace : (id) CFBridgingRelease(destination),
                                            kCIContextWorkingColorSpace : (id) CFBridgingRelease(destination),
                                            };
        
        self.ciContext = [CIContext contextWithMTLDevice:self.commandQueue.device options:ciContextOptions];

        
        BOOL deleteSource = NO;
        if(source == NULL)
        {
            // Assume video is HD color space if not otherwise marked
            source = CGColorSpaceCreateWithName(kCGColorSpaceITUR_709);
            deleteSource = YES;
        }
        
        CGColorConversionInfoRef colorConversionInfo = CGColorConversionInfoCreate(source, destination);
        
        CGFloat background[4] = {0,0,0,0};
        self.imageConversion = [[MPSImageConversion alloc] initWithDevice:self.commandQueue.device
                                                                 srcAlpha:MPSAlphaTypeAlphaIsOne
                                                                destAlpha:MPSAlphaTypeAlphaIsOne
                                                          backgroundColor:background
                                                           conversionInfo:colorConversionInfo];
        
        CGColorSpaceRelease(destination);
        if(deleteSource)
            CGColorSpaceRelease(source);

    }

    __weak typeof(self) weakSelf = self;
    
//    NSBlockOperation* conformOperation = [NSBlockOperation blockOperationWithBlock:^{

        __strong typeof(weakSelf) strongSelf = weakSelf;
    
    id<MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    
        if(strongSelf)
        {
            // Create our metal texture from our CVPixelBuffer
            size_t width = CVPixelBufferGetWidth(pixelBuffer);
            size_t height = CVPixelBufferGetHeight(pixelBuffer);

            CGColorSpaceRef linearColorSpaceRef = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);

            CVMetalTextureRef outTexture = NULL;
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &outTexture);
            
            id<MTLTexture> inputMTLTexture = CVMetalTextureGetTexture(outTexture);
            
#pragma mark - Linearlize
            
            MPSImage* inputImage = [[MPSImage alloc] initWithTexture:inputMTLTexture featureChannels:4];
            
            MPSImageDescriptor* colorConvertTempDescriptor = [[MPSImageDescriptor alloc] init];
            colorConvertTempDescriptor.width = inputImage.width;
            colorConvertTempDescriptor.height = inputImage.height;
            colorConvertTempDescriptor.featureChannels = inputImage.featureChannels;
            colorConvertTempDescriptor.numberOfImages = 1;
            colorConvertTempDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
            colorConvertTempDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;

//            MPSTemporaryImage* colorConvertTemp = [MPSTemporaryImage temporaryImageWithCommandBuffer:strongSelf.commandQueue.commandBuffer imageDescriptor:colorConvertTempDescriptor];
            MPSImage* colorConvert = [[MPSImage alloc] initWithDevice:strongSelf.commandQueue.device imageDescriptor:colorConvertTempDescriptor];

            // Convert to linear color space
            [strongSelf.imageConversion encodeToCommandBuffer:commandBuffer sourceImage:inputImage destinationImage:colorConvert];
            
#pragma mark - Rotate
            
            // Rotate if necessary
            NSDictionary* ciImageOptions = @{ kCIImageColorSpace : (id) CFBridgingRelease(linearColorSpaceRef)};
            CIImage* linearCIImage = [CIImage imageWithMTLTexture:colorConvert.texture options:ciImageOptions];
            CIImage* transformedImage = [linearCIImage imageByApplyingTransform:transform];
            
            // Resize
//            CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
//            [resizeFilter setValue:transformedImage forKey:@"inputImage"];
//            [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
//            [resizeFilter setValue:[NSNumber numberWithFloat:xRatio] forKey:@"inputScale"];
            
//            CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
//            CIVector *cropRect = [CIVector vectorWithX:rect.origin.x Y:rect.origin.y Z:rect.size.width W:rect.size.height];
//            [cropFilter setValue:resizeFilter.outputImage forKey:@"inputImage"];
//            [cropFilter setValue:cropRect forKey:@"inputRectangle"];
//            CIImage *croppedImage = cropFilter.outputImage;
            
            //
            MPSImageDescriptor* toMPSImageDescriptor = [[MPSImageDescriptor alloc] init];
            toMPSImageDescriptor.width = inputImage.width;
            toMPSImageDescriptor.height = inputImage.height;
            toMPSImageDescriptor.featureChannels = inputImage.featureChannels;
            toMPSImageDescriptor.numberOfImages = 1;
            toMPSImageDescriptor.channelFormat = MPSImageFeatureChannelFormatUnorm8;
            toMPSImageDescriptor.cpuCacheMode = MTLCPUCacheModeDefaultCache;

//            MPSTemporaryImage* toMPSTempImage = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:toMPSImageDescriptor];
            MPSImage* toMPSImage = [[MPSImage alloc] initWithDevice:strongSelf.commandQueue.device imageDescriptor:toMPSImageDescriptor];
//            id<MTLTexture> texture = [
//
            [strongSelf.ciContext render:transformedImage toMTLTexture:toMPSImage.texture commandBuffer:commandBuffer bounds:transformedImage.extent colorSpace:linearColorSpaceRef];
            
            // Convert to various formats we need to ingest
          
            // enqueue
            
            
            
            [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
                
                if(completionBlock)
                {
                    SynopsisVideoFrameCache* cache = [[SynopsisVideoFrameCache alloc] init];
                    // TODO: Add images to our cache - asdf
                    
                    SynopsisVideoFormatSpecifier* resultFormat = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatBGR8 backing:SynopsisVideoBackingGPU];
                    SynopsisVideoFrameMPImage* result = [[SynopsisVideoFrameMPImage alloc] initWithMPSImage:toMPSImage formatSpecifier:resultFormat];
                    
                    [cache cacheFrame:result];
                    
                    completionBlock(cache, nil);
                }
            }];

            // Actually submit our commands to the GPU
            [commandBuffer commit];

            // Release our CVMetalTextureRef
            CFRelease(outTexture);
            CGColorSpaceRelease(linearColorSpaceRef);
            
        } // End if strongSelf
        
        // We always have to release our pixel buffer
        CVPixelBufferRelease(pixelBuffer);
//
//
//    }];
//
//    // TODO: OPTIMIZE THIS AWAY!
//    [self.conformQueue addOperations:@[conformOperation] waitUntilFinished:YES];

    
}


@end
