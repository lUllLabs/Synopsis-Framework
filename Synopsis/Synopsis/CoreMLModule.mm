//
//  CoreML.m
//  Synopsis
//
//  Created by vade on 6/7/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "CoreMLModule.h"
#import "Inceptionv3.h"
#import "GoogLeNetPlaces.h"
#import <Metal/Metal.h>
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>


@interface CoreMLModule ()
@property (readwrite, strong) Inceptionv3* inceptionMLModel;
@property (readwrite, strong) GoogLeNetPlaces* GoogLeNetPlacesMLModel;
@property (readwrite, strong) VNCoreMLModel* inceptionVNModel;
@property (readwrite, strong) VNCoreMLModel* GoogLeNetPlacesVNModel;
@property (readwrite, strong) VNSequenceRequestHandler* sequenceRequestHandler;
@property (readwrite, strong) NSLock* metadataLock;
@end

@implementation CoreMLModule

- (instancetype) initWithQualityHint:(SynopsisAnalysisQualityHint)qualityHint
{
    self = [super initWithQualityHint:qualityHint];
    if(self)
    {
        self.sequenceRequestHandler = [[VNSequenceRequestHandler alloc] init];
        self.inceptionMLModel = [[Inceptionv3 alloc] init];
        self.GoogLeNetPlacesMLModel = [[GoogLeNetPlaces alloc] init];
        
        NSError* error = nil;
        self.inceptionVNModel = [VNCoreMLModel modelForMLModel:self.inceptionMLModel.model error:&error];
        self.GoogLeNetPlacesVNModel = [VNCoreMLModel modelForMLModel:self.GoogLeNetPlacesMLModel.model error:&error];
        
        self.metadataLock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString*) moduleName
{
    return @"CoreML";
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
    if(frame.empty())
        return nil;
    
    // Weirdly had issues using this CVPIxelBuffer for whatever reason
    // IOSurface backing was nil, which might explain lack of ability to create
    // Metal Textures or whatever the hell happens underneath
    CVPixelBufferRef matPixelBuffer = NULL;
    
    NSDictionary * attributes = @{
                                  (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{},
                                  (NSString *)kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey: @(YES),
                                  (NSString *)kCVPixelBufferIOSurfaceOpenGLFBOCompatibilityKey : @(YES),
                                  (NSString *)kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey : @(YES),
                                  (NSString *)kCVPixelBufferMetalCompatibilityKey : @(YES),
                                  };
    
    CVReturn err = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                frame.cols,
                                                frame.rows,
                                                kCVPixelFormatType_24RGB,
                                                frame.data,
                                                frame.cols * 3,
                                                NULL,
                                                NULL,
                                                 (__bridge CFDictionaryRef)(attributes),
                                                &matPixelBuffer);
    
    CIImage* image = [CIImage imageWithCVImageBuffer:matPixelBuffer];
    
    // Sadly for right now we're going to make this a blocking API
    // I need to re-factor so analysis can take a completion block.
    dispatch_group_t analysisWaitGroup = dispatch_group_create();
    
    // Our Mutable Metadata Dictionary:
    NSMutableDictionary* metadata = [NSMutableDictionary new];
    
    dispatch_group_enter(analysisWaitGroup);
    VNCoreMLRequest* inceptionRequest = [[VNCoreMLRequest alloc] initWithModel:self.inceptionVNModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        NSArray* top5 = [request.results subarrayWithRange:NSMakeRange(0, 5)];
        NSMutableArray* top5String = [NSMutableArray arrayWithCapacity:5];
        
        for(VNClassificationObservation* classification in top5)
        {
            [top5String addObject:classification.identifier];
        }
        
        [self.metadataLock lock];
        metadata[kSynopsisStandardMetadataLabelsDictKey] = top5String;
//        metadata[kSynopsisStandardMetadataScoreDictKey] =
        [self.metadataLock unlock];
        
        dispatch_group_leave(analysisWaitGroup);
    }];
    
    dispatch_group_enter(analysisWaitGroup);
    VNCoreMLRequest* googleNetRequest = [[VNCoreMLRequest alloc] initWithModel:self.GoogLeNetPlacesVNModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        
        VNClassificationObservation* classification = request.results[0];
        [self.metadataLock lock];
        metadata[kSynopsisStandardMetadataDescriptionDictKey] = classification.identifier;
        [self.metadataLock unlock];
        
        dispatch_group_leave(analysisWaitGroup);
    }];
    
    // TODO: In next beta try to successfully force MTLDevice on our requests
    // Currently does not work (throws exception)
    inceptionRequest.preferBackgroundProcessing = NO;
    googleNetRequest.preferBackgroundProcessing = NO;
    
    NSError* error = nil;
    
    // Its unclear if I want to use a sequence request or an image request
    // Sadly, neither appear to batch
    [self.sequenceRequestHandler performRequests:@[inceptionRequest,googleNetRequest] onCIImage:image error:&error];
    
//    VNImageRequestHandler* imageRequestHandler = [[VNImageRequestHandler alloc] initWithCIImage:image options:nil];
//    [imageRequestHandler performRequests:@[googleNetRequest] error:&error];
    
    
    
    if(error)
        NSLog(@"Error: %@", error);
    
    dispatch_group_wait(analysisWaitGroup,DISPATCH_TIME_FOREVER);
    
    return metadata;
}

- (NSDictionary*) finaledAnalysisMetadata
{
    return nil;
}


@end
