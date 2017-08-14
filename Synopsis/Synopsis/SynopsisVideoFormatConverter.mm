//
//  FrameCache.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import "SynopsisVideoFormatConverter.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

#import "StandardAnalyzerDefines.h"

@interface SynopsisVideoFormatConverter ()
{
    CVPixelBufferRef pixelBuffer;
}
// Current Frame Accessors
@property (readwrite, assign) matType currentBGR_8UC3I_Frame;
@property (readwrite, assign) matType currentBGR_32FC3_Frame;
@property (readwrite, assign) matType currentGray_8UC1_Frame;
@property (readwrite, assign) matType currentPerceptual_32FC3_Frame;

@end

@implementation SynopsisVideoFormatConverter

- (instancetype) initWithPixelBuffer:(CVPixelBufferRef)pb
{
    self = [super init];
    if(self)
    {
        if(pb)
        {
            pixelBuffer = CVPixelBufferRetain(pb);
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            
            // placeholder images
            self.currentBGR_8UC3I_Frame = matType();
            self.currentBGR_32FC3_Frame = matType();
            self.currentGray_8UC1_Frame = matType();
            self.currentPerceptual_32FC3_Frame = matType();
            
            [self cacheAndConvertBuffer:CVPixelBufferGetBaseAddress(pixelBuffer)
                                  width:CVPixelBufferGetWidth(pixelBuffer)
                                 height:CVPixelBufferGetHeight(pixelBuffer)
                            bytesPerRow:CVPixelBufferGetBytesPerRow(pixelBuffer)];
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

- (void) dealloc
{
    self.currentBGR_8UC3I_Frame.release();
    self.currentBGR_32FC3_Frame.release();
    self.currentGray_8UC1_Frame.release();
    self.currentPerceptual_32FC3_Frame.release();
}

- (matType) frameForFormat:(SynopsisFrameCacheFormat)format
{
    switch(format)
    {
        case SynopsisFrameCacheFormatOpenCVBGR8:
            return self.currentBGR_8UC3I_Frame;
            
        case SynopsisFrameCacheFormatOpenCVBGRF32:
            return self.currentBGR_32FC3_Frame;
        
        case SynopsisFrameCacheFormatOpenCVGray8:
            return self.currentGray_8UC1_Frame;
            
        case SynopsisFrameCacheFormatOpenCVPerceptual:
            return self.currentPerceptual_32FC3_Frame;
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
    
    BGRAImage.release();
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferRelease(pixelBuffer);
    
    // Convert 8 bit BGR to Grey
    cv::cvtColor(self.currentBGR_8UC3I_Frame, _currentGray_8UC1_Frame, cv::COLOR_BGR2GRAY);
    
    // Convert 8 Bit BGR to Float BGR
    self.currentBGR_8UC3I_Frame.convertTo(_currentBGR_32FC3_Frame, CV_32FC3, 1.0/255.0);
    
    // Convert Float BGR to Float Perceptual
    cv::cvtColor(self.currentBGR_32FC3_Frame, _currentPerceptual_32FC3_Frame, TO_PERCEPTUAL);
}


@end
