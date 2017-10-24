//
//  Module.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//


#import <opencv2/opencv.hpp>

#import "Synopsis.h"
#import "StandardAnalyzerDefines.h"
#import "AnalyzerPluginProtocol.h"

#import <Foundation/Foundation.h>

@interface Module : NSObject

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint NS_DESIGNATED_INITIALIZER;

@property (readonly) SynopsisAnalysisQualityHint qualityHint;

- (NSString*) moduleName;
- (SynopsisVideoFormat) requiredVideoFormat;
- (SynopsisVideoBacking) requiredVideoBacking;

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame;
- (NSDictionary*) finaledAnalysisMetadata;


@end
