//
//  SynopsisDenseFeatureLayer.h
//  Synopsis-Framework
//
//  Created by vade on 5/5/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface SynopsisDenseFeatureLayer : SynopsisLayer
@property (readwrite, strong) SynopsisDenseFeature* feature;
@end
