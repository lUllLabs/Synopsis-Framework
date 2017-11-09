//
//  GPUMPSMobileNetDataLoader.h
//  Synopsis-macOS
//
//  Created by vade on 11/7/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface GPUMPSMobileNetDataLoader : NSObject<MPSCNNConvolutionDataSource>

- (nonnull instancetype) initWithURL:(nonnull NSURL*)url;
- (nonnull instancetype) initWithName:(NSString* _Nonnull)name kernelSize:(NSUInteger)size inputFeatureChannels:(NSUInteger)inputFeatureChannels outputFeatureChannels:(NSUInteger)outputFeatureChannels stride:(NSUInteger)stride;

// Old style method
- (const float* _Nonnull) data;


//- (nonnull const float*) conv1_s2_w;
//- (nonnull const float*) conv1_s2_b;
//- (nonnull const float*) conv2_1_dw_w;
//- (nonnull const float*) conv2_1_dw_b;
//- (nonnull const float*) conv2_1_s1_w;
//- (nonnull const float*) conv2_1_s1_b;
//- (nonnull const float*) conv2_2_dw_w;
//- (nonnull const float*) conv2_2_dw_b;
//- (nonnull const float*) conv2_2_s1_w;
//- (nonnull const float*) conv2_2_s1_b;
//- (nonnull const float*) conv3_1_dw_w;
//- (nonnull const float*) conv3_1_dw_b;
//- (nonnull const float*) conv3_1_s1_w;
//- (nonnull const float*) conv3_1_s1_b;
//- (nonnull const float*) conv3_2_dw_w;
//- (nonnull const float*) conv3_2_dw_b;
//- (nonnull const float*) conv3_2_s1_w;
//- (nonnull const float*) conv3_2_s1_b;
//- (nonnull const float*) conv4_1_dw_w;
//- (nonnull const float*) conv4_1_dw_b;
//- (nonnull const float*) conv4_1_s1_w;
//- (nonnull const float*) conv4_1_s1_b;
//- (nonnull const float*) conv4_2_dw_w;
//- (nonnull const float*) conv4_2_dw_b;
//- (nonnull const float*) conv4_2_s1_w;
//- (nonnull const float*) conv4_2_s1_b;
//- (nonnull const float*) conv5_1_dw_w;
//- (nonnull const float*) conv5_1_dw_b;
//- (nonnull const float*) conv5_1_s1_w;
//- (nonnull const float*) conv5_1_s1_b;
//- (nonnull const float*) conv5_2_dw_w;
//- (nonnull const float*) conv5_2_dw_b;
//- (nonnull const float*) conv5_2_s1_w;
//- (nonnull const float*) conv5_2_s1_b;
//- (nonnull const float*) conv5_3_dw_w;
//- (nonnull const float*) conv5_3_dw_b;
//- (nonnull const float*) conv5_3_s1_w;
//- (nonnull const float*) conv5_3_s1_b;
//- (nonnull const float*) conv5_4_dw_w;
//- (nonnull const float*) conv5_4_dw_b;
//- (nonnull const float*) conv5_4_s1_w;
//- (nonnull const float*) conv5_4_s1_b;
//- (nonnull const float*) conv5_5_dw_w;
//- (nonnull const float*) conv5_5_dw_b;
//- (nonnull const float*) conv5_5_s1_w;
//- (nonnull const float*) conv5_5_s1_b;
//- (nonnull const float*) conv5_6_dw_w;
//- (nonnull const float*) conv5_6_dw_b;
//- (nonnull const float*) conv5_6_s1_w;
//- (nonnull const float*) conv5_6_s1_b;
//- (nonnull const float*) conv6_1_dw_w;
//- (nonnull const float*) conv6_1_dw_b;
//- (nonnull const float*) conv6_1_s1_w;
//- (nonnull const float*) conv6_1_s1_b;
//- (nonnull const float*) fc7_w;
//- (nonnull const float*) fc7_b;

@end
