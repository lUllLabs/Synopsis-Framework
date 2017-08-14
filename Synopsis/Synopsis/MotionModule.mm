//
//  MotionModule.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/video/tracking.hpp"
#import "MotionModule.h"

@interface MotionModule ()
{
    std::vector<cv::Point2f> frameFeatures[2];
    
    unsigned int frameCount;
    
    float avgVectorMagnitude;
    float avgVectorX;
    float avgVectorY;
}
@end

@implementation MotionModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    {
        avgVectorX = 0.0;
        avgVectorY = 0.0;
        avgVectorMagnitude = 0.0;
    }
    return self;
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataMotionDictKey;//@"Motion";
}

- (SynopsisFrameCacheFormat) currentFrameFormat
{
    return SynopsisFrameCacheFormatOpenCVGray8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)current previousFrame:(matType)previous
{
    // Empty mat - will be zeros
    cv::Mat flow;
    
    if(!previous.empty())
        cv::calcOpticalFlowFarneback(previous, current, flow, 0.5, 3, 15, 3, 5, 1.2, 0);
    
    // Avg entire flow field
    cv::Scalar avgMotion = cv::mean(flow);
    
    float xMotion = (float) -avgMotion[0] / (float)current.size().width;
    float yMotion = (float) avgMotion[1] / (float)current.size().height;
    
    float frameVectorMagnitude = sqrtf(  (xMotion * xMotion)
                                          + (yMotion * yMotion)
                                          );
    
    // Add Features to metadata
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    metadata[@"MotionVector"] = @[@(xMotion), @(yMotion)];
    metadata[@"Motion"] = @(frameVectorMagnitude);
    
    // sum Direction and speed of aggregate frames
    avgVectorMagnitude += frameVectorMagnitude;
    avgVectorX += xMotion;
    avgVectorY += yMotion;
    
    frameCount++;
    
    return metadata;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    NSMutableDictionary* metadata = [NSMutableDictionary new];

    float frameCountf = (float) frameCount;
    
    metadata[@"MotionVector"] = @[@(avgVectorX / frameCountf ), @(avgVectorY / frameCountf)];
    metadata[@"Motion"] = @(avgVectorMagnitude / frameCountf);

    return metadata;
}

@end
