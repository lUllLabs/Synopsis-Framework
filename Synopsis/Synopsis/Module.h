//
//  Module.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "opencv.hpp"
#import "ocl.hpp"
#import "types_c.h"
#import "opencv2/core/utility.hpp"

#import "Synopsis.h"
#import "StandardAnalyzerDefines.h"
#import "AnalyzerPluginProtocol.h"

#import <Foundation/Foundation.h>

@interface Module : NSObject

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint NS_DESIGNATED_INITIALIZER;

@property (readonly) SynopsisAnalysisQualityHint qualityHint;

- (NSString*) moduleName;
- (SynopsisFrameCacheFormat) currentFrameFormat;

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame;
- (NSDictionary*) finaledAnalysisMetadata;


@end
