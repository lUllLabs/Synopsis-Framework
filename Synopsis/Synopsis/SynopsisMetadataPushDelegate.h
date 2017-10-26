//
//  SynopsisMetadataPushDelegate.h
//  Synopsis-Framework
//
//  Created by vade on 6/21/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class SynopsisMetadataDecoder;

typedef void(^SynopsisMetadataPushDelegateCompletionBlock)(NSDictionary* synopsisMetadata, NSString* synopisisKey, id otherMetadata, NSString* otherKey);

@interface SynopsisMetadataPushDelegate : NSObject<AVPlayerItemMetadataOutputPushDelegate>

@property (readonly) SynopsisMetadataDecoder* decoder;

- (instancetype) initWithOptionalMetadataDecoder:(SynopsisMetadataDecoder*)decoder completionBlock:(SynopsisMetadataPushDelegateCompletionBlock)completionBlock;

@end
