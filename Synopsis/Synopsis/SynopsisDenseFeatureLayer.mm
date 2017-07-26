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

@interface SynopsisDenseFeatureLayer ()
@property (readwrite, strong) CALayer* containerLayer;
@end

@implementation SynopsisDenseFeatureLayer

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        NSDictionary* actions = @{@"contents" : [NSNull null] , @"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
        self.actions = actions;
        
        self.containerLayer = [CALayer layer];
        self.containerLayer.actions = actions;
        self.containerLayer.frame = self.bounds;
        [self addSublayer:self.containerLayer];
    }
    return self;
}

- (void) drawInContext:(CGContextRef)ctx
{
    self.containerLayer.frame = self.bounds;
    
    if(self.feature)
    {
        cv::Mat mat = self.feature.cvMatValue;
        if(!mat.empty())
        {
            cv::Mat normalized;
//            cv::normalize(mat, normalized);
//            normalized *= normalized;
            mat.convertTo(normalized, CV_8UC1, 255.0);
            
            int width = normalized.rows;
            int height = normalized.cols;
            
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
            CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, width, height, kCVPixelFormatType_OneComponent8, (__bridge CFDictionaryRef) (options), &imageBuffer) ;
            
            NSParameterAssert(status == kCVReturnSuccess && imageBuffer != NULL);
            
            CVPixelBufferLockBaseAddress(imageBuffer, 0);
            void *base = CVPixelBufferGetBaseAddress(imageBuffer) ;
            memcpy(base, normalized.data, normalized.total());
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
            
            self.containerLayer.contents = (id)CFBridgingRelease(imageBuffer);
        }
        else
        {
            self.containerLayer.contents = nil;
        }

    }
    else
    {
        self.containerLayer.contents = nil;
    }
}

@end
