//
//  Synopsis.h
//  Synopsis
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//


#ifndef INCLUDE_ENCODER
#error "INCLUDE_ENCODER is not defined in your precprocessor macros. Please choose if you want metadata analysis and encoding included or not"
#endif

#include "TargetConditionals.h"
#import <Foundation/Foundation.h>

#define SYNOPSIS_VERSION_MAJOR 0
#define SYNOPSIS_VERSION_MINOR 0
#define SYNOPSIS_VERSION_PATCH 1

#define SYNOPSIS_VERSION_NUMBER  ((SYNOPSIS_VERSION_MAJOR *100*100) + (SYNOPSIS_VERSION_MINOR *100) + SYNOPSIS_VERSION_PATCH)
#define SYNOPSIS_LIB_VERSION SYNOPSIS_VERSION_MAJOR.SYNOPSIS_VERSION_MINOR.SYNOPSIS_VERSION_PATCH


// Identifier Synopsis for AVMetadataItems
extern NSString* const kSynopsisMetadataIdentifier;
extern NSString* const kSynopsisMetadataVersionKey;
extern NSUInteger const kSynopsisMetadataVersionValue;

// Major Metadata versions : 
extern NSUInteger const kSynopsisMetadataVersionPreAlpha;
extern NSUInteger const kSynopsisMetadataVersionAlpha1;
//extern NSUInteger const kSynopsisMetadataVersionBeta;
//extern NSUInteger const kSynopsisMetadataVersionOne;

// HFS+ Extended Attribute tag for Spotlight search
// Version Key / Dict
extern NSString* const kSynopsisMetadataHFSAttributeVersionKey;
extern NSUInteger const kSynopsisMetadataHFSAttributeVersionValue;
extern NSString* const kSynopsisMetadataHFSAttributeDescriptorKey;


// Supported Synopsis NSSortDescriptor Keys
extern NSString* const kSynopsisStandardMetadataDictKey;
extern NSString* const kSynopsisStandardMetadataFeatureVectorDictKey;
extern NSString* const kSynopsisStandardMetadataLabelsDictKey;
extern NSString* const kSynopsisStandardMetadataScoreDictKey;
extern NSString* const kSynopsisStandardMetadataDominantColorValuesDictKey;
extern NSString* const kSynopsisStandardMetadataHistogramDictKey;
extern NSString* const kSynopsisStandardMetadataMotionDictKey;
extern NSString* const kSynopsisStandardMetadataMotionVectorDictKey;
extern NSString* const kSynopsisStandardMetadataSaliencyDictKey;
extern NSString* const kSynopsisStandardMetadataTrackerDictKey;

extern NSString* const kSynopsisStandardMetadataDescriptionDictKey;

DEPRECATED_ATTRIBUTE extern NSString* const kSynopsisStandardMetadataPerceptualHashDictKey;

// Rough amount of overhead a particular plugin or module has
// For example very very taxing
typedef enum : NSUInteger {
    SynopsisAnalysisOverheadNone = 0,
    SynopsisAnalysisOverheadLow,
    SynopsisAnalysisOverheadMedium,
    SynopsisAnalysisOverheadHigh,
} SynopsisAnalysisOverhead;


// Should a plugin have configurable quality settings
// Hint the plugin to use a specific quality hint
typedef enum : NSUInteger {
    SynopsisAnalysisQualityHintLow,
    SynopsisAnalysisQualityHintMedium,
    SynopsisAnalysisQualityHintHigh,
    // No downsampling
    SynopsisAnalysisQualityHintOriginal = NSUIntegerMax,
} SynopsisAnalysisQualityHint;

typedef enum : unsigned int {
    SynopsisFrameCacheFormatOpenCVBGR8 = 0,
    SynopsisFrameCacheFormatOpenCVBGRF32,
    SynopsisFrameCacheFormatOpenCVGray8,
    SynopsisFrameCacheFormatOpenCVPerceptual
} SynopsisFrameCacheFormat;


#import <Synopsis/SynopsisVideoFormatConverter.h>
#import <Synopsis/SynopsisDenseFeature.h>
#import <Synopsis/MetadataComparisons.h>

// Spotlight, Metadata, Sorting and Filtering Objects

#if TARGET_OS_OSX
#if INCLUDE_ENCODER
#import <Synopsis/AnalyzerPluginProtocol.h>
#import <Synopsis/StandardAnalyzerPlugin.h>
#endif
#endif

#if INCLUDE_ENCODER
#import <Synopsis/SynopsisMetadataEncoder.h>
#endif

#import <Synopsis/SynopsisMetadataDecoder.h>
#import <Synopsis/SynopsisMetadataItem.h>
#import <Synopsis/SynopsisMetadataPushDelegate.h>
#import <Synopsis/NSSortDescriptor+SynopsisMetadata.h>
#import <Synopsis/NSPredicate+SynopsisMetadata.h>


// UI
#import <Synopsis/SynopsisLayer.h>
#import <Synopsis/SynopsisDominantColorLayer.h>
#import <Synopsis/SynopsisHistogramLayer.h>
#import <Synopsis/SynopsisDenseFeatureLayer.h>


// Utilities

#import <Synopsis/Color+linearRGBColor.h>


