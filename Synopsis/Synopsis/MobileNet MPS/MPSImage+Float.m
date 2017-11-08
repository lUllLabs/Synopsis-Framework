//
//  MPSImage+Float.m
//  Synopsis-macOS
//
//  Created by vade on 11/7/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "MPSImage+Float.h"

@implementation MPSImage (Float)

- (NSArray<NSNumber*>*) floatArray
{
    assert(self.pixelFormat == MTLPixelFormatRGBA16Float);
    
    NSUInteger numSlices = (self.featureChannels + 3)/4;

    NSUInteger channelsPlusPadding = (self.featureChannels < 3) ? self.featureChannels : numSlices * 4;
    
    // Find how many elements we need to copy over from each pixel in a slice.
    // For 1 channel it's just 1 element (R); for 2 channels it is 2 elements
    // (R+G), and for any other number of channels it is 4 elements (RGBA).
    NSUInteger numComponents = (self.featureChannels < 3) ? self.featureChannels : 4;
    
    // Allocate the memory for the array. If batching is used, we need to copy
    // numSlices slices for each image in the batch.
    NSUInteger count = self.width * self.height * channelsPlusPadding * self.numberOfImages;


    MTLRegion region = MTLRegionMake3D(0, 0, 0, self.width, self.height, 1);
    
    size_t uint16_Size = sizeof(UInt16);
    size_t float_Size = sizeof(float);
    UInt16* outputFloat16 = (UInt16*) malloc(uint16_Size * count);
    float* outputFloat32 = (float*) malloc(float_Size * count);
    
    for(NSUInteger i = 0; i < numSlices; i++)
    {
        [self.texture getBytes: &(outputFloat16[self.width * self.height * numComponents * i])
                   bytesPerRow:self.width * numComponents * uint16_Size
                 bytesPerImage:0
                    fromRegion:region
                   mipmapLevel:0
                         slice:i];
    }

    // Convert from float16 -> float 32
    vImage_Buffer bufferFloat16;
    bufferFloat16.data = outputFloat16;
    bufferFloat16.height = 1;
    bufferFloat16.width = count;
    bufferFloat16.rowBytes = count * uint16_Size;

    vImage_Buffer bufferFloat32;
    bufferFloat32.data = outputFloat32;
    bufferFloat32.height = 1;
    bufferFloat32.width = count;
    bufferFloat32.rowBytes = count * float_Size;

    if ( vImageConvert_Planar16FtoPlanarF(&bufferFloat16, &bufferFloat32, 0) != kvImageNoError )
    {
        NSLog(@"Error converting float16 to float32");
    }

    NSMutableArray<NSNumber*>* results = [NSMutableArray arrayWithCapacity:count];
    for(NSUInteger i = 0; i < count; i++ )
    {
        float f = (float)outputFloat32[i];
        results[i] = @( f );
    }
    
    free(outputFloat16);
    free(outputFloat32);

    return results;
}


@end
