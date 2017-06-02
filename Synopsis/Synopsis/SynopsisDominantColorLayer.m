//
//  SynopsisDominantColorLayer.m
//  Synopsis-Framework
//
//  Created by vade on 4/21/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisDominantColorLayer.h"

@interface SynopsisDominantColorLayer ()
@property (readwrite) NSMutableArray<CALayer*>* dominantColorCALayers;
@end

@implementation SynopsisDominantColorLayer


#define kSynopsisDominantColorCount 5
- (instancetype) init
{
    self = [super init];
    if(self)
    {
        self.dominantColorCALayers = [NSMutableArray new];
        
        CGFloat width = self.bounds.size.width / (CGFloat)kSynopsisDominantColorCount;
        CGSize size = (CGSize){width, self.bounds.size.height};
        CGFloat initialOffset = (CGFloat)0.0;

        NSDictionary* actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null], @"backgroundColor" : [NSNull null]};

        // assume we have Dominant Colors for now.
        for(NSUInteger i = 0; i < kSynopsisDominantColorCount; i++)
        {
            CALayer* colorLayer = [CALayer layer];
            
            colorLayer.frame = (CGRect){0, 0, size.width, size.height};
            colorLayer.position = (CGPoint){initialOffset + (width * 0.5), size.height * 0.5};
            colorLayer.actions = actions;
            
            initialOffset += width;
            
            [self addSublayer:colorLayer];
            [self.dominantColorCALayers addObject:colorLayer];
        }
    }
    
    return self;
}

- (void) layoutSublayers
{
    CGFloat width = self.bounds.size.width / (CGFloat)kSynopsisDominantColorCount;
    CGSize size = (CGSize){width, self.bounds.size.height};
    CGFloat initialOffset = (CGFloat)0.0;
    
    // assume we have Dominant Colors for now.
    for(NSUInteger i = 0; i < kSynopsisDominantColorCount; i++)
    {
        CALayer* colorLayer = self.dominantColorCALayers[i];
        
        colorLayer.frame = (CGRect){0, 0, size.width, size.height};
        colorLayer.position = (CGPoint){initialOffset + (width * 0.5), size.height * 0.5};
        
        initialOffset += width;
        
    }
}

- (void) drawInContext:(CGContextRef)ctx
{
    assert((self.dominantColorCALayers.count == self.dominantColorsArray.count) && (self.dominantColorsArray.count == kSynopsisDominantColorCount));
    
    for(NSUInteger i = 0; i < kSynopsisDominantColorCount; i++)
    {
        CALayer* colorLayer = self.dominantColorCALayers[i];
        CGColorRef color = (__bridge CGColorRef)(self.dominantColorsArray[i]);
        
        // TODO: Do I need to enforce linear colorspace here?
        colorLayer.backgroundColor = color;
    }
}

@end
