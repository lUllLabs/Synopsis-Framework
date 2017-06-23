//
//  SynopsisMetadataItem.m
//  Synopslight
//
//  Created by vade on 7/28/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import <AVFoundation/AVFoundation.h>
#import "SynopsisMetadataItem.h"

#import "Color+linearRGBColor.h"

@interface SynopsisMetadataItem ()
{
    CGImageRef cachedImage;
}
@property (readwrite) NSURL* url;
@property (readwrite, strong) AVURLAsset* urlAsset;
@property (readwrite, strong) NSDictionary* globalSynopsisMetadata;
@property (readwrite, strong) SynopsisMetadataDecoder* decoder;
@end

@implementation SynopsisMetadataItem

- (instancetype) initWithURL:(NSURL *)url
{
    self = [super init];
    if(self)
    {
        self.url = url;
        self.urlAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @YES}];
        
        
        NSArray* metadataItems = [self.urlAsset metadata];
        
        AVMetadataItem* synopsisMetadataItem = nil;
        
        for(AVMetadataItem* metadataItem in metadataItems)
        {
            if([metadataItem.identifier isEqualToString:kSynopsislMetadataIdentifier])
            {
                synopsisMetadataItem = metadataItem;
                break;
            }
        }
        
        if(synopsisMetadataItem)
        {
            // Does our metadata item have our version key?
            NSUInteger version = 0;
            if(synopsisMetadataItem.extraAttributes[kSynopsislMetadataVersionKey])
            {
                version = [synopsisMetadataItem.extraAttributes[kSynopsislMetadataVersionKey] unsignedIntegerValue];
            }
            
            self.decoder = [[SynopsisMetadataDecoder alloc] initWithVersion:version];

            self.globalSynopsisMetadata = [self.decoder decodeSynopsisMetadata:synopsisMetadataItem];
        }
    }
    
    return self;
}

- (void) dealloc
{
    CGImageRelease(self.cachedImage);
}

- (CGImageRef) cachedImage
{
    return cachedImage;
}

- (void) setCachedImage:(CGImageRef)image
{
    cachedImage = CGImageRetain(image);
}

// We test equality based on the file system object we are represeting.
- (BOOL) isEqual:(id)object
{
    if([object isKindOfClass:[SynopsisMetadataItem class]])
    {
        SynopsisMetadataItem* obj = (SynopsisMetadataItem*)object;
        
        BOOL equal = [self.url.absoluteURL isEqual:obj.url.absoluteURL];
        
        // helpful for debugging even if stupid 
        if(equal)
            return YES;
        
        return NO;
    }
    
    return [super isEqual:object];
}

- (id) valueForKey:(NSString *)key
{
    NSDictionary* standardDictionary = [self.globalSynopsisMetadata objectForKey:kSynopsisStandardMetadataDictKey];

    if([key isEqualToString:kSynopsislMetadataIdentifier])
        return self.globalSynopsisMetadata;
    
    else if([key isEqualToString:kSynopsisStandardMetadataDictKey])
    {
       return standardDictionary;
    }

    else if(standardDictionary[key])
    {
        return standardDictionary[key];
    }
    else
    {
        return [super valueForKey:key];
    }
}

@end
