//
//  GPUMPSMobileNet.m
//  Synopsis-macOS
//
//  Created by vade on 11/6/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "GPUMPSMobileNet.h"
#import "GPUMPSMobileNetDataLoader.h"
#import "SlimMPS.h"
#import "MPSImage+Float.h"

@interface GPUMPSMobileNet ()
{
    
}

@property (readwrite, strong) NSArray<NSString*>* labels;

@property (readwrite, strong) id<MTLComputePipelineState> pipelineRGB;
@property (readwrite, strong) id<MTLComputePipelineState> pipelineBGR;

// TODO: See if cheaper to use bilinear scale
@property (readwrite, strong) MPSImageLanczosScale* lanczos;
@property (readwrite, strong) MPSImageBilinearScale* scaleForCoreML;
@property (readwrite, strong) MPSImageConversion* formatConverter;

@property (readwrite, strong) MPSCNNSoftMax* softmax;

// The layers in the network:
@property (readwrite, strong) MPSCNNConvolution* conv1_s2;  // 224x224x3  input, kernels (3x3x3x32  = 864 weights + 32 bias). s=2,p=1

@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv2_1_dw; // 112x112x32 input, kernels (3x3x32 = 288 weights + 32 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv2_1_s1; // 112x112x32 input, kernels (1x1x32x64 = 2048 weights + 64 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv2_2_dw; // 112x112x64 input, kernels (3x3x64 = 576 weights + 64 bias) s=2,p=1
@property (readwrite, strong) PointWiseConvolution* conv2_2_s1; // 56x56x64 input, kernels (1x1x64x128 = 8912 weights + 128 bias) s=1,p=0

@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv3_1_dw; // 56x56x128 input, kernels (3x3x128 = 1152 weights + 128 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv3_1_s1; // 56x56x128 input, kernels (1x1x128x128 = 16384 weights + 128 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv3_2_dw; // 56x56x128 input, kernels (3x3x128 = 1152 weights + 128 bias) s=2,p=1
@property (readwrite, strong) PointWiseConvolution* conv3_2_s1; // 28x28x128 input, kernels (1x1x128x256 = 32768 weights + 256 bias) s=1,p=0

@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv4_1_dw; // 28x28x256 input, kernels (3x3x256 = 2304 weights + 256 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv4_1_s1; // 28x28x256 input, kernels (1x1x256x256 = 65536 weights + 256 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv4_2_dw; // 28x28x256 input, kernels (3x3x256 = 2304 weights + 256 bias) s=2,p=1
@property (readwrite, strong) PointWiseConvolution* conv4_2_s1; // 14x14x256 input, kernels (1x1x256x512 = 131072 weights + 512 bias) s=1,p=0

@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_1_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_1_s1; // 14x14x512 input, kernels (1x1x512x512 = 262144 weights + 512 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_2_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_2_s1; // 14x14x512 input, kernels (1x1x512x512 = 262144 weights + 512 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_3_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_3_s1; // 14x14x512 input, kernels (1x1x512x512 = 262144 weights + 512 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_4_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_4_s1; // 14x14x512 input, kernels (1x1x512x512 = 262144 weights + 512 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_5_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_5_s1; // 14x14x512 input, kernels (1x1x512x512 = 262144 weights + 512 bias) s=1,p=0
@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv5_6_dw; // 14x14x512 input, kernels (3x3x512 = 4608 weights + 512 bias) s=2,p=1
@property (readwrite, strong) PointWiseConvolution* conv5_6_s1; // 7x7x512 input, kernels (1x1x512x1024 = 524288 weights + 1024 bias) s=1,p=0

@property (readwrite, strong) SlimMPSCNNDepthConvolution* conv6_1_dw; // 7x7x1024 input, kernels (3x3x1024 = 9216 weights + 1024 bias) s=1,p=1
@property (readwrite, strong) PointWiseConvolution* conv6_1_s1; // 7x7x1024 input, kernels (1x1x1024x1024 = 1048576 weights + 1024 bias) s=1,p=0
@property (readwrite, strong) MPSCNNPoolingAverage* pool6;   // 7x7x1024 input ->1x1x1024 output, caffe global_pooling: true
@property (readwrite, strong) MPSCNNConvolution* fc7;        //  fc weights (1x1x1024x1000 = 1024000 weights + 1000 bias)

