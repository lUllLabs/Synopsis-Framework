//
//  SynopsisDenseFeature+Private.h
//  Synopsis-Framework
//
//  Created by vade on 3/27/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisDenseFeature.h"

@interface SynopsisDenseFeature (Private)

+ (SynopsisDenseFeature*) valueWithCVMat:(cv::Mat)mat;
- (cv::Mat) cvMatValue;


@end
