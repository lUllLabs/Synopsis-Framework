//
//  SynopsisMetadataEncoderVersion0.m
//  Synopsis-Framework
//
//  Created by vade on 6/20/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisMetadataEncoderVersion0.h"
#import <Synopsis/Synopsis.h>
#import "GZIP.h"
#import "NSDictionary+JSONString.h"

@implementation SynopsisMetadataEncoderVersion0

- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    NSData* gzipData = [self encodeSynopsisMetadataToData:metadata];

    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.identifier = kSynopsislMetadataIdentifier;
    item.dataType = (__bridge NSString *)kCMMetadataBaseDataType_RawData;
    item.value = gzipData;
    item.time = timeRange.start;
    item.duration = timeRange.duration;
    
    NSMutableDictionary* extraAttributes = [NSMutableDictionary dictionaryWithDictionary:item.extraAttributes];
    extraAttributes[kSynopsislMetadataVersionKey] = @(kSynopsislMetadataVersionValue);
    item.extraAttributes = extraAttributes;
    
    return item;
}

- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    AVMetadataItem* item = [self encodeSynopsisMetadataToMetadataItem:metadata timeRange:timeRange];
    
    AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithItems:@[item] timeRange:timeRange];
    
    return group;
}

- (NSData*) encodeSynopsisMetadataToData:(NSDictionary*)metadata
{
    if([NSJSONSerialization isValidJSONObject:metadata])
    {
        // TODO: Probably want to mark to NO for shipping code:
        NSString* aggregateMetadataAsJSON = [metadata jsonStringWithPrettyPrint:NO];
        NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSData* gzipData = [jsonData gzippedData];
        
        return gzipData;
    }

    return nil;
}

@end
