//
//  NSPredicate+SynopsisMetadata.m
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "NSPredicate+SynopsisMetadata.h"
#import "Constants.h"
#import "SynopsisMetadataItem.h"
#import "NSColor+linearRGBColor.h"

@implementation NSPredicate (SynopsisMetadata)

+(NSPredicate*) synopsisWarmColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisDominantColorValuesSortKey];
        NSArray* linearDomColors = [NSColor linearColorsWithArraysOfRGBComponents:dominantColorsArray];
        
        for(NSColor* color in linearDomColors)
        {
            CGFloat hue = [color hueComponent];
            
            if(hue >= 0.5)
                return NO;
        }
        
        return YES;
    }];
}

+(NSPredicate*) synopsisCoolColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSArray* dominantColorsArray = [evaluatedObject valueForKey:kSynopsisDominantColorValuesSortKey];
        NSArray* linearDomColors = [NSColor linearColorsWithArraysOfRGBComponents:dominantColorsArray];
        
        for(NSColor* color in linearDomColors)
        {
            CGFloat hue = [color hueComponent];
            
            if(hue <= 0.5)
                return NO;
        }
        
        return YES;
    }];
}

+(NSPredicate*) synopsisNeutralColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}

+(NSPredicate*) synopsisLightColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}

+(NSPredicate*) synopsisDarkColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}

// Colors sharing a specific hue but changing in saturation or lightness
+(NSPredicate*) synopsisMonochromaticColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}

// Colors near a specific hue
+(NSPredicate*) synopsisAnalogousColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];

}

+(NSPredicate*) synopsisComplimentaryColorPredicate
{
    return [NSPredicate predicateWithBlock:^BOOL(SynopsisMetadataItem*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return NO;
    }];
}


@end
