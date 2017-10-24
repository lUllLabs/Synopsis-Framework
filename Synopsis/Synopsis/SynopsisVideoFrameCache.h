//
//  SynopsisVideoFrameCache.h
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Synopsis/SynopsisVideoFrame.h>

@interface SynopsisVideoFrameCache : NSObject

- (void) cacheFrame:(id<SynopsisVideoFrame>)frame;
- (id<SynopsisVideoFrame>) cachedFrameForFormatSpecifier:(SynopsisVideoFormatSpecifier*)formatSpecifier;

@end
