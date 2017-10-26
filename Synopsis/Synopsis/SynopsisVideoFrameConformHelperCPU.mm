//
//  SynopsisVideoFrameConformHelperCPU.m
//  Synopsis-Framework
//
//  Created by vade on 10/24/17.
//  Copyright © 2017 v002. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import "StandardAnalyzerDefines.h"

#import "SynopsisVideoFrameConformHelperCPU.h"
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>

#import "SynopsisVideoFrameOpenCV.h"

#define SynopsisvImageTileFlag kvImageNoFlags
//#define SynopsisvImageTileFlag kvImageDoNotTile

@interface SynopsisVideoFrameConformHelperCPU ()
{
    CVPixelBufferPoolRef transformPixelBufferPool;
    CVPixelBufferPoolRef scaledPixelBufferPool;
    vImageConverterRef toLinearConverter;
}
@property (readwrite, strong) NSOperationQueue* conformQueue;
@end

@implementation SynopsisVideoFrameConformHelperCPU

- (id) init
{
    self = [super init];
    if(self)
    {
        transformPixelBufferPool = NULL;
        scaledPixelBufferPool = NULL;
        toLinearConverter = NULL;
        
        self.conformQueue = [[NSOperationQueue alloc] init];
        self.conformQueue.maxConcurrentOperationCount = 1;
        self.conformQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    
    return self;
}

- (void) dealloc
{
    if(transformPixelBufferPool != NULL)
    {
        CVPixelBufferPoolRelease(transformPixelBufferPool);
        transformPixelBufferPool = NULL;
    }
    
    if(scaledPixelBufferPool != NULL)
    {
        CVPixelBufferPoolRelease(scaledPixelBufferPool);
        scaledPixelBufferPool = NULL;
    }
    
    if(toLinearConverter != NULL)
    {
        CFRelease(toLinearConverter);
    }
}

- (void) conformPixelBuffer:(CVPixelBufferRef)buffer
                  toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers
              withTransform:(CGAffineTransform)transform
                       rect:(CGRect)rect
            completionBlock:(SynopsisVideoFrameConformSessionCompletionBlock)completionBlock;
{
    
    NSBlockOperation* conformOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        CVPixelBufferRef pixelBuffer = [self createPixelBuffer:buffer withTransform:transform withRect:rect];
        
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        
        SynopsisVideoFrameCache* cache = [self conformToOpenCVFormatsWith:CVPixelBufferGetBaseAddress(pixelBuffer)
                                                                    width:CVPixelBufferGetWidth(pixelBuffer)
                                                                   height:CVPixelBufferGetHeight(pixelBuffer)
                                                              bytesPerRow:CVPixelBufferGetBytesPerRow(pixelBuffer)
                                                                toFormats:formatSpecifiers];
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CVPixelBufferRelease(pixelBuffer);
        
        if(completionBlock)
        {
            completionBlock(cache, nil);
        }
    }];
    
    // TODO: OPTIMIZE THIS AWAY!
    [self.conformQueue addOperations:@[conformOperation] waitUntilFinished:YES];
}

#pragma mark - OpenCV Format Conversion

