//
//  SynopsisPythonHelper.h
//  Synopsis-Framework
//
//  Created by vade on 10/17/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SynopsisPythonHelper : NSObject

+ (instancetype) sharedHelper;
- (BOOL) invokeScript:(NSURL*)scriptURL withArguments:(NSArray<NSString*>*)arguments;

@end
