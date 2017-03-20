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

static inline float similarity(cv::Mat a, cv::Mat b)
{
    float ab = a.dot(b);
    float da = cv::norm(a);
    float db = cv::norm(b);
    return (ab / (da * db));
}


float compareFeatureVector(NSArray* feature1, NSArray* feature2)
{
    @autoreleasepool
    {
        //    assert(feature1.count == feature2.count);
        
        cv::Mat featureVec1 = cv::Mat((int)feature1.count, 1, CV_32FC1);
        cv::Mat featureVec2 = cv::Mat((int)feature2.count, 1, CV_32FC1);
        
        for(int i = 0; i < feature1.count; i++)
        {
            NSNumber* fVec1 = feature1[i];
            NSNumber* fVec2 = feature2[i];
            
            featureVec1.at<float>(i,0) = fVec1.floatValue;
            featureVec2.at<float>(i,0) = fVec2.floatValue;
            
            fVec1 = nil;
            fVec2 = nil;
        }
        
        float s = similarity(featureVec1, featureVec2);
        
        featureVec1.release();
        featureVec2.release();
        
        //    NSLog(@"Sim : %f", s);
        
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


float compareHistogtams(NSArray* hist1, NSArray* hist2)
{
    @autoreleasepool
    {
        cv::Mat hist1Mat = cv::Mat(256, 3, CV_32FC1);
        cv::Mat hist2Mat = cv::Mat(256, 3, CV_32FC1);
        
        for(int i = 0; i < 256; i++)
        {
            NSArray<NSNumber *>* rgbHist1 = hist1[i];
            NSArray<NSNumber *>* rgbHist2 = hist2[i];
            
            hist1Mat.at<float>(i,0) = rgbHist1[0].floatValue;
            hist1Mat.at<float>(i,1) = rgbHist1[1].floatValue;
            hist1Mat.at<float>(i,2) = rgbHist1[2].floatValue;
            
            hist2Mat.at<float>(i,0) = rgbHist2[0].floatValue;
            hist2Mat.at<float>(i,1) = rgbHist2[1].floatValue;
            hist2Mat.at<float>(i,2) = rgbHist2[2].floatValue;
        }
        
//        float s = similarity(hist1Mat, hist2Mat);
//        
//        hist1Mat.release();
//        hist2Mat.release();
//        
//        return s;
        
        //     cvHISTCMP_CHISQR_ALT is for texture comparison - which seems useful for us here?
        //     Looks like HISTCMP_CORREL is better ?
        float dR = (float) cv::compareHist(hist1Mat, hist2Mat, cv::HistCompMethods::HISTCMP_BHATTACHARYYA);
        
        // TODO: What is the range we get from cv::CompareHist ?
        dR /= 256.0;
//        Return how similar they are, not how far apart they are
        return 1.0 - dR;

    }
    
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