// Image Descriptors for the network
@property (readwrite, strong) MPSImageDescriptor* input_id;
@property (readwrite, strong) MPSImageDescriptor* conv1_id;
@property (readwrite, strong) MPSImageDescriptor* conv2_1dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv2_1s_id;
@property (readwrite, strong) MPSImageDescriptor* conv2_2dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv2_2s_id;

@property (readwrite, strong) MPSImageDescriptor* conv3_1dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv3_1s_id;
@property (readwrite, strong) MPSImageDescriptor* conv3_2dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv3_2s_id;

@property (readwrite, strong) MPSImageDescriptor* conv4_1dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv4_1s_id;
@property (readwrite, strong) MPSImageDescriptor* conv4_2dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv4_2s_id;

@property (readwrite, strong) MPSImageDescriptor* conv5_dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv5_s_id;
@property (readwrite, strong) MPSImageDescriptor* conv5_6dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv5_6s_id;

@property (readwrite, strong) MPSImageDescriptor* conv6_dw_id;
@property (readwrite, strong) MPSImageDescriptor* conv6_s_id;

@property (readwrite, strong) MPSImageDescriptor* pool6_id;
@property (readwrite, strong) MPSImageDescriptor* output_id;

// Weights - This is a dumb stopgap for now
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv1_s2_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv1_s2_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_1_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_1_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_1_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_1_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_2_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_2_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_2_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv2_2_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_1_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_1_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_1_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_1_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_2_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_2_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_2_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv3_2_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_1_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_1_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_1_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_1_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_2_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_2_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_2_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv4_2_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_1_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_1_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_1_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_1_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_2_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_2_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_2_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_2_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_3_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_3_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_3_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_3_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_4_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_4_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_4_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_4_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_5_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_5_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_5_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_5_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_6_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_6_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_6_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv5_6_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv6_1_dw_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv6_1_dw_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv6_1_s1_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* conv6_1_s1_b;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* fc7_w;
@property (readwrite, strong) GPUMPSMobileNetDataLoader* fc7_b;

@end


