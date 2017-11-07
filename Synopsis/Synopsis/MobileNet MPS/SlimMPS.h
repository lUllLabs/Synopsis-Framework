//
//  SlimMPS.h
//  Synopsis-macOS
//
//  Created by vade on 11/6/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface SlimMPSCNNConvolution: MPSCNNConvolution
- (nonnull instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                                kernelHeight:(NSUInteger)kernelHeight
                        inputFeatureChannels:(NSUInteger)inputFeatureChannels
                       outputFeatureChannels:(NSUInteger)outputFeatureChannels
                                neuronFilter:(MPSCNNNeuron* __nullable)neuronFilter
                                      device:(nonnull id<MTLDevice>)device
                                     weights:(const float* _Nonnull)weights
                                        bias:(const float* _Nonnull)bias
                                     padding:(BOOL)willPad
                                     strideX:(NSUInteger)strideX
                                     strideY:(NSUInteger)strideY
             destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset
                                    groupNum:(NSUInteger)groupNum;
@end

@interface SlimMPSCNNDepthConvolution : MPSCNNConvolution
- (nonnull instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                        kernelHeight:(NSUInteger)kernelHeight
                     featureChannels:(NSUInteger)featureChannels
                        neuronFilter:(MPSCNNNeuron* __nullable)neuronFilter
                              device:(id<MTLDevice> _Nonnull)device
                             weights:(const float* _Nonnull)weights
                                bias:(const float* _Nonnull)bias
                             strideX:(NSUInteger)strideX
                             strideY:(NSUInteger)strideY
                   channelMultiplier:(NSUInteger)channelMultiplier
     destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset
                            groupNum:(NSUInteger)groupNum;
@end

@interface SlimMPSCNNFullyConnected: MPSCNNFullyConnected
- (nonnull instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                                kernelHeight:(NSUInteger)kernelHeight
                        inputFeatureChannels:(NSUInteger)inputFeatureChannels
                       outputFeatureChannels:(NSUInteger)outputFeatureChannels
                                neuronFilter:(MPSCNNNeuron* __nullable)neuronFilter
                                      device:(id<MTLDevice> _Nonnull)device
                                     weights:(const float* _Nonnull)weights
                                        bias:(const float* _Nonnull)bias
             destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset;
@end