// TODO: Think about lazy conversion. If we dont hit an accessor, we dont convert.
- (SynopsisVideoFrameCache*) conformToOpenCVFormatsWith:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow toFormats:(NSArray<SynopsisVideoFormatSpecifier*>*)formatSpecifiers;
{
    SynopsisVideoFrameCache* cache = [[SynopsisVideoFrameCache alloc] init];

    // TODO: Use These!
    BOOL doBGR = NO;
    BOOL doFloat = NO;
    BOOL doGray = NO;
    BOOL doPerceptual = NO;
    
    cv::Mat BGRAImage = [self imageFromBaseAddress:baseAddress width:width height:height bytesPerRow:bytesPerRow];
    
    // Convert img BGRA to CIE_LAB or LCh - Float 32 for color calulation fidelity
    // Note floating point assumtions:
    // http://docs.opencv.org/2.4.11/modules/imgproc/doc/miscellaneous_transformations.html
    // The conventional ranges for R, G, and B channel values are:
    // 0 to 255 for CV_8U images
    // 0 to 65535 for CV_16U images
    // 0 to 1 for CV_32F images = matType
    // Convert our 8 Bit BGRA to BGR
    
    // Convert to BGR
    cv::Mat BGRImage;
    cv::cvtColor(BGRAImage, BGRImage, cv::COLOR_BGRA2BGR);
    
    SynopsisVideoFormatSpecifier* bgr = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatBGR8 backing:SynopsisVideoBackingCPU];
    SynopsisVideoFrameOpenCV* videoFrameBGRA = [[SynopsisVideoFrameOpenCV alloc] initWithCVMat:BGRImage formatSpecifier:bgr];
    [cache cacheFrame:videoFrameBGRA];
    
    
    // Convert 8 bit BGR to Grey
    cv::Mat grayImage;
    cv::cvtColor(BGRImage, grayImage, cv::COLOR_BGR2GRAY);
    
    SynopsisVideoFormatSpecifier* gray = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatGray8 backing:SynopsisVideoBackingCPU];
    SynopsisVideoFrameOpenCV* videoFrameGray = [[SynopsisVideoFrameOpenCV alloc] initWithCVMat:grayImage formatSpecifier:gray];
    [cache cacheFrame:videoFrameGray];

    
    // Convert 8 Bit BGR to Float BGR
    cv::Mat BGR32Image;
    BGRImage.convertTo(BGR32Image, CV_32FC3, 1.0/255.0);
    
    SynopsisVideoFormatSpecifier* floatBGR = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatBGRF32 backing:SynopsisVideoBackingCPU];
    SynopsisVideoFrameOpenCV* videoFrameBGRF32 = [[SynopsisVideoFrameOpenCV alloc] initWithCVMat:BGR32Image formatSpecifier:floatBGR];
    [cache cacheFrame:videoFrameBGRF32];

    // Convert Float BGR to Float Perceptual
    cv::Mat perceptualImage;
    cv::cvtColor(BGR32Image, perceptualImage, TO_PERCEPTUAL);
    
    SynopsisVideoFormatSpecifier* perceptualFormat = [[SynopsisVideoFormatSpecifier alloc] initWithFormat:SynopsisVideoFormatPerceptual backing:SynopsisVideoBackingCPU];
    SynopsisVideoFrameOpenCV* videoFramePerceptual = [[SynopsisVideoFrameOpenCV alloc] initWithCVMat:perceptualImage formatSpecifier:perceptualFormat];
    [cache cacheFrame:videoFramePerceptual];

    BGRAImage.release();
    BGRImage.release();
    BGR32Image.release();
    perceptualImage.release();
    grayImage.release();
    
    return cache;
}


- (cv::Mat) imageFromBaseAddress:(void*)baseAddress width:(size_t)width height:(size_t)height bytesPerRow:(size_t)bytesPerRow
{
    size_t extendedWidth = bytesPerRow / sizeof( uint32_t ); // each pixel is 4 bytes/32 bits
    
    return cv::Mat((int)height, (int)extendedWidth, CV_8UC4, baseAddress);
}


#pragma mark - VImage and CoreVideo Resize / Conforming

