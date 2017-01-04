//
//  TrackerModule.m
//  Synopsis
//
//  Created by vade on 11/13/16.
//  Copyright © 2016 metavisual. All rights reserved.
//


#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/video/tracking.hpp"
#import "MotionModule.h"

#import "TrackerModule.h"

#define OPTICAL_FLOW 1

@interface TrackerModule ()
{
    std::vector<cv::Point2f> frameFeatures[2];

    cv::Ptr<cv::ORB> detector;
    
    int numFeaturesToTrack;


}
@end

@implementation TrackerModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    {
        
        switch (qualityHint) {
            case SynopsisAnalysisQualityHintLow:
                numFeaturesToTrack = 25;
                break;
            case SynopsisAnalysisQualityHintMedium:
                numFeaturesToTrack = 50;
                break;
            case SynopsisAnalysisQualityHintHigh:
                numFeaturesToTrack = 100;
                break;
            case SynopsisAnalysisQualityHintOriginal:
                numFeaturesToTrack = 200;
                break;
                
            default:
                break;
        }
        
        // TODO: Adjust based on Quality.
        // Default parameters of ORB
        int nfeatures=numFeaturesToTrack;
        float scaleFactor=1.2f;
        int nlevels=8;
        int edgeThreshold=20; // Changed default (31);
        int firstLevel=0;
        int WTA_K=2;
        int scoreType=cv::ORB::HARRIS_SCORE;
        int patchSize=31;
        int fastThreshold=20;
        
        detector = cv::ORB::create(nfeatures,
                                   scaleFactor,
                                   nlevels,
                                   edgeThreshold,
                                   firstLevel,
                                   WTA_K,
                                   scoreType,
                                   patchSize,
                                   fastThreshold );
    }
    return self;
}

- (void) dealloc
{
#if OPTICAL_FLOW
#else
    detector.release();
#endif
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataTrackerDictKey;//@"Tracker";
}

- (FrameCacheFormat) currentFrameFormat
{
    return FrameCacheFormatGray8;
}

- (FrameCacheFormat) previousFrameFormat
{
    return FrameCacheFormatGray8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame
{
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
#if OPTICAL_FLOW
    [metadata addEntriesFromDictionary:[self detectFeaturesFlow:frame previousImage:lastFrame]];
#else
    
    [metadata addEntriesFromDictionary:[self detectFeaturesORBCVMat:frame]];
#endif
    return metadata;
}


- (NSDictionary*) finaledAnalysisMetadata
{
    return nil;
}

#pragma mark - Optical Flow

static BOOL hasInitialized = false;
static int tryCount = 0;

- (NSDictionary*) detectFeaturesFlow:(matType)current previousImage:(matType) previous
{
    cv::TermCriteria termcrit(cv::TermCriteria::COUNT|cv::TermCriteria::EPS,20,0.03);
    std::vector<float> err;
    std::vector<uchar> status;
    
    NSMutableArray* pointsArray = [NSMutableArray new];
    int numAccumulatedFlowPoints = 0;

    if(!hasInitialized || (tryCount == 0) )
    {
        cv::goodFeaturesToTrack(current, // the image
                                frameFeatures[1],   // the output detected features
                                numFeaturesToTrack,  // the maximum number of features
                                0.01,     // quality level
                                5     // min distance between two features
                                );
        
        //cv::cornerSubPix(current, currentFrameFeatures, cv::Size(10, 10), cv::Size(-1,-1), termcrit);
        
    }
    
    else if( !frameFeatures[0].empty() )
    {
        cv::Size optical_flow_window = cvSize(3,3);
        cv::calcOpticalFlowPyrLK(previous,
                                 current, // 2 consecutive images
                                 frameFeatures[0], // input point positions in first im
                                 frameFeatures[1], // output point positions in the 2nd
                                 status,    // tracking success
                                 err,      // tracking error
                                 optical_flow_window,
                                 3,
                                 termcrit
                                 );
        
        for(int i = 0; i < frameFeatures[0].size(); i++)
        {
            if(status.size())
            {
                if(status[i])
                {
                    numAccumulatedFlowPoints++;
                    
                    cv::Point curr = frameFeatures[0][i];
                    
                    CGPoint point = CGPointZero;
                    {
                        point = CGPointMake((float)curr.x / (float)current.size().width,
                                            1.0 - (float)curr.y / (float)current.size().height);
                    }
                    
                    [pointsArray addObject:@[ @(point.x), @(point.y)]];
                }
            }
        }
    }
    else
    {
        for(int i = 0; i < frameFeatures[1].size(); i++)
        {
            numAccumulatedFlowPoints++;
            
            cv::Point curr = frameFeatures[1][i];
            
            CGPoint point = CGPointZero;
            {
                point = CGPointMake((float)curr.x / (float)current.size().width,
                                    1.0 - (float)curr.y / (float)current.size().height);
            }
            
            [pointsArray addObject:@[ @(point.x), @(point.y)]];
        }
    }
    
    // Add Features to metadata
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    metadata[kSynopsisStandardMetadataTrackerDictKey] = pointsArray;
    
    // Switch up our last frame
    std::swap(frameFeatures[1], frameFeatures[0]);
    hasInitialized = true;
    
    // If we havent found any points, thats a problem
    if(numAccumulatedFlowPoints < (numFeaturesToTrack / 4))
    {
            tryCount = 0; // causes reset?
            frameFeatures[0].clear();
            frameFeatures[1].clear();
    }
    
    return metadata;

}


- (NSDictionary*) detectFeaturesORBCVMat:(matType)image
{
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    std::vector<cv::KeyPoint> keypoints;
    detector->detect(image, keypoints, cv::noArray());
    
    NSMutableArray* keyPointsArray = [NSMutableArray new];
    
    for(std::vector<cv::KeyPoint>::iterator keyPoint = keypoints.begin(); keyPoint != keypoints.end(); keyPoint++)
    {
        CGPoint point = CGPointZero;
        {
            point = CGPointMake((float)keyPoint->pt.x / (float)image.size().width,
                                (float)keyPoint->pt.y / (float)image.size().height);
        }
        
        [keyPointsArray addObject:@[ @(point.x), @(point.y)]];
    }
    
    // Add Features to metadata
    metadata[kSynopsisStandardMetadataTrackerDictKey] = keyPointsArray;
    
    return metadata;
}

@end
