//
//  MetadataComparisons.m
//  Synopsis-Framework
//
//  Created by vade on 8/6/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MetadataComparisons.h"

static inline NSString* toBinaryRepresentation(unsigned long long value)
{
    long nibbleCount = sizeof(value) * 2;
    NSMutableString *bitString = [NSMutableString stringWithCapacity:nibbleCount * 5];
    
    for (long index = 4 * nibbleCount - 1; index >= 0; index--)
    {
        [bitString appendFormat:@"%i", value & (1 << index) ? 1 : 0];
    }
    
    return bitString;
}

// kind of dumb - maybe we represent our hashes as numbers? whatever
inline float compareHashes(NSString* hash1, NSString* hash2)
{
    // Split our strings into 4 64 bit ints each.
    // has looks like int64_t-int64_t-int64_t-int64_t-
    
    NSArray* hash1Strings = [hash1 componentsSeparatedByString:@"-"];
    NSArray* hash2Strings = [hash2 componentsSeparatedByString:@"-"];
    
    //    Assert(hash1Strings.count == hash2Strings.count, @"Unable to match Hash Counts");
    
    NSString* allBinaryResult = @"";
    
    for(NSUInteger i = 0; i < hash1Strings.count; i++)
    {
        NSString* hash1String = hash1Strings[i];
        NSString* hash2String = hash2Strings[i];
        
        NSScanner *scanner1 = [NSScanner scannerWithString:hash1String];
        unsigned long long result1 = 0;
        [scanner1 setScanLocation:0]; // bypass '#' character
        [scanner1 scanHexLongLong:&result1];
        
        NSScanner *scanner2 = [NSScanner scannerWithString:hash2String];
        unsigned long long result2 = 0;
        [scanner2 setScanLocation:0]; // bypass '#' character
        [scanner2 scanHexLongLong:&result2];
        
        unsigned long long result = result1 ^ result2;
        
        NSString* resultAsBinaryString = toBinaryRepresentation(result);
        
        allBinaryResult = [allBinaryResult stringByAppendingString:resultAsBinaryString];
    }
    
    NSUInteger characterCount = [[allBinaryResult componentsSeparatedByString:@"1"] count];
    
    float percent = ((256 - characterCount) * 100.0) / 256.0;
    
    return percent / 100.0;
}

inline float weightHueDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSArray* colorArray in colors)
    {
        NSColor* color = (NSColor*) [NSColor colorWithRed:[colorArray[0] floatValue] green:[colorArray[1] floatValue] blue:[colorArray[2] floatValue] alpha:1.0];
        
        sum += [color hueComponent];
    }
    
    sum /= colors.count;
    sum *= 100.0;
    
    return sum;

}

inline float weightSaturationDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSArray* colorArray in colors)
    {
        NSColor* color = (NSColor*) [NSColor colorWithRed:[colorArray[0] floatValue] green:[colorArray[1] floatValue] blue:[colorArray[2] floatValue] alpha:1.0];
        
        sum += [color saturationComponent];
    }
    
    sum /= colors.count;
    sum *= 100.0;

    return sum;
}

inline float weightBrightnessDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSArray* colorArray in colors)
    {
        NSColor* color = (NSColor*) [NSColor colorWithRed:[colorArray[0] floatValue] green:[colorArray[1] floatValue] blue:[colorArray[2] floatValue] alpha:1.0];
        
        sum += [color brightnessComponent];
    }
    
    sum /= colors.count;
    sum *= 100.0;

    return sum;

}

