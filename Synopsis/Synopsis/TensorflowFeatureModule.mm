//
//  TensorflowFeatureModule.m
//  Synopsis
//
//  Created by vade on 11/29/16.
//  Copyright © 2016 metavisual. All rights reserved.
//




#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wconversion"

#import "tensorflow/cc/ops/const_op.h"
#import "tensorflow/cc/ops/image_ops.h"
#import "tensorflow/cc/ops/standard_ops.h"
#import "tensorflow/core/framework/graph.pb.h"
#import "tensorflow/core/framework/tensor.h"
#import "tensorflow/core/graph/default_device.h"
#import "tensorflow/core/graph/graph_def_builder.h"
#import "tensorflow/core/lib/core/errors.h"
#import "tensorflow/core/lib/core/stringpiece.h"
#import "tensorflow/core/lib/core/threadpool.h"
#import "tensorflow/core/lib/io/path.h"
#import "tensorflow/core/lib/strings/stringprintf.h"
#import "tensorflow/core/platform/init_main.h"
#import "tensorflow/core/platform/logging.h"
#import "tensorflow/core/platform/types.h"
#import "tensorflow/core/public/session.h"
#import "tensorflow/core/util/command_line_flags.h"
#import "tensorflow/core/util/stat_summarizer.h"
#import "tensorflow/core/util/tensor_format.h"

#import "TensorflowFeatureModule.h"

#import <fstream>
#import <vector>

#pragma GCC diagnostic pop

#define TF_DEBUG_TRACE 0

@interface TensorflowFeatureModule ()
{
    // TensorFlow
    std::unique_ptr<tensorflow::Session> inceptionSession;
    tensorflow::GraphDef inceptionGraphDef;
    
    // Todo: Adopt code from iOS example and not use this
    std::unique_ptr<tensorflow::Session> topLabelsSession;
    
#if TF_DEBUG_TRACE
    std::unique_ptr<tensorflow::StatSummarizer> stat_summarizer;
    tensorflow::RunMetadata run_metadata;
#endif
    
    // Cached resized tensor from our input buffer (image)
    tensorflow::Tensor resized_tensor;
    
    // input image tensor
    std::string input_layer;
    
    // Label / Score tensor
    std::string final_layer;
    
    // Feature vector tensor
    std::string feature_layer;
    
    // top scoring classes
    std::vector<int> top_label_indices;  // contains top n label indices for input image
    std::vector<float> top_class_probs;  // contains top n probabilities for current input image
}

@property (atomic, readwrite, strong) NSString* inception2015GraphName;
@property (atomic, readwrite, strong) NSString* inception2015LabelName;
@property (atomic, readwrite, strong) NSArray* labelsArray;
@property (atomic, readwrite, strong) NSMutableArray* averageFeatureVec;
@property (atomic, readwrite, strong) NSMutableDictionary* averageLabelScores;
@property (atomic, readwrite, assign) NSUInteger frameCount;

@end

