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

@property (readonly) NSURL* directoryURL;

- (instancetype) initWithDirectoryAtURL:(NSURL*)url notificationBlock:(SynopsisDirectoryWatcherNoticiationBlock)notificationBlock;

@end
