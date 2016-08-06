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

float compareHashes(NSString* hash1, NSString* hash2);

float weightHueDominantColors(NSArray* colors);
float weightSaturationDominantColors(NSArray* colors);
float weightBrightnessDominantColors(NSArray* colors);

#endif /* MetadataComparisons_h */
