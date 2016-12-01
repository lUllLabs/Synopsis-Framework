//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "opencv2/opencv.hpp"
#import "opencv2/core/ocl.hpp"
#import "opencv2/core/types_c.h"
#import "opencv2/core/utility.hpp"
#import "opencv2/features2d.hpp"

#import "Constants.h"
#import "MetadataComparisons.h"

#import "NSSortDescriptor+SynopsisMetadata.h"
#import "NSColor+linearRGBColor.h"
#pragma mark - Hash Helper Functions

// Perceptual Hash
// Calculate how alike 2 hashes are
// We use this result to compare how close 2 hashes are to a 3rd relative hash

#pragma mark -

@implementation NSSortDescriptor (SynopsisMetadata)

+ (NSSortDescriptor*)synopsisBestMatchSortDescriptorRelativeTo:(NSDictionary*)standardMetadata
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSDictionary* global1 = (NSDictionary*)obj1;
        NSDictionary* global2 = (NSDictionary*)obj2;
        
//        NSString* phash1 = [global1 valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];
//        NSString* phash2 = [global2 valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];
//        NSString* relativeHash = [standardMetadata valueForKey:kSynopsisStandardMetadataPerceptualHashDictKey];
//    
//        float ph1 = compareHashes(phash1, relativeHash);
//        float ph2 = compareHashes(phash2, relativeHash);

        
        NSArray* featureVec1 = [global1 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
        NSArray* featureVec2 = [global2 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
        NSArray* relativeVec = [standardMetadata valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

        float fv1 = compareFeatureVector(featureVec1, relativeVec);
        float fv2 = compareFeatureVector(featureVec2, relativeVec);
        
        NSArray* hist1 = [global1 valueForKey:kSynopsisStandardMetadataHistogramDictKey];
        NSArray* hist2 = [global2 valueForKey:kSynopsisStandardMetadataHistogramDictKey];
        NSArray* relativeHist = [standardMetadata valueForKey:kSynopsisStandardMetadataHistogramDictKey];
        
        float h1 = compareHistogtams(hist1, relativeHist);
        float h2 = compareHistogtams(hist2, relativeHist);

        NSArray* domColors1 = [NSColor linearColorsWithArraysOfRGBComponents:[global1 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
        NSArray* domColors2 = [NSColor linearColorsWithArraysOfRGBComponents:[global2 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
        NSArray* relativeColors = [NSColor linearColorsWithArraysOfRGBComponents:[standardMetadata valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey]];
        
        float relativeHue = weightHueDominantColors(relativeColors);
        float relativeSat = weightSaturationDominantColors(relativeColors);
        float relativeBri = weightBrightnessDominantColors(relativeColors);
        
        float hue1 = 1.0 - fabsf(weightHueDominantColors(domColors1) - relativeHue);
        float hue2 = 1.0 - fabsf(weightHueDominantColors(domColors2) - relativeHue);
      
        float sat1 = 1.0 - fabsf(weightSaturationDominantColors(domColors1) - relativeSat);
        float sat2 = 1.0 - fabsf(weightSaturationDominantColors(domColors2) - relativeSat);
        
        float bri1 = 1.0 - fabsf(weightBrightnessDominantColors(domColors1) - relativeBri);
        float bri2 = 1.0 - fabsf(weightBrightnessDominantColors(domColors2) - relativeBri);
        
//        NSArray* combinedFeatures1 = @[ @(fv1), @(ph1), @(h1), @(hue1), @(sat1), @(bri1)];
//        NSArray* combinedFeatures2 = @[ @(fv2), @(ph2), @(h2), @(hue2), @(sat2), @(bri2)];

        // Biased Linear weights.
        float distance1 = fv1 + (( h1 + hue1 + sat1 + bri1 ) * 0.5);
        float distance2 = fv2 + (( h2 + hue2 + sat2 + bri2 ) * 0.5);

//        const float colorFeatureWeight = 0.5;
//        // Euclidean Distance - biased towards features / hash -  biased against hue, sat, bri
//        float distance1 = sqrtf( ( fv1 * fv1 ) + ( ph1 * ph1 ) + ( ( h1 * h1  ) + ( hue1 * hue1 * colorFeatureWeight  ) + ( sat1 * sat1 * colorFeatureWeight  ) + ( bri1 * bri1 * colorFeatureWeight ) ) );
//        float distance2 = sqrtf( ( fv2 * fv2 ) + ( ph2 * ph2 ) + ( ( h2 * h2  ) + ( hue2 * hue2 * colorFeatureWeight  ) + ( sat2 * sat2 * colorFeatureWeight  ) + ( bri2 * bri2 * colorFeatureWeight ) ) );


        if(distance1 > distance2)
            return  NSOrderedAscending;
        if(distance1 < distance2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisFeatureSortDescriptorRelativeTo:(NSArray*)featureVector
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataFeatureVectorDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* fVec1 = (NSArray*) obj1;
        NSArray* fVec2 = (NSArray*) obj2;
        
        float percent1 = compareFeatureVector(fVec1, featureVector);
        float percent2 = compareFeatureVector(fVec2, featureVector);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisHashSortDescriptorRelativeTo:(NSString*)relativeHash
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataPerceptualHashDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSString* hash1 = (NSString*) obj1;
        NSString* hash2 = (NSString*) obj2;
        
        float percent1 = compareHashes(hash1, relativeHash);
        float percent2 = compareHashes(hash2, relativeHash);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisHistogramSortDescriptorRelativeTo:(NSArray*)histogram
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataHistogramDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* hist1 = (NSArray*) obj1;
        NSArray* hist2 = (NSArray*) obj2;
        
        float percent1 = compareHistogtams(hist1, histogram);
        float percent2 = compareHistogtams(hist2, histogram);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}


+ (NSSortDescriptor*)synopsisColorCIESortDescriptorRelativeTo:(NSColor*)color;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}


// TODO: Assert all colors are RGB prior to accessing components
+ (NSSortDescriptor*)synopsisColorSaturationSortDescriptor
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {

        NSArray* domColors1 = [NSColor linearColorsWithArraysOfRGBComponents:obj1];
        NSArray* domColors2 = [NSColor linearColorsWithArraysOfRGBComponents:obj2];
        
        CGFloat sum1 = weightSaturationDominantColors(domColors1);
        CGFloat sum2 = weightSaturationDominantColors(domColors2);
        
        if(sum1 > sum2)
            return NSOrderedAscending;
        if(sum1 < sum2)
            return NSOrderedDescending;
        
        return NSOrderedSame;

    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisColorHueSortDescriptor
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* domColors1 = [NSColor linearColorsWithArraysOfRGBComponents:obj1];
        NSArray* domColors2 = [NSColor linearColorsWithArraysOfRGBComponents:obj2];
        
        CGFloat sum1 = weightHueDominantColors(domColors1);
        CGFloat sum2 = weightHueDominantColors(domColors2);
        
        if(sum1 > sum2)
            return NSOrderedAscending;
        if(sum1 < sum2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisColorBrightnessSortDescriptor
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* domColors1 = [NSColor linearColorsWithArraysOfRGBComponents:obj1];
        NSArray* domColors2 = [NSColor linearColorsWithArraysOfRGBComponents:obj2];
        
        CGFloat sum1 = weightBrightnessDominantColors(domColors1);
        CGFloat sum2 = weightBrightnessDominantColors(domColors2);
        
        if(sum1 > sum2)
            return NSOrderedAscending;
        if(sum1 < sum2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}


@end
