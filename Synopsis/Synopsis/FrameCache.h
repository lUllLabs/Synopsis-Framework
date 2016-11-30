//
//  FrameCache.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

// OpenCV/OpenCL compile type config

#import "opencv.hpp"
#import "ocl.hpp"
#import "types_c.h"
#import "opencv2/core/utility.hpp"

#import "Synopsis.h"
#import <Foundation/Foundation.h>

#import "StandardAnalyzerDefines.h"

@interface FrameCache : NSObject

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint NS_DESIGNATED_INITIALIZER;

- (void) cacheAndConvertBuffer:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow;

- (matType) currentFrameForFormat:(FrameCacheFormat)format;
- (matType) previousFrameForFormat:(FrameCacheFormat)format;


@end
