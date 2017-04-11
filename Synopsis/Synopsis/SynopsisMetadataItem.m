//
//  SynopsisMetadataItem.m
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import <AVFoundation/AVFoundation.h>
#import "SynopsisMetadataItem.h"
#import "GZIP.h"

#import "Color+linearRGBColor.h"

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
            self.globalSynopsisMetadata = [SynopsisMetadataItem decodeSynopsisMetadata:synopsisMetadataItem];
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
    NSDictionary* standardDictionary = [self.globalSynopsisMetadata objectForKey:kSynopsisStandardMetadataDictKey];

    if([key isEqualToString:kSynopsislMetadataIdentifier])
        return self.globalSynopsisMetadata;
    
    if([key isEqualToString:kSynopsisStandardMetadataDictKey])
    {
       return standardDictionary;
    }

    return standardDictionary[key];
    
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
//        NSData* zipped = (NSData*)metadataItem.value;
//        NSData* json = [zipped gunzippedData];
//        id decodedJSON = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
//        if(decodedJSON)
//        {
////            return decodedJSON;
//            return [self metadataWithOptimizedObjects:decodedJSON];
//        }
        return [self decodeSynopsisData: (NSData*)metadataItem.value];
    }
    
    return nil;
}


+ (id) decodeSynopsisData:(NSData*) data
{
    NSData* zipped = data;
    NSData* json = [zipped gunzippedData];
    id decodedJSON = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:nil];
    if(decodedJSON)
    {
        //            return decodedJSON;
        return [self metadataWithOptimizedObjects:decodedJSON];
    }
    
    return nil;

}


+ (NSDictionary*) metadataWithOptimizedObjects:(NSDictionary*)global
{
    NSMutableDictionary* optimizedStandardDictionary = [NSMutableDictionary dictionaryWithDictionary:global[kSynopsisStandardMetadataDictKey]];
    
    // manually switch out our target types
    
    // Convert all arrays of NSNumbers into linear RGB NSColors once, and only once
    NSArray* domColors = [ColorHelper linearColorsWithArraysOfRGBComponents:[optimizedStandardDictionary valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];

    optimizedStandardDictionary[kSynopsisStandardMetadataDominantColorValuesDictKey] = domColors;

    // Convert all feature vectors to cv::Mat, and set cv::Mat value appropriately
    NSArray* featureArray = [optimizedStandardDictionary valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

    SynopsisDenseFeature* featureValue = [[SynopsisDenseFeature alloc] initWithFeatureArray:featureArray];
    
    optimizedStandardDictionary[kSynopsisStandardMetadataFeatureVectorDictKey] = featureValue;

    // Convert histogram bins to cv::Mat
    NSArray* histogramArray = [optimizedStandardDictionary valueForKey:kSynopsisStandardMetadataHistogramDictKey];

    // Make 3 mutable arrays for R/G/B
    // We then flatten by making planar r followed by planar g, then b to a single dimensional array
    NSMutableArray* histogramR = [NSMutableArray arrayWithCapacity:256];
    NSMutableArray* histogramG = [NSMutableArray arrayWithCapacity:256];
    NSMutableArray* histogramB = [NSMutableArray arrayWithCapacity:256];
    
    for(int i = 0; i < 256; i++)
    {
        NSArray<NSNumber *>* rgbHist = histogramArray[i];
        
        // Min / Max fixes some NAN errors
        [histogramR addObject: @( MIN(1.0, MAX(0.0,  rgbHist[0].floatValue)) )];
        [histogramG addObject: @( MIN(1.0, MAX(0.0,  rgbHist[1].floatValue)) )];
        [histogramB addObject: @( MIN(1.0, MAX(0.0,  rgbHist[2].floatValue)) )];
    }
    
    NSArray* histogramFeatures = [[[NSArray arrayWithArray:histogramR] arrayByAddingObjectsFromArray:histogramG] arrayByAddingObjectsFromArray:histogramB];
 
    SynopsisDenseFeature* histValue = [[SynopsisDenseFeature alloc] initWithFeatureArray:histogramFeatures];
    
    optimizedStandardDictionary[kSynopsisStandardMetadataHistogramDictKey] = histValue;
    
    // Convert all feature vectors to cv::Mat, and set cv::Mat value appropriately
    NSArray* motionArray = [optimizedStandardDictionary valueForKey:kSynopsisStandardMetadataMotionVectorDictKey];
    
    SynopsisDenseFeature* motionValue = [[SynopsisDenseFeature alloc] initWithFeatureArray:motionArray];
    
    optimizedStandardDictionary[kSynopsisStandardMetadataMotionVectorDictKey] = motionValue;

    // replace our standard dictionary with optimized outputs
    NSMutableDictionary* optimizedGlobalDict = [NSMutableDictionary dictionaryWithDictionary:global];
    optimizedGlobalDict[kSynopsisStandardMetadataDictKey] = optimizedStandardDictionary;
    
    return optimizedGlobalDict;
}

@end
