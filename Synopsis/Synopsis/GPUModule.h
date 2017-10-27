//
//  GPUModule.h
//  Synopsis-Framework
//
//  Created by vade on 10/25/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "Synopsis.h"
#import "SynopsisVideoFrameMPImage.h"
#import "StandardAnalyzerDefines.h"
#import "AnalyzerPluginProtocol.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#import <Foundation/Foundation.h>

typedef void (^GPUModuleCompletionBlock)(NSDictionary*, NSError*);

@interface GPUModule : NSObject

// GPU backed modules init with an options dict for Metal Device bullshit
- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint device:(id<MTLDevice>)device;

@property (readonly) SynopsisAnalysisQualityHint qualityHint;
@property (readonly) dispatch_queue_t completionQueue;

+ (SynopsisVideoFormat) requiredVideoFormat;
+ (SynopsisVideoBacking) requiredVideoBacking;

- (NSString*) moduleName;

- (void) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame commandBuffer:(id<MTLCommandBuffer>)buffer completionBlock:(GPUModuleCompletionBlock)completionBlock;

- (NSDictionary*) finalizedAnalysisMetadata;

@end