@implementation GPUMPSMobileNet

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint device:(id<MTLDevice>)device
{
    self = [super initWithQualityHint:qualityHint device:device];
    if(self)
    {
        NSURL* labelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"synset_words" withExtension:@"txt"];
        NSString* allLabels = [NSString stringWithContentsOfURL:labelURL encoding:NSUTF8StringEncoding error:nil];
        self.labels = [allLabels componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSURL* baseDataURL = [[NSBundle bundleForClass:[self class]] resourceURL];
        self.conv1_s2_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv1_w.bin"]];
        self.conv1_s2_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv1_b.bin"]];
        self.conv2_1_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_1_dw_w.bin"]];
        self.conv2_1_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_1_dw_b.bin"]];
        self.conv2_1_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_1_sep_w.bin"]];
        self.conv2_1_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_1_sep_b.bin"]];
        self.conv2_2_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_2_dw_w.bin"]];
        self.conv2_2_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_2_dw_b.bin"]];
        self.conv2_2_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_2_sep_b.bin"]];
        self.conv2_2_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv2_2_sep_w.bin"]];
        self.conv3_1_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_1_dw_w.bin"]];
        self.conv3_1_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_1_dw_b.bin"]];
        self.conv3_1_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_1_sep_w.bin"]];
        self.conv3_1_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_1_sep_b.bin"]];
        self.conv3_2_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_2_dw_w.bin"]];
        self.conv3_2_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_2_dw_b.bin"]];
        self.conv3_2_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_2_sep_w.bin"]];
        self.conv3_2_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv3_2_sep_b.bin"]];
        self.conv4_1_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_1_dw_w.bin"]];
        self.conv4_1_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_1_dw_b.bin"]];
        self.conv4_1_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_1_sep_w.bin"]];
        self.conv4_1_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_1_sep_b.bin"]];
        self.conv4_2_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_2_dw_w.bin"]];
        self.conv4_2_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_2_dw_b.bin"]];
        self.conv4_2_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_2_sep_w.bin"]];
        self.conv4_2_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv4_2_sep_b.bin"]];
        self.conv5_1_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_1_dw_w.bin"]];
        self.conv5_1_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_1_dw_b.bin"]];
        self.conv5_1_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_1_sep_w.bin"]];
        self.conv5_1_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_1_sep_b.bin"]];
        self.conv5_2_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_2_dw_w.bin"]];
        self.conv5_2_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_2_dw_b.bin"]];
        self.conv5_2_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_2_sep_w.bin"]];
        self.conv5_2_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_2_sep_b.bin"]];
        self.conv5_3_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_3_dw_w.bin"]];
        self.conv5_3_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_3_dw_b.bin"]];
        self.conv5_3_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_3_sep_w.bin"]];
        self.conv5_3_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_3_sep_b.bin"]];
        self.conv5_4_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_4_dw_w.bin"]];
        self.conv5_4_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_4_dw_b.bin"]];
        self.conv5_4_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_4_sep_w.bin"]];
        self.conv5_4_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_4_sep_b.bin"]];
        self.conv5_5_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_5_dw_w.bin"]];
        self.conv5_5_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_5_dw_b.bin"]];
        self.conv5_5_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_5_sep_w.bin"]];
        self.conv5_5_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_5_sep_b.bin"]];
        self.conv5_6_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_6_dw_w.bin"]];
        self.conv5_6_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_6_dw_b.bin"]];
        self.conv5_6_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_6_sep_w.bin"]];
        self.conv5_6_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv5_6_sep_b.bin"]];
        self.conv6_1_dw_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv6_dw_w.bin"]];
        self.conv6_1_dw_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv6_dw_b.bin"]];
        self.conv6_1_s1_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv6_sep_w.bin"]];
        self.conv6_1_s1_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"conv6_sep_b.bin"]];
        self.fc7_w = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"fc7_w.bin"]];
        self.fc7_b = [[GPUMPSMobileNetDataLoader alloc] initWithURL:[baseDataURL URLByAppendingPathComponent:@"fc7_b.bin"]];
        
        
        // Create all of our Image Descriptors
        self.input_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 224 height: 224 featureChannels: 3];

        self.conv1_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 112 height: 112 featureChannels: 32];
        self.conv2_1dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 112 height: 112 featureChannels: 32];
        self.conv2_1s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 112 height: 112 featureChannels: 64];
        
        self.conv2_2dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 56 height: 56 featureChannels: 64];
        self.conv2_2s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 56 height: 56 featureChannels: 128];
        self.conv3_1dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 56 height: 56 featureChannels: 128];
        self.conv3_1s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 56 height: 56 featureChannels: 128];
        self.conv3_2dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 28 height: 28 featureChannels: 128];
        self.conv3_2s_id =  [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 28 height: 28 featureChannels: 256];

        self.conv4_1dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 28 height: 28 featureChannels: 256];
        self.conv4_1s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 28 height: 28 featureChannels: 256];
        self.conv4_2dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 14 height: 14 featureChannels: 256];
        self.conv4_2s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 14 height: 14 featureChannels: 512];

        self.conv5_dw_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 14 height: 14 featureChannels: 512];
        self.conv5_s_id   = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 14 height: 14 featureChannels: 512];
        self.conv5_6dw_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 7 height: 7 featureChannels: 512];
        self.conv5_6s_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 7 height: 7 featureChannels: 1024];

        self.conv6_dw_id  = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 7 height: 7 featureChannels: 1024];
        self.conv6_s_id   = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 7 height: 7 featureChannels: 1024];
        self.pool6_id     = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 1 height: 1 featureChannels: 1024];

