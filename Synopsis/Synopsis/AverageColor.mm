//
//  AverageColor.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "AverageColor.h"

@implementation AverageColor

- (NSString*) moduleName
{
    return @"AverageColor";
}

- (FrameCacheFormat) currentFrameFormat
{
    return FrameCacheFormatBGR8;
}

- (FrameCacheFormat) previousFrameFormat
{
    return FrameCacheFormatBGR8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame
{
    // Our Mutable Metadata Dictionary:
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    cv::Scalar avgPixelIntensity = cv::mean(frame);
    
    // Add to metadata - normalize to float
    metadata[[self moduleName]] = @[@(avgPixelIntensity.val[2]), // R
                                  @(avgPixelIntensity.val[1]), // G
                                  @(avgPixelIntensity.val[0]), // B
                                  ];
    
    return metadata;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    return nil;
}


@end
