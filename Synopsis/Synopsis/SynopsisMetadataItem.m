//
//  SynopsisMetadataItem.m
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import "SynopsisMetadataItem.h"
#import "GZIP.h"

@interface SynopsisMetadataItem ()
@property (readwrite) NSURL* url;
@property (readwrite, strong) AVURLAsset* urlAsset;
@property (readwrite, strong) NSDictionary* globalSynopsisMetadata;
@end

@implementation SynopsisMetadataItem

- (instancetype) initWithURL:(NSURL *)url
{
    self = [super initWithURL:url];
    if(self)
    {
        self.url = url;
        self.urlAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @NO}];

        NSArray* metadataItems = [self.urlAsset metadata];
        
        AVMetadataItem* synopsisMetadataItem = nil;
        
        for(AVMetadataItem* metadataItem in metadataItems)
        {
            if([metadataItem.identifier isEqualToString:kSynopsislMetadataIdentifier])
            {
                synopsisMetadataItem = metadataItem;
                break;
            }
        }
        
        if(synopsisMetadataItem)
        {
            NSData* compressedDataDictionary = (NSData*)synopsisMetadataItem.value;
            
            if(compressedDataDictionary.length)
            {
                NSData* unzippedData = [compressedDataDictionary gunzippedData];
                
                if(unzippedData.length)
                {
                    self.globalSynopsisMetadata = [NSJSONSerialization JSONObjectWithData:unzippedData options:0 error:nil];
                }
            }
        }
    }
    
    return self;
}

// We test equality based on the file system object we are represeting.
- (BOOL) isEqual:(id)object
{
    if([object isKindOfClass:[SynopsisMetadataItem class]])
    {
        SynopsisMetadataItem* obj = (SynopsisMetadataItem*)object;
        
        BOOL equal = [self.url.absoluteURL isEqual:obj.url.absoluteURL];
        
        // helpful for debugging even if stupid 
        if(equal)
            return YES;
        
        return NO;
    }
    
    return [super isEqual:object];
}

- (id) valueForKey:(NSString *)key
{
    NSDictionary* standardDictionary = [self.globalSynopsisMetadata objectForKey:kSynopsisGlobalMetadataDictKey];

    if([key isEqualToString:kSynopsisGlobalMetadataSortKey])
    {
       return standardDictionary;
    }
    
    if([key isEqualToString:kSynopsisPerceptualHashSortKey])
    {
        return [standardDictionary objectForKey:kSynopsisPerceptualHashDictKey];
    }

    if([key isEqualToString:kSynopsisDominantColorValuesSortKey])
    {
        return [standardDictionary objectForKey:kSynopsisDominantColorValuesDictKey];
    }

    if([key isEqualToString:kSynopsisHistogramSortKey])
    {
        return [standardDictionary objectForKey:kSynopsisHistogramDictKey];
    }

    return nil;//[super valueForKey:key];
}

+ (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem
{
    NSString* key = metadataItem.identifier;
    
    if([key isEqualToString:kSynopsislMetadataIdentifier])
    {
        // JSON
        //                // Decode our metadata..
        //                NSString* stringValue = (NSString*)metadataItem.value;
        //                NSData* dataValue = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
        //                id decodedJSON = [NSJSONSerialization JSONObjectWithData:dataValue options:kNilOptions error:nil];
        //                if(decodedJSON)
        //                    [metadataDictionary setObject:decodedJSON forKey:key];
        
        //                // BSON:
        //                NSData* zipped = (NSData*)metadataItem.value;
        //                NSData* bsonData = [zipped gunzippedData];
        //                NSDictionary* bsonDict = [NSDictionary dictionaryWithBSON:bsonData];
        //                if(bsonDict)
        //                    [metadataDictionary setObject:bsonDict forKey:key];
        
        // GZIP + JSON
        NSData* zipped = (NSData*)metadataItem.value;
        NSData* json = [zipped gunzippedData];
        id decodedJSON = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
        if(decodedJSON)
        {
            return decodedJSON;
        }
        
        return nil;
    }
    
    return nil;
}

@end
