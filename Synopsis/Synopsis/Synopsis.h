//
//  Synopsis.h
//  Synopsis
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//


#include "TargetConditionals.h"
#import <Foundation/Foundation.h>

//! Project version number for Synopsis.
FOUNDATION_EXPORT double SynopsisVersionNumber;

//! Project version string for Synopsis.
FOUNDATION_EXPORT const unsigned char SynopsisVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Synopsis/PublicHeader.h>

#import <Synopsis/Constants.h>

#import <Synopsis/SynopsisDenseFeature.h>

#import <Synopsis/MetadataComparisons.h>

// Spotlight, Metadata, Sorting and Filtering Objects
#import <Synopsis/SynopsisMetadataDecoder.h>
#import <Synopsis/SynopsisMetadataItem.h>
#import <Synopsis/NSSortDescriptor+SynopsisMetadata.h>
#import <Synopsis/NSPredicate+SynopsisMetadata.h>

#if TARGET_OS_OSX
#import <Synopsis/AnalyzerPluginProtocol.h>
#import <Synopsis/StandardAnalyzerPlugin.h>
#endif

// UI
#import <Synopsis/SynopsisLayer.h>
#import <Synopsis/SynopsisDominantColorLayer.h>
#import <Synopsis/SynopsisHistogramLayer.h>
#import <Synopsis/SynopsisDenseFeatureLayer.h>


// Utilities

#import <Synopsis/Color+linearRGBColor.h>


