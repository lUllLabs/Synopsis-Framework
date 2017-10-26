//
//  MPSHistogramModule.m
//  Synopsis-Framework
//
//  Created by vade on 10/25/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "MPSHistogramModule.h"

@interface MPSHistogramModule ()
@property (readwrite, strong) MPSImageHistogram* histogramOp;
@property (readwrite, assign) MPSImageHistogramInfo* histogramInfo;
@end

@implementation MPSHistogramModule

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
        // Now we must read the
         unsigned char* start = [histogramResult contents];
         NSUInteger buffLength = [histogramResult length];
         
         NSMutableArray* histogramValues = [NSMutableArray arrayWithCapacity:256];
         
         for(int i = 0; i < buffLength; i++)
         {
             unsigned char r = start[i];
             unsigned char g = start[i + 1];
             unsigned char b = start[i + 2];

             NSArray* channelValuesForRow = @[ @( (float)r / 255.0 ), // R
                                               @( (float)g / 255.0 ), // G
                                               @( (float)b / 255.0 ), // B
                                               ];
             //
             [histogramValues addObject:channelValuesForRow];
             i += 4 ;
         }

         if(completionBlock)
         {
             
             completionBlock( @{[self moduleName] : histogramValues} , nil);
         }

     }];
    
}

- (NSDictionary*) finaledAnalysisMetadata;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}
@end