@implementation TensorflowFeatureModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    if(self)
    {
        
        self.averageLabelScores = [NSMutableDictionary dictionary];
        
#define V3 1
#if V3
        //        self.inception2015GraphName = @"tensorflow_inceptionV3_graph";
        //        self.inception2015GraphName = @"tensorflow_inceptionV3_graph_optimized";
//        self.inception2015GraphName = @"tensorflow_inceptionV3_graph_optimized_quantized";
        self.inception2015GraphName = @"CinemaNetI_nceptionV3_optimized";
        
        self.inception2015LabelName = @"CinemaNetI_nceptionV3_optimized";
        //        self.inception2015GraphName = @"tensorflow_inceptionV3_graph_optimized_quantized_8bit";
        input_layer = "Mul";
        final_layer = "final_result";
        feature_layer = "pool_3";
#else
        self.inception2015GraphName = @"deploy_quantized_tensorflow_inceptionV2_graph";

        // This graph has the device removed, which runs on GPU, but is slow
        // THis means im unclear if im actually running on the fucing GPU or not.
        // I have no idea
//        self.inception2015GraphName = @"deploy_quantized_weights_tensorflow_inceptionV2_graph";
        
        //        self.inception2015GraphName = @"tensorflow_inceptionV2_graph_optimized";
        //        self.inception2015GraphName = @"tensorflow_inception_graph_optimized_quantized_8bit";
        input_layer = "input";
        final_layer = "output";
        feature_layer = "softmax0";
        
#endif
        inceptionSession = NULL;
        topLabelsSession = NULL;
        
        self.averageFeatureVec = nil;
        
        // From 'Begin'
        
        tensorflow::port::InitMain(NULL, NULL, NULL);
        
        // Cache labels
        NSString* inception2015LabelPath = [[NSBundle bundleForClass:[self class]] pathForResource:self.inception2015LabelName ofType:@"txt"];
        NSString* rawLabels = [NSString stringWithContentsOfFile:inception2015LabelPath usedEncoding:nil error:nil];
        self.labelsArray = [rawLabels componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        for(NSString* label in self.labelsArray)
        {
            self.averageLabelScores[label] = @(0.0);
        }
        
        // Create Tensorflow graph and session
        NSString* inception2015GraphPath = [[NSBundle bundleForClass:[self class]] pathForResource:self.inception2015GraphName ofType:@"pb"];
        
        tensorflow::Status load_graph_status = ReadBinaryProto(tensorflow::Env::Default(), [inception2015GraphPath cStringUsingEncoding:NSUTF8StringEncoding], &inceptionGraphDef);
        
        if (!load_graph_status.ok())
        {
//            if(self.errorLog)
//                self.errorLog(@"Tensorflow:Unable to Load Graph");
        }
        else
        {
//            if(self.successLog)
//                self.successLog(@"Tensorflow: Loaded Graph");
        }
        
        tensorflow::SessionOptions options;
        
        inceptionSession = std::unique_ptr<tensorflow::Session>(tensorflow::NewSession(options));
        
        tensorflow::Status session_create_status = inceptionSession->Create(inceptionGraphDef);
        
        if (!session_create_status.ok())
        {
//            if(self.errorLog)
//                self.errorLog(@"Tensorflow: Unable to create session");
        }
        else
        {
//            if(self.successLog)
//                self.successLog(@"Tensorflow: Created Session");

//            tensorflow::graph::SetDefaultDevice("/gpu:0", &inceptionGraphDef);

        }
        

#if TF_DEBUG_TRACE
        stat_summarizer = std::unique_ptr<tensorflow::StatSummarizer>(new tensorflow::StatSummarizer(inceptionGraphDef));
#endif

    }
    return self;
}


- (NSString*) moduleName
{
    return kSynopsisStandardMetadataFeatureVectorDictKey;//@"Feature";
}

- (FrameCacheFormat) currentFrameFormat
{
    return FrameCacheFormatBGR8;
}

- (FrameCacheFormat) previousFrameFormat
{
    return FrameCacheFormatBGR8;
}

