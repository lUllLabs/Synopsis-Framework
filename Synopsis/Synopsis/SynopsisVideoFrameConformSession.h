//
//  SynopsisVideoFrameConformSession.h
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>
#import <Synopsis/SynopsisVideoFrameCache.h>
#import <Metal/Metal.h>

typedef void(^SynopsisVideoFrameConformSessionCompletionBlock)(SynopsisVideoFrameCache*, NSError*);

@interface SynopsisVideoFrameConformSession : NSObject

// Inform the conform session what format conversion and backing we will require
// This allows us to only create the resources we need, only do the conversions required, and not waste any time doing anything else.

- (instancetype) initWithRequiredFormatSpecifiers:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers commandQueue:(id<MTLCommandQueue>)commandQueue;

@property (readonly, strong) id<MTLCommandQueue>commandQueue;

- (void) conformPixelBuffer:(CVPixelBufferRef)pixelbuffer withTransform:(CGAffineTransform)transform rect:(CGRect)rect completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;

- (void) blockForPendingConforms;
- (void) cancelPendingConforms;

@end
