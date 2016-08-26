//
//  NSPredicate+SynopsisMetadata.h
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPredicate (SynopsisMetadata)

// Color Scheme / Model Preidates
+(NSPredicate*) synopsisWarmColorPredicate;

+(NSPredicate*) synopsisCoolColorPredicate;

+(NSPredicate*) synopsisNeutralColorPredicate;

+(NSPredicate*) synopsisLightColorPredicate;

+(NSPredicate*) synopsisDarkColorPredicate;

// Colors sharing a specific hue but changing in saturation or lightness
+(NSPredicate*) synopsisMonochromaticColorPredicate;

// Colors near a specific hue
+(NSPredicate*) synopsisAnalogousColorPredicate;

+(NSPredicate*) synopsisComplimentaryColorPredicate;

@end
