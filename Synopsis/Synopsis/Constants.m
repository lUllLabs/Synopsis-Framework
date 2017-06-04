//
//  Synopsis.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString* const kSynopsisMetadataHFSAttributeTag = @"info_synopsis_descriptors";

// Top Level Metadata key for AVFoundation used in both Summary (global) and per frame metadata
// See AVMetdataItem.h / AVMetdataIdentifier.h
NSString* const kSynopsislMetadataIdentifier = @"mdta/info.synopsis.metadata";

// Sort keys can't use reverse dns due to Cocoa assumption of object hierarchy travelsal by '.'
NSString* const kSynopsislMetadataIdentifierSortKey = @"mdta_info_synopsis_metadata";

// TODO: Should be Standard Analyzer no?
NSString* const kSynopsisStandardMetadataDictKey = @"StandardMetadata";
//NSString* const kSynopsisStandardMetadataSortKey = @"info_synopsis_standardanalyzer";

// Keys for standard modules:
NSString* const kSynopsisStandardMetadataFeatureVectorDictKey = @"Features";
NSString* const kSynopsisStandardMetadataLabelsDictKey = @"Labels";
NSString* const kSynopsisStandardMetadataScoreDictKey = @"Scores";
NSString* const kSynopsisStandardMetadataDominantColorValuesDictKey = @"DominantColors";
NSString* const kSynopsisStandardMetadataHistogramDictKey = @"Histogram";
NSString* const kSynopsisStandardMetadataMotionDictKey = @"Motion";
NSString* const kSynopsisStandardMetadataMotionVectorDictKey = @"MotionVector";
NSString* const kSynopsisStandardMetadataSaliencyDictKey = @"Saliency";
NSString* const kSynopsisStandardMetadataDescriptionDictKey = @"Description";
NSString* const kSynopsisStandardMetadataTrackerDictKey = @"Tracker";

//NSString* const kSynopsisStandardMetadataFeatureVectorSortKey = @"info_synopsis_features";
//NSString* const kSynopsisStandardMetadataDominantColorValuesSortKey = @"info_synopsis_dominant_colors";
//NSString* const kSynopsisStandardMetadataHistogramSortKey = @"info_synopsis_histogram";
//NSString* const kSynopsisStandardMetadataMotionSortKey = @"info_synopsis_motion";
//NSString* const kSynopsisStandardMetadataSaliencySorttKey = @"info_synopsis_saliency";
//NSString* const kSynopsisStandardMetadataDescriptionSortKey = @"info_synopsis_description";

DEPRECATED_ATTRIBUTE NSString* const kSynopsisStandardMetadataPerceptualHashDictKey = @"PerceptualHash";
//DEPRECATED_ATTRIBUTE NSString* const kSynopsisStandardMetadataPerceptualHashSortKey = @"info_synopsis_perceptual_hash";


