//
//  SynopsisVideoFrame.h
//  Synopsis-macOS
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>

@protocol SynopsisVideoFrame;
- (SynopsisVideoBacking) backing
- (SynopsisVideoFormat) format;
- (id) videoFrame;
@end