- (CVPixelBufferRef) createScaledPixelBuffer:(CVPixelBufferRef)pixelBuffer withRect:(CGRect)resizeRect
{
    //    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    //    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    //
    //    CGRect originalRect = {0, 0, width, height};
    
    // Avoid half pixel values.
    resizeRect = CGRectIntegral(resizeRect);
    
    CGSize resizeSize = CGSizeZero;
    resizeSize = resizeRect.size;
    
    // Lazy Pixel Buffer Pool initialization
    // TODO: Our pixel buffer pool wont re-init if for some reason pixel buffer sizes change
    if(scaledPixelBufferPool == NULL)
    {
        NSDictionary* poolAttributes = @{ (NSString*)kCVPixelBufferWidthKey : @(resizeSize.width),
                                          (NSString*)kCVPixelBufferHeightKey : @(resizeSize.height),
                                          (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                          };
        CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef _Nullable)(poolAttributes), &scaledPixelBufferPool);
        if(err != kCVReturnSuccess)
        {
            NSLog(@"Error : %i", err);
        }
    }
    
    
    // Create our input vImage from our CVPixelBuffer
    CVPixelBufferLockBaseAddress(pixelBuffer,kCVPixelBufferLock_ReadOnly);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    vImage_Error err;
    
    vImage_Buffer inBuff;
    inBuff.height = CVPixelBufferGetHeight(pixelBuffer);
    inBuff.width = CVPixelBufferGetWidth(pixelBuffer);
    inBuff.rowBytes = bytesPerRow;
    inBuff.data = baseAddress;
    
    // Convert in buff to linear
    if(toLinearConverter == NULL)
    {
        // TODO: Introspect to confirm we are 709 / 601 / 2020 / P3 etc etc
        // Fuck Video
        
        ColorSyncProfileRef rec709 = ColorSyncProfileCreateWithName(kColorSyncITUR709Profile);
        ColorSyncProfileRef linearProfile = ColorSyncProfileCreateWithName(kColorSyncACESCGLinearProfile);
//        ColorSyncProfileRef linearProfile = [self linearRGBProfile];
        
        const void *keys[] = {kColorSyncProfile, kColorSyncRenderingIntent, kColorSyncTransformTag};
        
        const void *srcVals[] = {rec709,  kColorSyncRenderingIntentPerceptual, kColorSyncTransformPCSToPCS};
        const void *dstVals[] = {linearProfile,  kColorSyncRenderingIntentPerceptual, kColorSyncTransformPCSToPCS};
        
        CFDictionaryRef srcDict = CFDictionaryCreate (
                                                      NULL,
                                                      (const void **)keys,
                                                      (const void **)srcVals,
                                                      3,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
        
        
        CFDictionaryRef dstDict = CFDictionaryCreate (
                                                      NULL,
                                                      (const void **)keys,
                                                      (const void **)dstVals,
                                                      3,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
        
        const void* arrayVals[] = {srcDict, dstDict, NULL};
        
        CFArrayRef profileSequence = CFArrayCreate(NULL, (const void **)arrayVals, 2, &kCFTypeArrayCallBacks);
        
        ColorSyncTransformRef transform = ColorSyncTransformCreate(profileSequence, NULL);
        
        CFTypeRef codeFragment = NULL;
        codeFragment = ColorSyncTransformCopyProperty(transform, kColorSyncTransformFullConversionData, NULL);
        
        if (transform)
            CFRelease (transform);
        
        vImage_CGImageFormat inputFormat;
        inputFormat.bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
        inputFormat.renderingIntent = kCGRenderingIntentPerceptual;
        inputFormat.colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceITUR_709);
        inputFormat.bitsPerPixel = 32;
        inputFormat.bitsPerComponent = 8;
        inputFormat.decode = NULL;
        inputFormat.version = 0;
        
        vImage_CGImageFormat desiredFormat;
        desiredFormat.bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
        desiredFormat.renderingIntent = kCGRenderingIntentPerceptual;
        desiredFormat.colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGBLinear);
        desiredFormat.bitsPerPixel = 32;
        desiredFormat.bitsPerComponent = 8;
        desiredFormat.decode = NULL;
        desiredFormat.version = 0;
        
        const CGFloat backColorF[4] = {0.0};
        
        toLinearConverter = vImageConverter_CreateWithColorSyncCodeFragment(codeFragment, &inputFormat, &desiredFormat, backColorF, SynopsisvImageTileFlag, &err);
        
        CFRelease(codeFragment);
        CFRelease(srcDict);
        CFRelease(dstDict);
        CFRelease(profileSequence);
        CFRelease(rec709);
        CFRelease(linearProfile);
    }
    
    // TODO: Create linear pixel buffer pool / reuse memory
    vImage_Buffer linear;
    linear.data = malloc(CVPixelBufferGetDataSize(pixelBuffer));
    linear.height = CVPixelBufferGetHeight(pixelBuffer);
    linear.width = CVPixelBufferGetWidth(pixelBuffer);
    linear.rowBytes = bytesPerRow;
    
    // TODO: Use temp buffer not NULL
    
    err = vImageConvert_AnyToAny(toLinearConverter, &inBuff, &linear, NULL, SynopsisvImageTileFlag);
    if (err != kvImageNoError)
        NSLog(@" error %ld", err);
    
    // Scale our transformmed buffer
    CVPixelBufferRef scaledBuffer;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, scaledPixelBufferPool, &scaledBuffer);
    
    CVPixelBufferLockBaseAddress(scaledBuffer, 0);
    unsigned char *resizedBytes = (unsigned char*)CVPixelBufferGetBaseAddress(scaledBuffer);
    
    vImage_Buffer resized = {resizedBytes, CVPixelBufferGetHeight(scaledBuffer), CVPixelBufferGetWidth(scaledBuffer), CVPixelBufferGetBytesPerRow(scaledBuffer)};
    
    err = vImageScale_ARGB8888(&linear, &resized, NULL, SynopsisvImageTileFlag);
    if (err != kvImageNoError)
        NSLog(@" error %ld", err);
    
    // Free / unlock
    // Since we converted our inBuff to linear we free it to be clean
    free(linear.data);
    linear.data = NULL;
    
    // Since we just proxy our inBuff as our pixelBuffer we unlock and the pool cleans it up
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    inBuff.data = NULL; // explicit
    
    CVPixelBufferUnlockBaseAddress(scaledBuffer, 0);
    
    return scaledBuffer;
}

