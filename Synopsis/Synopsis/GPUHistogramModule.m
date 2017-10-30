//
//  MPSHistogramModule.m
//  Synopsis-Framework
//
//  Created by vade on 10/25/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "GPUHistogramModule.h"

@interface GPUHistogramModule ()
@property (readwrite, strong) MPSImageHistogram* histogramOp;
@property (readwrite, assign) MPSImageHistogramInfo* histogramInfo;
@end

@implementation GPUHistogramModule

// GPU backed modules init with an options dict for Metal Device bullshit
- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint device:(id<MTLDevice>)device
{
    self = [super initWithQualityHint:qualityHint device:device];
    if(self)
    {
        self.histogramInfo = malloc(sizeof(MPSImageHistogramInfo));
        
        vector_float4 max = {1, 1, 1, 1};
        vector_float4 min = {0, 0, 0, 0};
        self.histogramInfo->numberOfHistogramEntries = 256;
        self.histogramInfo->maxPixelValue = max;
        self.histogramInfo->minPixelValue = min;
        self.histogramInfo->histogramForAlpha = NO;
    
        self.histogramOp = [[MPSImageHistogram alloc] initWithDevice:device histogramInfo:self.histogramInfo];
    }
    return self;
}

- (void)dealloc
{
    if(self.histogramInfo)
        free(self.histogramInfo);
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataHistogramDictKey;
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
    
    id<MTLBuffer> histogramResult = [buffer.device newBufferWithLength:[self.histogramOp histogramSizeForSourceFormat:MTLPixelFormatBGRA8Unorm] options:MTLResourceStorageModeShared];
    
    [self.histogramOp encodeToCommandBuffer:buffer
                              sourceTexture:frameMPImage.mpsImage.texture
                                  histogram:histogramResult
                            histogramOffset:0];
    
    [buffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
         //specifically dispatch work away from encode thread - so we dont block enqueueing new work
         // by reading old work and doing dumb math
         dispatch_async(self.completionQueue, ^{
             
             uint32_t* start = [histogramResult contents];
             NSUInteger buffLength = [histogramResult length];
             
             NSMutableArray<NSMutableArray<NSNumber*>*>* histogramValues = [NSMutableArray arrayWithCapacity:256];
             
             size_t uint32tsize = sizeof(uint32_t);
             
             // 4 bytes for uint32tsize typically
             buffLength = buffLength / uint32tsize;
             
             //3 Channels
             buffLength = buffLength / 3;
             
//             float rSum = 0.0;
             float rMax = 0.0;
//             float rMin = 1.0;

//             float gSum = 0.0;
             float gMax = 0.0;
//             float gMin = 1.0;
             
//             float bSum = 0.0;
             float bMax = 0.0;
//             float bMin = 1.0;
             
             for(int i = 0; i < buffLength; i++)
             {
                 // Planar histogram offsets?
                 uint32_t rUI = start[i];
                 uint32_t gUI = start[i + 256];
                 uint32_t bUI = start[i + 512];
                 
                 float r = (float)rUI;
                 float g = (float)gUI;
                 float b = (float)bUI;
                 
//                 r = pow(r, 1.0/2.2);
//                 g = pow(g, 1.0/2.2);
//                 b = pow(b, 1.0/2.2);

//                 rSum += r;
//                 gSum += g;
//                 bSum += b;
                 
                 rMax = MAX(r, rMax);
                 gMax = MAX(g, gMax);
                 bMax = MAX(b, bMax);

//                 rMin = MIN(r, rMin);
//                 gMin = MIN(g, gMin);
//                 bMin = MIN(b, bMin);
                 
                 NSArray* channelValuesForRow = @[ @(r), @(g), @(b)];
                 
                 [histogramValues addObject:[channelValuesForRow mutableCopy]];
             }
             
//             float maxSum = MAX(rSum, MAX(bSum, gSum));
             float max = MAX(rMax, MAX(bMax, gMax));
//             float min = MAX(rMin, MAX(bMin, gMin));

             for(NSMutableArray<NSNumber*>* tuplet in histogramValues)
             {
                 tuplet[0] = @( tuplet[0].floatValue / max );
                 tuplet[1] = @( tuplet[1].floatValue / max );
                 tuplet[2] = @( tuplet[2].floatValue / max );
                 
//                 tuplet[0] = @( [self remapValue:tuplet[0].floatValue oldLow:min oldHigh:max newLow:0 newHigh:1] );
//                 tuplet[1] = @( [self remapValue:tuplet[1].floatValue oldLow:min oldHigh:max newLow:0 newHigh:1] );
//                 tuplet[2] = @( [self remapValue:tuplet[2].floatValue oldLow:min oldHigh:max newLow:0 newHigh:1] );
             }
             
             if(completionBlock)
             {
                 completionBlock( @{[self moduleName] : histogramValues} , nil);
             }
         });
     }];
}

- (float) remapValue:(float)value oldLow:(float)low1 oldHigh:(float)high1 newLow:(float)low2 newHigh:(float)high2
{
    return (low2 + (value - low1) * (high2 - low2) / (high1 - low1) );
}

- (NSDictionary*) finaledAnalysisMetadata;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

@end

