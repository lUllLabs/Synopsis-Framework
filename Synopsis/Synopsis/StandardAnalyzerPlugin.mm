//
//  OpenCVAnalyzerPlugin.m
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

// Include OpenCV before anything else because FUCK C++
//#import "highgui.hpp"

#import "opencv.hpp"
#import "ocl.hpp"
#import "types_c.h"
#import "features2d.hpp"
#import "opencv2/core/utility.hpp"

#import "Constants.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>
#import <OpenCL/opencl.h>

#import "StandardAnalyzerPlugin.h"

#import "StandardAnalyzerDefines.h"

// Modules
#import "FrameCache.h"
#import "AverageColor.h"
#import "DominantColorModule.h"
#import "HistogramModule.h"
#import "MotionModule.h"
#import "PerceptualHashModule.h"
#import "TrackerModule.h"
#import "SaliencyModule.h"
#import "TensorflowFeatureModule.h"

@interface StandardAnalyzerPlugin ()
{
}

#pragma mark - Plugin Protocol Requirements

@property (atomic, readwrite, strong) NSString* pluginName;
@property (atomic, readwrite, strong) NSString* pluginIdentifier;
@property (atomic, readwrite, strong) NSArray* pluginAuthors;
@property (atomic, readwrite, strong) NSString* pluginDescription;
@property (atomic, readwrite, assign) NSUInteger pluginAPIVersionMajor;
@property (atomic, readwrite, assign) NSUInteger pluginAPIVersionMinor;
@property (atomic, readwrite, assign) NSUInteger pluginVersionMajor;
@property (atomic, readwrite, assign) NSUInteger pluginVersionMinor;
@property (atomic, readwrite, strong) NSDictionary* pluginReturnedMetadataKeysAndDataTypes;
@property (atomic, readwrite, strong) NSString* pluginMediaType;

#pragma mark - Analyzer Modules

@property (readwrite) BOOL hasModules;
@property (atomic, readwrite, strong) NSArray* moduleClasses;

@property (atomic, readwrite, strong) NSMutableArray* modules;

@property (readwrite, strong) FrameCache* frameCache;

@end

@implementation StandardAnalyzerPlugin

- (id) init
{
    self = [super init];
    if(self)
    {
        self.pluginName = @"OpenCV Analyzer";
        self.pluginIdentifier = kSynopsisStandardMetadataDictKey;
        self.pluginAuthors = @[@"Anton Marini"];
        self.pluginDescription = @"Standard Analyzer, providing Color, Features, Histogram, Motion, Tracking and Visual Saliency.";
        self.pluginAPIVersionMajor = 0;
        self.pluginAPIVersionMinor = 1;
        self.pluginVersionMajor = 0;
        self.pluginVersionMinor = 1;
        self.pluginMediaType = AVMediaTypeVideo;
        
        self.hasModules = YES;
        
        self.modules = [NSMutableArray new];
        self.moduleClasses  = @[// AVG Color is useless and just an example module
                                //NSStringFromClass([AverageColor class]),
//                                NSStringFromClass([DominantColorModule class]),
//                                NSStringFromClass([HistogramModule class]),
//                                NSStringFromClass([MotionModule class]),
                                //NSStringFromClass([PerceptualHashModule class]),
                                NSStringFromClass([TensorflowFeatureModule class]),
//                                NSStringFromClass([TrackerModule class]),
//                                NSStringFromClass([SaliencyModule class]),
                              ];
        
        cv::setUseOptimized(true);        
    }
    
    return self;
}

- (void) setOpenCLEnabled:(BOOL)enable
{
    if(enable)
    {
        if(cv::ocl::haveOpenCL())
        {
            cv::ocl::setUseOpenCL(true);
        }
    }
    else
    {
        cv::ocl::setUseOpenCL(false);
    }
}


- (void) beginMetadataAnalysisSessionWithQuality:(SynopsisAnalysisQualityHint)qualityHint
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        cv::namedWindow("OpenCV Debug", CV_WINDOW_NORMAL);
//    });
    
    [self setOpenCLEnabled:USE_OPENCL];
    
    self.frameCache = [[FrameCache alloc] initWithQualityHint:qualityHint];
    
    for(NSString* classString in self.moduleClasses)
    {
        Class moduleClass = NSClassFromString(classString);
        
        Module* module = [(Module*)[moduleClass alloc] initWithQualityHint:qualityHint];
        
        if(module != nil)
        {
        
            [self.modules addObject:module];
            
            if(self.successLog)
                self.successLog([@"Loaded Module: " stringByAppendingString:classString]);
        }
    }
}

- (cv::Mat) imageFromBaseAddress:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    size_t extendedWidth = bytesPerRow / sizeof( uint32_t ); // each pixel is 4 bytes/32 bits
    
    return cv::Mat((int)height, (int)extendedWidth, CV_8UC4, baseAddress);
}

- (void) submitAndCacheCurrentVideoBuffer:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    [self setOpenCLEnabled:USE_OPENCL];
    
    [self.frameCache cacheAndConvertBuffer:baseAddress width:width height:height bytesPerRow:bytesPerRow];
}

- (NSDictionary*) analyzeMetadataDictionaryForModuleIndex:(SynopsisModuleIndex)moduleIndex error:(NSError**)error
{
#define SHOWIMAGE 0
    
#if SHOWIMAGE
    
    cv::Mat flipped;
    cv::flip(currentBGRImage, flipped, 0);

    dispatch_sync(dispatch_get_main_queue(), ^{
        cv::imshow("Image", flipped);
    });

#endif
    
    // See inline notes for thoughts / considerations on each standard module.
    
    // Due to nuances with OpenCV's OpenCL (or maybe my own misunderstanding of OpenCL)
    // We cannot run this analysis in parallel for the OpenCL case.
    // We need to look into that...
    
    [self setOpenCLEnabled:USE_OPENCL];
    
    Module* module = self.modules[moduleIndex];
    
    FrameCacheFormat currentFormat = [module currentFrameFormat];
    FrameCacheFormat previousFormat = [module previousFrameFormat];
    
    return [module analyzedMetadataForCurrentFrame:[self.frameCache currentFrameForFormat:currentFormat] previousFrame:[self.frameCache previousFrameForFormat:previousFormat]];
}

#pragma mark - Finalization

- (NSDictionary*) finalizeMetadataAnalysisSessionWithError:(NSError**)error
{
    NSMutableDictionary* finalized = [NSMutableDictionary new];
    
    for(Module* module in self.modules)
    {
        [finalized addEntriesFromDictionary:[module finaledAnalysisMetadata]];
    }

    return finalized;
}



@end
