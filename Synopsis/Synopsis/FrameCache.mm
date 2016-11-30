//
//  FrameCache.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import "opencv.hpp"
#import "ocl.hpp"
#import "types_c.h"
#import "opencv2/core/utility.hpp"

#import "FrameCache.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <OpenCL/opencl.h>

#import "StandardAnalyzerDefines.h"

@interface FrameCache ()

@property (readwrite, assign) SynopsisAnalysisQualityHint quality;

// Current Frame Accessors
@property (readwrite, assign) matType currentBGR_8UC3I_Frame;
@property (readwrite, assign) matType currentBGR_32FC3_Frame;
@property (readwrite, assign) matType currentGray_8UC1_Frame;
@property (readwrite, assign) matType currentPerceptual_32FC3_Frame;

// Last Frame Accessors
@property (readwrite, assign) matType lastBGR_32FC3_Frame;
@property (readwrite, assign) matType lastBGR_8UC3I_Frame;
@property (readwrite, assign) matType lastGray_8UC1_Frame;
@property (readwrite, assign) matType lastPerceptual_32FC3_Frame;



@end

@implementation FrameCache

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super init];
    if(self)
    {
        self.quality = qualityHint;
        
        // placeholder images
        self.currentBGR_8UC3I_Frame = matType();
        self.currentBGR_32FC3_Frame = matType();
        self.currentGray_8UC1_Frame = matType();
        self.currentPerceptual_32FC3_Frame = matType();
        
        self.lastBGR_8UC3I_Frame = matType();
        self.lastBGR_32FC3_Frame = matType();
        self.lastGray_8UC1_Frame = matType();
        self.lastPerceptual_32FC3_Frame = matType();
    }
    
    return self;
}

- (instancetype)init
{
    self = [self initWithQualityHint:SynopsisAnalysisQualityHintMedium];
    return self;
}


- (void) dealloc
{
    self.currentBGR_8UC3I_Frame.release();
    self.currentBGR_32FC3_Frame.release();
    self.currentGray_8UC1_Frame.release();
    self.currentPerceptual_32FC3_Frame.release();

    self.lastBGR_8UC3I_Frame.release();
    self.lastBGR_32FC3_Frame.release();
    self.lastGray_8UC1_Frame.release();
    self.lastPerceptual_32FC3_Frame.release();

}

- (matType) currentFrameForFormat:(FrameCacheFormat)format
{
    switch(format)
    {
        case FrameCacheFormatBGR8:
            return self.currentBGR_8UC3I_Frame;
            
        case FrameCacheFormatBGRF32:
            return self.currentBGR_32FC3_Frame;
        
        case FrameCacheFormatGray8:
            return self.currentGray_8UC1_Frame;
            
        case FrameCacheFormatPerceptual:
            return self.currentPerceptual_32FC3_Frame;
    }
}

- (matType) previousFrameForFormat:(FrameCacheFormat)format
{
    switch(format)
    {
        case FrameCacheFormatBGR8:
            return self.lastBGR_8UC3I_Frame;
            
        case FrameCacheFormatBGRF32:
            return self.lastBGR_32FC3_Frame;
            
        case FrameCacheFormatGray8:
            return self.lastGray_8UC1_Frame;
            
        case FrameCacheFormatPerceptual:
            return self.lastPerceptual_32FC3_Frame;
    }
}

- (cv::Mat) imageFromBaseAddress:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    size_t extendedWidth = bytesPerRow / sizeof( uint32_t ); // each pixel is 4 bytes/32 bits
    
    return cv::Mat((int)height, (int)extendedWidth, CV_8UC4, baseAddress);
}

// TODO: Think about lazy conversion. If we dont hit an accessor, we dont convert.
- (void) cacheAndConvertBuffer:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    // Cache our current images if we have them, to our last images
    if( !self.currentBGR_8UC3I_Frame.empty() )
    {
        self.currentBGR_8UC3I_Frame.copyTo( _lastBGR_8UC3I_Frame) ;
    }

    if( !self.currentBGR_32FC3_Frame.empty() )
    {
        self.currentBGR_32FC3_Frame.copyTo( _lastBGR_32FC3_Frame );
    }

    if( !self.currentGray_8UC1_Frame.empty() )
    {
        self.currentGray_8UC1_Frame.copyTo( _lastGray_8UC1_Frame );
    }

    if( !self.lastPerceptual_32FC3_Frame.empty() )
    {
        self.lastPerceptual_32FC3_Frame.copyTo( _lastPerceptual_32FC3_Frame );
    }
    
    cv::Mat BGRAImage = [self imageFromBaseAddress:baseAddress width:width height:height bytesPerRow:bytesPerRow];
    
    // Convert img BGRA to CIE_LAB or LCh - Float 32 for color calulation fidelity
    // Note floating point assumtions:
    // http://docs.opencv.org/2.4.11/modules/imgproc/doc/miscellaneous_transformations.html
    // The conventional ranges for R, G, and B channel values are:
    // 0 to 255 for CV_8U images
    // 0 to 65535 for CV_16U images
    // 0 to 1 for CV_32F images = matType
    // Convert our 8 Bit BGRA to BGR
    cv::cvtColor(BGRAImage, _currentBGR_8UC3I_Frame, cv::COLOR_BGRA2BGR);
    
    // Convert 8 bit BGR to Grey
    cv::cvtColor(self.currentBGR_8UC3I_Frame, _currentGray_8UC1_Frame, cv::COLOR_BGR2GRAY);
    
    // Convert 8 Bit BGR to Float BGR
    self.currentBGR_8UC3I_Frame.convertTo(_currentBGR_32FC3_Frame, CV_32FC3, 1.0/255.0);
    
    // Convert Float BGR to Float Perceptual
    cv::cvtColor(self.currentBGR_32FC3_Frame, _currentPerceptual_32FC3_Frame, TO_PERCEPTUAL);
}


@end