//        self.input_id.storageMode = MTLStorageModePrivate;
//        self.conv1_id.storageMode = MTLStorageModePrivate;
//        self.conv2_1dw_id.storageMode = MTLStorageModePrivate;
//        self.conv2_1s_id.storageMode = MTLStorageModePrivate;
//        self.conv2_2dw_id.storageMode = MTLStorageModePrivate;
//        self.conv2_2s_id.storageMode = MTLStorageModePrivate;
//        self.conv3_1dw_id.storageMode = MTLStorageModePrivate;
//        self.conv3_1s_id.storageMode = MTLStorageModePrivate;
//        self.conv3_2s_id.storageMode = MTLStorageModePrivate;
//        self.conv3_2dw_id.storageMode = MTLStorageModePrivate;
//        self.conv4_1dw_id.storageMode = MTLStorageModePrivate;
//        self.conv4_1s_id.storageMode = MTLStorageModePrivate;
//        self.conv4_2dw_id.storageMode = MTLStorageModePrivate;
//        self.conv4_2s_id.storageMode = MTLStorageModePrivate;
//        self.conv5_dw_id.storageMode = MTLStorageModePrivate;
//        self.conv5_s_id.storageMode = MTLStorageModePrivate;
//        self.conv5_6dw_id.storageMode = MTLStorageModePrivate;
//        self.conv5_6s_id.storageMode = MTLStorageModePrivate;
//        self.conv6_dw_id.storageMode = MTLStorageModePrivate;
//        self.conv6_s_id.storageMode = MTLStorageModePrivate;
//        self.pool6_id.storageMode = MTLStorageModePrivate;

        // This will be change for each taxonomy we train using Mobilenet
        // This is the default:
        self.output_id = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatFloat16 width: 1 height: 1 featureChannels: 1000];

        NSError* libraryError = nil;
        id<MTLLibrary> library = [self.device newDefaultLibraryWithBundle:[NSBundle bundleForClass:[self class]] error:&libraryError];
       
        id<MTLFunction> adjust_mean_rgb = [library newFunctionWithName:@"adjust_mean_rgb"];
        self.pipelineRGB =  [self.device newComputePipelineStateWithFunction:adjust_mean_rgb error:nil];
        
        id<MTLFunction> adjust_mean_bgr = [library newFunctionWithName:@"adjust_mean_bgr"];
        self.pipelineBGR =  [self.device newComputePipelineStateWithFunction:adjust_mean_bgr error:nil];

        self.lanczos = [[MPSImageLanczosScale alloc] initWithDevice:self.device];
        self.scaleForCoreML = [[MPSImageBilinearScale alloc] initWithDevice:self.device];
        
        CGFloat bg[4] = {0,0,0,0};
        self.formatConverter = [[MPSImageConversion alloc] initWithDevice:self.device
                                                                 srcAlpha:MPSAlphaTypeAlphaIsOne
                                                                destAlpha:MPSAlphaTypeAlphaIsOne
                                                          backgroundColor:bg
                                                           conversionInfo:NULL];
        
        MPSCNNNeuronReLU* relu = [[MPSCNNNeuronReLU alloc] initWithDevice:self.device a:0];

        self.conv1_s2 = [[SlimMPSCNNConvolution alloc] initWithKernelWidth:3
                                                              kernelHeight:3
                                                      inputFeatureChannels:3
                                                     outputFeatureChannels:32
                                                              neuronFilter:relu
                                                                    device:self.device
                                                                   weights:self.conv1_s2_w.data
                                                                      bias:self.conv1_s2_b.data
                                                                   padding:NO
                                                                   strideX:2
                                                                   strideY:2];
        
        self.conv2_1_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:32
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv2_1_dw_w.data
                                                                             bias:self.conv2_1_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv2_1_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:32
                                                               outputFeatureChannels:64
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv2_1_s1_w.data
                                                                                bias:self.conv2_1_s1_b.data];

        self.conv2_2_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:64
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv2_2_dw_w.data
                                                                             bias:self.conv2_2_dw_b.data
                                                                          strideX:2
                                                                          strideY:2];
        
        self.conv2_2_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:64
                                                               outputFeatureChannels:128
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv2_2_s1_w.data
                                                                                bias:self.conv2_2_s1_b.data];
        
        self.conv3_1_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:128
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv3_1_dw_w.data
                                                                             bias:self.conv3_1_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv3_1_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:128
                                                               outputFeatureChannels:128
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv3_1_s1_w.data
                                                                                bias:self.conv3_1_s1_b.data];
                           

        self.conv3_2_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:128
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv3_2_dw_w.data
                                                                             bias:self.conv3_2_dw_b.data
                                                                          strideX:2
                                                                          strideY:2];
        
        self.conv3_2_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:128
                                                               outputFeatureChannels:256
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv3_2_s1_w.data
                                                                                bias:self.conv3_2_s1_b.data];
        
        self.conv4_1_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:256
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv4_1_dw_w.data
                                                                             bias:self.conv4_1_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv4_1_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:256
                                                               outputFeatureChannels:256
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv4_1_s1_w.data
                                                                                bias:self.conv4_1_s1_b.data];
        
        self.conv4_2_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:256
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv4_2_dw_w.data
                                                                             bias:self.conv4_2_dw_b.data
                                                                          strideX:2
                                                                          strideY:2];
        
        self.conv4_2_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:256
                                                               outputFeatureChannels:512
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv4_2_s1_w.data
                                                                                bias:self.conv4_2_s1_b.data];
        
        self.conv5_1_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_1_dw_w.data
                                                                             bias:self.conv5_1_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv5_1_s1 = [[PointWiseConvolution alloc]initWithInputFeatureChannels:512
                                                              outputFeatureChannels:512
                                                                       neuronFilter:relu
                                                                             device:self.device
                                                                            weights:self.conv5_1_s1_w.data
                                                                               bias:self.conv5_1_s1_b.data];
        
        
        self.conv5_2_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_2_dw_w.data
                                                                             bias:self.conv5_2_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv5_2_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:512
                                                               outputFeatureChannels:512
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv5_2_s1_w.data
                                                                                bias:self.conv5_2_s1_b.data];
        
        self.conv5_3_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_3_dw_w.data
                                                                             bias:self.conv5_3_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv5_3_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:512
                                                               outputFeatureChannels:512
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv5_3_s1_w.data
                                                                                bias:self.conv5_3_s1_b.data];

        self.conv5_4_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_4_dw_w.data
                                                                             bias:self.conv5_4_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv5_4_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:512
                                                               outputFeatureChannels:512
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv5_4_s1_w.data
                                                                                bias:self.conv5_4_s1_b.data];
        
        self.conv5_5_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_5_dw_w.data
                                                                             bias:self.conv5_5_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv5_5_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:512
                                                               outputFeatureChannels:512
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv5_5_s1_w.data
                                                                                bias:self.conv5_5_s1_b.data];
        
        self.conv5_6_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:512
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv5_6_dw_w.data
                                                                             bias:self.conv5_6_dw_b.data
                                                                          strideX:2
                                                                          strideY:2];
        
        self.conv5_6_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:512
                                                               outputFeatureChannels:1024
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv5_6_s1_w.data
                                                                                bias:self.conv5_6_s1_b.data];
        
        self.conv6_1_dw = [[SlimMPSCNNDepthConvolution alloc] initWithKernelWidth:3
                                                                     kernelHeight:3
                                                                  featureChannels:1024
                                                                     neuronFilter:relu
                                                                           device:self.device
                                                                          weights:self.conv6_1_dw_w.data
                                                                             bias:self.conv6_1_dw_b.data
                                                                          strideX:1
                                                                          strideY:1];
        
        self.conv6_1_s1 = [[PointWiseConvolution alloc] initWithInputFeatureChannels:1024
                                                               outputFeatureChannels:1024
                                                                        neuronFilter:relu
                                                                              device:self.device
                                                                             weights:self.conv6_1_s1_w.data
                                                                                bias:self.conv6_1_s1_b.data];
        
        self.pool6 = [[MPSCNNPoolingAverage alloc] initWithDevice:self.device
                                                      kernelWidth:7
                                                     kernelHeight:7
                                                  strideInPixelsX:7
                                                  strideInPixelsY:7];
        MPSOffset offset;
        offset.x = 3; offset.y = 3; offset.z = 0;
        self.pool6.offset = offset;
