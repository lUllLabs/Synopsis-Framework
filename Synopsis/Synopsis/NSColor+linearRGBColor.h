//
//  NSColor+linearRGBColor.h
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (linearRGBColor)

+ (NSColor*) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat) alpha;
+ (NSColor*) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

// Feed in an NSArray containing arrays of NSNumbers for RGB (a)
+ (NSArray*) linearColorsWithArraysOfRGBComponents:(NSArray*)colorComponentsArray;

@end
