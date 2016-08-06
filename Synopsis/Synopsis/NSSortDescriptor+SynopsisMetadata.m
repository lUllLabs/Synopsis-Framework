//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "NSSortDescriptor+SynopsisMetadata.h"
#import "Constants.h"
#import "MetadataComparisons.h"

#pragma mark - Hash Helper Functions

// Perceptual Hash
// Calculate how alike 2 hashes are
// We use this result to compare how close 2 hashes are to a 3rd relative hash


#pragma mark -

@implementation NSSortDescriptor (SynopsisMetadata)

+ (NSSortDescriptor*)synopsisBestMatchSortDescriptorRelativeTo:(NSDictionary*)standardMetadata
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisGlobalMetadataSortKey ascending:NO comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSDictionary* global1 = (NSDictionary*)obj1;
        NSDictionary* global2 = (NSDictionary*)obj2;
        
        NSString* hash1 = [global1 valueForKey:kSynopsisPerceptualHashDictKey];
        NSString* hash2 = [global2 valueForKey:kSynopsisPerceptualHashDictKey];
        NSString* relativeHash = [standardMetadata valueForKey:kSynopsisPerceptualHashDictKey];
        
        float percent1 = compareHashes(hash1, relativeHash);
        float percent2 = compareHashes(hash2, relativeHash);
        
        NSArray* domColors1 = [global1 valueForKey:kSynopsisDominantColorValuesDictKey];
        NSArray* domColors2 = [global2 valueForKey:kSynopsisDominantColorValuesDictKey];
        NSArray* relativeColors = [standardMetadata valueForKey:kSynopsisDominantColorValuesDictKey];
        
        float relativeHue = weightHueDominantColors(relativeColors);
        float relativeSat = weightSaturationDominantColors(relativeColors);
        float relativeBri = weightBrightnessDominantColors(relativeColors);
        
        percent1 += fabsf(weightHueDominantColors(domColors1) - relativeHue);
        percent2 += fabsf(weightHueDominantColors(domColors2) - relativeHue);
      
        percent1 += fabsf(weightSaturationDominantColors(domColors1) - relativeSat);
        percent2 += fabsf(weightSaturationDominantColors(domColors2) - relativeSat);
        
        percent1 += fabsf(weightBrightnessDominantColors(domColors1) - relativeBri);
        percent2 += fabsf(weightBrightnessDominantColors(domColors2) - relativeBri);

        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
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
