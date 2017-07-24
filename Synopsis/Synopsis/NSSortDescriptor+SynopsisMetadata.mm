//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "Synopsis.h"
#import "SynopsisDenseFeature.h"
#import "MetadataComparisons.h"

#import "NSSortDescriptor+SynopsisMetadata.h"
#import "Color+linearRGBColor.h"
#import <CoreGraphics/CoreGraphics.h>

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
        
        SynopsisDenseFeature* featureVec1 = [global1 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
        SynopsisDenseFeature* featureVec2 = [global2 valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];
        SynopsisDenseFeature* relativeVec = [standardMetadata valueForKey:kSynopsisStandardMetadataFeatureVectorDictKey];

        SynopsisDenseFeature* hist1 = [global1 valueForKey:kSynopsisStandardMetadataHistogramDictKey];
        SynopsisDenseFeature* hist2 = [global2 valueForKey:kSynopsisStandardMetadataHistogramDictKey];
        SynopsisDenseFeature* relativeHist = [standardMetadata valueForKey:kSynopsisStandardMetadataHistogramDictKey];

        NSArray* domColors1 = [global1 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
        NSArray* domColors2 = [global2 valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
        NSArray* relativeColors = [standardMetadata valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];

        // Parellelize sorting math
        dispatch_group_t sortGroup = dispatch_group_create();

        __block float fv1;
        __block float fv2;
        
        dispatch_group_enter(sortGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            fv1 = compareFeatureVector(featureVec1, relativeVec);
            fv2 = compareFeatureVector(featureVec2, relativeVec);
            dispatch_group_leave(sortGroup);
        });
        
        __block float h1;
        __block float h2;

        dispatch_group_enter(sortGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            h1 = compareHistogtams(hist1 , relativeHist);
            h2 = compareHistogtams(hist2 , relativeHist);
            dispatch_group_leave(sortGroup);
        });

        // Do something useful while we wait for those 2 threads to finish
        float relativeHue = weightHueDominantColors(relativeColors);
        float relativeSat = weightSaturationDominantColors(relativeColors);
        float relativeBri = weightBrightnessDominantColors(relativeColors);
        
        float hue1 = 1.0 - fabsf(weightHueDominantColors(domColors1) - relativeHue);
        float hue2 = 1.0 - fabsf(weightHueDominantColors(domColors2) - relativeHue);
        
        float sat1 = 1.0 - fabsf(weightSaturationDominantColors(domColors1) - relativeSat);
        float sat2 = 1.0 - fabsf(weightSaturationDominantColors(domColors2) - relativeSat);
        
        float bri1 = 1.0 - fabsf(weightBrightnessDominantColors(domColors1) - relativeBri);
        float bri2 = 1.0 - fabsf(weightBrightnessDominantColors(domColors2) - relativeBri);

        dispatch_wait(sortGroup, DISPATCH_TIME_FOREVER);
        
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

+ (NSSortDescriptor*)synopsisFeatureSortDescriptorRelativeTo:(SynopsisDenseFeature*)featureVector
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataFeatureVectorDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        SynopsisDenseFeature* fVec1 = (SynopsisDenseFeature*) obj1;
        SynopsisDenseFeature* fVec2 = (SynopsisDenseFeature*) obj2;
        
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
        
        float percent1 = compareGlobalHashes(hash1, relativeHash);
        float percent2 = compareGlobalHashes(hash2, relativeHash);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

+ (NSSortDescriptor*)synopsisDominantRGBDescriptorRelativeTo:(NSArray*)colors
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* color1 = (NSArray*) obj1;
        NSArray* color2 = (NSArray*) obj2;
        
		NSSortDescriptor	*tmpSD = [NSSortDescriptor synopsisColorHueSortDescriptor];
		NSSortDescriptor	*hueSD = [NSSortDescriptor sortDescriptorWithKey:nil ascending:[tmpSD ascending] comparator:[tmpSD comparator]];
        NSArray* acolors = [colors sortedArrayUsingDescriptors:@[hueSD]];
        color1 = [color1 sortedArrayUsingDescriptors:@[hueSD]];
        color2 = [color2 sortedArrayUsingDescriptors:@[hueSD]];
        
        float		percent1 = compareDominantColorsRGB(acolors, color1);
        float		percent2 = compareDominantColorsRGB(acolors, color2);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
 
}

+ (NSSortDescriptor*)synopsisDominantHSBDescriptorRelativeTo:(NSArray*)colors;
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSArray* color1 = (NSArray*) obj1;
        NSArray* color2 = (NSArray*) obj2;
        
        float percent1 = compareDominantColorsHSB(colors, color1);
        float percent2 = compareDominantColorsHSB(colors, color2);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}

// See which two objects are closest to the relativeHash
+ (NSSortDescriptor*)synopsisMotionVectorSortDescriptorRelativeTo:(SynopsisDenseFeature*)motionVector;
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataMotionVectorDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        SynopsisDenseFeature* hist1 = (SynopsisDenseFeature*) obj1;
        SynopsisDenseFeature* hist2 = (SynopsisDenseFeature*) obj2;
        
        float percent1 = fabsf(compareFeatureVector(hist1, motionVector));
        float percent2 = fabsf(compareFeatureVector(hist2, motionVector));
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}


+ (NSSortDescriptor*)synopsisHistogramSortDescriptorRelativeTo:(SynopsisDenseFeature*)histogram
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataHistogramDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        SynopsisDenseFeature* hist1 = (SynopsisDenseFeature*) obj1;
        SynopsisDenseFeature* hist2 = (SynopsisDenseFeature*) obj2;
        
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


+ (NSSortDescriptor*)synopsisColorCIESortDescriptorRelativeTo:(CGColorRef)color;
{
    [NSObject doesNotRecognizeSelector:_cmd];
    return nil;
}


// TODO: Assert all colors are RGB prior to accessing components
+ (NSSortDescriptor*)synopsisColorSaturationSortDescriptor
{
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisStandardMetadataDominantColorValuesDictKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
		CGFloat sum1 = weightSaturationDominantColors(@[obj1]);
		CGFloat sum2 = weightSaturationDominantColors(@[obj2]);
		
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
    	
    	CGFloat sum1 = weightHueDominantColors(@[obj1]);
        CGFloat sum2 = weightHueDominantColors(@[obj2]);
    	
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
        CGFloat sum1 = weightBrightnessDominantColors(@[obj1]);
		CGFloat sum2 = weightBrightnessDominantColors(@[obj2]);
		
        if(sum1 > sum2)
            return NSOrderedAscending;
        if(sum1 < sum2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortDescriptor;
}


@end
