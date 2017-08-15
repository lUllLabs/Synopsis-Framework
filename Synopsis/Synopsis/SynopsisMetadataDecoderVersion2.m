//
//  SynopsisMetadataDecoderVersion2.m
//  Synopsis-Framework
//
//  Created by vade on 7/21/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisMetadataDecoderVersion2.h"

#import <Synopsis/Synopsis.h>
#import "zstd.h"

static ZSTD_DDict* decompressionDict = nil;

@interface SynopsisMetadataDecoderVersion2 ()
{
    ZSTD_DCtx* decompressionContext;
}
@end

@implementation SynopsisMetadataDecoderVersion2

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            NSURL* pathToCompressionDict = [[NSBundle bundleForClass:[self class]] URLForResource:@"dictionary" withExtension:@"zstddict"];
            
            NSData* dictionaryData = [NSData dataWithContentsOfURL:pathToCompressionDict];
            
            decompressionDict = ZSTD_createDDict(dictionaryData.bytes, dictionaryData.length);
        });

        if(decompressionDict == nil)
        {
            return nil;
        }
        
        decompressionContext = nil;
        
        decompressionContext = ZSTD_createDCtx();
        
        if(decompressionContext == nil)
        {
            return nil;
        }
    }
    
    return self;
}

- (void) dealloc
{
    if(decompressionContext != nil)
    {
        ZSTD_freeDCtx(decompressionContext);
    }
}


- (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem
{
    NSString* key = metadataItem.identifier;
    
    if([key isEqualToString:kSynopsisMetadataIdentifier])
    {
        return [self decodeSynopsisData: (NSData*)metadataItem.value];
    }
    
    return nil;
}

- (id) decodeSynopsisData:(NSData*) data
{
    unsigned long long expectedDecompressedSize = ZSTD_getFrameContentSize(data.bytes, data.length);
    
    // Not compressed with zstd
    if( expectedDecompressedSize == ZSTD_CONTENTSIZE_ERROR)
    {
        return nil;
    }
    
    // unable to determine destination size
    if( expectedDecompressedSize == ZSTD_CONTENTSIZE_UNKNOWN)
    {
        return nil;
    }
    
    void* const decompressionBuffer = malloc(expectedDecompressedSize);

    size_t decompressedSize = ZSTD_decompress_usingDDict(decompressionContext, decompressionBuffer, expectedDecompressedSize, data.bytes, data.length, decompressionDict);
    
    // if our expected size and actual size dont match, we had a decompression issue.
    if(decompressedSize != expectedDecompressedSize)
    {
        return nil;
    }
    
    NSData* decompressedData = [[NSData alloc] initWithBytesNoCopy:decompressionBuffer length:decompressedSize freeWhenDone:YES];
    
    id decodedJSON = nil;
    @try
    {
        decodedJSON  = [NSJSONSerialization JSONObjectWithData:decompressedData options:kNilOptions error:nil];
        
    }
    @catch (NSException *exception)
    {
        
        
    }
    @finally
    {
        if(decodedJSON)
        {
            return [self metadataWithOptimizedObjects:decodedJSON];
        }
    }
    
    return nil;
}

- (NSDictionary*) metadataWithOptimizedObjects:(NSDictionary*)global
{
    // manually switch out our target types
    NSMutableDictionary* optimizedStandardDictionary = [NSMutableDictionary dictionaryWithDictionary:global[kSynopsisStandardMetadataDictKey]];
    
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
