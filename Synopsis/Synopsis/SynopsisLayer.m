//
//  SynopsisLayer.m
//  Synopsis-Framework
//
//  Created by vade on 4/20/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisLayer.h"

@implementation SynopsisLayer


- (instancetype) init;
{
    self = [super init];
    if(self)
    {
        CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        
        const CGFloat backgrounds[4] = {0.0, 0.0, 0.0, 1.0};
        const CGFloat borders[4] = {0.5, 0.5, 0.5, 0.5};
        CGColorRef background = CGColorCreate(cspace, backgrounds);
        CGColorRef border = CGColorCreate(cspace, borders);
        
        CGColorSpaceRelease(cspace);
        
        self.cornerRadius = 3.0;
        self.backgroundColor = background;
        self.borderColor = border;
        self.borderWidth =  1.0;
        self.masksToBounds = YES;

        CGColorRelease(background);
        CGColorRelease(border);
        //self.allowsGroupOpacity = NO;
    }
    return self;
}

- (instancetype) initWithLayer:(CALayer*)layer
{
    self = [super initWithLayer:layer];
    if(self)
    {
        if ([layer isKindOfClass:[SynopsisLayer class]])
        {
            CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            
            const CGFloat backgrounds[4] = {0.0, 0.0, 0.0, 1.0};
            const CGFloat borders[4] = {0.5, 0.5, 0.5, 0.5};
            CGColorRef background = CGColorCreate(cspace, backgrounds);
            CGColorRef border = CGColorCreate(cspace, borders);
            
            CGColorSpaceRelease(cspace);
            
            self.cornerRadius = 3.0;
            self.backgroundColor = background;
            self.borderColor = border;
            self.borderWidth =  1.0;
            
            CGColorRelease(background);
            CGColorRelease(border);
            //self.allowsGroupOpacity = NO;
        }
        
    }
    return self;
}

@end
