//
//  FileWatcher.h
//  Synopsis
//
//  Created by vade on 9/14/17.
//  Copyright © 2017 metavisual. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SynopsisDirectoryWatcherNoticiationBlock)(NSArray<NSURL*>*);

@interface SynopsisDirectoryWatcher : NSObject

@property (readwrite, assign) BOOL ignoreSubdirectories;
@property (readonly) NSURL* directoryURL;

- (instancetype) initWithDirectoryAtURL:(NSURL*)url ignoreSubdirectories:(BOOL)ignore notificationBlock:(SynopsisDirectoryWatcherNoticiationBlock)notificationBlock;

@end
