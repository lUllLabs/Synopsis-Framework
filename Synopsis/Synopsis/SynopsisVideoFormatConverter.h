//
//  FrameCache.h
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Synopsis.h"
#import "AnalyzerPluginProtocol.h"


@interface SynopsisVideoFormatConverter : NSObject

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint NS_DESIGNATED_INITIALIZER;

- (void) cacheAndConvertBuffer:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow;

@end