//        self.pool6.edgeMode = MPSImageEdgeModeClamp
        
        self.fc7 = [[SlimMPSCNNConvolution alloc] initWithKernelWidth:1
                                                         kernelHeight:1
                                                 inputFeatureChannels:1024
                                                outputFeatureChannels:1000 // TODO: Change this
                                                         neuronFilter:nil
                                                               device:self.device
                                                              weights:self.fc7_w.data
                                                                 bias:self.fc7_b.data
                                                              padding:false
                                                              strideX:1
                                                              strideY:1];

//        self.fc7 = [[SlimMPSCNNFullyConnected alloc] initWithKernelWidth:1
//                                                            kernelHeight:1
//                                                    inputFeatureChannels:1024
//                                                   outputFeatureChannels:1000
//                                                            neuronFilter:nil
//                                                                  device:self.device
//                                                                 weights:self.fc7_w.data
//                                                                    bias:self.fc7_b.data
//                                         destinationFeatureChannelOffset:0];
        
        self.softmax = [[MPSCNNSoftMax alloc] initWithDevice:self.device];
    }
    
    return self;
}

- (NSString*) moduleName
{
    return kSynopsisStandardMetadataFeatureVectorDictKey;
}

+ (SynopsisVideoBacking) requiredVideoBacking
{
    return SynopsisVideoBackingGPU;
}

+ (SynopsisVideoFormat) requiredVideoFormat
{
    return SynopsisVideoFormatBGR8;
}

