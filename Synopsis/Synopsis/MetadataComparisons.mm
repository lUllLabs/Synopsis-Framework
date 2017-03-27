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

#import "SynopsisDenseFeature+Private.h"

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

static inline float similarity(const cv::Mat a, const cv::Mat b)
{
    float ab = a.dot(b);
    float da = cv::norm(a);
    float db = cv::norm(b);
    return (ab / (da * db));
}


float compareFeatureVector(SynopsisDenseFeature* featureVec1, SynopsisDenseFeature* featureVec2)
{
    @autoreleasepool
    {
        const cv::Mat vec1 = [featureVec1 cvMatValue];
        const cv::Mat vec2 = [featureVec2 cvMatValue];

        float s = similarity(vec1, vec2);
        
        return s;
    }
}

// kind of dumb - maybe we represent our hashes as numbers? whatever
float compareGlobalHashes(NSString* hash1, NSString* hash2)
{
    // Split our strings into 4 64 bit ints each.
    // has looks like int64_t-int64_t-int64_t-int64_t-
    @autoreleasepool
    {
        NSArray* hash1Strings = [hash1 componentsSeparatedByString:@"-"];
        NSArray* hash2Strings = [hash2 componentsSeparatedByString:@"-"];
        
        //    Assert(hash1Strings.count == hash2Strings.count, @"Unable to match Hash Counts");
        //    NSString* allBinaryResult = @"";
        
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
            
            NSUInteger characterCount = [[resultAsBinaryString componentsSeparatedByString:@"1"] count] - 1;
            
            float percent = ((64.0 - characterCount) * 100.0) / 64.0;
            
            percentPerHash[i] = percent / 100.0;
        }
        
        float totalPercent = percentPerHash[0] + percentPerHash[1] + percentPerHash[2] + percentPerHash[3];
        
        totalPercent *= 0.25;
        
        return totalPercent;
        
        // Euclidean distance between vector of correlation of each hash?
        
        //    return sqrtf( ( percentPerHash[0] * percentPerHash[0] ) + ( percentPerHash[1] * percentPerHash[1] ) + ( percentPerHash[2] * percentPerHash[2] ) + ( percentPerHash[3] * percentPerHash[3] ) );
    }
}

float compareFrameHashes(NSString* hash1, NSString* hash2)
{
    @autoreleasepool
    {
        NSScanner *scanner1 = [NSScanner scannerWithString:hash1];
        unsigned long long result1 = 0;
        [scanner1 setScanLocation:0]; // bypass '#' character
        [scanner1 scanHexLongLong:&result1];
        
        NSScanner *scanner2 = [NSScanner scannerWithString:hash2];
        unsigned long long result2 = 0;
        [scanner2 setScanLocation:0]; // bypass '#' character
        [scanner2 scanHexLongLong:&result2];
        
        unsigned long long result = result1 ^ result2;
        
        NSString* resultAsBinaryString = toBinaryRepresentation(result);
        
        NSUInteger characterCount = [[resultAsBinaryString componentsSeparatedByString:@"1"] count] - 1;
        
        float percent = ((64.0 - characterCount) * 100.0) / 64.0;
        
        return (percent / 100.0);
    }
}


float compareHistogtams(SynopsisDenseFeature* hist1Feature, SynopsisDenseFeature* hist2Feature)
{
    @autoreleasepool
    {
        //     HISTCMP_CHISQR_ALT is for texture comparison - which seems useful for us here?
        //     Looks like HISTCMP_CORREL is better ?

        float dR = (float) cv::compareHist([hist1Feature cvMatValue], [hist2Feature cvMatValue], cv::HistCompMethods::HISTCMP_BHATTACHARYYA);
        
        // Does feature similarity do anything similar to HistComp?
        // Not quite? Worth checking again
//        float s = similarity(hist1Mat, hist2Mat);
        
        if( isnan(dR))
            dR = 1.0;
        
        return 1.0 - dR;
    }
    
}

float compareDominantColorsRGB(NSArray<NSColor*>* colors1, NSArray<NSColor*>* colors2)
{
    @autoreleasepool
    {

        cv::Mat hsvDominantColors1 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat hsvDominantColors2 = cv::Mat( (int) colors2.count, 3, CV_32FC1);
        
        for(int i = 0; i < colors1.count; i++)
        {
            NSColor* rgbColor1 = colors1[i];
            NSColor* rgbColor2 = colors2[i];
            
            hsvDominantColors1.at<float>(i,0) = [rgbColor1 redComponent];
            hsvDominantColors1.at<float>(i,1) = [rgbColor1 blueComponent];
            hsvDominantColors1.at<float>(i,2) = [rgbColor1 greenComponent];
            
            hsvDominantColors2.at<float>(i,0) = [rgbColor2 redComponent];
            hsvDominantColors2.at<float>(i,1) = [rgbColor2 blueComponent];
            hsvDominantColors2.at<float>(i,2) = [rgbColor2 greenComponent];
        }

        float sim = similarity(hsvDominantColors1, hsvDominantColors2);
        
        hsvDominantColors1.release();
        hsvDominantColors2.release();
        
        return sim;

    }
}

float compareDominantColorsHSB(NSArray<NSColor*>* colors1, NSArray<NSColor*>* colors2)
{
    @autoreleasepool
    {
        cv::Mat hsvDominantColors1 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat hsvDominantColors2 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        
        for(int i = 0; i < colors1.count; i++)
        {
            NSColor* rgbColor1 = colors1[i];
            NSColor* rgbColor2 = colors2[i];
            
            hsvDominantColors1.at<float>(i,0) = [rgbColor1 hueComponent];
            hsvDominantColors1.at<float>(i,1) = [rgbColor1 saturationComponent];
            hsvDominantColors1.at<float>(i,2) = [rgbColor1 brightnessComponent];
            
            hsvDominantColors2.at<float>(i,0) = [rgbColor2 hueComponent];
            hsvDominantColors2.at<float>(i,1) = [rgbColor2 saturationComponent];
            hsvDominantColors2.at<float>(i,2) = [rgbColor2 brightnessComponent];
        }
        
        hsvDominantColors1.release();
        hsvDominantColors2.release();
        
        return similarity(hsvDominantColors1, hsvDominantColors2);
    }
}


float weightHueDominantColors(NSArray<NSColor*>* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {
        sum += [color hueComponent];
    }
    
    sum /= colors.count;
    
    return sum;

}

float weightSaturationDominantColors(NSArray<NSColor*>* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {
        sum += [color saturationComponent];
    }
    
    sum /= colors.count;

    return sum;
}

float weightBrightnessDominantColors(NSArray<NSColor*>* colors)
{
    CGFloat sum = 0;
    
    for(NSColor* color in colors)
    {        
        sum += [color brightnessComponent];
    }
    
    sum /= colors.count;

    return sum;
}