- (CVPixelBufferRef) createTransformedPixelBuffer:(CVPixelBufferRef)pixelBuffer withTransform:(CGAffineTransform)transform flip:(BOOL)flip
{
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGRect originalRect = {0, 0, (CGFloat)width, (CGFloat)height};
    
    CVPixelBufferLockBaseAddress(pixelBuffer,kCVPixelBufferLock_ReadOnly);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    vImage_Buffer inBuff;
    inBuff.height = CVPixelBufferGetHeight(pixelBuffer);
    inBuff.width = CVPixelBufferGetWidth(pixelBuffer);
    inBuff.rowBytes = bytesPerRow;
    inBuff.data = baseAddress;
    
    // Transform
    CGAffineTransform finalTransform = transform;
    if(flip)
    {
        CGRect flippedRect = CGRectApplyAffineTransform(originalRect, finalTransform);
        flippedRect = CGRectIntegral(flippedRect);
        
        CGAffineTransform flip = CGAffineTransformMakeTranslation(flippedRect.size.width * 0.5, flippedRect.size.height * 0.5);
        flip = CGAffineTransformScale(flip, 1, -1);
        flip = CGAffineTransformTranslate(flip, -flippedRect.size.width * 0.5, -flippedRect.size.height * 0.5);
        
        finalTransform = CGAffineTransformConcat(finalTransform, flip);
    }
    
    CGRect transformedRect = CGRectApplyAffineTransform(originalRect, finalTransform);
    
    vImage_CGAffineTransform finalAffineTransform;
    finalAffineTransform.a = finalTransform.a;
    finalAffineTransform.b = finalTransform.b;
    finalAffineTransform.c = finalTransform.c;
    finalAffineTransform.d = finalTransform.d;
    finalAffineTransform.tx = finalTransform.tx;
    finalAffineTransform.ty = finalTransform.ty;
    
    // Create our pixel buffer pool for our transformed size
    // TODO: Our pixel buffer pool wont re-init if for some reason pixel buffer sizes change
    if(transformPixelBufferPool == NULL)
    {
        NSDictionary* poolAttributes = @{ (NSString*)kCVPixelBufferWidthKey : @(transformedRect.size.width),
                                          (NSString*)kCVPixelBufferHeightKey : @(transformedRect.size.height),
                                          (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                          };
        CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef _Nullable)(poolAttributes), &transformPixelBufferPool);
        if(err != kCVReturnSuccess)
        {
            NSLog(@"Error : %i", err);
        }
    }
    
    CVPixelBufferRef transformedBuffer;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, transformPixelBufferPool, &transformedBuffer);
    
    CVPixelBufferLockBaseAddress(transformedBuffer, 0);
    unsigned char *transformBytes = (unsigned char *)CVPixelBufferGetBaseAddress(transformedBuffer);
    
    const uint8_t backColorU[4] = {0};
    
    vImage_Buffer transformed = {transformBytes, CVPixelBufferGetHeight(transformedBuffer), CVPixelBufferGetWidth(transformedBuffer), CVPixelBufferGetBytesPerRow(transformedBuffer)};
    vImage_Error err;
    
    err = vImageAffineWarpCG_ARGB8888(&inBuff, &transformed, NULL, &finalAffineTransform, backColorU, kvImageLeaveAlphaUnchanged | kvImageBackgroundColorFill | SynopsisvImageTileFlag);
    if (err != kvImageNoError)
        NSLog(@" error %ld", err);
    
    // Free / unlock
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    inBuff.data = NULL; // explicit
    
    CVPixelBufferUnlockBaseAddress(transformedBuffer, 0);
    
    return transformedBuffer;
}

