//
//  SynopsisVideoFrameCache.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisVideoFrameCache.h"

@interface SynopsisVideoFrameCache ()
@property (readwrite, strong) NSMutableArray* videoCacheArray;
@end
@implementation SynopsisVideoFrameCache

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.videoCacheArray = [NSMutableArray new];
    }
    return self;
}

- (void) cacheFrame:(id<SynopsisVideoFrame>)frame
{
    [self.videoCacheArray addObject:frame];
}

- (id<SynopsisVideoFrame>) cachedFrameForFormatSpecifier:(SynopsisVideoFormatSpecifier*)formatSpecifier;
{
    id<SynopsisVideoFrame> matchingFrame = nil;
    for(id<SynopsisVideoFrame>frame in self.videoCacheArray)
    {
        if( [frame.videoFormatSpecifier isEqual:formatSpecifier])
        {
            matchingFrame = frame;
            break;
        }
    }
    
    return matchingFrame;
}


@end
