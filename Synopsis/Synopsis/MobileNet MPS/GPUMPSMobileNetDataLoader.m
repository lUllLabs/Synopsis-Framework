//
//  GPUMPSMobileNetDataLoader.m
//  Synopsis-macOS
//
//  Created by vade on 11/7/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "GPUMPSMobileNetDataLoader.h"

@interface GPUMPSMobileNetDataLoader ()
@property (readwrite, strong) NSData* databacking;
@end


@implementation GPUMPSMobileNetDataLoader

- (nonnull instancetype) initWithURL:(NSURL*)url
{
    self = [super init];
    if(self)
    {
        assert(url != nil);
            
        NSError* error = nil;
        self.databacking = [NSData dataWithContentsOfURL:url options:0 error:&error];
    
        if(error)
        {
            NSLog(@"Error loading dat file: %@", error);
        }
//        self.databacking = [[NSMutableData alloc] initWithCapacity:16884128];
    }
    
    return self;
}
- (const float*) data { return self.databacking.bytes; };

//- (nonnull const float*) conv1_s2_w { return self.data.bytes + 0;  }
//- (nonnull const float*) conv1_s2_b { return self.data.bytes + 864;  }
//- (nonnull const float*) conv2_1_dw_w { return self.data.bytes + 896; }
//- (nonnull const float*) conv2_1_dw_b { return self.data.bytes + 1184; }
//- (nonnull const float*) conv2_1_s1_w { return self.data.bytes + 1216; }
//- (nonnull const float*) conv2_1_s1_b { return self.data.bytes + 3264; }
//- (nonnull const float*) conv2_2_dw_w { return self.data.bytes + 3328; }
//- (nonnull const float*) conv2_2_dw_b { return self.data.bytes + 3904; }
//- (nonnull const float*) conv2_2_s1_w { return self.data.bytes + 3968; }
//- (nonnull const float*) conv2_2_s1_b { return self.data.bytes + 12160; }
//- (nonnull const float*) conv3_1_dw_w { return self.data.bytes + 12288; }
//- (nonnull const float*) conv3_1_dw_b { return self.data.bytes + 13440; }
//- (nonnull const float*) conv3_1_s1_w { return self.data.bytes + 13568; }
//- (nonnull const float*) conv3_1_s1_b { return self.data.bytes + 29952; }
//- (nonnull const float*) conv3_2_dw_w { return self.data.bytes + 30080; }
//- (nonnull const float*) conv3_2_dw_b { return self.data.bytes + 31232; }
//- (nonnull const float*) conv3_2_s1_w { return self.data.bytes + 31360; }
//- (nonnull const float*) conv3_2_s1_b { return self.data.bytes + 64128; }
//- (nonnull const float*) conv4_1_dw_w { return self.data.bytes + 64384; }
//- (nonnull const float*) conv4_1_dw_b { return self.data.bytes + 66688; }
//- (nonnull const float*) conv4_1_s1_w { return self.data.bytes + 66944; }
//- (nonnull const float*) conv4_1_s1_b { return self.data.bytes + 132480; }
//- (nonnull const float*) conv4_2_dw_w { return self.data.bytes + 132736; }
//- (nonnull const float*) conv4_2_dw_b { return self.data.bytes + 135040; }
//- (nonnull const float*) conv4_2_s1_w { return self.data.bytes + 135296; }
//- (nonnull const float*) conv4_2_s1_b { return self.data.bytes + 266368; }
//- (nonnull const float*) conv5_1_dw_w { return self.data.bytes + 266880; }
//- (nonnull const float*) conv5_1_dw_b { return self.data.bytes + 271488; }
//- (nonnull const float*) conv5_1_s1_w { return self.data.bytes + 272000; }
//- (nonnull const float*) conv5_1_s1_b { return self.data.bytes + 534144; }
//- (nonnull const float*) conv5_2_dw_w { return self.data.bytes + 534656; }
//- (nonnull const float*) conv5_2_dw_b { return self.data.bytes + 539264; }
//- (nonnull const float*) conv5_2_s1_w { return self.data.bytes + 539776; }
//- (nonnull const float*) conv5_2_s1_b { return self.data.bytes + 801920; }
//- (nonnull const float*) conv5_3_dw_w { return self.data.bytes + 802432; }
//- (nonnull const float*) conv5_3_dw_b { return self.data.bytes + 807040; }
//- (nonnull const float*) conv5_3_s1_w { return self.data.bytes + 807552; }
//- (nonnull const float*) conv5_3_s1_b { return self.data.bytes + 1069696; }
//- (nonnull const float*) conv5_4_dw_w { return self.data.bytes + 1070208; }
//- (nonnull const float*) conv5_4_dw_b { return self.data.bytes + 1074816; }
//- (nonnull const float*) conv5_4_s1_w { return self.data.bytes + 1075328; }
//- (nonnull const float*) conv5_4_s1_b { return self.data.bytes + 1337472; }
//- (nonnull const float*) conv5_5_dw_w { return self.data.bytes + 1337984; }
//- (nonnull const float*) conv5_5_dw_b { return self.data.bytes + 1342592; }
//- (nonnull const float*) conv5_5_s1_w { return self.data.bytes + 1343104; }
//- (nonnull const float*) conv5_5_s1_b { return self.data.bytes + 1605248; }
//- (nonnull const float*) conv5_6_dw_w { return self.data.bytes + 1605760; }
//- (nonnull const float*) conv5_6_dw_b { return self.data.bytes + 1610368; }
//- (nonnull const float*) conv5_6_s1_w { return self.data.bytes + 1610880; }
//- (nonnull const float*) conv5_6_s1_b { return self.data.bytes + 2135168; }
//- (nonnull const float*) conv6_1_dw_w { return self.data.bytes + 2136192; }
//- (nonnull const float*) conv6_1_dw_b { return self.data.bytes + 2145408; }
//- (nonnull const float*) conv6_1_s1_w { return self.data.bytes + 2146432; }
//- (nonnull const float*) conv6_1_s1_b { return self.data.bytes + 3195008; }
//- (nonnull const float*) fc7_w { return self.data.bytes + 3196032; }
//- (nonnull const float*) fc7_b { return self.data.bytes + 4220032; }

@end