- (NSDictionary*) analyzedMetadataForCurrentFrame:(matType)frame previousFrame:(matType)lastFrame
{
    self.frameCount++;
    
#if USE_OPENCL
    cv::Mat frameMat = frame.getMat(cv::ACCESS_READ);
#else
    cv::Mat frameMat = frame;
#endif

    void* baseAddress = (void*)frameMat.datastart;
    size_t width = (size_t) frameMat.cols;
    size_t height = (size_t) frameMat.rows;
    size_t bytesPerRow =  (size_t) frameMat.cols * 3; // (BGR)
    [self submitAndCacheCurrentVideoBuffer:baseAddress width:width height:height bytesPerRow:bytesPerRow];
    
    // Actually run the image through the model.
    std::vector<tensorflow::Tensor> outputs;
    
#if TF_DEBUG_TRACE
    tensorflow::RunOptions run_options;
    run_options.set_trace_level(tensorflow::RunOptions::FULL_TRACE);
    tensorflow::Status run_status = inceptionSession->Run(run_options, { {input_layer, resized_tensor} }, {feature_layer, final_layer}, {}, &outputs, &run_metadata);
#else
    tensorflow::Status run_status = inceptionSession->Run({ {input_layer, resized_tensor} }, {feature_layer, final_layer}, {}, &outputs);
#endif

    // release cached UMAT
#if USE_OPENCL
    frameMat.release();
#endif

    if (!run_status.ok()) {
        LOG(ERROR) << "Running model failed: " << run_status;
        return nil;
    }
    
    NSDictionary* labelsAndScores = [self dictionaryFromOutput:outputs];
    
    return labelsAndScores;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    
#if TF_DEBUG_TRACE
    const tensorflow::StepStats& step_stats = run_metadata.step_stats();
    stat_summarizer->ProcessStepStats(step_stats);
    stat_summarizer->PrintStepStats();
#endif
    

    for(NSString* key in [self.averageLabelScores allKeys])
    {
        NSNumber* score = self.averageLabelScores[key];
        NSNumber* newScore = @(score.floatValue / self.frameCount);
        self.averageLabelScores[key] = newScore;
    }
    
    NSNumber* topScore = [[[self.averageLabelScores allValues] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        if([obj1 floatValue] > [obj2 floatValue])
            return NSOrderedAscending;
        else if([obj1 floatValue] < [obj2 floatValue])
            return NSOrderedDescending;

        return NSOrderedSame;
    }] firstObject];
    
    NSString* topLabel = [[self.averageLabelScores allKeysForObject:topScore] firstObject];
    
    return @{ kSynopsisStandardMetadataFeatureVectorDictKey : self.averageFeatureVec,
              kSynopsisStandardMetadataDescriptionDictKey : @[ topLabel ],
              kSynopsisStandardMetadataLabelsDictKey : [self.averageLabelScores allKeys],
              kSynopsisStandardMetadataScoreDictKey : [self.averageLabelScores allValues],
              };
}

#pragma mark - From Old TF Plugin

- (void) submitAndCacheCurrentVideoBuffer:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    
    //    const int sourceRowBytes = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    //    const int image_width = (int)CVPixelBufferGetWidth(pixelBuffer);
    //    const int fullHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    //    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    //    unsigned char *sourceBaseAddr =
    //    (unsigned char *)(CVPixelBufferGetBaseAddress(pixelBuffer));
    
#if V3
    const int wanted_input_width = 299;
    const int wanted_input_height = 299;
    const int wanted_input_channels = 3;
    const float input_mean = 128.0f;
    const float input_std = 128.0f;
#else
    const int wanted_input_width = 224;
    const int wanted_input_height = 224;
    const int wanted_input_channels = 3;
    const float input_mean = 117.0f;
    const float input_std = 1.0f;
#endif
    
    int image_height;
    unsigned char *sourceStartAddr;
    
    if (height <= width)
    {
        image_height = (int)height;
        sourceStartAddr = (unsigned char*)baseAddress;
    }
    else
    {
        image_height = (int)width;
        const int marginY = (int)((height - width) / 2);
        sourceStartAddr = ( (unsigned char*)baseAddress + (marginY * bytesPerRow));
    }

    // Now back to 3, since we are pulling from OpenCV BGR8
    // Do we care about BGR ordering
    const int image_channels = 3;
    
    assert(image_channels >= wanted_input_channels);
    
    
