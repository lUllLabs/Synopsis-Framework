//
//  HistogramLayer.m
//  TrashTVPlayground
//
//  Created by vade on 4/20/17.
//  Copyright © 2017 trash. All rights reserved.
//

#import "SynopsisHistogramLayer.h"
#import <CoreImage/CoreImage.h>
#import "TargetConditionals.h"
@interface SynopsisHistogramLayer ()

@property (readwrite) CALayer* redHistogram;
@property (readwrite) CALayer* greenHistogram;
@property (readwrite) CALayer* blueHistogram;
@property (readwrite) NSMutableArray<CALayer*>* rHistogramCALayers;
@property (readwrite) NSMutableArray<CALayer*>* gHistogramCALayers;
@property (readwrite) NSMutableArray<CALayer*>* bHistogramCALayers;

@end

@implementation SynopsisHistogramLayer

- (instancetype) init
{
    self = [super init];
    if(self)
    {

#if !TARGET_OS_OSX
        self.geometryFlipped = YES;
#endif

        CGColorSpaceRef cspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

        const CGFloat reds[4] = {1, 0, 0, 1};
        const CGFloat greens[4] = {0, 1, 0, 1};
        const CGFloat blues[4] = {0, 0, 1, 1};
        
        CGColorRef red = CGColorCreate(cspace, reds);
        CGColorRef green = CGColorCreate(cspace, greens);
        CGColorRef blue = CGColorCreate(cspace, blues);
        
        CGColorSpaceRelease(cspace);

        self.rHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
        self.gHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
        self.bHistogramCALayers = [NSMutableArray arrayWithCapacity:256];
        
        NSDictionary* actions = @{@"frame" : [NSNull null], @"position" : [NSNull null], @"frameSize" : [NSNull null], @"frameOrigin" : [NSNull null], @"bounds" : [NSNull null]};
        
        // a layer per bin value
        for(NSUInteger i = 0; i < 256; i++)
        {
            CALayer* rLayer = [CALayer layer];
            rLayer.backgroundColor = red;
            rLayer.minificationFilter = kCAFilterNearest;
            rLayer.magnificationFilter = kCAFilterNearest;
            rLayer.edgeAntialiasingMask = 0;
            rLayer.actions = actions;
            rLayer.frame = (CGRect){ 0,0, 1, 1};
            [self.rHistogramCALayers addObject:rLayer];
            
            CALayer* gLayer = [CALayer layer];
            gLayer.backgroundColor = green;
            gLayer.minificationFilter = kCAFilterNearest;
            gLayer.magnificationFilter = kCAFilterNearest;
            gLayer.edgeAntialiasingMask = 0;
            gLayer.actions = actions;
            gLayer.frame = (CGRect){ {0,0}, {1, 1}};
            [self.gHistogramCALayers addObject:gLayer];
            
            CALayer* bLayer = [CALayer layer];
            bLayer.backgroundColor = blue;
            bLayer.minificationFilter = kCAFilterNearest;
            bLayer.magnificationFilter = kCAFilterNearest;
            bLayer.edgeAntialiasingMask = 0;
            bLayer.actions = actions;
            bLayer.frame = (CGRect){ {0,0}, {1, 1}};
            [self.bHistogramCALayers addObject:bLayer];
        }
        
        self.redHistogram = [CALayer layer];
        self.greenHistogram = [CALayer layer];
        self.blueHistogram = [CALayer layer];
        
        self.greenHistogram.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
        self.blueHistogram.compositingFilter = [CIFilter filterWithName:@"CIAdditionCompositing"];
        
        for(CALayer* layer in self.rHistogramCALayers)
        {
            [self.redHistogram addSublayer:layer];
        }
        
        for(CALayer* layer in self.gHistogramCALayers)
        {
            [self.greenHistogram addSublayer:layer];
        }
        
        for(CALayer* layer in self.bHistogramCALayers)
        {
            [self.blueHistogram addSublayer:layer];
        }
        
        [self addSublayer:self.redHistogram];
        [self addSublayer:self.greenHistogram];
        [self addSublayer:self.blueHistogram];
    }

    return self;
}

- (void) drawInContext:(CGContextRef)ctx
{
    CGFloat width = self.bounds.size.width / (CGFloat)256.0;
    CGSize size = (CGSize){width, self.bounds.size.height};
    CGFloat initialOffset = (CGFloat)0.0;
    
    NSUInteger histogramFeatureCount = [self.histogram featureCount];
    
    assert(histogramFeatureCount == 768);
    
    histogramFeatureCount /= 3;
    
    NSUInteger binNumber = 0;
    for(NSUInteger currBin = 0; currBin < histogramFeatureCount; currBin++)
    {
        NSNumber* rValue = self.histogram[currBin];
        NSNumber* gValue = self.histogram[currBin + 256];
        NSNumber* bValue = self.histogram[currBin + 512];
        
        CALayer* rValueLayer = self.rHistogramCALayers[binNumber];
        CALayer* gValueLayer = self.gHistogramCALayers[binNumber];
        CALayer* bValueLayer = self.bHistogramCALayers[binNumber];
        
        rValueLayer.frame = (CGRect){0, 0, size.width, size.height * rValue.floatValue};
        rValueLayer.position = (CGPoint){initialOffset + (width * 0.5), rValueLayer.frame.size.height * 0.5};
        
        gValueLayer.frame = (CGRect){0, 0, size.width, size.height * gValue.floatValue};
        gValueLayer.position = (CGPoint){initialOffset + (width * 0.5), gValueLayer.frame.size.height * 0.5};
        
        bValueLayer.frame = (CGRect){0, 0, size.width, size.height * bValue.floatValue};
        bValueLayer.position = (CGPoint){initialOffset + (width * 0.5), bValueLayer.frame.size.height * 0.5};
        
        initialOffset += width;
        binNumber++;
    }
}

@end
