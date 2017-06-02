//
//  SynopsisDenseFeatureLayer.m
//  Synopsis-Framework
//
//  Created by vade on 5/5/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "TargetConditionals.h"
#import "SynopsisDenseFeature+Private.h"
#import "SynopsisDenseFeatureLayer.h"

@implementation SynopsisDenseFeatureLayer

- (instancetype) init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

- (void) drawInContext:(CGContextRef)ctx
{
    
    cv::Mat mat = self.feature.cvMatValue;
    cv::Mat normalized;
    cv::normalize(mat, normalized);
    
    normalized.convertTo(normalized, CV_8UC4);
    
    int depth = normalized.depth();
    int channels = normalized.channels();
    
    int width = normalized.cols;
    int height = normalized.rows;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                              [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
#if TARGET_OS_OSX
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLTextureCacheCompatibilityKey,   
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
#else
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESTextureCacheCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
#endif
                             @{}, kCVPixelBufferIOSurfacePropertiesKey,
                             [NSNumber numberWithInt:width], kCVPixelBufferWidthKey,
                             [NSNumber numberWithInt:height], kCVPixelBufferHeightKey,
                             nil];
    
    CVPixelBufferRef imageBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, width, height, kCVPixelFormatType_32BGRA, (CFDictionaryRef) CFBridgingRetain(options), &imageBuffer) ;
    
    NSParameterAssert(status == kCVReturnSuccess && imageBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *base = CVPixelBufferGetBaseAddress(imageBuffer) ;
    memcpy(base, normalized.data, normalized.total());
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    self.contents = (id)CFBridgingRelease(imageBuffer);    
}

@end
