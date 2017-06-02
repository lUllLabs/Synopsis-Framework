//
//  HistogramLayer.h
//  TrashTVPlayground
//
//  Created by vade on 4/20/17.
//  Copyright © 2017 trash. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Synopsis/SynopsisDenseFeature.h>
#import <Synopsis/SynopsisLayer.h>

@interface SynopsisHistogramLayer : SynopsisLayer
- (instancetype) init;
@property (strong) SynopsisDenseFeature* histogram;
@end
