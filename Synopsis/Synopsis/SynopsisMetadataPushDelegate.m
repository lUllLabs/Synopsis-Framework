//
//  SynopsisMetadataPushDelegate.m
//  Synopsis-Framework
//
//  Created by vade on 6/21/17.
//  Copyright © 2017 v002. All rights reserved.
//
#import "SynopsisMetadataDecoder.h"
#import "SynopsisMetadataPushDelegate.h"

@interface SynopsisMetadataPushDelegate ()
@property (readwrite, strong) SynopsisMetadataDecoder* decoder;
@property (readwrite, copy) SynopsisMetadataPushDelegateCompletionBlock completionBlock;
@end

@implementation SynopsisMetadataPushDelegate

- (instancetype) initWithOptionalMetadataDecoder:(SynopsisMetadataDecoder*)decoder completionBlock:(SynopsisMetadataPushDelegateCompletionBlock)completionBlock;
{
    self = [super init];
    if(self)
    {
        self.decoder = decoder;
        self.completionBlock = completionBlock;
    }
    
    return self;
}

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output didOutputTimedMetadataGroups:(NSArray *)groups fromPlayerItemTrack:(AVPlayerItemTrack *)track
{
//    if(self.metadataInspector.visible)
    {
        NSMutableDictionary* metadataDictionary = [NSMutableDictionary dictionary];
        
        for(AVTimedMetadataGroup* group in groups)
        {
            for(AVMetadataItem* metadataItem in group.items)
            {
                NSString* key = metadataItem.identifier;
                
                id decodedJSON = [self.decoder decodeSynopsisMetadata:metadataItem];
                if(decodedJSON)
                {
                    [metadataDictionary setObject:decodedJSON forKey:key];
                }
                else
                {
                    id value = metadataItem.value;
                    
                    [metadataDictionary setObject:value forKey:key];
                }
            }
        }
        
        
//        [self.metadataInspector setFrameMetadata:metadataDictionary];
    }
}


@end