- (CVPixelBufferRef) createRotatedPixelBuffer:(CVPixelBufferRef)pixelBuffer withRotation:(CGAffineTransform)transform flip:(BOOL)flip
{
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGRect originalRect = {0, 0, (CGFloat)width, (CGFloat)height};
    
    CVPixelBufferLockBaseAddress(pixelBuffer,kCVPixelBufferLock_ReadOnly);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    vImage_Buffer inBuff;
    inBuff.height = CVPixelBufferGetHeight(pixelBuffer);
    inBuff.width = CVPixelBufferGetWidth(pixelBuffer);
    inBuff.rowBytes = bytesPerRow;
    inBuff.data = baseAddress;
    
    // Transform
    CGAffineTransform finalTransform = transform;
    if(flip)
    {
        CGRect flippedRect = CGRectApplyAffineTransform(originalRect, finalTransform);
        flippedRect = CGRectIntegral(flippedRect);
        
        CGAffineTransform flip = CGAffineTransformMakeTranslation(flippedRect.size.width * 0.5, flippedRect.size.height * 0.5);
        flip = CGAffineTransformScale(flip, 1, -1);
        flip = CGAffineTransformTranslate(flip, -flippedRect.size.width * 0.5, -flippedRect.size.height * 0.5);
        
        finalTransform = CGAffineTransformConcat(finalTransform, flip);
    }
    
    CGRect transformedRect = CGRectApplyAffineTransform(originalRect, finalTransform);
    
    vImage_CGAffineTransform finalAffineTransform;
    finalAffineTransform.a = finalTransform.a;
    finalAffineTransform.b = finalTransform.b;
    finalAffineTransform.c = finalTransform.c;
    finalAffineTransform.d = finalTransform.d;
    finalAffineTransform.tx = finalTransform.tx;
    finalAffineTransform.ty = finalTransform.ty;
    
    // Create our pixel buffer pool for our transformed size
    // TODO: Our pixel buffer pool wont re-init if for some reason pixel buffer sizes change
    if(transformPixelBufferPool == NULL)
    {
        NSDictionary* poolAttributes = @{ (NSString*)kCVPixelBufferWidthKey : @(transformedRect.size.width),
                                          (NSString*)kCVPixelBufferHeightKey : @(transformedRect.size.height),
                                          (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                          };
        CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef _Nullable)(poolAttributes), &transformPixelBufferPool);
        if(err != kCVReturnSuccess)
        {
            NSLog(@"Error : %i", err);
        }
    }
    
    CVPixelBufferRef transformedBuffer;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, transformPixelBufferPool, &transformedBuffer);
    
    CVPixelBufferLockBaseAddress(transformedBuffer, 0);
    unsigned char *transformBytes = (unsigned char *)CVPixelBufferGetBaseAddress(transformedBuffer);
    
    const uint8_t backColorU[4] = {0};
    
    vImage_Buffer transformed = {transformBytes, CVPixelBufferGetHeight(transformedBuffer), CVPixelBufferGetWidth(transformedBuffer), CVPixelBufferGetBytesPerRow(transformedBuffer)};
    vImage_Error err;
    
    err = vImageAffineWarpCG_ARGB8888(&inBuff, &transformed, NULL, &finalAffineTransform, backColorU, kvImageLeaveAlphaUnchanged | kvImageBackgroundColorFill | SynopsisvImageTileFlag);
    if (err != kvImageNoError)
        NSLog(@" error %ld", err);
    
    // Free / unlock
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    inBuff.data = NULL; // explicit
    
    CVPixelBufferUnlockBaseAddress(transformedBuffer, 0);
    
    return transformedBuffer;
}

