//
//  PerceptualHashModule.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "SynopsisVideoFrameOpenCV.h"
#import "PerceptualHashModule.h"

@interface PerceptualHashModule()
{
    // For "Accumulated' DHas
    cv::Mat averageImageForHash;
    unsigned long long differenceHashAccumulated;
}

@property (atomic, readwrite, strong) NSMutableArray* everyHash;
@end

@implementation PerceptualHashModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    {
        averageImageForHash = cv::Mat(8, 8, CV_8UC1);
        self.everyHash = [NSMutableArray new];        
        differenceHashAccumulated = 0;

    }
    return self;
}

- (void) dealloc
{
    // If we have our old last sample buffer, free it
    averageImageForHash.release();
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataPerceptualHashDictKey;//@"PerceptualHash";
}

+ (SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingCPU;
}

+ (SynopsisVideoFormat) requiredVideoFormat
{
    return SynopsisVideoFormatGray8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame;
{
    SynopsisVideoFrameOpenCV* frameCV = (SynopsisVideoFrameOpenCV*)frame;
    // Its unclear if RGB hashing is of any benefit, since generally
    // speaking (and some testing confirms) that the GRADIENT's in
    // the RGB channels are similar, even if the values are different.
    // The resulting hashes tend to confirm this.
    
    // We should test to see if in fact searching / accuracy is worth
    // Storing the triple hash versis just one?
    
    // We also need to deduce a method to average the hash, or to compute
    // some sort of average image to hash.
    // My gut says literally averaging the image wont really result a useful difference
    // gradient, as we are just kind of making each frame more like the other
    // the opposite of a difference gradient.
    
    // Perhaps difference each frame with the last ?
    
//    result = [self differenceHashRGBInCVMat:frameCV.mat];
//    result = [self differenceHashGreyInCVMat:frameCV.mat];
    return [self perceptualHashGreyInCVMat:frameCV.mat];
}

- (NSDictionary*) finaledAnalysisMetadata
{
    //    unsigned long long differenceHash = 0;
    //    unsigned char lastValue = 0;
    //
    //    // Calculate Hash from running average image
    //    for(int i = 0;  i < averageImageForHash.rows; i++)
    //    {
    //        for(int j = 0; j < averageImageForHash.cols; j++)
    //        {
    //            differenceHash <<= 1;
    //
    //            // get pixel value
    //            unsigned char value = averageImageForHash.at<unsigned char>(i, j);
    //
    //            //cv::Vec3i
    //            differenceHash |=  1 * ( value >= lastValue);
    //
    //            lastValue = value;
    //        }
    //    }
    
    NSString* firstHash = self.everyHash[0];
    NSString* lastHash = [self.everyHash lastObject];
    NSString* firstQuarterHash = self.everyHash[self.everyHash.count/4];
    NSString* lastQuarterHash = self.everyHash[self.everyHash.count/4 + self.everyHash.count/2];

    return @{[self moduleName] : [NSString stringWithFormat:@"%@-%@-%@-%@", firstHash,firstQuarterHash,lastQuarterHash, lastHash]};

}

#pragma mark - Hashing

- (NSDictionary*) differenceHashRGBInCVMat:(matType)image
{
    
    // resize greyscale to 8x8
    matType eightByEight;
    cv::resize(image, eightByEight, cv::Size(8,8));
    
#if USE_OPENCL
    cv::Mat imageMat = eightByEight.getMat(cv::ACCESS_READ);
#else
    cv::Mat imageMat = eightByEight;
#endif
    
    unsigned long long differenceHashR = 0;
    unsigned long long differenceHashG = 0;
    unsigned long long differenceHashB = 0;
    
    cv::Vec3b lastValue;
    
    for(int i = 0;  i < imageMat.rows; i++)
    {
        for(int j = 0; j < imageMat.cols; j++)
        {
            differenceHashR <<= 1;
            differenceHashG <<= 1;
            differenceHashB <<= 1;
            
            // get pixel value
            cv::Vec3b value = imageMat.at<cv::Vec3b>(i, j);
            
            differenceHashR |=  1 * ( value[2] >= lastValue[2]);
            differenceHashG |=  1 * ( value[1] >= lastValue[1]);
            differenceHashB |=  1 * ( value[0] >= lastValue[0]);
            
            lastValue = value;
        }
    }
    
#if USE_OPENCL
    imageMat.release();
#endif
    
    return @{@"Hash R" : [NSString stringWithFormat:@"%16llx", differenceHashR],
             @"Hash G" : [NSString stringWithFormat:@"%16llx", differenceHashG],
             @"Hash B" : [NSString stringWithFormat:@"%16llx", differenceHashB],
             };
}

- (NSDictionary*) differenceHashGreyInCVMat:(matType)image
{
    // resize greyscale to 8x8
    matType eightByEight;
    cv::resize(image, eightByEight, cv::Size(8,8));
    
#if USE_OPENCL
    cv::Mat imageMat = eightByEight.getMat(cv::ACCESS_READ);
#else
    cv::Mat imageMat = eightByEight;
#endif
    
    unsigned long long differenceHash = 0;
    unsigned char lastValue = 127;
    
    for(int i = 0;  i < imageMat.rows; i++)
    {
        for(int j = 0; j < imageMat.cols; j++)
        {
            differenceHash <<= 1;
            
            // get pixel value
            unsigned char value = imageMat.at<unsigned char>(i, j);
            
            differenceHash |=  1 * ( value >= lastValue);
            
            lastValue = value;
        }
    }
    
    // average our running average with our imageMat
    if(averageImageForHash.empty())
    {
        averageImageForHash = imageMat.clone();
    }
    else
    {
        cv::addWeighted(imageMat, 0.5, averageImageForHash, 0.5, 0.0, averageImageForHash);
    }
    
#if USE_OPENCL
    imageMat.release();
#endif
    
    // Experiment with different accumulation strategies for our Hash?
    differenceHashAccumulated = differenceHashAccumulated ^ differenceHash;
    
    return @{
             [self moduleName] : [NSString stringWithFormat:@"%16llx", differenceHash],
             };
}

- (NSDictionary*) perceptualHashGreyInCVMat:(matType)image
{
    // resize greyscale to 8x8
    matType thirtyTwo;
    cv::resize(image, thirtyTwo, cv::Size(32,32));
    
    thirtyTwo.convertTo(thirtyTwo, CV_32FC1);
    
    // calculate DCT on our float image
    matType dct;
    
    cv::dct(thirtyTwo, dct);
    
#if USE_OPENCL
    cv::Mat dctMat = dct.getMat(cv::ACCESS_READ);
#else
    cv::Mat dctMat = dct;
#endif
    
    // sample only the top left to get lowest frequency components in an 8x8
    // Setup a rectangle to define your region of interest
    cv::Rect roi(0, 0, 8, 8);
    
    cv::Mat dctEight = dctMat(roi);
    dctEight.at<float>(0, 0) = 0;
    
    cv::Scalar mean = cv::mean(dctEight);
    float meanD = mean[0];
    
    uint64_t differenceHash = 0x0000000000000000;
    uint64_t one = 0x0000000000000001;
    
    for(int i = 0;  i < dctEight.rows; i++)
    {
        for(int j = 0; j < dctEight.cols; j++)
        {
            // get pixel value
            float value = dctEight.at<float>(i, j);
            if( value >= meanD)
                differenceHash |=  one;
            
            one = one << 1;
            
        }
    }
    
    NSString* hashString = [NSString stringWithFormat:@"%16llx", differenceHash];
    
    [self.everyHash addObject:hashString];
    
#if USE_OPENCL
    dctMat.release();
#endif
    
    return @{
             [self moduleName] : hashString,
             };
}




@end
