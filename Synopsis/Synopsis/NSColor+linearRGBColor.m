//
//  NSColor+linearRGBColor.m
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "NSColor+linearRGBColor.h"

@implementation NSColor (linearRGBColor)


+ (NSColor*) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat) alpha
{
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    NSColorSpace* cspace = [[NSColorSpace alloc] initWithCGColorSpace:linear];
    CGColorSpaceRelease(linear);
    
    CGFloat components[4] = {red, green, blue, alpha};
    
   return [NSColor colorWithColorSpace:cspace components:components count:4];
}

+ (NSColor*) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
{
    return [self colorWithLinearRed:green green:green blue:blue alpha:1.0];
}

+ (NSArray*) linearColorsWithArraysOfRGBComponents:(NSArray*)colorComponentsArray
{
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    NSColorSpace* cspace = [[NSColorSpace alloc] initWithCGColorSpace:linear];
    CGColorSpaceRelease(linear);

    NSMutableArray* colors = [NSMutableArray arrayWithCapacity:colorComponentsArray.count];
    for(NSArray* colorComponents in colorComponentsArray)
    {
        CGFloat components[4];
        components[0] = [colorComponents[0] floatValue];
        components[1] = [colorComponents[1] floatValue];
        components[2] = [colorComponents[2] floatValue];
        components[3] = 1;
        
        if(colorComponents.count > 3)
        {
            components[3] = [colorComponents[3] floatValue];
        }
        
         [colors addObject:[NSColor colorWithColorSpace:cspace components:components count:4]];
    }
    
    return colors;
}


@end
