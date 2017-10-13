//
//  SynopsisFileManager.h
//  Synopsis-macOS
//
//  Created by vade on 10/13/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>

@interface SynopsisRemoteFileHelper : NSObject

- (BOOL) fileURLIsRemote:(NSURL*)fileURL;
- (BOOL) safelyCopyFileURLOnRemoteFileSystem:(NSURL*)fromURL toURL:(NSURL*)toURL error:(NSError**)error;
- (NSArray<NSURL*>*) safelyEnumerateDirectoryOnRemoteVolume:(NSURL*) directory;

@end