- (CVPixelBufferRef) createPixelBuffer:(CVPixelBufferRef)pixelBuffer withTransform:(CGAffineTransform)transform  withRect:(CGRect)resizeRect
{
    BOOL inputIsFlipped = CVImageBufferIsFlipped(pixelBuffer);
    
    CVPixelBufferRef scaledPixelBuffer = [self createScaledPixelBuffer:pixelBuffer withRect:resizeRect];
    
    // Is our transform equal to any 90 º rotations?
    if(!CGAffineTransformEqualToTransform(CGAffineTransformIdentity, transform))
    {
        CGAffineTransform ninety = CGAffineTransformMakeRotation(90);
        CGAffineTransform oneeighty = CGAffineTransformMakeRotation(180);
        CGAffineTransform twoseventy = CGAffineTransformMakeRotation(270);
        CGAffineTransform three360 = CGAffineTransformMakeRotation(360);
        
        // since we are transforming our scaled pixel buffer, and our transform is not identity,
        // the tx and ty components of the input transform are no longer correct since width and height are different.
        // Multiply them by the ratio of difference
        size_t scaledWidth = CVPixelBufferGetWidth(scaledPixelBuffer);
        size_t scaledHeight = CVPixelBufferGetHeight(scaledPixelBuffer);
        
        size_t originalWidth = CVPixelBufferGetWidth(pixelBuffer);
        size_t originalHeight = CVPixelBufferGetHeight(pixelBuffer);
        
        CGFloat widthRatio = (float)scaledWidth / (float)originalWidth;
        GLfloat heightRatio = (float)scaledHeight / (float)originalHeight;
        
        // round to nearest pixel
        transform.tx =  (size_t) round(transform.tx * widthRatio);
        transform.ty =  (size_t) round(transform.ty * heightRatio);
        
        unsigned int rotation = -1;
        if(CGAffineTransformEqualToTransform(ninety, transform))
            rotation = 1;
        else if(CGAffineTransformEqualToTransform(oneeighty, transform))
            rotation = 2;
        else if(CGAffineTransformEqualToTransform(twoseventy, transform))
            rotation = 2;
        else if(CGAffineTransformEqualToTransform(three360, transform))
            rotation = 2;
        
        // If our input affine transform is not a simple rotation (not sure, maybe a translate too?), use vImageAffineWarpCG_ARGB8888
        if(rotation == -1)
        {
            CVPixelBufferRef transformedPixelBuffer = [self createTransformedPixelBuffer:scaledPixelBuffer withTransform:transform flip:inputIsFlipped];
            
            CVPixelBufferRelease(scaledPixelBuffer);
            
            return transformedPixelBuffer;
        }
        else
        {
            CVPixelBufferRef rotatedPixelBuffer = [self createTransformedPixelBuffer:scaledPixelBuffer withTransform:transform flip:inputIsFlipped];
            
            CVPixelBufferRelease(scaledPixelBuffer);
            
            return rotatedPixelBuffer;
            
        }
    }
    
    return scaledPixelBuffer;
}

