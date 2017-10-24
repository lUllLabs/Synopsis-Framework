//
//  SaliencyModule.m
//  Synopsis
//
//  Created by vade on 11/13/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "SynopsisVideoFrameOpenCV.h"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/saliency.hpp"

#import "SaliencyModule.h"

@interface SaliencyModule ()
{
    // Oh god I hate C++
    cv::Ptr<cv::saliency::StaticSaliencySpectralResidual> saliencyAlgorithm;
}

@property (atomic, readwrite, assign) BOOL algoInitted;

@end

@implementation SaliencyModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    {
        saliencyAlgorithm = new cv::saliency::StaticSaliencySpectralResidual();
        self.algoInitted = NO;
    }
    return self;
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataSaliencyDictKey;//@"Saliency";
}

+ (SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingCPU;
}

+ (SynopsisVideoFormat) requiredVideoFormat
{
    return SynopsisVideoFormatBGR8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame;
{
    SynopsisVideoFrameOpenCV* frameCV = (SynopsisVideoFrameOpenCV*)frame;
    SynopsisVideoFrameOpenCV* previousFrameCV = (SynopsisVideoFrameOpenCV*)lastFrame;

    if(! self.algoInitted)
    {
        saliencyAlgorithm->setImageWidth( frameCV.mat.size().width );
        saliencyAlgorithm->setImageHeight( frameCV.mat.size().height );

//        saliencyAlgorithm->setImagesize(frame.size().width, frame.size().height);
//        saliencyAlgorithm->init();
        
        self.algoInitted = YES;
    }
    
    matType saliencyMap;
    if( saliencyAlgorithm->computeSaliency( frameCV.mat, saliencyMap ) )
    {
//        matType binaryMap;
//        saliencyAlgorithm->computeBinaryMap(saliencyMap, binaryMap);

        saliencyMap.convertTo(saliencyMap, CV_8UC1, 255.0);
        
        matType binaryMap;
        cv::threshold(saliencyMap,binaryMap,128,255,cv::THRESH_OTSU);
        
        matType Points;
        cv::findNonZero(binaryMap,Points);

        cv::Rect2f Min_Rect = cv::boundingRect(Points);
        
        cv::Point2f tl = Min_Rect.tl();
        cv::Point2f br = Min_Rect.br();
        
        tl.x /=  frame.size().width;
        tl.y /=  frame.size().height;

        br.x /=  frame.size().width;
        br.y /=  frame.size().height;
        
        return @{[self moduleName] : @[ @(tl.x), @(tl.y), @(br.x), @(br.y)] };
    }
    
    return nil;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    return nil;
}


@end
