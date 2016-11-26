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

// Identifier Synopsis for AVMetadataItems
extern NSString* const kSynopsislMetadataIdentifier;
extern NSString* const kSynopsislMetadataIdentifierSortKey;

// Supported Synopsis NSSortDescriptor Keys
extern NSString* const kSynopsisGlobalMetadataDictKey;
extern NSString* const kSynopsisFeatureVectorDictKey;
extern NSString* const kSynopsisPerceptualHashDictKey;
extern NSString* const kSynopsisDominantColorValuesDictKey;
extern NSString* const kSynopsisHistogramDictKey;
extern NSString* const kSynopsisDescriptionDictKey;

// Supported Synopsis Sort Keys (these keys cant use the reverse dns notation due to conflicts with key value bs)
// ie: tld.domain.value is treated as a path, not as a raw string
// These replace dots with _ so we avoid the issue
extern NSString* const kSynopsisGlobalMetadataSortKey;
extern NSString* const kSynopsisFeatureVectorSortKey;
extern NSString* const kSynopsisPerceptualHashSortKey;
extern NSString* const kSynopsisDominantColorValuesSortKey;
extern NSString* const kSynopsisHistogramSortKey;


#endif /* SynopsisStrings_h */
