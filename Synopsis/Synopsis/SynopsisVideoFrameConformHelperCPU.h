//
//  SynopsisVideoFrameConformHelperCPU.h
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>
#import "SynopsisVideoFrameCache.h"
@interface SynopsisVideoFrameConformHelperCPU : NSObject

- (SynopsisVideoFrameCache*) cachedAndConformPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                               toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers
                                           withTransform:(CGAffineTransform)transform
                                                    rect:(CGRect)rect;


@end
