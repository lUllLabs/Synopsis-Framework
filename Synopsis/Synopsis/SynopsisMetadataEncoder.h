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

@protocol SynopsisMetadataEncoder <NSObject>
- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange;
- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange;
- (NSData*) encodeSynopsisMetadataToData:(NSDictionary*)metadata;
@end

@interface SynopsisMetadataEncoder : NSObject<SynopsisMetadataEncoder>

- (instancetype) initWithVersion:(NSUInteger) version;



@end
