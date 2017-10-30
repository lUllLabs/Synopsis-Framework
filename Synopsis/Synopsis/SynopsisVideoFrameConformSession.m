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

@property (readwrite, strong) id<MTLCommandQueue>commandQueue;

@end

@implementation SynopsisVideoFrameConformSession

- (instancetype) initWithRequiredFormatSpecifiers:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers commandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    if(self)
    {
        self.commandQueue = commandQueue;
        self.conformCPUHelper = [[SynopsisVideoFrameConformHelperCPU alloc] init];
        self.conformGPUHelper = [[SynopsisVideoFrameConformHelperGPU alloc] initWithCommandQueue:self.commandQueue];

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

- (void) conformPixelBuffer:(CVPixelBufferRef)pixelBuffer withTransform:(CGAffineTransform)transform rect:(CGRect)rect completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock
{
    NSArray* localCPUFormats = [self.cpuOnlyFormatSpecifiers allObjects];
    NSArray* localGPUFormats = [self.gpuOnlyFormatSpecifiers allObjects];

    // This can run the completion block more than once because programming is hard
    
//    if(localCPUFormats.count)
//    {
//        [self.conformCPUHelper conformPixelBuffer:pixelBuffer
//                                        toFormats:localCPUFormats
//                                    withTransform:transform
//                                             rect:rect
//                                  completionBlock:completionBlock];
//    }
//
//    if(localGPUFormats.count)
    {
        [self.conformGPUHelper conformPixelBuffer:pixelBuffer
                                        toFormats:localGPUFormats
                                    withTransform:transform
                                             rect:rect
                                  completionBlock:completionBlock];
    }
    
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
