//
//  SampleBufferAnalyzerPluginProtocol.h
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

#import <Synopsis/Synopsis.h>

#import <CoreFoundation/CoreFoundation.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark - Plugin Particulars

// Rough amount of overhead a particular plugin or module has
// For example very very taxing
typedef enum : NSUInteger {
    SynopsisAnalysisOverheadNone = 0,
    SynopsisAnalysisOverheadLow,
    SynopsisAnalysisOverheadMedium,
    SynopsisAnalysisOverheadHigh,
} SynopsisAnalysisOverhead;


// Should a plugin have configurable quality settings
// Hint the plugin to use a specific quality hint
typedef enum : NSUInteger {
    SynopsisAnalysisQualityHintLow,
    SynopsisAnalysisQualityHintMedium,
    SynopsisAnalysisQualityHintHigh,
    // No downsampling
    SynopsisAnalysisQualityHintOriginal = NSUIntegerMax,
} SynopsisAnalysisQualityHint;


typedef void (^LogBlock)(NSString* log);

@protocol AnalyzerPluginProtocol <NSObject>

@required

// Human Readable Plugin Named Also used in UI
@property (readonly) NSString* pluginName;

// Metadata Tag identifying the analyzers metadata section in the aggegated metatada track
// This should be something like info.v002.Synopsis.pluginname -

// all metadata either global or per frame is within a dictionary under this key

@property (readonly) NSString* pluginIdentifier;

// Authors for Credit - array of NSStrings
@property (readonly) NSArray* pluginAuthors;

// Human Readable Description
@property (readonly) NSString* pluginDescription;

// Expected host API Version
@property (readonly) NSUInteger pluginAPIVersionMajor;
@property (readonly) NSUInteger pluginAPIVersionMinor;

// Plugin Version (for tuning / changes to capabilities, etc)
@property (readonly) NSUInteger pluginVersionMajor;
@property (readonly) NSUInteger pluginVersionMinor;

// The type of media the plugin analyzes.
// For now, plugins only work with Video or Audio, we dont pass in two buffers at once.
// Supported values are currently only AVMediaTypeVideo, or AVMediaTypeAudio.
// Perhaps Muxed comes in the future.
@property (readonly) NSString* pluginMediaType;

// Logging callbacks fo inclusion in the UI
@property (copy) LogBlock errorLog;
@property (copy) LogBlock successLog;
@property (copy) LogBlock warningLog;
@property (copy) LogBlock verboseLog;

// Processing overhead for the plugin
//@property (readonly) SynopsisAnalysisOverhead pluginOverhead;

typedef void(^SynopsisAnalyzerPluginFrameAnalyzedCompleteCallback)(NSDictionary*, NSError*);

#pragma mark - Analysis Methods

// Initialize any resources required by the plugin for Analysis
// This is where one might initialize resources that exist over the lifetime of the module
// For example, feature detectors, Metal/OpenGL/CL/Cuda contexts
// Memory pools, etc.
- (void) beginMetadataAnalysisSessionWithQuality:(SynopsisAnalysisQualityHint)qualityHint;

// Analyze a sample buffer.
// The resulting dictionary is aggregated with all other plugins and added to the
// This method will be called once per frame, once per enabled module.

- (void) analyzeCurrentCVPixelBufferRef:(CVPixelBufferRef)pixelBuffer completionHandler:(SynopsisAnalyzerPluginFrameAnalyzedCompleteCallback)completionHandler;

// Finalize any calculations required to return global metadata
// Global Metadata is metadata that describes the entire file, not the individual frames or samples
// Things like most prominent colors over all, agreggate amounts of motion, etc
- (NSDictionary*) finalizeMetadataAnalysisSessionWithError:(NSError**)error;

@end
