//
//  SynopsisMetadataDecoder.h
//  Synopsis-Framework
//
//  Created by vade on 4/12/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SynopsisMetadataDecoder : NSObject

+ (id) decodeSynopsisMetadata:(AVMetadataItem*)metadataItem;
+ (id) decodeSynopsisData:(NSData*) data;

@end
