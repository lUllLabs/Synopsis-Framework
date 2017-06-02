//
//  NSValue+NSValue_OpenCV.h
//  Synopsis-Framework
//
//  Created by vade on 3/26/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SynopsisDenseFeature : NSObject

- (instancetype) initWithFeatureArray:(NSArray*)featureArray;

+ (instancetype) denseFeatureByCombiningFeature:(SynopsisDenseFeature*)feature withFeature:(SynopsisDenseFeature*)feature2;

- (NSUInteger) featureCount;

// Array like access, so one can do
// SynopsisDenseFeature* someFeature = ...
// NSNumber* zerothFeature = someFeature[0];

- (NSNumber*)objectAtIndexedSubscript:(NSUInteger)idx;


@end

