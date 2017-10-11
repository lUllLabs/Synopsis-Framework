//
//  FileWatcher.h
//  Synopsis
//
//  Created by vade on 9/14/17.
//  Copyright © 2017 metavisual. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    SynopsisDirectoryWatcherModePolling = ( 1 << 0 ), // use Polling mechanism
    SynopsisDirectoryWatcherModeFSEvent = ( 1 << 1 ), //  use FSEvents
    
    SynopsisDirectoryWatcherModeDefault = SynopsisDirectoryWatcherModePolling | SynopsisDirectoryWatcherModeFSEvent ,
} SynopsisDirectoryWatcherMode;

// TODO: Think about if we need or want additional flags?
//typedef enum : NSUInteger {
//    SynopsisDirectoryWatcherFlagsTopLevelChanges = ( 1 << 0 ),
//    SynopsisDirectoryWatcherFlagsAllChangedFiles = ( 1 << 1 ),
//} SynopsisDirectoryWatcherFlags;

typedef void(^SynopsisDirectoryWatcherNoticiationBlock)(NSArray<NSURL*>*);

#pragma mark -

@interface SynopsisDirectoryWatcher : NSObject

- (instancetype) initWithDirectoryAtURL:(NSURL*)url mode:(SynopsisDirectoryWatcherMode)mode notificationBlock:(SynopsisDirectoryWatcherNoticiationBlock)notificationBlock;

@property (readonly) NSURL* directoryURL;
@property (readwrite, assign) double notificationDelay;

- (BOOL) doesPolling;
- (BOOL) doesFSEvent;

- (BOOL) setPollingInterval:(double)interval;
- (double) pollingInterval;

// on some file systems we cannot gurantee that SynopsisDirectoryWatcherFlagsAllChangedFiles will be respected
// You may request it, but remote mounted volumes for example will only give you
//- (SynopsisDirectoryWatcherFlags) workingFlags;


@end
