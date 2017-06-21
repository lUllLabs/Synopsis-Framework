//
//  NSDictionary+JSONString.h
//  MetadataTranscoderTestHarness
//
//  Created by vade on 4/3/15.
//  Copyright (c) 2015 Synopsis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (JSONString)
-(NSString*) jsonStringWithPrettyPrint:(BOOL) prettyPrint;
@end


@interface NSArray (JSONString)
-(NSString*) jsonStringWithPrettyPrint:(BOOL) prettyPrint;
@end
