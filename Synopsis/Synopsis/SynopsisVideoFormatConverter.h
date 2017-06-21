//
//  FrameCache.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//


#import <Synopsis/Synopsis.h>
#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface SynopsisVideoFormatConverter : NSObject

- (instancetype) initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
