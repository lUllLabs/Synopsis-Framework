//
//  NSPredicate+SynopsisMetadata.h
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SynopsisMetadataItem;

@interface NSPredicate (SynopsisMetadata)

// Color Scheme / Model Preidates
+(NSPredicate*) synopsisWarmColorPredicate;

+(NSPredicate*) synopsisCoolColorPredicate;

+(NSPredicate*) synopsisNeutralColorPredicate;

+(NSPredicate*) synopsisLightColorPredicate;

+(NSPredicate*) synopsisDarkColorPredicate;

// TODO:

// Colors sharing a specific hue but changing in saturation or lightness
+(NSPredicate*) synopsisMonochromaticColorPredicateRelativeTo:(SynopsisMetadataItem*)item;

// Colors near a specific hue
+(NSPredicate*) synopsisAnalogousColorPredicateRelativeTo:(SynopsisMetadataItem*)item;

+(NSPredicate*) synopsisComplimentaryColorPredicateRelativeTo:(SynopsisMetadataItem*)item;

@end
