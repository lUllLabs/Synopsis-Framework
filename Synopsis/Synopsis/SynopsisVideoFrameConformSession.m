//
//  SynopsisVideoFrameConformSession.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisVideoFrameConformSession.h"
#import "SynopsisVideoFrameConformHelperCPU.h"


@interface SynopsisVideoFrameConformSession ()
@property (readwrite, strong) NSOperationQueue* conformQueue;
@property (readwrite, strong) SynopsisVideoFrameConformHelperCPU* conformCPUHelper;
@property (readwrite, strong) NSSet<SynopsisVideoFormatSpecifier*>* cpuOnlyFormatSpecifiers;
@property (readwrite, strong) NSSet<SynopsisVideoFormatSpecifier*>* gpuOnlyFormatSpecifiers;
@end

@implementation SynopsisVideoFrameConformSession

- (instancetype) initWithRequiredFormatSpecifiers:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers;
{
    self = [super init];
    if(self)
    {
        self.conformQueue = [[NSOperationQueue alloc] init];
        self.conformQueue.maxConcurrentOperationCount = 1;
        self.conformQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        
        self.conformCPUHelper = [[SynopsisVideoFrameConformHelperCPU alloc] init];
        
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
    NSArray* localCPUFormats = [self.cpuOnlyFormatSpecifiers copy];
//    NSArray*
    
    NSBlockOperation* transformBlock = [NSBlockOperation blockOperationWithBlock:^{
        
        SynopsisVideoFrameCache* videoFrameCache = [self.conformCPUHelper cachedAndConformPixelBuffer:pixelBuffer toFormats:localCPUFormats withTransform:transform rect:rect];
                
        if(completionBlock)
        {
            completionBlock(videoFrameCache, nil);
        }
    }];
    
    // TODO: OPTIMIZE THIS AWAY!
    [self.conformQueue addOperations:@[transformBlock] waitUntilFinished:YES];
}


- (void) blockForPendingConforms
{
    [self.conformQueue waitUntilAllOperationsAreFinished];
}

- (void) cancelPendingConforms
{
    [self.conformQueue cancelAllOperations];
}


@end
