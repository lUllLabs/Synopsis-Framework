//
//  SlimMPS.m
//  Synopsis-macOS
//
//  Created by vade on 11/6/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "SlimMPS.h"

@interface SlimMPSCNNConvolution ()
@property (readwrite, assign) BOOL usePadding;
@end

@implementation SlimMPSCNNConvolution

//init(kernelWidth: UInt, kernelHeight: UInt, inputFeatureChannels: UInt, outputFeatureChannels: UInt, neuronFilter: MPSCNNNeuron? = nil, device: MTLDevice, weights: UnsafePointer<Float>,bias: UnsafePointer<Float>, padding willPad: Bool = true, strideXY: (UInt, UInt) = (1, 1), destinationFeatureChannelOffset: UInt = 0, groupNum: UInt = 1){

- (instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                        kernelHeight:(NSUInteger)kernelHeight
                inputFeatureChannels:(NSUInteger)inputFeatureChannels
               outputFeatureChannels:(NSUInteger)outputFeatureChannels
                        neuronFilter:(MPSCNNNeuron* __nullable)neuronFilter
                              device:(id<MTLDevice>)device
                             weights:(const float* _Nonnull)weights
                                bias:(const float* _Nonnull)bias
                             padding:(BOOL)willPad
                             strideX:(NSUInteger)strideX
                             strideY:(NSUInteger)strideY
     destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset
                            groupNum:(NSUInteger)groupNum
{
    MPSCNNConvolutionDescriptor* convDesc = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                    kernelHeight:kernelHeight
                                                                                            inputFeatureChannels:inputFeatureChannels
                                                                                           outputFeatureChannels:outputFeatureChannels
                                                                                                    neuronFilter:neuronFilter];
    convDesc.strideInPixelsX = strideX;
    convDesc.strideInPixelsY = strideY;

    // "Group size can't be less than 1"
    assert((groupNum > 0));
    
    convDesc.groups = groupNum;
    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = destinationFeatureChannelOffset;
        self.usePadding = willPad;
    }
    return self;
}

- (void) encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer sourceImage:(MPSImage *)sourceImage destinationImage:(MPSImage *)destinationImage
{
    MPSOffset offset;
    offset.z = 0;
    
    // select offset according to padding being used or not
    if(self.usePadding)
    {
        NSInteger pad_along_height = ((destinationImage.height - 1) * self.strideInPixelsY + self.kernelHeight - sourceImage.height);
        NSInteger pad_along_width  = ((destinationImage.width - 1) * self.strideInPixelsX + self.kernelWidth - sourceImage.width);
        NSInteger pad_top = (NSInteger)(pad_along_height / 2);
        NSInteger pad_left = (NSInteger)(pad_along_width / 2);
        
        offset.x = (NSInteger)(self.kernelWidth / 2) - pad_left;
        offset.y = (NSInteger)(self.kernelHeight / 2) - pad_top;        
    }
    else
    {
        offset.x = (NSInteger)(self.kernelWidth / 2);
        offset.y = (NSInteger)(self.kernelHeight / 2);
    }
    
    self.offset = offset;

    
    [super encodeToCommandBuffer:commandBuffer sourceImage:sourceImage destinationImage:destinationImage];
}

@end

@interface SlimMPSCNNDepthConvolution ()
@end


@implementation SlimMPSCNNDepthConvolution

- (instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                        kernelHeight:(NSUInteger)kernelHeight
                     featureChannels:(NSUInteger)featureChannels
                        neuronFilter:(MPSCNNNeuron*)neuronFilter
                              device:(id<MTLDevice>)device
                             weights:(const float* _Nonnull)weights
                                bias:(const float* _Nonnull)bias
                             strideX:(NSUInteger)strideX
                             strideY:(NSUInteger)strideY
                   channelMultiplier:(NSUInteger)channelMultiplier
     destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset
                            groupNum:(NSUInteger)groupNum
{
    MPSCNNDepthWiseConvolutionDescriptor* convDesc = [MPSCNNDepthWiseConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                                      kernelHeight:kernelHeight
                                                                                                              inputFeatureChannels:featureChannels
                                                                                                             outputFeatureChannels:featureChannels
                                                                                                                      neuronFilter:neuronFilter];
    convDesc.strideInPixelsX = strideX;
    convDesc.strideInPixelsY = strideY;
    
    // "Group size can't be less than 1"
    assert((groupNum > 0));

    // ensure assumptions match
    assert((convDesc.channelMultiplier == channelMultiplier));
    
    convDesc.groups = groupNum;
        
    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = destinationFeatureChannelOffset;
    }
    return self;
}


@end


@interface SlimMPSCNNFullyConnected ()
@end

@implementation SlimMPSCNNFullyConnected

//init(kernelWidth: UInt, kernelHeight: UInt, inputFeatureChannels: UInt, outputFeatureChannels: UInt, neuronFilter: MPSCNNNeuron? = nil, device: MTLDevice, weights: UnsafePointer<Float>,bias: UnsafePointer<Float>, destinationFeatureChannelOffset: UInt = 0){

- (instancetype) initWithKernelWidth:(NSUInteger)kernelWidth
                        kernelHeight:(NSUInteger)kernelHeight
                inputFeatureChannels:(NSUInteger)inputFeatureChannels
               outputFeatureChannels:(NSUInteger)outputFeatureChannels
                        neuronFilter:(MPSCNNNeuron*)neuronFilter
                              device:(id<MTLDevice>)device
                             weights:(const float* _Nonnull)weights
                                bias:(const float* _Nonnull)bias
     destinationFeatureChannelOffset:(NSUInteger)destinationFeatureChannelOffset
{
    MPSCNNConvolutionDescriptor* convDesc = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                    kernelHeight:kernelHeight
                                                                                            inputFeatureChannels:inputFeatureChannels
                                                                                           outputFeatureChannels:outputFeatureChannels
                                                                                                    neuronFilter:neuronFilter];

    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = destinationFeatureChannelOffset;
    }
    return self;
}

@end
