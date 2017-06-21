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

- (AVTimedMetadataGroup*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    NSData* gzipData = [self encodeSynopsisMetadataToData:metadata];
    
    AVMutableMetadataItem *textItem = [AVMutableMetadataItem metadataItem];
    textItem.identifier = kSynopsislMetadataIdentifier;
    textItem.dataType = (__bridge NSString *)kCMMetadataBaseDataType_RawData;
    textItem.value = gzipData;
    textItem.time = timeRange.start;
    textItem.duration = timeRange.duration;
    
    NSMutableDictionary* extraAttributes = [NSMutableDictionary dictionaryWithDictionary:textItem.extraAttributes];
    extraAttributes[kSynopsislMetadataVersionKey] = @(kSynopsislMetadataVersionValue);
    textItem.extraAttributes = extraAttributes;
    
    AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithItems:@[textItem] timeRange:timeRange];
    
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