- (void) dispatch:(id<MTLComputePipelineState>)pipeline commandBuffer:(id<MTLCommandBuffer>)commandBuffer inputImage:(MPSImage*)inputImage outputImage:(MPSImage*)outputImage
{
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    [encoder setComputePipelineState:pipeline]; // BGR doesnt swap, RGB does, comment above for clarity
    [encoder setTexture:inputImage.texture atIndex:0];
    [encoder setTexture:outputImage.texture atIndex:1];
    //    // TODO: Where do these numbers come from?
    //    MTLSize threadsPerGroup = MTLSizeMake(8, 8, 1);
    //    MTLSize threadGroup =  MTLSizeMake(normalizedImage.texture.width / threadsPerGroup.width,
    //                                       normalizedImage.texture.height / threadsPerGroup.height,
    //                                       1);
    NSUInteger slices = ((inputImage.featureChannels + 3)/4);
    
    NSUInteger w = pipeline.threadExecutionWidth;
    NSUInteger h = pipeline.maxTotalThreadsPerThreadgroup / w;
    NSUInteger d = 1;
    MTLSize threadGroupSize = MTLSizeMake(w, h, d);
    
    MTLSize threadGroups = MTLSizeMake((inputImage.width  + threadGroupSize.width  - 1) / threadGroupSize.width,
                                       (inputImage.height + threadGroupSize.height - 1) / threadGroupSize.height,
                                       (slices + threadGroupSize.depth  - 1) / threadGroupSize.depth);
    
    
    [encoder dispatchThreadgroups:threadGroups threadsPerThreadgroup:threadGroupSize];
    [encoder endEncoding];
}

- (void) analyzedMetadataForCurrentFrame:(id<SynopsisVideoFrame>)frame previousFrame:(id<SynopsisVideoFrame>)lastFrame commandBuffer:(id<MTLCommandBuffer>)commandBuffer completionBlock:(GPUModuleCompletionBlock)completionBlock;
{
 
//    [MPSTemporaryImage prefetchStorageWithCommandBuffer:commandBuffer imageDescriptorList:@[ self.input_id,
//                                                                                             self.conv1_id,
//                                                                                             self.conv2_1dw_id,
//                                                                                             self.conv2_1s_id,
//                                                                                             self.conv2_2dw_id,
//                                                                                             self.conv2_2s_id,
//                                                                                             self.conv3_1dw_id,
//                                                                                             self.conv3_1s_id,
//                                                                                             self.conv3_2dw_id,
//                                                                                             self.conv3_2s_id,
//                                                                                             self.conv4_1dw_id,
//                                                                                             self.conv4_1s_id,
//                                                                                             self.conv4_2dw_id,
//                                                                                             self.conv4_2s_id,
//                                                                                             self.conv5_dw_id,
//                                                                                             self.conv5_s_id,
//                                                                                             self.conv5_6dw_id,
//                                                                                             self.conv5_6s_id,
//                                                                                             self.conv6_dw_id,
//                                                                                             self.conv6_s_id,
//                                                                                             self.pool6_id,
//                                                                                             // Note we make FC7 an MPSImage because we read the feature vector values on output
////                                                                                             self.output_id
//                                                                                             ]];
//
    SynopsisVideoFrameMPImage* frameMPImage = (SynopsisVideoFrameMPImage*)frame;
    MPSImage* inputImage = frameMPImage.mpsImage;
    
    // Scale the input image to 224x224 pixels.
//    MPSTemporaryImage* resizedImage = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.input_id];
    MPSImage* resizedImage = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.input_id];

    [self.scaleForCoreML encodeToCommandBuffer:commandBuffer sourceImage:inputImage destinationImage:resizedImage];
    
    MPSImage* normalizedImage = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.input_id];
    
    // Adjust the RGB values of each pixel to be in the range -128...127
    // by subtracting the "mean pixel". If the input texture is RGB, this
    // also swaps the R and B values because the model expects BGR pixels.
    // As far as I can tell there is no MPS shader that can do these things,
    // so we use a custom compute kernel.
    [self dispatch:self.pipelineRGB commandBuffer:commandBuffer inputImage:resizedImage outputImage:normalizedImage];

    // see MPSTemporaryImage docs why this is needed
//    resizedImage.readCount -= 1;
    
    // Now we take the output from our custom shader and pass it through the
    // layers of the neural network. For each layer we use a new "temporary"
    


//    MPSImage to hold the results.
//    MPSTemporaryImage* conv1_s2_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv1_id];
    MPSImage* conv1_s2_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv1_id];
    [self.conv1_s2 encodeToCommandBuffer:commandBuffer sourceImage:normalizedImage destinationImage:conv1_s2_img];

//    MPSTemporaryImage* conv2_1dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv2_1dw_id];
    MPSImage* conv2_1dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv2_1dw_id];
    [self.conv2_1_dw encodeToCommandBuffer:commandBuffer sourceImage:conv1_s2_img destinationImage:conv2_1dw_img];

