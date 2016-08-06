//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.h
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSSortDescriptor (SynopsisMetadata)

// Todo:: Uses weightes best match of all the independed sorting / weighting algorithms
+ (NSSortDescriptor*)synopsisBestMatchSortDescriptorRelativeTo:(NSDictionary*)standardMetadata;

// See which two objects are closest to the relativeHash
+ (NSSortDescriptor*)synopsisHashSortDescriptorRelativeTo:(NSString*)relativeHash;

// Todo:: Use OpenCV Histogram Similarity
+ (NSSortDescriptor*)synopsisHistogramSortDescriptorRelativeTo:(NSArray*)histogram;

// Todo:: Use CIE Delta E 2000 / 1994 and 1976
+ (NSSortDescriptor*)synopsisColorCIESortDescriptorRelativeTo:(NSColor*)color;

// Todo:: Implement simply via NSColor
+ (NSSortDescriptor*)synopsisColorSaturationSortDescriptorRelativeTo:(NSColor*)color;

// Todo:: Implement simply via NSColor
+ (NSSortDescriptor*)synopsisColorHueSortDescriptorRelativeTo:(NSColor*)color;

// Todo:: Implement simply via NSColor
+ (NSSortDescriptor*)synopsisColorBrightnessSortDescriptorRelativeTo:(NSColor*)color;


@end
