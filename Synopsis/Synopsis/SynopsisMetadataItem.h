//
//  SynopsisMetadataItem.h
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SynopsisMetadataDecoder;
// Thin wrapper for NSMetadataItem to implement Key Value access to HFS + Extended attribute's (which Synopsis Can leverage)

@interface SynopsisMetadataItem : NSObject
@property (readonly) NSURL* url;
@property (readonly) AVURLAsset* urlAsset;

// Re-use this during playback if you can!
@property (readonly) SynopsisMetadataDecoder* decoder;

- (instancetype) initWithURL:(NSURL *)url;

- (CGImageRef) cachedImage;
- (void) setCachedImage:(CGImageRef)image;

@end