//    MPSTemporaryImage* conv2_1s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv2_1s_id];
    MPSImage* conv2_1s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv2_1s_id];
    [self.conv2_1_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv2_1dw_img destinationImage:conv2_1s_img];

//    MPSTemporaryImage* conv2_2dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv2_2dw_id];
    MPSImage* conv2_2dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv2_2dw_id];
    [self.conv2_2_dw encodeToCommandBuffer:commandBuffer sourceImage:conv2_1s_img destinationImage:conv2_2dw_img];

//    MPSTemporaryImage* conv2_2s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv2_2s_id];
    MPSImage* conv2_2s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv2_2s_id];
    [self.conv2_2_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv2_2dw_img destinationImage:conv2_2s_img];

//    MPSTemporaryImage* conv3_1dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv3_1dw_id];
    MPSImage* conv3_1dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv3_1dw_id];
    [self.conv3_1_dw encodeToCommandBuffer:commandBuffer sourceImage:conv2_2s_img destinationImage:conv3_1dw_img];

//    MPSTemporaryImage* conv3_1s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv3_1s_id];
    MPSImage* conv3_1s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv3_1s_id];
    [self.conv3_1_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv3_1dw_img destinationImage:conv3_1s_img];

//    MPSTemporaryImage* conv3_2dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv3_2dw_id];
    MPSImage* conv3_2dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv3_2dw_id];
    [self.conv3_2_dw encodeToCommandBuffer:commandBuffer sourceImage:conv3_1s_img destinationImage:conv3_2dw_img];

//    MPSTemporaryImage* conv3_2s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv3_2s_id];
    MPSImage* conv3_2s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv3_2s_id];
    [self.conv3_2_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv3_2dw_img destinationImage:conv3_2s_img];

//    MPSTemporaryImage* conv4_1dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv4_1dw_id];
    MPSImage* conv4_1dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv4_1dw_id];
    [self.conv4_1_dw encodeToCommandBuffer:commandBuffer sourceImage:conv3_2s_img destinationImage:conv4_1dw_img];

//    MPSTemporaryImage* conv4_1s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv4_1dw_id];
    MPSImage* conv4_1s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv4_1dw_id];
    [self.conv4_1_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv4_1dw_img destinationImage:conv4_1s_img];

//    MPSTemporaryImage* conv4_2dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv4_2dw_id];
    MPSImage* conv4_2dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv4_2dw_id];
    [self.conv4_2_dw encodeToCommandBuffer:commandBuffer sourceImage:conv4_1s_img destinationImage:conv4_2dw_img];

//    MPSTemporaryImage* conv4_2s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv4_2s_id];
    MPSImage* conv4_2s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv4_2s_id];
    [self.conv4_2_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv4_2dw_img destinationImage:conv4_2s_img];

//    MPSTemporaryImage* conv5_1dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_dw_id];
    MPSImage* conv5_1dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_dw_id];
    [self.conv5_1_dw encodeToCommandBuffer:commandBuffer sourceImage:conv4_2s_img destinationImage:conv5_1dw_img];

//    MPSTemporaryImage* conv5_1s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_s_id];
    MPSImage* conv5_1s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_s_id];
    [self.conv5_1_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_1dw_img destinationImage:conv5_1s_img];

//    MPSTemporaryImage* conv5_2dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_dw_id];
    MPSImage* conv5_2dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_dw_id];
    [self.conv5_2_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_1s_img destinationImage:conv5_2dw_img];

//    MPSTemporaryImage* conv5_2s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_s_id];
    MPSImage* conv5_2s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_s_id];
    [self.conv5_2_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_2dw_img destinationImage:conv5_2s_img];

//    MPSTemporaryImage* conv5_3dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_dw_id];
    MPSImage* conv5_3dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_dw_id];
    [self.conv5_3_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_2s_img destinationImage:conv5_3dw_img];

//    MPSTemporaryImage* conv5_3s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_s_id];
    MPSImage* conv5_3s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_s_id];
    [self.conv5_3_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_3dw_img destinationImage:conv5_3s_img];

//    MPSTemporaryImage* conv5_4dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_dw_id];
    MPSImage* conv5_4dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_dw_id];
    [self.conv5_4_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_3s_img destinationImage:conv5_4dw_img];

//    MPSTemporaryImage* conv5_4s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_s_id];
    MPSImage* conv5_4s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_s_id];
    [self.conv5_4_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_4dw_img destinationImage:conv5_4s_img];

