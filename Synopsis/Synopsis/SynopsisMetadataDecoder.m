//
//  SynopsisMetadataDecoder.m
//  Synopsis-Framework
//
//  Created by vade on 4/12/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>

#import "SynopsisMetadataDecoder.h"
#import "SynopsisMetadataDecoderVersion0.h"


@interface SynopsisMetadataDecoder ()
@property (readwrite, strong) id<SynopsisMetadataDecoder>decoder;
@property (readwrite, assign) NSUInteger version;
@end

@implementation SynopsisMetadataDecoder

- (instancetype) initWithVersion:(NSUInteger)version
{
    self = [super init];
    if(self)
    {
        // Beta - uses GZIP (ahhhhh)
        // TODO: GET RID OF THIS - no one else has this metadata
        if(version == 0)
        {
            self.decoder = [[SynopsisMetadataDecoderVersion0 alloc] init];
        }
        
        self.version = version;
    }
    
    return self;
}

- (instancetype) initWithMetadataItem:(AVMetadataItem*)metadataItem
{
    NSMutableDictionary* extraAttributes = [NSMutableDictionary dictionaryWithDictionary:metadataItem.extraAttributes];
    
    // Versions later versions may not have had extra attributes, so we default to 0 (beta)
    NSUInteger version = 0;
    
    if(extraAttributes[kSynopsislMetadataVersionKey])
    {
        NSNumber* vNum =  extraAttributes[kSynopsislMetadataVersionKey];
        version = vNum.unsignedIntegerValue;
    }
    return  [self initWithVersion:version];
}

- (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem
{
    return [self.decoder decodeSynopsisMetadata:metadataItem];
}

- (id) decodeSynopsisData:(NSData*) data
{
    return [self.decoder decodeSynopsisData:data];
    }

@end
