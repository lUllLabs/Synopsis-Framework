//
//  FileWatcher.m
//  Synopsis
//
//  Created by vade on 9/14/17.
//  Copyright © 2017 metavisual. All rights reserved.
//

#import "SynopsisDirectoryWatcher.h"

@interface SynopsisDirectoryWatcher (FSEventStreamCallbackSupport)
- (void) coalescedNotificationWithChangedURLArray:(NSArray<NSURL*>*)changedUrls;
@end

#pragma mark -

void mycallback(
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    @autoreleasepool
    {
        if(clientCallBackInfo != NULL)
        {
            SynopsisDirectoryWatcher* watcher = (__bridge SynopsisDirectoryWatcher*)(clientCallBackInfo);

            int i;
            
            NSMutableArray* changedURLS = [NSMutableArray new];
            
            NSLog(@"Recieved %lu Directory Watch Events", numEvents);
            
            for (i = 0; i < numEvents; i++)
            {
                FSEventStreamEventFlags flags = eventFlags[i];

                NSLog(@"Flags: %u", flags);
                
                BOOL none = (flags & kFSEventStreamEventFlagNone) != 0;
                BOOL subdirs = (flags & kFSEventStreamEventFlagMustScanSubDirs) != 0;
//                BOOL created = (flags & kFSEventStreamEventFlagItemCreated) != 0;
//                BOOL removed = (flags & kFSEventStreamEventFlagItemRemoved) != 0;
//                BOOL inodeMetaModified = (flags & kFSEventStreamEventFlagItemInodeMetaMod) != 0;
//                BOOL renamed = (flags & kFSEventStreamEventFlagItemRenamed) != 0;
//                BOOL modified = (flags & kFSEventStreamEventFlagItemModified) != 0;
//                BOOL finderInfoModified = (flags & kFSEventStreamEventFlagItemFinderInfoMod) != 0;
//                BOOL changedOwner = (flags & kFSEventStreamEventFlagItemChangeOwner) != 0;
//                BOOL xattrModified = (flags & kFSEventStreamEventFlagItemXattrMod) != 0;
//                BOOL isFile = (flags & kFSEventStreamEventFlagItemIsFile) != 0;
//                BOOL isDir = (flags & kFSEventStreamEventFlagItemIsDir) != 0;
//                BOOL isSymlink = (flags & kFSEventStreamEventFlagItemIsSymlink) != 0;
                
                if(none)
                {
                    NSLog(@"Event %u Flag None", i);
                }
                
                if(subdirs)
                {
                    NSLog(@"Event %u Flag Scan Subdirs", i);
                }

//                NSString* filePath = [[NSString alloc] initWithCString:paths[i] encoding:NSUTF8StringEncoding];
//                NSURL* fileURL = [NSURL fileURLWithPath:filePath];
//                [changedURLS addObject:fileURL];
            }
            if(numEvents)
            {
                    [watcher coalescedNotificationWithChangedURLArray:changedURLS];
            }
        }
    }
}

#pragma mark -

@interface SynopsisDirectoryWatcher ()
{
    FSEventStreamRef eventStream;
}
@property (readwrite, strong) NSURL* directoryURL;
@property (readwrite, strong) dispatch_queue_t fileSystemNotificationQueue;
@property (readwrite, strong) dispatch_source_t pollingTimerSource;
@property (readwrite, copy) SynopsisDirectoryWatcherNoticiationBlock notificationBlock;
@property (readwrite, strong) NSSet* latestDirectorySet;

@end

@implementation SynopsisDirectoryWatcher

- (instancetype) initWithDirectoryAtURL:(NSURL*)url ignoreSubdirectories:(BOOL)ignoreSubdirectories notificationBlock:(SynopsisDirectoryWatcherNoticiationBlock)notificationBlock
{
    self = [super init];
    if(self)
    {
        eventStream = NULL;
        
        self.fileSystemNotificationQueue = dispatch_queue_create("info.synopsis.filewatchqueue", DISPATCH_QUEUE_SERIAL);
        
        if([url isFileURL])
        {
            NSNumber* isDirValue;
            NSError* error;
            if([url getResourceValue:&isDirValue forKey:NSURLIsDirectoryKey error:&error])
            {
                if([isDirValue boolValue])
                {
                    self.directoryURL = url;
                    self.ignoreSubdirectories = ignoreSubdirectories;
                    self.latestDirectorySet = [self generateHeirarchyForURL:self.directoryURL];
                    
                    self.notificationBlock = notificationBlock;
                    
                    //[self initDispatch];
                    [self initFSEvents];
                    [self initPollingSource];
                }
            }
        }
        else
        {
            return nil;
        }
    }
    
    return self;
}

- (void) initFSEvents
{
    if(eventStream)
    {
        FSEventStreamStop(eventStream);
        FSEventStreamRelease(eventStream);
        eventStream = NULL;
    }
    
    NSArray* paths = @[ [self.directoryURL path]];
    
    FSEventStreamContext* context = (FSEventStreamContext*) malloc(sizeof(FSEventStreamContext));
    context->info = (__bridge void*) (self);
    context->release = NULL;
    context->retain = NULL;
    context->version = 0;
    context->copyDescription = NULL;
    
    eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                      mycallback,
                                      context,
                                      (CFArrayRef)CFBridgingRetain(paths),
                                      kFSEventStreamEventIdSinceNow,
                                      1.0,
                                      kFSEventStreamCreateFlagNone | kFSEventStreamCreateFlagIgnoreSelf);
    
    FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    FSEventStreamStart(eventStream);
}

- (void) initPollingSource
{
    self.pollingTimerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.fileSystemNotificationQueue);
    double interval = 5.0;
    dispatch_source_set_timer(self.pollingTimerSource, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
    dispatch_source_set_event_handler(self.pollingTimerSource, ^{

        NSLog(@"Directory Watcher Polling");

        [self coalescedNotificationWithChangedURLArray:nil];
    });

    dispatch_resume(self.pollingTimerSource);
}

- (void) dealloc
{
    if(eventStream)
    {
        FSEventStreamStop(eventStream);
        FSEventStreamInvalidate(eventStream);
        FSEventStreamRelease(eventStream);
        eventStream = NULL;
    }
    
    if(self.pollingTimerSource)
    {
        dispatch_source_cancel(self.pollingTimerSource);
    }
}

- (NSSet*) generateHeirarchyForURL:(NSURL*)url;
{
    NSMutableSet* urlSet = [[NSMutableSet alloc] init];
    
    NSDirectoryEnumerationOptions options = (self.ignoreSubdirectories) ? NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles : NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
    
    NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtURL:url
                                                             includingPropertiesForKeys:[NSArray array]
                                                                                options:options
                                                                           errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                                               return YES;
                                                                           }];
    for (NSURL* url in enumerator)
    {
        [urlSet addObject:url];
    }
    
    return urlSet;
}

- (void) coalescedNotificationWithChangedURLArray:(NSArray<NSURL*>*)changedUrls
{
    dispatch_async(self.fileSystemNotificationQueue, ^{
        if(self.notificationBlock)
        {
            NSSet* currentDirectorySet = [self generateHeirarchyForURL:self.directoryURL];
            
            NSMutableSet* deltaSet = [[NSMutableSet alloc] init];
            [deltaSet setSet:currentDirectorySet];
            [deltaSet minusSet:self.latestDirectorySet];
            
            self.latestDirectorySet = currentDirectorySet;
            
            if(deltaSet.count)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSLog(@"Directory Watcher found actionable changes: %@", deltaSet);
                    
                    self.notificationBlock([deltaSet allObjects]);
                });
            }
        }

    });
}



@end
