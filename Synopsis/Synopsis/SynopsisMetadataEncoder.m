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
#import "SynopsisMetadataEncoderVersion2.h"
#import "NSDictionary+JSONString.h"

@interface SynopsisMetadataEncoder ()
@property (readwrite, strong) id<SynopsisVersionedMetadataEncoder>encoder;
@property (readwrite, assign) NSUInteger version;
@property (readwrite, assign) BOOL cacheForExport;

@property (readwrite, strong) NSDictionary* cachedGlobalMetadata;
@property (readwrite, strong) NSMutableArray* cachedPerFrameMetadata;

@end

@implementation SynopsisMetadataEncoder

- (instancetype) initWithVersion:(NSUInteger)version cacheJSONForExport:(BOOL)cacheJSONForExport
{
    self = [super init];
    if(self)
    {
        // Beta - uses GZIP (ahhhhh)
        // TODO: GET RID OF THIS - no one else has this metadata
        if(version < kSynopsisMetadataVersionAlpha1)
        {
            self.encoder = [[SynopsisMetadataEncoderVersion0 alloc] init];
        }
        else
        {
            self.encoder = [[SynopsisMetadataEncoderVersion2 alloc] init];
        }
        
        self.version = version;
        self.cacheForExport = cacheJSONForExport;
        self.cachedPerFrameMetadata = [NSMutableArray array];
    }
    
    return self;
}

- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    if(self.cacheForExport)
    {
        // encodeSynopsisMetadataToMetadataItem is our global metadata
        // we set this to item 0 in our array, without any time range
        self.cachedGlobalMetadata = metadata;
    }
    
    NSData* jsonData = [self encodeSynopsisMetadataToData:metadata];
    return [self.encoder encodeSynopsisMetadataToMetadataItem:jsonData timeRange:timeRange];
}

- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    if(self.cacheForExport)
    {
        [self.cachedPerFrameMetadata addObject:@[ @{ @"PTS" : @(CMTimeGetSeconds(timeRange.start)) },
                                                 metadata,]
         ];
    }
    
    NSData* jsonData = [self encodeSynopsisMetadataToData:metadata];
    return [self.encoder encodeSynopsisMetadataToTimesMetadataGroup:jsonData timeRange:timeRange];
}

- (NSData*) encodeSynopsisMetadataToData:(NSDictionary*)metadata;
{
    NSString* aggregateMetadataAsJSON = [metadata jsonStringWithPrettyPrint:NO];
    NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self.encoder encodeSynopsisMetadataToData:jsonData];
}

- (BOOL) exportJSONToURL:(NSURL*)fileURL
{
    if(self.cacheForExport)
    {
        NSArray* jsonDict = @[self.cachedGlobalMetadata,
                              self.cachedPerFrameMetadata,
                              ];
        
        NSString* aggregateMetadataAsJSON = [jsonDict jsonStringWithPrettyPrint:NO];
        NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];

        [jsonData writeToURL:fileURL atomically:YES];
        
        return YES;
    }
    else
        return NO;
}

@end
