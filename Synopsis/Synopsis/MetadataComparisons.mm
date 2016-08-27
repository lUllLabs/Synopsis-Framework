//
//  MetadataComparisons.m
//  Synopsis-Framework
//
//  Created by vade on 8/6/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "opencv2/opencv.hpp"
#import "opencv2/core/ocl.hpp"
#import "opencv2/core/types_c.h"
#import "opencv2/core/utility.hpp"
#import "opencv2/features2d.hpp"

#import "MetadataComparisons.h"
#import "NSColor+linearRGBColor.h"
#import <Cocoa/Cocoa.h>


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
float compareHashes(NSString* hash1, NSString* hash2)
{
    // Split our strings into 4 64 bit ints each.
    // has looks like int64_t-int64_t-int64_t-int64_t-
    
    NSArray* hash1Strings = [hash1 componentsSeparatedByString:@"-"];
    NSArray* hash2Strings = [hash2 componentsSeparatedByString:@"-"];
    
    //    Assert(hash1Strings.count == hash2Strings.count, @"Unable to match Hash Counts");
    NSString* allBinaryResult = @"";
    
    float percentPerHash[4] = {0.0, 0.0, 0.0, 0.0};
    
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
        
        NSUInteger characterCount = [[allBinaryResult componentsSeparatedByString:@"1"] count] - 1;
        
        float percent = ((64.0 - characterCount) * 100.0) / 64.0;
        
        percentPerHash[i] = percent / 100.0;
    }
    
//    NSUInteger characterCount = [[allBinaryResult componentsSeparatedByString:@"1"] count] - 1;
//    
//    float percent = ((256 - characterCount) * 100.0) / 256.0;
    
    // Euclidean distance between vector of correlation of each hash?

    return sqrtf( ( percentPerHash[0] * percentPerHash[0] ) + ( percentPerHash[1] * percentPerHash[1] ) + ( percentPerHash[2] * percentPerHash[2] ) + ( percentPerHash[3] * percentPerHash[3] ) );
}

float compareHistogtams(NSArray* hist1, NSArray* hist2)
{
    cv::Mat hist1RMat = cv::Mat(256, 1, CV_32FC1);
    cv::Mat hist1GMat = cv::Mat(256, 1, CV_32FC1);
    cv::Mat hist1BMat = cv::Mat(256, 1, CV_32FC1);

    cv::Mat hist2RMat = cv::Mat(256, 1, CV_32FC1);
    cv::Mat hist2GMat = cv::Mat(256, 1, CV_32FC1);
    cv::Mat hist2BMat = cv::Mat(256, 1, CV_32FC1);

    for(int i = 0; i < 256; i++)
    {
        NSArray<NSNumber *>* rgbHist1 = hist1[i];
        NSArray<NSNumber *>* rgbHist2 = hist2[i];
        
        hist1RMat.at<float>(i,0) = rgbHist1[0].floatValue;
        hist1GMat.at<float>(i,0) = rgbHist1[1].floatValue;
        hist1BMat.at<float>(i,0) = rgbHist1[2].floatValue;

        hist2RMat.at<float>(i,0) = rgbHist2[0].floatValue;
        hist2GMat.at<float>(i,0) = rgbHist2[1].floatValue;
        hist2BMat.at<float>(i,0) = rgbHist2[2].floatValue;
    }

    // HISTCMP_CHISQR_ALT is for texture comparison - which seems useful for us here?
    // Looks like HISTCMP_CORREL is better ?
    float dR = (float) cv::compareHist(hist1RMat, hist2RMat, cv::HistCompMethods::HISTCMP_CORREL);
    float dG = (float) cv::compareHist(hist1GMat, hist2GMat, cv::HistCompMethods::HISTCMP_CORREL);
    float dB = (float) cv::compareHist(hist1BMat, hist2BMat, cv::HistCompMethods::HISTCMP_CORREL);

    // TODO: What is the range we get from cv::CompareHist ? 
    dR /= 256.0;
    dG /= 256.0;
    dB /= 256.0;
    
    // Return how similar they are, not how far apart they are
    return sqrtf( (dR * dR) + (dG * dG) + (dB * dB));
}


float weightHueDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {
        sum += [color hueComponent];
    }
    
    sum /= colors.count;
    
    return sum;

}

float weightSaturationDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {
        sum += [color saturationComponent];
    }
    
    sum /= colors.count;

    return sum;
}

float weightBrightnessDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {        
        sum += [color brightnessComponent];
    }
    
    sum /= colors.count;

    return sum;
}

