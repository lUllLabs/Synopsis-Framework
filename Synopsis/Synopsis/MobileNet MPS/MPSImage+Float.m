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
    
    NSUInteger count = self.width * self.height * self.featureChannels;
    NSUInteger numSlices = (self.featureChannels + 3)/4;

    MTLRegion region = MTLRegionMake3D(0, 0, 0, self.width, self.height, 1);
    
    size_t uint16_Size = sizeof(UInt16);
    size_t float_Size = sizeof(float);
    UInt16* outputFloat16 = (UInt16*) malloc(uint16_Size * count);
    float* outputFloat32 = (float*) malloc(float_Size * count);
    
    for(NSUInteger i = 0; i < numSlices; i++)
    {
        [self.texture getBytes: &(outputFloat16[self.width * self.height * 4 * i])
                   bytesPerRow:self.width * 4 * uint16_Size
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
        results[i] = @(outputFloat32[i]);
    }
    
    free(outputFloat16);
    free(outputFloat32);

    return results;
}


@end
