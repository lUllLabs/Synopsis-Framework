//
//  SynopsisVideoFormatConverter+SynopsisVideoFormatConverter_Private_h.h
//  Synopsis-Framework
//
//  Created by vade on 6/13/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "opencv2/core/mat.hpp"
#import "opencv2/core/utility.hpp"
#import "SynopsisVideoFormatConverter.h"

@interface SynopsisVideoFormatConverter (Private)

- (cv::Mat) frameForFormat:(SynopsisFrameCacheFormat)format;
@end
