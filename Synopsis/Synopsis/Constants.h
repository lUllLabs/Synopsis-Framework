//
//  SynopsisStrings.h
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#ifndef SynopsisStrings_h
#define SynopsisStrings_h

#import <Cocoa/Cocoa.h>

// HFS+ Extended Attribute tag for Spotlight search
extern NSString* const kSynopsisMetadataHFSAttributeTag;

// Identifier Synopsis for AVMetadataItems
extern NSString* const kSynopsislMetadataIdentifier;

// Supported Synopsis NSSortDescriptor Keys
extern NSString* const kSynopsisStandardMetadataDictKey;
extern NSString* const kSynopsisStandardMetadataFeatureVectorDictKey;
extern NSString* const kSynopsisStandardMetadataDominantColorValuesDictKey;
extern NSString* const kSynopsisStandardMetadataHistogramDictKey;
extern NSString* const kSynopsisStandardMetadataMotionDictKey;
extern NSString* const kSynopsisStandardMetadataSaliencyDictKey;

extern NSString* const kSynopsisStandardMetadataDescriptionDictKey;

// Supported Synopsis Sort Keys (these keys cant use the reverse dns notation due to conflicts with key value bs)
// ie: tld.domain.value is treated as a path, not as a raw string
// These replace dots with _ so we avoid the issue
//extern NSString* const kSynopsisStandardMetadataSortKey;
//extern NSString* const kSynopsisStandardMetadataFeatureVectorSortKey;
//extern NSString* const kSynopsisStandardMetadataDominantColorValuesSortKey;
//extern NSString* const kSynopsisStandardMetadataHistogramSortKey;
//extern NSString* const kSynopsisStandardMetadataSaliencySortKey;
//extern NSString* const kSynopsisStandardDescriptionSortKey;

DEPRECATED_ATTRIBUTE extern NSString* const kSynopsisStandardMetadataPerceptualHashDictKey;
//DEPRECATED_ATTRIBUTE extern NSString* const kSynopsisStandardMetadataPerceptualHashSortKey;


#endif /* SynopsisStrings_h */
