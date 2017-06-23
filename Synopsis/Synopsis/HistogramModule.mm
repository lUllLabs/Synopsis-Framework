//
//  HistogramModule.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "HistogramModule.h"

@interface HistogramModule ()
{
    // No need for OpenCL for these
    cv::Mat accumulatedHist0;
    cv::Mat accumulatedHist1;
    cv::Mat accumulatedHist2;
}
@end

@implementation HistogramModule

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame
{
    return [self detectHistogramInCVMat:frame];
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataHistogramDictKey;//@"Histogram";
}

- (SynopsisFrameCacheFormat) currentFrameFormat
{
    return SynopsisFrameCacheFormatOpenCVBGR8;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    // Normalize the result
    normalize(accumulatedHist0, accumulatedHist0, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() ); // B
    normalize(accumulatedHist1, accumulatedHist1, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() ); // G
    normalize(accumulatedHist2, accumulatedHist2, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() ); // R
    
    NSMutableArray* histogramValues = [NSMutableArray arrayWithCapacity:accumulatedHist0.rows];
    
    for(int i = 0; i < accumulatedHist0.rows; i++)
    {
        NSArray* channelValuesForRow = @[ @( accumulatedHist2.at<float>(i, 0) / 255.0 ), // R
                                          @( accumulatedHist1.at<float>(i, 0) / 255.0 ), // G
                                          @( accumulatedHist0.at<float>(i, 0) / 255.0 ), // B
                                          ];
        
        histogramValues[i] = channelValuesForRow;
    }

    return @{[self moduleName] : histogramValues};
}

#pragma mark - Histogram

- (NSDictionary*) detectHistogramInCVMat:(matType)image
{
    // Our Mutable Metadata Dictionary:
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    // Split image into channels
    std::vector<cv::Mat> imageChannels(3);
    cv::split(image, imageChannels);
    
    cv::Mat histMat0, histMat1, histMat2;
    
    int numBins = 256;
    int histSize[] = {numBins};
    
    float range[] = { 0.0, 255.0 };
    const float* ranges[] = { range };
    
    // we compute the histogram from these channels
    int channels[] = {0};
    
    // TODO : use Accumulation of histogram to average over all frames ?
    calcHist(&imageChannels[0], // image
             1, // image count
             channels, // channel mapping
             cv::Mat(), // do not use mask
             histMat0,
             1, // dimensions
             histSize,
             ranges,
             true, // the histogram is uniform
             false );
    
    calcHist(&imageChannels[1], // image
             1, // image count
             channels, // channel mapping
             cv::Mat(), // do not use mask
             histMat1,
             1, // dimensions
             histSize,
             ranges,
             true, // the histogram is uniform
             false );
    
    calcHist(&imageChannels[2], // image
             1, // image count
             channels, // channel mapping
             cv::Mat(), // do not use mask
             histMat2,
             1, // dimensions
             histSize,
             ranges,
             true, // the histogram is uniform
             false );
    
    // We are going to accumulate our histogram to get an average histogram for every frame of the movie
    if(accumulatedHist0.empty())
    {
        histMat0.copyTo(accumulatedHist0);
    }
    else
    {
        cv::add(accumulatedHist0, histMat0, accumulatedHist0);
    }
    
    if(accumulatedHist1.empty())
    {
        histMat1.copyTo(accumulatedHist1);
    }
    else
    {
        cv::add(accumulatedHist1, histMat1, accumulatedHist1);
    }
    
    if(accumulatedHist2.empty())
    {
        histMat2.copyTo(accumulatedHist2);
    }
    else
    {
        cv::add(accumulatedHist2, histMat2, accumulatedHist2);
    }
    
    // Normalize the result
    normalize(histMat0, histMat0, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() );
    normalize(histMat1, histMat1, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() );
    normalize(histMat2, histMat2, 0.0, 255.0, cv::NORM_MINMAX, -1, cv::Mat() );
    
    NSMutableArray* histogramValues = [NSMutableArray arrayWithCapacity:histMat0.rows];
    
    for(int i = 0; i < histMat0.rows; i++)
    {
        NSArray* channelValuesForRow = @[ @( histMat2.at<float>(i, 0) / 255.0 ), // R
                                          @( histMat1.at<float>(i, 0) / 255.0 ), // G
                                          @( histMat0.at<float>(i, 0) / 255.0 ), // B
                                          ];
        
        histogramValues[i] = channelValuesForRow;
    }
    
    metadata[[self moduleName]] = histogramValues;
    
    return metadata;
}

@end
