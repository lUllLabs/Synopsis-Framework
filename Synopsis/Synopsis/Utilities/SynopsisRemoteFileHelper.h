//
//  SynopsisFileManager.h
//  Synopsis-macOS
//
//  Created by vade on 10/13/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import <Synopsis/Synopsis.h>

/* Why do we have this code at all you may wonder?
 
 Because NSFileManager cannot be trusted to do work on remotely mounted volumes it appears.
 
 It appears there is some sort of race condition that occurs when NSFIleManager moves a directory on a remote volume, and then immeidatrly attempts to enumerate it.
 Because NSFileManager is a "good boye" and tries to copy all file meteadata along with the data itself, copies are not 'atomic' but rather may involve multiple writes/updates
 Copy src -> dest, then update ACLs, perms, modification/create dates, info, XATTR metadata).
 
 This, plus some internal caching of state, allow us to have the fun scneario where
 
 * NSFileManager successfully moves /Volume/Mount_on_Server/Parent_1/Child to /Volume/Mount_on_Server/Parent_2/Child
 * (say user triggered manual or watch folder action, moves files into temp..)
 * Enumeration of contents ("Child") of "Parent_2" has stale state due to unfinished updates of metadata
 * Enumeration of directory fails because NSFIleManager *reads* stale metadata or cache and thinks its in a different folder, rather than where it just put it.
 
 Attempts to fix include
 
 * [url removeAllCachedResourceValues];
 * Using paths rather than NSURLs to avoid run loop caching of resource value metadata
 * Making replacements for the functions we need, which are smart enough, but not so smart they trigger the same issue
 
 The latter *appears* to have worked.
 
 Things to think about
 * Resulting files from these copies *DO NOT HAVE OUR SYNOPSIS / SPOTLIGHT XATTR Data* !!!
 * * Do we figure out if XATTR is safe in our scenario and trust out code to do the right thing
 * * This issue only rears its ugly head when a URL is on a volume
 * * Do we check for this, and only use our 'remote volume' safe methods when we need to?
 * What to do about .DSStore BS?
 * Do we care about any hidden files at all?
 * Do we are about moving to nftw which apparently is the way to correctly do directory enumeration?
 
 */

@interface SynopsisRemoteFileHelper : NSObject

- (BOOL) fileURLIsRemote:(NSURL*)fileURL;
- (BOOL) safelyCopyFileURLOnRemoteFileSystem:(NSURL*)fromURL toURL:(NSURL*)toURL error:(NSError**)error;
- (NSArray<NSURL*>*) safelyEnumerateDirectoryOnRemoteVolume:(NSURL*) directory;

@end
