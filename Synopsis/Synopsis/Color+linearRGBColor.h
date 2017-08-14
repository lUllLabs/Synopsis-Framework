//
//  NSColor+linearRGBColor.h
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface ColorHelper : NSObject

+ (CGColorRef) createColorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat) alpha;
+ (CGColorRef) createColorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

// Feed in an NSArray containing arrays of NSNumbers for RGB (a)
+ (NSArray*) linearColorsWithArraysOfRGBComponents:(NSArray*)colorComponentsArray;

+ (void) convertHSVtoRGBFloat:(float *)c;
+ (void) convertRGBtoHSVFloat:(float *)c;

@end
