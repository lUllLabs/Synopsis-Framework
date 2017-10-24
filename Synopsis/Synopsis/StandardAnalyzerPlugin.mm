//
//  OpenCVAnalyzerPlugin.m
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

// Include OpenCV before anything else because FUCK C++
//#import "highgui.hpp"

#import <opencv2/opencv.hpp>
#import <opencv2/core/ocl.hpp>

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

#import "StandardAnalyzerPlugin.h"

#import "StandardAnalyzerDefines.h"

// Modules
#import "SynopsisVideoFormatConverter.h"
#import "SynopsisVideoFormatConverter+Private.h"

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
@property (atomic, readwrite, strong) NSString* pluginMediaType;
@property (atomic, readwrite, strong) dispatch_queue_t concurrentModuleQueue;
@property (atomic, readwrite, strong) dispatch_queue_t serialDictionaryQueue;

@property (atomic, readwrite, strong) NSOperationQueue* moduleOperationQueue;
@property (atomic, readwrite, strong) NSMutableDictionary* lastModuleOperation;

#pragma mark - Analyzer Modules

@property (readwrite) BOOL hasModules;
@property (atomic, readwrite, strong) NSArray* moduleClasses;

@property (atomic, readwrite, strong) NSMutableArray* modules;

@property (atomic, readwrite, strong) SynopsisVideoFormatConverter* lastFrameVideoFormatConverter;

@end

@implementation StandardAnalyzerPlugin

- (id) init
{
    self = [super init];
    if(self)
    {
        self.pluginName = @"Standard Analyzer";
        self.pluginIdentifier = kSynopsisStandardMetadataDictKey;
        self.pluginAuthors = @[@"Anton Marini"];
        self.pluginDescription = @"Standard Analyzer, providing Color, Features, Content Tagging, Histogram, Motion";
        self.pluginAPIVersionMajor = 0;
        self.pluginAPIVersionMinor = 1;
        self.pluginVersionMajor = 0;
        self.pluginVersionMinor = 1;
        self.pluginMediaType = AVMediaTypeVideo;
        
        self.hasModules = YES;
        
        self.modules = [NSMutableArray new];
        self.moduleClasses  = @[// AVG Color is useless and just an example module
                                //NSStringFromClass([AverageColor class]),
                                NSStringFromClass([DominantColorModule class]),
                                NSStringFromClass([HistogramModule class]),
                                NSStringFromClass([MotionModule class]),
//                                NSStringFromClass([PerceptualHashModule class]),
                                NSStringFromClass([TensorflowFeatureModule class]),
                                NSStringFromClass([TrackerModule class]),
//                                NSStringFromClass([SaliencyModule class]),
                              ];
        
        self.moduleOperationQueue = [[NSOperationQueue alloc] init];
        self.moduleOperationQueue.maxConcurrentOperationCount = self.moduleClasses.count;
        
        cv::setUseOptimized(true);
        
        self.concurrentModuleQueue = dispatch_queue_create("module_queue", DISPATCH_QUEUE_CONCURRENT);
        self.serialDictionaryQueue = dispatch_queue_create("dictionary_queue", DISPATCH_QUEUE_SERIAL);
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
    
    
    for(NSString* classString in self.moduleClasses)
    {
        Class moduleClass = NSClassFromString(classString);
        
        Module* module = [(Module*)[moduleClass alloc] initWithQualityHint:qualityHint];
        
        if(module != nil)
        {
            [self.modules addObject:module];
            
            if(self.verboseLog)
                self.verboseLog([@"Loaded Module: " stringByAppendingString:classString]);
        }
    }
}

- (void) analyzeCurrentCVPixelBufferRef:(SynopsisVideoFormatConverter*)converter completionHandler:(SynopsisAnalyzerPluginFrameAnalyzedCompleteCallback)completionHandler;
{
    [self setOpenCLEnabled:USE_OPENCL];
        
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    
    NSBlockOperation* completionOp = [NSBlockOperation blockOperationWithBlock:^{
        
        if(completionHandler)
            completionHandler(dictionary, nil);
    }];
    
    for(Module* module in self.modules)
    {
        SynopsisVideoFormat requiredFormat = [module requiredVideoFormat];
        SynopsisVideoBacking requiredBacking = [module requiredVideoBacking];
        
        matType currentFrame = [converter frameForFormat:requiredFormat backing:requiredBacking];
        matType previousFrame;
        
        if(self.lastFrameVideoFormatConverter)
            previousFrame = [self.lastFrameVideoFormatConverter frameForFormat:requiredFormat backing:requiredBacking];
        
        NSBlockOperation* moduleOperation = [NSBlockOperation blockOperationWithBlock:^{
        
            NSDictionary* result = [module analyzedMetadataForCurrentFrame:currentFrame previousFrame:previousFrame];
            
            dispatch_barrier_sync(self.serialDictionaryQueue, ^{
                [dictionary addEntriesFromDictionary:result];
            });
        }];

        NSString* key = NSStringFromClass([module class]);
        NSOperation* lastModuleOperation = self.lastModuleOperation[key];
        if(lastModuleOperation)
        {
            [moduleOperation addDependency:lastModuleOperation];
        }
        
        self.lastModuleOperation[key] = moduleOperation;
        
        [completionOp addDependency:moduleOperation];
        
        [self.moduleOperationQueue addOperation:moduleOperation];
    }
    
    [self.moduleOperationQueue addOperation:completionOp];
    
    [self.moduleOperationQueue waitUntilAllOperationsAreFinished];
    
    self.lastFrameVideoFormatConverter = converter;
}

#pragma mark - Finalization

- (NSDictionary*) finalizeMetadataAnalysisSessionWithError:(NSError**)error
{
    NSMutableDictionary* finalized = [NSMutableDictionary new];
    
    for(Module* module in self.modules)
    {
        // If a module has a description key, we append, and not add to it
        if([module finaledAnalysisMetadata][kSynopsisStandardMetadataDescriptionDictKey])
        {
            NSArray* currentDescriptionArray = finalized[kSynopsisStandardMetadataDescriptionDictKey];

            // Add new entries which will overwrite old description
            [finalized addEntriesFromDictionary:[module finaledAnalysisMetadata]];

            // Re-write Description key with appended array
            finalized[kSynopsisStandardMetadataDescriptionDictKey] = [finalized[kSynopsisStandardMetadataDescriptionDictKey] arrayByAddingObjectsFromArray:currentDescriptionArray];
        }
        else
        {
            [finalized addEntriesFromDictionary:[module finaledAnalysisMetadata]];
        }
    }

    return finalized;
}



@end
