//
//  OpenCVAnalyzerPlugin.m
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreGraphics/CoreGraphics.h>

#import "StandardAnalyzerPlugin.h"

#import "StandardAnalyzerDefines.h"

// CPU Modules
#import "AverageColor.h"
#import "DominantColorModule.h"
#import "HistogramModule.h"
#import "MotionModule.h"
#import "PerceptualHashModule.h"
#import "TrackerModule.h"
#import "SaliencyModule.h"
#import "TensorflowFeatureModule.h"

// GPU Module
#import "GPUHistogramModule.h"
#import "GPUMobileNetFeatureExtractor.h"

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

@property (atomic, readwrite, strong) NSArray* cpuModuleClasses;
@property (atomic, readwrite, strong) NSMutableArray<CPUModule*>* cpuModules;

@property (atomic, readwrite, strong) NSArray* gpuModuleClasses;
@property (atomic, readwrite, strong) NSMutableArray<GPUModule*>* gpuModules;

#pragma mark - Ingest

@property (atomic, readwrite, strong) SynopsisVideoFrameCache* lastFrameCache;
@property (readwrite, strong) NSArray<SynopsisVideoFormatSpecifier*>*pluginFormatSpecfiers;

@property (readwrite, strong) id<MTLCommandQueue> commandQueue;

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

        self.cpuModules = [NSMutableArray new];
        self.gpuModules = [NSMutableArray new];

        self.cpuModuleClasses  = @[// AVG Color is useless and just an example module
                                //NSStringFromClass([AverageColor class]),
//                                NSStringFromClass([DominantColorModule class]),
//                                NSStringFromClass([HistogramModule class]),
//                                NSStringFromClass([MotionModule class]),
////                                NSStringFromClass([PerceptualHashModule class]),
//                                NSStringFromClass([TensorflowFeatureModule class]),
//                                NSStringFromClass([TrackerModule class]),
//                                NSStringFromClass([SaliencyModule class]),
                              ];

        self.gpuModuleClasses  = @[
                                   NSStringFromClass([GPUHistogramModule class]),
                                   NSStringFromClass([GPUMobileNetFeatureExtractor class]),
                                   ];
        
        NSMutableArray<SynopsisVideoFormatSpecifier*>*requiredSpecifiers = [NSMutableArray new];
        for(NSString* moduleClass in self.cpuModuleClasses)
        {
            Class module = NSClassFromString(moduleClass);
            SynopsisVideoFormatSpecifier* format = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:[module requiredVideoFormat] backing:[module requiredVideoBacking]];
            [requiredSpecifiers addObject:format];
        }
       
        for(NSString* moduleClass in self.gpuModuleClasses)
        {
            Class module = NSClassFromString(moduleClass);
            SynopsisVideoFormatSpecifier* format = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:[module requiredVideoFormat] backing:[module requiredVideoBacking]];
            [requiredSpecifiers addObject:format];
        }
        
        self.pluginFormatSpecfiers = requiredSpecifiers;
        
        self.moduleOperationQueue = [[NSOperationQueue alloc] init];
        self.moduleOperationQueue.maxConcurrentOperationCount = self.cpuModuleClasses.count;
        
        self.concurrentModuleQueue = dispatch_queue_create("module_queue", DISPATCH_QUEUE_CONCURRENT);
        self.serialDictionaryQueue = dispatch_queue_create("dictionary_queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void) beginMetadataAnalysisSessionWithQuality:(SynopsisAnalysisQualityHint)qualityHint commandQueue:(id<MTLCommandQueue>)commandQueue;
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        cv::namedWindow("OpenCV Debug", CV_WINDOW_NORMAL);
//    });
    
    self.commandQueue = commandQueue.device.newCommandQueue;

    for(NSString* classString in self.cpuModuleClasses)
    {
        Class moduleClass = NSClassFromString(classString);
        
        CPUModule* module = [(CPUModule*)[moduleClass alloc] initWithQualityHint:qualityHint];
        
        if(module != nil)
        {
            [self.cpuModules addObject:module];
            
            if(self.verboseLog)
                self.verboseLog([@"Loaded Module: " stringByAppendingString:classString]);
        }
    }
    
    for(NSString* classString in self.gpuModuleClasses)
    {
        Class moduleClass = NSClassFromString(classString);
        
        GPUModule* module = [(GPUModule*)[moduleClass alloc] initWithQualityHint:qualityHint device:self.commandQueue.device];
        
        if(module != nil)
        {
            [self.gpuModules addObject:module];
            
            if(self.verboseLog)
                self.verboseLog([@"Loaded Module: " stringByAppendingString:classString]);
        }
    }
}

