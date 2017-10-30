//
//  OpenCVAnalyzerPlugin.h
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <Synopsis/Synopsis.h>

@interface StandardAnalyzerPlugin : NSObject <AnalyzerPluginProtocol>

#pragma mark - Plugin Protocol Requirements

@property (readonly) NSString* pluginName;
@property (readonly) NSString* pluginIdentifier;
@property (readonly) NSArray* pluginAuthors;
@property (readonly) NSString* pluginDescription;
@property (readonly) NSUInteger pluginAPIVersionMajor;
@property (readonly) NSUInteger pluginAPIVersionMinor;
@property (readonly) NSUInteger pluginVersionMajor;
@property (readonly) NSUInteger pluginVersionMinor;
@property (readonly) NSString* pluginMediaType;


@property (readonly) NSArray<SynopsisVideoFormatSpecifier*>*pluginFormatSpecfiers;


// Logging callbacks fo inclusion in the UI
@property (copy) LogBlock errorLog;
@property (copy) LogBlock successLog;
@property (copy) LogBlock warningLog;
@property (copy) LogBlock verboseLog;

#pragma mark -

@property (readonly) NSArray* cpuModuleClasses;


- (void) beginMetadataAnalysisSessionWithQuality:(SynopsisAnalysisQualityHint)qualityHint commandQueue:(id<MTLCommandQueue>)commandQueue;

- (void) analyzeCurrentCVPixelBufferRef:(SynopsisVideoFrameCache*)frameCache completionHandler:(SynopsisAnalyzerPluginFrameAnalyzedCompleteCallback)completionHandler;

- (NSDictionary*) finalizeMetadataAnalysisSessionWithError:(NSError**)error;

@end
