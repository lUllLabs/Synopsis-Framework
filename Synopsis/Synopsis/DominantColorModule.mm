//
//  DominantColorAnalyzer.m
//  Synopsis
//
//  Created by vade on 11/10/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "SynopsisVideoFrameOpenCV.h"
#import "CIEDE2000.h"
#import "DominantColorModule.h"
#import "MedianCutOpenCV.hpp"

#import <Quartz/Quartz.h>

@interface DominantColorModule ()
{
    // for kMeans
    matType bestLables;
    matType centers;
}
@property (atomic, readwrite, strong) NSMutableArray* everyDominantColor;
@end

@implementation DominantColorModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    {
        self.everyDominantColor = [NSMutableArray new];
    }
    return self;
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataDominantColorValuesDictKey;//@"DominantColors";
}

+(SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingCPU;
}

+ (SynopsisVideoFormat) requiredVideoFormat
{
    return SynopsisVideoFormatPerceptual;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame;
{
    SynopsisVideoFrameOpenCV* frameCV = (SynopsisVideoFrameOpenCV*)frame;

    // KMeans is slow as hell and also stochastic - same image run 2x gets slightly different results.
    // Median Cut is not particularly accurate ? Maybe I have a subtle bug due to averaging / scaling?
    // Dominant colors still average absed on centroid, even though we attempt to look up the closest
    // real color value near the centroid.
    
    // This needs some looking at and Median Cut is slow as fuck
    
    // result = [self dominantColorForCVMatKMeans:currentPerceptualImage];
    return [self dominantColorForCVMatMedianCutCV:frameCV.mat];
}

- (NSDictionary*) finaledAnalysisMetadata
{
    // Also this code is heavilly borrowed so yea.
    int k = 5;
    int numPixels = (int)self.everyDominantColor.count;
    
    int sourceColorCount = 0;
    
    cv::Mat allDomColors = cv::Mat(1, numPixels, CV_32FC3);
    
    // Populate Median Cut Points by color values;
    for(NSArray* dominantColorsArray in self.everyDominantColor)
    {
        allDomColors.at<cv::Vec3f>(0, sourceColorCount) = cv::Vec3f([dominantColorsArray[0] floatValue], [dominantColorsArray[1] floatValue], [dominantColorsArray[2] floatValue]);
        sourceColorCount++;
    }
    
    bool useCIEDE2000 = USE_CIEDE2000;
    
    MedianCutOpenCV::ColorCube allColorCube(allDomColors, useCIEDE2000);
    
    auto palette = MedianCutOpenCV::medianCut(allColorCube, k, useCIEDE2000);
    
    NSMutableArray* dominantColors = [NSMutableArray new];
    
    for ( auto colorCountPair: palette )
    {
        // convert from LAB to BGR
        const cv::Vec3f& labColor = colorCountPair.first;
        
        cv::Mat closestLABPixel = cv::Mat(1,1, CV_32FC3, labColor);
        cv::Mat bgr(1,1, CV_32FC3);
        cv::cvtColor(closestLABPixel, bgr, FROM_PERCEPTUAL);
        
        cv::Vec3f bgrColor = bgr.at<cv::Vec3f>(0,0);
        
        [dominantColors addObject: @[@(bgrColor[2]),
                                     @(bgrColor[1]),
                                     @(bgrColor[0]),
                                     ]];
    }
    
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    metadata[kSynopsisStandardMetadataDominantColorValuesDictKey] = dominantColors;
    metadata[kSynopsisStandardMetadataDescriptionDictKey] = [self matchColorNamesToColors:dominantColors];
    return metadata;
}

- (cv::Mat) nearestColorCIEDE2000:(cv::Vec3f)labColorVec3f inFrame:(matType)frame
{
    cv::Vec3f closestDeltaEColor;
    
    double delta = DBL_MAX;
    
    // iterate every pixel in our frame, and generate an CIEDE2000::LAB color from it
    // test the delta, and test if our pixel is our min
    
#if USE_OPENCL
    // Get a MAT from our UMat
    cv::Mat frameMAT = frame.getMat(cv::ACCESS_READ);
#else
    cv::Mat frameMAT = frame;
#endif
    
    // Populate Median Cut Points by color values;
    for(int i = 0;  i < frameMAT.rows; i++)
    {
        for(int j = 0; j < frameMAT.cols; j++)
        {
            // get pixel value
            cv::Vec3f frameLABColor = frameMAT.at<cv::Vec3f>(i, j);
            
            double currentPixelDelta = CIEDE2000::CIEDE2000(labColorVec3f, frameLABColor);
            
            if(currentPixelDelta < delta)
            {
                closestDeltaEColor = frameLABColor;
                delta = currentPixelDelta;
            }
        }
    }
    
#if USE_OPENCL
    // Free Mat which unlocks our UMAT if we have it
    frameMAT.release();
#endif
    
    cv::Mat closestLABColor(1,1, CV_32FC3, closestDeltaEColor);
    return closestLABColor;
}

// This doesnt appear to do anything.
- (cv::Mat) nearestColorMinMaxLoc:(cv::Vec3f)colorVec inFrame:(matType)frame
{
    //  find our nearest *actual* LAB pixel in the frame, not from the median cut..
    // Split image into channels
    std::vector<matType> frameChannels;
    cv::split(frame, frameChannels);
    
    // Find absolute differences for each channel
    matType diff_L;
    cv::absdiff(frameChannels[0], colorVec[0], diff_L);
    matType diff_A;
    cv::absdiff(frameChannels[1], colorVec[1], diff_A);
    matType diff_B;
    cv::absdiff(frameChannels[2], colorVec[2], diff_B);
    
    // Calculate L1 distance (diff_L + diff_A + diff_B)
    matType dist;
    matType dist2;
    cv::add(diff_L, diff_A, dist);
    cv::add(dist, diff_B, dist2);
    
    // Find the location of pixel with minimum color distance
    cv::Point minLoc;
    cv::minMaxLoc(dist2, 0, 0, &minLoc);
    
    // get pixel value
#if USE_OPENCL
    cv::Mat frameMat = frame.getMat(cv::ACCESS_READ);
    cv::Vec3f closestColor = frameMat.at<cv::Vec3f>(minLoc);
    frameMat.release();
#else
    cv::Vec3f closestColor = frame.at<cv::Vec3f>(minLoc);
#endif
    
    cv::Mat closestColorPixel(1,1, CV_32FC3, closestColor);
    
    return closestColorPixel;
}

- (NSDictionary*) dominantColorForCVMatMedianCutCV:(matType)image
{
    // Our Mutable Metadata Dictionary:
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    // Also this code is heavilly borrowed so yea.
    int k = 5;
    
    bool useCIEDE2000 = USE_CIEDE2000;
    
#if USE_OPENCL
    cv::Mat imageMat = image.getMat(cv::ACCESS_READ);
#else
    cv::Mat imageMat = image;
#endif
    
    auto palette = MedianCutOpenCV::medianCut(imageMat, k, useCIEDE2000);
    
#if USE_OPENCL
    imageMat.release();
#endif
    
    
    NSMutableArray* dominantColors = [NSMutableArray new];
    
    for ( auto colorCountPair: palette )
    {
        // convert from LAB to BGR
        const cv::Vec3f& labColor = colorCountPair.first;
        
        cv::Mat closestLABPixel = cv::Mat(1,1, CV_32FC3, labColor);
        
        // Looking at inspector output, its not clear that nearestColorMinMaxLoc is effective at all
        //        cv::Mat closestLABPixel = [self nearestColorMinMaxLoc:labColor inFrame:image];
        //        cv::Mat closestLABPixel = [self nearestColorCIEDE2000:labColor inFrame:image];
        
        // convert to BGR
        cv::Mat bgr(1,1, CV_32FC3);
        cv::cvtColor(closestLABPixel, bgr, FROM_PERCEPTUAL);
        
        cv::Vec3f bgrColor = bgr.at<cv::Vec3f>(0,0);
        
        NSArray* color = @[@(bgrColor[2]), // / 255.0), // R
                           @(bgrColor[1]), // / 255.0), // G
                           @(bgrColor[0]), // / 255.0), // B
                           ];
        
        NSArray* lColor = @[ @(labColor[0]), // L
                             @(labColor[1]), // A
                             @(labColor[2]), // B
                             ];
        
        [dominantColors addObject:color];
        
        // We will process this in finalize
        [self.everyDominantColor addObject:lColor];
    }
    
    metadata[[self moduleName]] = dominantColors;
    
    return metadata;
    
}

- (NSDictionary*) dominantColorForCVMatKMeans:(matType)image
{
    // Our Mutable Metadata Dictionary:
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    // We choose k = 5 to match Adobe Kuler because whatever.
    int k = 5;
    int n = image.rows * image.cols;
    
    std::vector<matType> imgSplit;
    cv::split(image,imgSplit);
    
    matType img3xN(n,3,CV_32F);
    
    for(int i = 0; i != 3; ++i)
    {
        imgSplit[i].reshape(1,n).copyTo(img3xN.col(i));
    }
    
    // TODO: figure out what the fuck makes sense here.
    cv::kmeans(img3xN,
               k,
               bestLables,
               //               cv::TermCriteria(),
               cv::TermCriteria(cv::TermCriteria::EPS + cv::TermCriteria::COUNT, 5.0, 1.0),
               5,
               cv::KMEANS_PP_CENTERS,
               centers);
    
    NSMutableArray* dominantColors = [NSMutableArray new];
    
    //            cv::imshow("OpenCV Debug", quarterResLAB);
    
    for(int i = 0; i < centers.rows; i++)
    {
        // 0 1 or 0 - 255 .0 ?
#if USE_OPENCL
        cv::Mat centersMat = centers.getMat(cv::ACCESS_READ);
        cv::Vec3f labColor = centersMat.at<cv::Vec3f>(i, 0);
        centersMat.release();
#else
        cv::Vec3f labColor = centers.at<cv::Vec3f>(i, 0);
#endif
        
        cv::Mat lab(1,1, CV_32FC3, cv::Vec3f(labColor[0], labColor[1], labColor[2]));
        
        cv::Mat bgr(1,1, CV_32FC3);
        
        cv::cvtColor(lab, bgr, FROM_PERCEPTUAL);
        
        cv::Vec3f bgrColor = bgr.at<cv::Vec3f>(0,0);
        
        NSArray* color = @[@(bgrColor[2]), // / 255.0), // R
                           @(bgrColor[1]), // / 255.0), // G
                           @(bgrColor[0]), // / 255.0), // B
                           ];
        
        NSArray* lColor = @[ @(labColor[0]), // L
                             @(labColor[1]), // A
                             @(labColor[2]), // B
                             ];
        
        [dominantColors addObject:color];
        
        // We will process this in finalize
        [self.everyDominantColor addObject:lColor];
    }
    
    metadata[@"DominantColors"] = dominantColors;
    metadata[@"Description"] = [self matchColorNamesToColors:dominantColors];

    return metadata;
}

#pragma mark - Color Helpers

-(NSArray*) matchColorNamesToColors:(NSArray*)colorArray
{
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    NSColorSpace* colorspace = [[NSColorSpace alloc] initWithCGColorSpace:linear];

    
    NSMutableArray* dominantNSColors = [NSMutableArray arrayWithCapacity:colorArray.count];
    
    for(NSArray* color in colorArray)
    {
        CGFloat alpha = 1.0;
        if(color.count > 3)
            alpha = [color[3] floatValue];
        
        NSColor* domColor = [[NSColor colorWithRed:[color[0] floatValue]
                                             green:[color[1] floatValue]
                                              blue:[color[2] floatValue]
                                            alpha:alpha] colorUsingColorSpace:colorspace];
        
        [dominantNSColors addObject:domColor];
    }
    
    NSMutableSet* matchedNamedColors = [NSMutableSet setWithCapacity:dominantNSColors.count];
    
    for(NSColor* color in dominantNSColors)
    {
        NSString* namedColor = [self closestNamedColorForColor:color];
        NSLog(@"Found Color %@", namedColor);
        if(namedColor)
            [matchedNamedColors addObject:namedColor];
    }
    
    CGColorSpaceRelease(linear);
    
    return matchedNamedColors.allObjects;
}

- (NSString*) closestNamedColorForColor:(NSColor*)color
{
    NSColor* matchedColor = nil;
    
    // White, Grey, Black all are 'calibrated white' color spaces so you cant fetch color components from them
    // because no one at apple has seen a fucking prism.
    CGColorSpaceRef linear = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
    NSColorSpace* colorspace = [[NSColorSpace alloc] initWithCGColorSpace:linear];
    CGColorSpaceRelease(linear);
    
    CGFloat white[4] = {1.0, 1.0, 1.0, 1.0};
    CGFloat black[4] = {0.0, 0.0, 0.0, 1.0};
    CGFloat gray[4] = {0.5, 0.5, 0.5, 1.0};
    
    CGFloat red[4] = {1.0, 0.0, 0.0, 1.0};
    CGFloat green[4] = {0.0, 1.0, 0.0, 1.0};
    CGFloat blue[4] = {0.0, 0.0, 1.0, 1.0};
    
    CGFloat cyan[4] = {0.0, 1.0, 1.0, 1.0};
    CGFloat magenta[4] = {1.0, 0.0, 1.0, 1.0};
    CGFloat yellow[4] = {1.0, 1.0, 0.0, 1.0};
    
    CGFloat orange[4] = {1.0, 0.5, 0.0, 1.0};
    CGFloat purple[4] = {1.0, 0.0, 1.0, 1.0};
    
    NSDictionary* knownColors = @{ @"White" : [NSColor colorWithColorSpace:colorspace components:white count:4], // White
                                   @"Black" : [NSColor colorWithColorSpace:colorspace components:black count:4], // Black
                                   @"Gray" : [NSColor colorWithColorSpace:colorspace components:gray count:4], // Gray
                                   @"Red" : [NSColor colorWithColorSpace:colorspace components:red count:4],
                                   @"Green" : [NSColor colorWithColorSpace:colorspace components:green count:4],
                                   @"Blue" : [NSColor colorWithColorSpace:colorspace components:blue count:4],
                                   @"Cyan" : [NSColor colorWithColorSpace:colorspace components:cyan count:4],
                                   @"Magenta" : [NSColor colorWithColorSpace:colorspace components:magenta count:4],
                                   @"Yellow" : [NSColor colorWithColorSpace:colorspace components:yellow count:4],
                                   @"Orange" : [NSColor colorWithColorSpace:colorspace components:orange count:4],
                                   @"Purple" : [NSColor colorWithColorSpace:colorspace components:purple count:4],
                                   };
    
    //    NSUInteger numberMatches = 0;
    
    // Longest distance from any float color component
    CGFloat distance = CGFLOAT_MAX;
    
    for(NSColor* namedColor in [knownColors allValues])
    {
        CGFloat namedRed = [namedColor hueComponent];
        CGFloat namedGreen = [namedColor saturationComponent];
        CGFloat namedBlue = [namedColor brightnessComponent];
        
        CGFloat red = [color hueComponent];
        CGFloat green = [color saturationComponent];
        CGFloat blue = [color brightnessComponent];
        
        // Early bail
        if( red == namedRed && green == namedGreen && blue == namedBlue)
        {
            matchedColor = namedColor;
            break;
        }
        
        CGFloat newDistance = sqrt( pow( fabs(namedRed - red), 2.0) + pow( fabs(namedGreen - green), 2.0) + pow(fabs(namedBlue - blue), 2.0));
        
        if(newDistance < distance)
        {
            distance = newDistance;
            matchedColor = namedColor;
        }
    }
    
    return [[knownColors allKeysForObject:matchedColor] firstObject];
}


@end
