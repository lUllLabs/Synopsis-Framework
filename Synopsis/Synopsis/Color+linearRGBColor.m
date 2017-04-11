//
//  NSColor+linearRGBColor.m
//  Synopsis-Framework
//
//  Created by vade on 8/26/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "Color+linearRGBColor.h"

@implementation ColorHelper

+ (CGColorRef) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat) alpha
{
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    
    CGFloat components[4] = {red, green, blue, alpha};
    
    CGColorRef color = CGColorCreate(linear, components);
    
    
    CGColorSpaceRelease(linear);

    return color;
}

+ (CGColorRef) colorWithLinearRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue
{
    return [self colorWithLinearRed:green green:green blue:blue alpha:1.0];
}

+ (NSArray*) linearColorsWithArraysOfRGBComponents:(NSArray*)colorComponentsArray
{
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);

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
        
        CGColorRef color = CGColorCreate(linear, components);

         [colors addObject:(__bridge id)color];
    }
    
    CGColorSpaceRelease(linear);

    return colors;
}


@end



