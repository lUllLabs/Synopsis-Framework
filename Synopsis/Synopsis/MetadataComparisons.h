//
//  MetadataComparisons.h
//  Synopsis-Framework
//
//  Created by vade on 8/6/16.
//  Copyright © 2016 v002. All rights reserved.
//

#ifndef MetadataComparisons_h
#define MetadataComparisons_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// Compare Similarity
float compareFeatureVector(NSArray* feature1, NSArray* feature2);
float compareGlobalHashes(NSString* hash1, NSString* hash2);
float compareFrameHashes(NSString* hash1, NSString* hash2);
float compareHistogtams(NSArray* hist1, NSArray* hist2);
    
float compareDominantColorsRGB(NSArray* colors1, NSArray* colors2);
float compareDominantColorsHSB(NSArray* colors1, NSArray* colors2);
    
// Independent weights
float weightHueDominantColors(NSArray* colors);
float weightSaturationDominantColors(NSArray* colors);
float weightBrightnessDominantColors(NSArray* colors);

#ifdef __cplusplus
}
#endif

#endif /* MetadataComparisons_h */