//    resized_tensor = tensorflow::Tensor( tensorflow::DT_FLOAT,  tensorflow::ShapeFromFormat(tensorflow::FORMAT_NHWC, 1, wanted_input_height, wanted_input_width, wanted_input_channels));

    resized_tensor = tensorflow::Tensor( tensorflow::DT_FLOAT, tensorflow::TensorShape({1, wanted_input_height, wanted_input_width, wanted_input_channels}));

    auto image_tensor_mapped = resized_tensor.tensor<float, 4>();
    tensorflow::uint8 *in = sourceStartAddr;
    float *out = image_tensor_mapped.data();
    for (int y = 0; y < wanted_input_height; ++y)
    {
        float *out_row = out + (y * wanted_input_width * wanted_input_channels);
        for (int x = 0; x < wanted_input_width; ++x)
        {
            const int in_x = (y * (int)width) / wanted_input_width;
            const int in_y = (x * image_height) / wanted_input_height;
            
            tensorflow::uint8 *in_pixel = in + (in_y * width * (image_channels)) + (in_x * (image_channels));
            float *out_pixel = out_row + (x * wanted_input_channels);
            
            // Interestingly the iOS example uses BGRA and DOES NOT re-order tensor channels to RGB
            // Matching that.
            out_pixel[0] = ((float)in_pixel[0] - (float)input_mean) / (float)input_std;
            out_pixel[1] = ((float)in_pixel[1] - (float)input_mean) / (float)input_std;
            out_pixel[2] = ((float)in_pixel[2] - (float)input_mean) / (float)input_std;
        }
    }
    
    // http://stackoverflow.com/questions/36044197/how-do-i-pass-an-opencv-mat-into-a-c-tensorflow-graph
    //
    //    // So - were going to ditch the last channel
    //    tensorflow::Tensor input_tensor(tensorflow::DT_UINT8,
    //                                    tensorflow::TensorShape({1, static_cast<long long>(height), static_cast<long long>(width), 3})); // was 4
    //
    //    auto input_tensor_mapped = input_tensor.tensor<unsigned char, 4>();
    //
    //    const unsigned char* source_data = (unsigned char*)baseAddress;
    //
    //    // TODO: check that I am dropping the alpha channel correctly :X
    //    for (int y = 0; y < height; ++y)
    //    {
    //        const unsigned char* source_row = source_data + (y * width * 4);
    //        for (int x = 0; x < width; ++x)
    //        {
    //            const unsigned char* source_pixel = source_row + (x * 4);
    //            for (int c = 0; c < 3; ++c) // was 4
    //            {
    //                const unsigned char* source_value = source_pixel + c;
    //                input_tensor_mapped(0, y, x, c) = *source_value;
    //            }
    //        }
    //    }
    //
    //    std::vector<tensorflow::Tensor> resized_tensors = [self resizeAndNormalizeInputTensor:input_tensor];
    //    
    //    resized_tensor = resized_tensors[0];
}

- (NSDictionary*) dictionaryFromOutput:(const std::vector<tensorflow::Tensor>&)outputs
{
    NSMutableArray* outputLabels = [NSMutableArray arrayWithCapacity:self.labelsArray.count];
    NSMutableArray* outputScores = [NSMutableArray arrayWithCapacity:self.labelsArray.count];

    // 1 = labels and scores
    auto predictions = outputs[1].flat<float>();
    
    for (int index = 0; index < predictions.size(); index += 1)
    {
        const float predictionValue = predictions(index);
        
        NSString* labelKey  = self.labelsArray[index % predictions.size()];
        
        NSNumber* currentLabelScore = self.averageLabelScores[labelKey];
        
        NSNumber* incrementedScore = @([currentLabelScore floatValue] + predictionValue );
        self.averageLabelScores[labelKey] = incrementedScore;
        
        [outputLabels addObject:labelKey];
        [outputScores addObject:@(predictionValue)];
    }
    
#pragma mark - Feature Vector
    
    // 0 is feature vector
    tensorflow::Tensor feature = outputs[0];
    int64_t numElements = feature.NumElements();
    tensorflow::TTypes<float>::Flat featureVec = feature.flat<float>();
    
    NSMutableArray* featureElements = [NSMutableArray arrayWithCapacity:numElements];

    for(int i = 0; i < numElements; i++)
    {
        [featureElements addObject:@( featureVec(i) ) ];
    }
    
    if(self.averageFeatureVec == nil)
    {
        self.averageFeatureVec = featureElements;
    }
    else
    {
        // average each vector element with the prior
        for(int i = 0; i < featureElements.count; i++)
        {
            float  a = [featureElements[i] floatValue];
            float  b = [self.averageFeatureVec[i] floatValue];
            
            self.averageFeatureVec[i] = @( MAX(a,b)) ;
        }
    }
    
    return @{ kSynopsisStandardMetadataFeatureVectorDictKey : featureElements ,
              @"Labels" : outputLabels,
              @"Scores" : outputScores,
              };
    
    // Disable Labels and Scores since they are irrelevant until we re-train
    //    return @{
    //              };
}

@end
