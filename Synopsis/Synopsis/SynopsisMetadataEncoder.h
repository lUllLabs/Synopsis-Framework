//
//  SynopsisMetadataEncoder.h
//  Synopsis-Framework
//
//  Created by vade on 6/20/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol SynopsisVersionedMetadataEncoder <NSObject>
- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSData*)metadata timeRange:(CMTimeRange)timeRange;
- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSData*)metadata timeRange:(CMTimeRange)timeRange;
- (NSData*) encodeSynopsisMetadataToData:(NSData*)metadata;
@end

@interface SynopsisMetadataEncoder : NSObject
@property (readonly) NSUInteger version;
@property (readonly) BOOL cacheForExport;

- (instancetype) initWithVersion:(NSUInteger)version cacheJSONForExport:(BOOL)cacheJSONForExport;
- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange;
- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange;
- (NSData*) encodeSynopsisMetadataToData:(NSDictionary*)metadata;
- (BOOL) exportJSONToURL:(NSURL*)fileURL;

@end
