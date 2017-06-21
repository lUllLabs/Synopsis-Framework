//
//  SynopsisMetadataEncoder.m
//  Synopsis-Framework
//
//  Created by vade on 6/20/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import "SynopsisMetadataEncoder.h"
#import "SynopsisMetadataEncoderVersion0.h"

@interface SynopsisMetadataEncoder ()
@property (readwrite, strong) id<SynopsisMetadataEncoder>encoder;
@end

@implementation SynopsisMetadataEncoder

- (instancetype) initWithVersion:(NSUInteger)version
{
    self = [super init];
    if(self)
    {
        // Beta - uses GZIP (ahhhhh)
        // TODO: GET RID OF THIS - no one else has this metadata
        if(version == 0)
        {
            self.encoder = [[SynopsisMetadataEncoderVersion0 alloc] init];
        }
    }
    
    return self;
}

- (AVTimedMetadataGroup*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    return [self.encoder encodeSynopsisMetadataToMetadataItem:metadata timeRange:timeRange];
}

- (NSData*) encodeSynopsisMetadataToData:(NSDictionary*)metadata;
{
    return [self.encoder encodeSynopsisMetadataToData:metadata];
}

@end