//    MPSTemporaryImage* conv5_5dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_dw_id];
    MPSImage* conv5_5dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_dw_id];
    [self.conv5_5_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_4s_img destinationImage:conv5_5dw_img];

//    MPSTemporaryImage* conv5_5s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_s_id];
    MPSImage* conv5_5s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_s_id];
    [self.conv5_5_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_5dw_img destinationImage:conv5_5s_img];

//    MPSTemporaryImage* conv5_6dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_6dw_id];
    MPSImage* conv5_6dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_6dw_id];
    [self.conv5_6_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_5s_img destinationImage:conv5_6dw_img];

//    MPSTemporaryImage* conv5_6s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv5_6s_id];
    MPSImage* conv5_6s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv5_6s_id];
    [self.conv5_6_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv5_6dw_img destinationImage:conv5_6s_img];

//    MPSTemporaryImage* conv6_dw_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv6_dw_id];
    MPSImage* conv6_dw_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv6_dw_id];
    [self.conv6_1_dw encodeToCommandBuffer:commandBuffer sourceImage:conv5_6s_img destinationImage:conv6_dw_img];

//    MPSTemporaryImage* conv6_s_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.conv6_s_id];
    MPSImage* conv6_s_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.conv6_s_id];
    [self.conv6_1_s1 encodeToCommandBuffer:commandBuffer sourceImage:conv6_dw_img destinationImage:conv6_s_img];
    
//    MPSTemporaryImage* pool6_img = [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer imageDescriptor:self.pool6_id];
    MPSImage* pool6_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.pool6_id];
    [self.pool6 encodeToCommandBuffer:commandBuffer sourceImage:conv6_s_img destinationImage:pool6_img];

    // We make fc7 a MPS image because we will use it in the resulting output
    MPSImage* fc7_img = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.output_id];
    [self.fc7 encodeToCommandBuffer:commandBuffer sourceImage:pool6_img destinationImage:fc7_img];
    
    // Finally, apply the softmax function to the output of the last layer.
    // The output image is not an MPSTemporaryImage but a regular MSPImage.
    MPSImage* outputImage = [[MPSImage alloc] initWithDevice:self.device imageDescriptor:self.output_id];
    [self.softmax encodeToCommandBuffer:commandBuffer sourceImage:fc7_img destinationImage:outputImage];
    
    // Note we dont commit, our Analyzer plugin does that for us (once its also encodes all of our other GPU modules)
    // But we do add our completion block though
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
      
        dispatch_async(self.completionQueue, ^{

            NSArray<NSNumber*>* featureVector = [fc7_img floatArray];

            NSArray<NSNumber*>* probabilities = [outputImage floatArray];
            
            if(probabilities && featureVector)
            {
                NSMutableArray<NSArray*>* predictions = [NSMutableArray arrayWithCapacity:probabilities.count];
                
                [probabilities enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSArray* prediction = @[ self.labels[idx] , obj ];
                    [predictions addObject:prediction];
                }];
                
                [predictions sortUsingComparator:^NSComparisonResult(NSArray*  _Nonnull prediction1, NSArray*  _Nonnull prediction2) {
                    
                    if([ prediction1[1] floatValue] > [prediction2[1] floatValue])
                        return NSOrderedAscending;
                    else if([ prediction1[1] floatValue] < [prediction2[1] floatValue])
                        return NSOrderedDescending;
                    else
                        return NSOrderedSame;
                }];
                // Convert our outputImage to float
                // Read through each value and assign a prediction to it
                
                NSArray* top5 = [predictions subarrayWithRange:NSMakeRange(0, 5)];
                
                NSLog(@"Top Prediction: %@", top5);
                
                // Convert the texture from outputImage into something we can use from
                // Swift and then find the ImageNet classes with the highest probability.
                //        let result = self.labels.top5Labels(prediction: self.outputImage.toFloatArray())
                
                NSMutableDictionary* metadata = nil;
                
                //            if(request.results.count)
                {
                    metadata = [NSMutableDictionary dictionary];
                    if(completionBlock)
                    {
                        completionBlock( @{[self moduleName] : metadata} , nil);
                    }
                }
            }
            // No Results
            else
            {
                if(completionBlock)
                {
                    completionBlock( nil, nil);
                }
            }
        });
    }];
 
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

}



- (NSDictionary*) finalizedAnalysisMetadata;
{
    return nil;
}


@end
