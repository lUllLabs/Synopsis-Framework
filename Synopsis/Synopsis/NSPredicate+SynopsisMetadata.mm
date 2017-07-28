//
//  NSPredicate+SynopsisMetadata.m
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "Synopsis.h"
#import "MetadataComparisons.h"
#import "NSPredicate+SynopsisMetadata.h"
#import "Color+linearRGBColor.h"

@implementation NSPredicate (SynopsisMetadata)

+(NSPredicate*) synopsisWarmColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];

        float hueWeight = weightHueDominantColors(dominantColorsArray);
        
        if(hueWeight <= 0.5)
            return YES;
        
        return NO;
    }];
}

+(NSPredicate*) synopsisCoolColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
        
        float hueWeight = weightHueDominantColors(dominantColorsArray);
        
        if(hueWeight >= 0.5)
            return YES;
        
        return NO;
    }];
}

+(NSPredicate*) synopsisNeutralColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];

        float satWeight = weightSaturationDominantColors(dominantColorsArray);
        
        if(satWeight <= 0.25)
            return YES;
        
        return NO;
    }];
}

+(NSPredicate*) synopsisLightColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
        
        float brightWeight = weightBrightnessDominantColors(dominantColorsArray);
        
        if(brightWeight >= 0.66)
            return YES;
        
        return NO;
    }];
}

+(NSPredicate*) synopsisDarkColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisStandardMetadataDominantColorValuesDictKey];
        
        float brightWeight = weightBrightnessDominantColors(dominantColorsArray);
    
        if(brightWeight <= 0.33)
            return YES;
        
        return NO;
    }];
}

+(NSPredicate*) synopsisPredicateDescriptionContainsString:(NSString*)tag;
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* descriptions = [evaluatedObject valueForKey:kSynopsisStandardMetadataDescriptionDictKey];
        
        for(NSString* descriptionString in descriptions)
        {
            if([descriptionString localizedCaseInsensitiveContainsString:tag])
                return YES;
        }
    
        return NO;
    }];
}

// Colors sharing a specific hue but changing in saturation or lightness
+(NSPredicate*) synopsisMonochromaticColorPredicateRelativeTo:(SynopsisMetadataItem*)item
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}

// Colors near a specific hue
+(NSPredicate*) synopsisAnalogousColorPredicateRelativeTo:(SynopsisMetadataItem*)item
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];

}

+(NSPredicate*) synopsisComplimentaryColorPredicateRelativeTo:(SynopsisMetadataItem*)item
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}


@end
