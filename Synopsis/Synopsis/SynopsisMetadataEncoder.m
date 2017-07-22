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
@property (readwrite, assign) SynopsisMetadataEncoderJSONOption jsonOption;

@property (readwrite, strong) NSDictionary* cachedGlobalMetadata;
@property (readwrite, strong) NSMutableArray* cachedPerFrameMetadata;

@end

@implementation SynopsisMetadataEncoder

- (instancetype) initWithVersion:(NSUInteger)version withJSONOption:(SynopsisMetadataEncoderJSONOption)jsonOption;
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
        self.jsonOption = jsonOption;
        self.cachedPerFrameMetadata = [NSMutableArray array];
    }
    
    return self;
}

- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSDictionary*)metadata timeRange:(CMTimeRange)timeRange
{
    if(self.jsonOption)
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
    if(self.jsonOption)
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
    switch(self.jsonOption)
    {
        case SynopsisMetadataEncoderJSONOptionNone:
            return NO;
            
        case SynopsisMetadataEncoderJSONOptionContiguous:
        {
            NSArray* jsonDict = @[self.cachedGlobalMetadata,
                                  self.cachedPerFrameMetadata,
                                  ];
            
            NSString* aggregateMetadataAsJSON = [jsonDict jsonStringWithPrettyPrint:NO];
            NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
            [jsonData writeToURL:fileURL atomically:YES];
            
            return YES;
        }
            
        case SynopsisMetadataEncoderJSONOptionGlobalOnly:
        {
            NSString* aggregateMetadataAsJSON = [self.cachedGlobalMetadata jsonStringWithPrettyPrint:NO];
            NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
            [jsonData writeToURL:fileURL atomically:YES];
            
            return YES;
        }
            
        case SynopsisMetadataEncoderJSONOptionSequence:
        {
            NSString* aggregateMetadataAsJSON = [self.cachedGlobalMetadata jsonStringWithPrettyPrint:NO];
            NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
            [jsonData writeToURL:fileURL atomically:YES];
            
            [self.cachedPerFrameMetadata enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSArray* frameArray = (NSArray*)obj;
                
                NSString* framePath = [fileURL path];
                framePath = [framePath stringByDeletingPathExtension];
                framePath = [framePath stringByAppendingString:[NSString stringWithFormat:@"_Frame_%lu.json", idx]];
                
                NSString* aggregateMetadataAsJSON = [frameArray jsonStringWithPrettyPrint:NO];
                NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
                [jsonData writeToFile:framePath atomically:NO];
            }];

        }
         
        case SynopsisMetadataEncoderJSONOptionZSTDTraining:
        {
            NSString* aggregateMetadataAsJSON = [self.cachedGlobalMetadata jsonStringWithPrettyPrint:NO];
            NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
            [jsonData writeToURL:fileURL atomically:YES];
            
            [self.cachedPerFrameMetadata enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSArray* frameArray = (NSArray*)obj;
                
                // remove the PTS, we only ever encode the training data anyway
                if(frameArray.count == 2)
                {
                    NSDictionary* frameMetadata = frameArray[1];
                    
                    NSString* framePath = [fileURL path];
                    framePath = [framePath stringByDeletingPathExtension];
                    framePath = [framePath stringByAppendingString:[NSString stringWithFormat:@"_Frame_%lu.json", (unsigned long)idx]];
                    
                    NSString* aggregateMetadataAsJSON = [frameMetadata jsonStringWithPrettyPrint:NO];
                    NSData* jsonData = [aggregateMetadataAsJSON dataUsingEncoding:NSUTF8StringEncoding];
                    [jsonData writeToFile:framePath atomically:NO];
                }
            }];

        }
            
    }
    
    return NO;
}

@end
