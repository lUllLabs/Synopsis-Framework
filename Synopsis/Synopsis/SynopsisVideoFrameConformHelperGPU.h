//
//  SynopsisVideoFrameConformHelperGPU.h
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>
#import "SynopsisVideoFrameCache.h"
#import "SynopsisVideoFrameConformSession.h"

@interface SynopsisVideoFrameConformHelperGPU : NSObject

@property (readonly, strong) NSOperationQueue* conformQueue;

- (instancetype) initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void) conformPixelBuffer:(CVPixelBufferRef)pixelbuffer
                  toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers
              withTransform:(CGAffineTransform)transform
                       rect:(CGRect)rect
            completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;

@end