#pragma mark - Linear Color Sync Profile Helper

//- (ColorSyncProfileRef) linearRGBProfile
//{
//    static const uint8_t bytes[0x220] =
//    "\x00\x00\x02\x20\x61\x70\x70\x6c\x02\x20\x00\x00\x6d\x6e\x74\x72\
//    \x52\x47\x42\x20\x58\x59\x5a\x20\x07\xd2\x00\x05\x00\x0d\x00\x0c\
//    \x00\x00\x00\x00\x61\x63\x73\x70\x41\x50\x50\x4c\x00\x00\x00\x00\
//    \x61\x70\x70\x6c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\xf6\xd6\x00\x01\x00\x00\x00\x00\xd3\x2d\
//    \x61\x70\x70\x6c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x0a\x72\x58\x59\x5a\x00\x00\x00\xfc\x00\x00\x00\x14\
//    \x67\x58\x59\x5a\x00\x00\x01\x10\x00\x00\x00\x14\x62\x58\x59\x5a\
//    \x00\x00\x01\x24\x00\x00\x00\x14\x77\x74\x70\x74\x00\x00\x01\x38\
//    \x00\x00\x00\x14\x63\x68\x61\x64\x00\x00\x01\x4c\x00\x00\x00\x2c\
//    \x72\x54\x52\x43\x00\x00\x01\x78\x00\x00\x00\x0e\x67\x54\x52\x43\
//    \x00\x00\x01\x78\x00\x00\x00\x0e\x62\x54\x52\x43\x00\x00\x01\x78\
//    \x00\x00\x00\x0e\x64\x65\x73\x63\x00\x00\x01\xb0\x00\x00\x00\x6d\
//    \x63\x70\x72\x74\x00\x00\x01\x88\x00\x00\x00\x26\x58\x59\x5a\x20\
//    \x00\x00\x00\x00\x00\x00\x74\x4b\x00\x00\x3e\x1d\x00\x00\x03\xcb\
//    \x58\x59\x5a\x20\x00\x00\x00\x00\x00\x00\x5a\x73\x00\x00\xac\xa6\
//    \x00\x00\x17\x26\x58\x59\x5a\x20\x00\x00\x00\x00\x00\x00\x28\x18\
//    \x00\x00\x15\x57\x00\x00\xb8\x33\x58\x59\x5a\x20\x00\x00\x00\x00\
//    \x00\x00\xf3\x52\x00\x01\x00\x00\x00\x01\x16\xcf\x73\x66\x33\x32\
//    \x00\x00\x00\x00\x00\x01\x0c\x42\x00\x00\x05\xde\xff\xff\xf3\x26\
//    \x00\x00\x07\x92\x00\x00\xfd\x91\xff\xff\xfb\xa2\xff\xff\xfd\xa3\
//    \x00\x00\x03\xdc\x00\x00\xc0\x6c\x63\x75\x72\x76\x00\x00\x00\x00\
//    \x00\x00\x00\x01\x01\x00\x00\x00\x74\x65\x78\x74\x00\x00\x00\x00\
//    \x43\x6f\x70\x79\x72\x69\x67\x68\x74\x20\x41\x70\x70\x6c\x65\x20\
//    \x43\x6f\x6d\x70\x75\x74\x65\x72\x20\x49\x6e\x63\x2e\x00\x00\x00\
//    \x64\x65\x73\x63\x00\x00\x00\x00\x00\x00\x00\x13\x4c\x69\x6e\x65\
//    \x61\x72\x20\x52\x47\x42\x20\x50\x72\x6f\x66\x69\x6c\x65\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\
//    \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
//    
//    CFDataRef data = CFDataCreateWithBytesNoCopy (NULL, bytes, sizeof (bytes), kCFAllocatorNull);
//    
//    ColorSyncProfileRef mRef = ColorSyncProfileCreate (data, NULL);
//    
//    if (data)
//        CFRelease (data);
//    
//    if (mRef)
//    {
//        return mRef;
//    }
//    
//    return NULL;
//}

@end
