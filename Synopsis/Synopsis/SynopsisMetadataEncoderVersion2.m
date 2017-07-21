//
//  SynopsisMetadataEncoderVersion2.m
//  Synopsis-Framework
//
//  Created by vade on 7/21/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisMetadataEncoderVersion2.h"
#import "SynopsisMetadataDecoder.h"
#import <Synopsis/Synopsis.h>
#import "zstd.h"


static ZSTD_CDict* compressionDict = nil;

@interface SynopsisMetadataEncoderVersion2 ()
{
    ZSTD_CCtx* compressionContext;
}
@end

@implementation SynopsisMetadataEncoderVersion2

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{

            NSURL* pathToCompressionDict = [[NSBundle bundleForClass:[self class]] URLForResource:@"dictionary" withExtension:@"zstddict"];

            NSData* dictionaryData = [NSData dataWithContentsOfURL:pathToCompressionDict];
            
            compressionDict = ZSTD_createCDict(dictionaryData.bytes, dictionaryData.length, ZSTD_maxCLevel());
        });
        
        if(compressionDict == nil)
        {
            return nil;
        }
        
        compressionContext = nil;
        
        compressionContext = ZSTD_createCCtx();
        
        if(compressionContext == nil)
        {
            return nil;
        }

    }
    return self;
}

- (void) dealloc
{
    if(compressionContext != nil)
    {
        ZSTD_freeCCtx(compressionContext);
    }
}


- (AVMetadataItem*) encodeSynopsisMetadataToMetadataItem:(NSData*)metadata timeRange:(CMTimeRange)timeRange
{
    AVMutableMetadataItem *item = [AVMutableMetadataItem metadataItem];
    item.identifier = kSynopsisMetadataIdentifier;
    item.dataType = (__bridge NSString *)kCMMetadataBaseDataType_RawData;
    item.value = metadata;
    item.time = timeRange.start;
    item.duration = timeRange.duration;
    
    NSMutableDictionary* extraAttributes = [NSMutableDictionary dictionaryWithDictionary:item.extraAttributes];
    extraAttributes[kSynopsisMetadataVersionKey] = @(kSynopsisMetadataVersionValue);
   
    item.extraAttributes = extraAttributes;
    
    return item;
}

- (AVTimedMetadataGroup*) encodeSynopsisMetadataToTimesMetadataGroup:(NSData*)metadata timeRange:(CMTimeRange)timeRange
{
    AVMetadataItem* item = [self encodeSynopsisMetadataToMetadataItem:metadata timeRange:timeRange];
    
    AVTimedMetadataGroup *group = [[AVTimedMetadataGroup alloc] initWithItems:@[item] timeRange:timeRange];
    
    return group;
}

- (NSData*) encodeSynopsisMetadataToData:(NSData*)metadata
{

    size_t expectedCompressionSize = ZSTD_compressBound(metadata.length);
    
    void* const compressionBuffer = malloc(expectedCompressionSize);
    
    size_t const compressedSize = ZSTD_compress_usingCDict(compressionContext, compressionBuffer, expectedCompressionSize, metadata.bytes, metadata.length, compressionDict);
    
    // Hit error on compression use ZSTD_getErrorName for error reporting eventually.
    if(ZSTD_isError(compressedSize))
    {
        return nil;
    }
    
    NSData* zstdCompressedData = [[NSData alloc] initWithBytesNoCopy:compressionBuffer length:compressedSize freeWhenDone:YES];
    
    return zstdCompressedData;
}

@end
