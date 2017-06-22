//
//  SynopsisMetadataDecoder.h
//  Synopsis-Framework
//
//  Created by vade on 4/12/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol SynopsisMetadataDecoder <NSObject>
- (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem;
- (id) decodeSynopsisData:(NSData*) data;
@end

@interface SynopsisMetadataDecoder : NSObject<SynopsisMetadataDecoder>

- (instancetype) initWithMetadataItem:(AVMetadataItem*)metadataItem;
- (instancetype) initWithVersion:(NSUInteger)version;

@property (readonly) NSUInteger version;

@end
