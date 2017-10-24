//
//  SynopsisVideoFrameOpenCV.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//
#import "opencv2/core/mat.hpp"
#import "opencv2/core/utility.hpp"

#import "SynopsisVideoFrameOpenCV.h"

@interface SynopsisVideoFrameOpenCV ()
@property (readwrite, strong) SynopsisVideoFormatSpecifier* videoFormatSpecifier;
@property (readwrite, assign) cv::Mat openCVMatrix;
@end

@implementation SynopsisVideoFrameOpenCV

- (instancetype) initWithCVMat:(cv::Mat)mat formatSpecifier:(SynopsisVideoFormatSpecifier*)formatSpecifier;
{
    self = [super init];
    if(self)
    {
        self.openCVMatrix = mat;
//        self.openCVMatrix.addref();
        self.videoFormatSpecifier = formatSpecifier;
    }
    
    return self;
}

- (cv::Mat)mat;
{
    return self.openCVMatrix;
}

- (void) dealloc
{
    self.openCVMatrix.release();
}

@end
