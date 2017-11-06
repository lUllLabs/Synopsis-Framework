//
//  SynopsisVideoFrameConformSession.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisVideoFrameConformSession.h"
#import "SynopsisVideoFrameConformHelperCPU.h"
#import "SynopsisVideoFrameConformHelperGPU.h"

@interface SynopsisVideoFrameConformSession ()
@property (readwrite, strong) SynopsisVideoFrameConformHelperCPU* conformCPUHelper;
@property (readwrite, strong) SynopsisVideoFrameConformHelperGPU* conformGPUHelper;

@property (readwrite, strong) NSSet<SynopsisVideoFormatSpecifier*>* cpuOnlyFormatSpecifiers;
@property (readwrite, strong) NSSet<SynopsisVideoFormatSpecifier*>* gpuOnlyFormatSpecifiers;

@property (readwrite, strong) id<MTLDevice>device;
@property (readwrite, strong) dispatch_queue_t serialCompletionQueue;

@end

@implementation SynopsisVideoFrameConformSession

- (instancetype) initWithRequiredFormatSpecifiers:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers device:(id<MTLDevice>)device
{
    self = [super init];
    if(self)
    {
        self.device = device;
        self.conformCPUHelper = [[SynopsisVideoFrameConformHelperCPU alloc] init];
        self.conformGPUHelper = [[SynopsisVideoFrameConformHelperGPU alloc] initWithDevice:self.device];

        self.serialCompletionQueue = dispatch_queue_create("info.synopsis.formatConversion", DISPATCH_QUEUE_SERIAL);
        
        NSMutableSet<SynopsisVideoFormatSpecifier*>* cpu = [NSMutableSet new];
        NSMutableSet<SynopsisVideoFormatSpecifier*>* gpu = [NSMutableSet new];
        
        for(SynopsisVideoFormatSpecifier* format in formatSpecifiers)
        {
            switch(format.backing)
            {
                case SynopsisVideoBackingGPU:
                    [gpu addObject:format];
                    break;
                case SynopsisVideoBackingCPU:
                    [cpu addObject:format];
                    break;
                case SynopsisVideoBackingNone:
                    break;
            }
        }
        
        self.cpuOnlyFormatSpecifiers = cpu;
        self.gpuOnlyFormatSpecifiers = gpu;
    }
    
    return self;
}

- (void) conformPixelBuffer:(CVPixelBufferRef)pixelBuffer withTransform:(CGAffineTransform)transform rect:(CGRect)rect               
 completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock
{
    // Because we have 2 different completion blocks we must coalesce into one, we use
    // dispatch notify to tell us when we are actually done.
    
    NSArray<SynopsisVideoFormatSpecifier*>* localCPUFormats = [self.cpuOnlyFormatSpecifiers allObjects];
    NSArray<SynopsisVideoFormatSpecifier*>* localGPUFormats = [self.gpuOnlyFormatSpecifiers allObjects];

    SynopsisVideoFrameCache* allFormatCache = [[SynopsisVideoFrameCache alloc] init];

    dispatch_group_t formatConversionGroup = dispatch_group_create();
    dispatch_group_enter(formatConversionGroup);
    
    __block SynopsisVideoFrameCache* cpuCache = nil;
    __block NSError* cpuError = nil;

    __block SynopsisVideoFrameCache* gpuCache = nil;
    __block NSError* gpuError = nil;
    
    dispatch_group_notify(formatConversionGroup, self.serialCompletionQueue, ^{
        
        if(completionBlock)
        {
            for(SynopsisVideoFormatSpecifier* format in localCPUFormats)
            {
                id<SynopsisVideoFrame> frame = [cpuCache cachedFrameForFormatSpecifier:format];
                
                if(frame)
                {
                    [allFormatCache cacheFrame:frame];
                }
            }
            for(SynopsisVideoFormatSpecifier* format in localGPUFormats)
            {
                id<SynopsisVideoFrame> frame = [gpuCache cachedFrameForFormatSpecifier:format];
                
                if(frame)
                {
                    [allFormatCache cacheFrame:frame];
                }
            }
            
            completionBlock(allFormatCache, nil);
        }
    });
    
    if(localCPUFormats.count)
    {
        dispatch_group_enter(formatConversionGroup);
        [self.conformCPUHelper conformPixelBuffer:pixelBuffer
                                        toFormats:localCPUFormats
                                    withTransform:transform
                                             rect:rect
                                  completionBlock:^(SynopsisVideoFrameCache * cache, NSError *err) {
                                      cpuCache = cache;
                                      dispatch_group_leave(formatConversionGroup);
                                  }];
    }

    if(localGPUFormats.count)
    {
        dispatch_group_enter(formatConversionGroup);
        [self.conformGPUHelper conformPixelBuffer:pixelBuffer
                                        toFormats:localGPUFormats
                                    withTransform:transform
                                             rect:rect
                                  completionBlock:^(SynopsisVideoFrameCache * cache, NSError *err) {
                                      gpuCache = cache;
                                      dispatch_group_leave(formatConversionGroup);
                                  }];
    }
    
    dispatch_group_leave(formatConversionGroup);
}


- (void) blockForPendingConforms
{
    [self.conformCPUHelper.conformQueue waitUntilAllOperationsAreFinished];
    [self.conformGPUHelper.conformQueue waitUntilAllOperationsAreFinished];
}

- (void) cancelPendingConforms
{
    [self.conformCPUHelper.conformQueue cancelAllOperations];
    [self.conformGPUHelper.conformQueue cancelAllOperations];
}


@end
