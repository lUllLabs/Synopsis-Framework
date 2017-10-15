//
//  SynopsisFileManager.m
//  Synopsis-macOS
//
//  Created by vade on 10/13/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisRemoteFileHelper.h"
#import <copyfile.h>
#import <dirent.h>

@implementation SynopsisRemoteFileHelper

#pragma mark - Replacement NSFileManager Methods For Working with Mounted Volumes on Remote Servers  -

- (BOOL) fileURLIsRemote:(NSURL*)fileURL
{
    if(fileURL.isFileURL)
    {
        NSNumber* isLocalValue = nil;
        if([fileURL getResourceValue:&isLocalValue forKey:NSURLVolumeIsLocalKey error:nil])
        {
            return ![isLocalValue boolValue];
        }
        return NO;
    }
    
    return NO;
}

int copyCallBack(int what, int stage, copyfile_state_t state, const char * src, const char * dst, void * ctx)
{
    @autoreleasepool
    {
        NSString* srcPath = [[NSString alloc] initWithUTF8String:src];
        // NSLog(@"CopyFileCallback %@", srcPath);
        // NSString* dstPath = [[NSString alloc] initWithUTF8String:dst];
        // NSLog(@"CopyFileCallback %@", dstPath);
        
        // Dont copy invisible files
        if([srcPath hasPrefix:@"."])
        {
            return COPYFILE_SKIP;
        }
        
        if(what == COPYFILE_RECURSE_FILE)
        {
            // check if src contains a type we dont want to copy
            NSURL* srcURL = [NSURL fileURLWithPath:srcPath];
            
            NSString* fileType;
            NSError* error;
            
            if(![srcURL getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:&error])
            {
                // Bail on error?
                return COPYFILE_QUIT;
            }
            
            if([SynopsisSupportedFileTypes() containsObject:fileType])
            {
                //                NSLog(@"Skipping copying %@", srcPath);
                return COPYFILE_SKIP;
            }
        }
        
        if(what == COPYFILE_RECURSE_ERROR)
        {
            COPYFILE_QUIT;
        }
        
        return COPYFILE_CONTINUE;
    }
}

- (BOOL) safelyCopyURLOnRemoteVolume:(NSURL*)fromURL toURL:(NSURL*)toURL error:(NSError**)error
{
    NSString* fromString = [fromURL path];
    NSString* toString = [toURL path];
    
    // TODO: Test the shit out of these flags
    copyfile_flags_t flags = COPYFILE_RECURSIVE | COPYFILE_NOFOLLOW_SRC  | COPYFILE_DATA | COPYFILE_XATTR ;
    
    copyfile_state_t copystate = copyfile_state_alloc();
    
    copyfile_state_set(copystate, COPYFILE_STATE_STATUS_CB | COPYFILE_STATE_SRC_FILENAME , &copyCallBack);
    
    OSStatus returnValue = copyfile([fromString cStringUsingEncoding:NSUTF8StringEncoding], [toString cStringUsingEncoding:NSUTF8StringEncoding], copystate, flags);
    
    copyfile_state_free(copystate);
    
    if(returnValue == noErr)
    {
        return YES;
    }
    
    if(*error != nil)
    {
        //        TODO:set error to something descriptive
    }
    
    return NO;
}

- (NSArray<NSURL*>*) safelyEnumerateDirectoryOnRemoteVolume:(NSURL*) directory// completionBlock:((void) ^(void))completionBlock
{
    NSString* path = directory.path;
    DIR* dirp = opendir([path cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableArray<NSURL*>* urlArray = [NSMutableArray array];
    
    if (dirp == NULL)
    {
        return nil;
    }
    
    struct dirent* dp = NULL;
    while ((dp = readdir(dirp)) != NULL)
    {
        NSString* name = [[NSString alloc] initWithUTF8String: dp->d_name];
        if (dp->d_type == DT_DIR)
        {
            if(![name isEqualToString:@".."] && ![name isEqualToString:@"."])
            {
                NSURL* subDir = [directory URLByAppendingPathComponent:name isDirectory:YES];
                
                [urlArray addObjectsFromArray: [self safelyEnumerateDirectoryOnRemoteVolume:subDir] ];
            }
        }
        
        if (dp->d_type == DT_REG)
        {
            // Dont add invisible files
            if([name hasPrefix:@"."])
            {
                continue;
            }
            
            NSURL* fileURL = [directory URLByAppendingPathComponent:name isDirectory:NO];
            [urlArray addObject:fileURL];
        }
    }
    
    (void)closedir(dirp);
    
    return urlArray;
}


@end
