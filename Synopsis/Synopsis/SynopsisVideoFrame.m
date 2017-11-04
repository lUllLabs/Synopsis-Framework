//
//  SynopsisVideoFrame.c
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#include "SynopsisVideoFrame.h"

@interface SynopsisVideoFormatSpecifier ()
@property (readwrite, assign) SynopsisVideoFormat format;
@property (readwrite, assign) SynopsisVideoBacking backing;
@end

@implementation SynopsisVideoFormatSpecifier

- (instancetype) initWithFormat:(SynopsisVideoFormat)format backing:(SynopsisVideoBacking)backing
{
    self = [super init];
    if(self)
    {
        self.format = format;
        self.backing = backing;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    return [[SynopsisVideoFormatSpecifier alloc] initWithFormat:self.format backing:self.backing];
}

- (BOOL) isEqual:(id)object
{
    if([object isKindOfClass:[self class]])
    {
        SynopsisVideoFormatSpecifier* other = (SynopsisVideoFormatSpecifier*)object;
        
        if(other.format == self.format && other.backing == self.backing)
        {
            return YES;
        }
    }

    return [super isEqual:object];
}

-(NSUInteger)hash
{
   return  self.format + (self.backing + 1000);
}

@end
