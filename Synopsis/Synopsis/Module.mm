//
//  Module.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "Module.h"

@interface Module ()
@property (readwrite) SynopsisAnalysisQualityHint qualityHint;
@end

@implementation Module

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super init];
    {
        self.qualityHint = qualityHint;
    }
    return self;
}

- (instancetype)init
{
    self = [self initWithQualityHint:SynopsisAnalysisQualityHintMedium];
    return self;
}

- (NSString*) moduleName
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

- (SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingNone;
}

- (SynopsisVideoFormat) currentFrameFormat
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return SynopsisVideoFormatUnknown;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSDictionary*) finaledAnalysisMetadata;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
