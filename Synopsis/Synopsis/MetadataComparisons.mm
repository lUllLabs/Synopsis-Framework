//
//  MetadataComparisons.m
//  Synopsis-Framework
//
//  Created by vade on 8/6/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import "SynopsisDenseFeature+Private.h"

#import "MetadataComparisons.h"


#import "Color+linearRGBColor.h"


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
    if(featureVec1.featureCount != featureVec2.featureCount)
        return 0.0;
    
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
    if(hash1.length != hash2.length)
        return 0.0;

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
    if(hash1.length != hash2.length)
        return 0.0;

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
    if(!hist1Feature || !hist2Feature)
        return 0.0;

    if(hist1Feature.featureCount != hist1Feature.featureCount)
        return 0.0;

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

float compareDominantColorsRGB(NSArray* colors1, NSArray* colors2)
{
    if(colors1.count != colors2.count)
        return 0.0;
    
    @autoreleasepool
    {
        cv::Mat dominantColors1 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat dominantColors2 = cv::Mat( (int) colors2.count, 3, CV_32FC1);
        
        for(int i = 0; i < colors1.count; i++)
        {
            CGColorRef rgbColor1 = (__bridge CGColorRef)colors1[i];
            CGColorRef rgbColor2 = (__bridge CGColorRef)colors2[i];
            
            const CGFloat* components1 = CGColorGetComponents(rgbColor1);
            const CGFloat* components2 = CGColorGetComponents(rgbColor2);
            
            dominantColors1.at<float>(i,0) = (float)components1[0];
            dominantColors1.at<float>(i,1) = (float)components1[1];
            dominantColors1.at<float>(i,2) = (float)components1[2];
            
            dominantColors2.at<float>(i,0) = (float)components2[0];
            dominantColors2.at<float>(i,1) = (float)components2[1];
            dominantColors2.at<float>(i,2) = (float)components2[2];
        }

        float sim = similarity(dominantColors1, dominantColors2);
        
        dominantColors1.release();
        dominantColors2.release();
        
        return sim;
    }
}

float compareDominantColorsHSB(NSArray* colors1, NSArray* colors2)
{
    if(colors1.count != colors2.count)
        return 0.0;

    @autoreleasepool
    {
        cv::Mat dominantColors1 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat dominantColors2 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat hsvDominantColors1 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        cv::Mat hsvDominantColors2 = cv::Mat( (int) colors1.count, 3, CV_32FC1);
        
        for(int i = 0; i < colors1.count; i++)
        {
            CGColorRef rgbColor1 = (__bridge CGColorRef)colors1[i];
            CGColorRef rgbColor2 = (__bridge CGColorRef)colors2[i];
            
            const CGFloat* components1 = CGColorGetComponents(rgbColor1);
            const CGFloat* components2 = CGColorGetComponents(rgbColor2);
            
            dominantColors1.at<float>(i,0) = (float)components1[0];
            dominantColors1.at<float>(i,1) = (float)components1[1];
            dominantColors1.at<float>(i,2) = (float)components1[2];
            
            dominantColors2.at<float>(i,0) = (float)components2[0];
            dominantColors2.at<float>(i,1) = (float)components2[1];
            dominantColors2.at<float>(i,2) = (float)components2[2];
        }
        
        // Convert our mats to HSV
        cv::cvtColor(dominantColors1, hsvDominantColors1, cv::COLOR_RGB2HSV);
        cv::cvtColor(dominantColors2, hsvDominantColors2, cv::COLOR_RGB2HSV);
        
        dominantColors1.release();
        dominantColors2.release();
        
        float sim = similarity(hsvDominantColors1, hsvDominantColors2);

        hsvDominantColors1.release();
        hsvDominantColors2.release();
        
        return sim;
    }
}

float weightHueDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for (id colorObj in colors)
    {
    	CGColorRef color = (__bridge CGColorRef)colorObj;
    	float tmpComps[] = { 0., 0., 0., 1. };
        const CGFloat *colorComps = CGColorGetComponents(color);
        
        int max = fminl(4,CGColorGetNumberOfComponents(color));
        for (int i = 0; i < max; ++i)
        {
    		tmpComps[i] = *(colorComps + i);
    	}
    	
        [ColorHelper convertRGBtoHSVFloat:tmpComps];
    	sum += (tmpComps[0]) / 360.0;
    }

    sum /= colors.count;
    return sum;

}

float weightSaturationDominantColors(NSArray* colors)
{
    CGFloat sum = 0;
    
    for (id colorObj in colors)
    {
    	CGColorRef color = (__bridge CGColorRef)colorObj;
    	float tmpComps[] = { 0., 0., 0., 1. };
    	const CGFloat *colorComps = CGColorGetComponents(color);
        
        int max = fminl(4,CGColorGetNumberOfComponents(color));
    	for (int i = 0; i < max; ++i)
        {
    		tmpComps[i] = *(colorComps + i);
    	}
        
    	[ColorHelper convertRGBtoHSVFloat:tmpComps];
    	sum += tmpComps[1];
    }
    
    sum /= colors.count;
    return sum;
}

float weightBrightnessDominantColors(NSArray* colors)
{
	CGFloat sum = 0;
    
	for (id colorObj in colors)
    {
    	CGColorRef color = (__bridge CGColorRef)colorObj;
    	float tmpComps[] = { 0., 0., 0., 1. };
    	const CGFloat *colorComps = CGColorGetComponents(color);
        
        int max = fminl(4,CGColorGetNumberOfComponents(color));
        for (int i = 0; i < max; ++i)
        {
    		tmpComps[i] = *(colorComps + i);
    	}
        
    	[ColorHelper convertRGBtoHSVFloat:tmpComps];
    	sum += tmpComps[2];
    }
    
    sum /= colors.count;
    return sum;
}