- (void) analyzeCurrentCVPixelBufferRef:(SynopsisVideoFrameCache*)frameCache completionHandler:(SynopsisAnalyzerPluginFrameAnalyzedCompleteCallback)completionHandler;
{
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    
//    NSBlockOperation* completionOp = [NSBlockOperation blockOperationWithBlock:^{
//        
//        if(completionHandler)
//            completionHandler(dictionary, nil);
//    }];
    
//    for(CPUModule* module in self.cpuModules)
//    {
//        SynopsisVideoFormat requiredFormat = [[module class] requiredVideoFormat];
//        SynopsisVideoBacking requiredBacking = [[module class] requiredVideoBacking];
//        SynopsisVideoFormatSpecifier* formatSpecifier = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:requiredFormat backing:requiredBacking];
//
//        id<SynopsisVideoFrame> currentFrame = [frameCache cachedFrameForFormatSpecifier:formatSpecifier];
//        id<SynopsisVideoFrame> previousFrame = nil;
//
//        if(self.lastFrameCache)
//            previousFrame = [self.lastFrameCache cachedFrameForFormatSpecifier:formatSpecifier];
//
//        if(currentFrame)
//        {
//            NSBlockOperation* moduleOperation = [NSBlockOperation blockOperationWithBlock:^{
//
//                NSDictionary* result = [module analyzedMetadataForCurrentFrame:currentFrame previousFrame:previousFrame];
//
//                dispatch_barrier_sync(self.serialDictionaryQueue, ^{
//                    [dictionary addEntriesFromDictionary:result];
//                });
//            }];
//
//            NSString* key = NSStringFromClass([module class]);
//            NSOperation* lastModuleOperation = self.lastModuleOperation[key];
//            if(lastModuleOperation)
//            {
//                [moduleOperation addDependency:lastModuleOperation];
//            }
//
//            self.lastModuleOperation[key] = moduleOperation;
//
//            [completionOp addDependency:moduleOperation];
//
//            [self.moduleOperationQueue addOperation:moduleOperation];
//        }
//    }
    
#pragma mark - GPU Modules

    static NSUInteger frameSubmit = 0;
    static NSUInteger frameComplete = 0;

    frameSubmit++;
    NSLog(@"Analyzer Submitted frame %lu", frameSubmit);

//        dispatch_group_t gpuModuleGroup = dispatch_group_create();

//    dispatch_semaphore_t allGPUModulesComplete = dispatch_semaphore_create(0);
    
//    dispatch_group_notify(gpuModuleGroup, self.serialDictionaryQueue, ^{
//
//        dispatch_semaphore_signal(allGPUModulesComplete);
//
//        if(completionHandler)
//            completionHandler(dictionary, nil);
//    });

    id<MTLCommandBuffer> frameCommandBuffer = [self.commandQueue commandBuffer];

    for(GPUModule* module in self.gpuModules)
    {
//        dispatch_group_enter(gpuModuleGroup);

        SynopsisVideoFormat requiredFormat = [[module class] requiredVideoFormat];
        SynopsisVideoBacking requiredBacking = [[module class] requiredVideoBacking];
        SynopsisVideoFormatSpecifier* formatSpecifier = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:requiredFormat backing:requiredBacking];
        
        id<SynopsisVideoFrame> currentFrame = [frameCache cachedFrameForFormatSpecifier:formatSpecifier];
        id<SynopsisVideoFrame> previousFrame = nil;
        
        if(self.lastFrameCache)
            previousFrame = [self.lastFrameCache cachedFrameForFormatSpecifier:formatSpecifier];
        
        if(currentFrame)
        {
            [module analyzedMetadataForCurrentFrame:currentFrame previousFrame:previousFrame commandBuffer:frameCommandBuffer completionBlock:^(NSDictionary *result, NSError *err) {

//                dispatch_group_leave(gpuModuleGroup);

                dispatch_barrier_sync(self.serialDictionaryQueue, ^{
                    [dictionary addEntriesFromDictionary:result];
                });
            }];
        }

    }
    
    [frameCommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull) {

        frameComplete++;
        NSLog(@"Analyer Completed frame %lu", frameComplete);
        
        if(completionHandler)
            completionHandler(dictionary, nil);

    }];

    
    [frameCommandBuffer commit];

//    [frameCommandBuffer waitUntilCompleted];

    
//    // LAME AS FUCK ANTON
//    dispatch_wait(allGPUModulesComplete, DISPATCH_TIME_FOREVER);
    
    self.lastFrameCache = frameCache;
}

#pragma mark - Finalization

- (NSDictionary*) finalizeMetadataAnalysisSessionWithError:(NSError**)error
{
    NSLog(@"FINALIZING ANALYZER !!?@?");
    NSMutableDictionary* finalized = [NSMutableDictionary new];
    
//    for(CPUModule* module in self.cpuModules)
//    {
//        // If a module has a description key, we append, and not add to it
//        if([module finaledAnalysisMetadata][kSynopsisStandardMetadataDescriptionDictKey])
//        {
//            NSArray* currentDescriptionArray = finalized[kSynopsisStandardMetadataDescriptionDictKey];
//
//            // Add new entries which will overwrite old description
//            NSDictionary* moduleFinal = [module finaledAnalysisMetadata];
//            if(moduleFinal)
//                [finalized addEntriesFromDictionary:moduleFinal];
//
//            // Re-write Description key with appended array
//            finalized[kSynopsisStandardMetadataDescriptionDictKey] = [finalized[kSynopsisStandardMetadataDescriptionDictKey] arrayByAddingObjectsFromArray:currentDescriptionArray];
//        }
//        else
//        {
//            [finalized addEntriesFromDictionary:[module finaledAnalysisMetadata]];
//        }
//    }

    return finalized;
}



@end
