//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "Constants.h"
#import "MetadataComparisons.h"

#import "NSSortDescriptor+SynopsisMetadata.h"

#pragma mark - Hash Helper Functions

// Perceptual Hash
// Calculate how alike 2 hashes are
// We use this result to compare how close 2 hashes are to a 3rd relative hash

#pragma mark -

@implementation NSSortDescriptor (SynopsisMetadata)

+ (NSSortDescriptor*)synopsisBestMatchSortDescriptorRelativeTo:(NSDictionary*)standardMetadata
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisGlobalMetadataSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSDictionary* global1 = (NSDictionary*)obj1;
        NSDictionary* global2 = (NSDictionary*)obj2;
        
        NSString* hash1 = [global1 valueForKey:kSynopsisPerceptualHashDictKey];
        NSString* hash2 = [global2 valueForKey:kSynopsisPerceptualHashDictKey];
        NSString* relativeHash = [standardMetadata valueForKey:kSynopsisPerceptualHashDictKey];
    
        float h1 = compareHashes(hash1, relativeHash);
        float h2 = compareHashes(hash2, relativeHash);
    
        NSArray* hist1 = [global1 valueForKey:kSynopsisHistogramDictKey];
        NSArray* hist2 = [global2 valueForKey:kSynopsisHistogramDictKey];
        NSArray* relativeHist = [standardMetadata valueForKey:kSynopsisHistogramDictKey];
        
        float percent1 = compareHistogtams(hist1, relativeHist);
        float percent2 = compareHistogtams(hist2, relativeHist);

//        NSArray* domColors1 = [global1 valueForKey:kSynopsisDominantColorValuesDictKey];
//        NSArray* domColors2 = [global2 valueForKey:kSynopsisDominantColorValuesDictKey];
//        NSArray* relativeColors = [standardMetadata valueForKey:kSynopsisDominantColorValuesDictKey];
//        
//        float relativeHue = weightHueDominantColors(relativeColors);
//        float relativeSat = weightSaturationDominantColors(relativeColors);
//        float relativeBri = weightBrightnessDominantColors(relativeColors);
//        
//        float hue1 = 1.0 - fabsf(weightHueDominantColors(domColors1) - relativeHue);
//        float hue2 = 1.0 - fabsf(weightHueDominantColors(domColors2) - relativeHue);
//      
//        float sat1 = 1.0 - fabsf(weightSaturationDominantColors(domColors1) - relativeSat);
//        float sat2 = 1.0 - fabsf(weightSaturationDominantColors(domColors2) - relativeSat);
//        
//        float bri1 = 1.0 - fabsf(weightBrightnessDominantColors(domColors1) - relativeBri);
//        float bri2 = 1.0 - fabsf(weightBrightnessDominantColors(domColors2) - relativeBri);

        // Find clostest match in eucledean space. Assumes all 'points' are equally weighted
//        float distance1 = sqrtf( ( h1 * h1 ) + (percent1 * percent1) + (hue1 * hue1) + (sat1 * sat1) + (bri1 * bri1));
//        float distance2 = sqrtf( ( h2 * h2 ) + (percent2 * percent2) + (hue2 * hue2) + (sat2 * sat2) + (bri2 * bri2));

        float distance1 = sqrtf( ( h1 * h1 ) + (percent1 * percent1));// + (sat1 * sat1) + (bri1 * bri1));
        float distance2 = sqrtf( ( h2 * h2 ) + (percent2 * percent2));// + (sat2 * sat2) + (bri2 * bri2));

        if(distance1 > distance2)
            return  NSOrderedAscending;
        if(distance1 < distance2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisHashSortDescriptorRelativeTo:(NSString*)relativeHash;
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisPerceptualHashSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
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
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisHistogramSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
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
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisDominantColorValuesSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {

        NSArray* domColors1 = obj1;
        NSArray* domColors2 = obj2;
        
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
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisDominantColorValuesSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* domColors1 = obj1;
        NSArray* domColors2 = obj2;
        
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
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisDominantColorValuesSortKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* domColors1 = obj1;
        NSArray* domColors2 = obj2;
        
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
