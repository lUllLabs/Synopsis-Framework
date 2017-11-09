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
{
    MPSCNNConvolutionDescriptor* convDesc = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                    kernelHeight:kernelHeight
                                                                                            inputFeatureChannels:inputFeatureChannels
                                                                                           outputFeatureChannels:outputFeatureChannels
                                                                                                    neuronFilter:neuronFilter];
    convDesc.strideInPixelsX = strideX;
    convDesc.strideInPixelsY = strideY;
    convDesc.groups = 1;

    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = 0;
        self.usePadding = willPad;
        self.edgeMode = MPSImageEdgeModeZero;

    }
    return self;
}

//- (void) encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer sourceImage:(MPSImage *)sourceImage destinationImage:(MPSImage *)destinationImage
//{
//    MPSOffset offset;
//    offset.z = 0;
//
//    if(self.usePadding)
//    {
//        NSInteger pad_along_height = ((destinationImage.height - 1) * self.strideInPixelsY + self.kernelHeight - sourceImage.height);
//        NSInteger pad_along_width  = ((destinationImage.width - 1) * self.strideInPixelsX + self.kernelWidth - sourceImage.width);
//        
//        offset.x = (self.kernelWidth - pad_along_width)/2;
//        offset.y = (self.kernelHeight - pad_along_height)/2;
//    }
//    else
//    {
//        offset.x = (NSInteger)(self.kernelWidth / 2);
//        offset.y = (NSInteger)(self.kernelHeight / 2);
//    }
//    
//
//    self.offset = offset;
//
//    
//    [super encodeToCommandBuffer:commandBuffer sourceImage:sourceImage destinationImage:destinationImage];
//}

@end

@implementation PointWiseConvolution
- (nonnull instancetype) initWithInputFeatureChannels:(NSUInteger)inputFeatureChannels
                                outputFeatureChannels:(NSUInteger)outputFeatureChannels
                                         neuronFilter:(MPSCNNNeuron* __nullable)neuronFilter
                                               device:(nonnull id<MTLDevice>)device
                                              weights:(const float* _Nonnull)weights
                                                 bias:(const float* _Nonnull)bias
{
    self = [super initWithKernelWidth:1
                         kernelHeight:1
                 inputFeatureChannels:inputFeatureChannels
                outputFeatureChannels:outputFeatureChannels
                         neuronFilter:neuronFilter
                               device:device
                              weights:weights
                                 bias:bias
                              padding:YES
                              strideX:1
                              strideY:1];
    return self;
}
@end



@interface SlimMPSCNNDepthConvolution ()
@property (readwrite, assign) BOOL usePadding;
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
{
    MPSCNNDepthWiseConvolutionDescriptor* convDesc = [MPSCNNDepthWiseConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                                      kernelHeight:kernelHeight
                                                                                                              inputFeatureChannels:featureChannels
                                                                                                             outputFeatureChannels:featureChannels
                                                                                                                      neuronFilter:neuronFilter];
    convDesc.strideInPixelsX = strideX;
    convDesc.strideInPixelsY = strideY;
    convDesc.groups = 1;
    
    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = 0;
        self.usePadding = NO;
        self.edgeMode = MPSImageEdgeModeZero;
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
        NSInteger pad_along_width  = ((destinationImage.width - 1) * self.strideInPixelsX + self.kernelWidth - sourceImage.width);
        NSInteger pad_along_height = ((destinationImage.height - 1) * self.strideInPixelsY + self.kernelHeight - sourceImage.height);

        offset.x = (self.kernelWidth - pad_along_width)/2;
        offset.y = (self.kernelHeight - pad_along_height)/2;
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
{
    MPSCNNConvolutionDescriptor* convDesc = [MPSCNNConvolutionDescriptor cnnConvolutionDescriptorWithKernelWidth:kernelWidth
                                                                                                    kernelHeight:kernelHeight
                                                                                            inputFeatureChannels:inputFeatureChannels
                                                                                           outputFeatureChannels:outputFeatureChannels
                                                                                                    neuronFilter:neuronFilter];

    self = [self initWithDevice:device convolutionDescriptor:convDesc kernelWeights:weights biasTerms:bias flags:MPSCNNConvolutionFlagsNone];
    if(self)
    {
        self.destinationFeatureChannelOffset = 0;
    }
    return self;
}

@end
