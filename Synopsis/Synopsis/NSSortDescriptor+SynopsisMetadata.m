//
//  NSSortDescriptor+Synopsis_NSSortDescriptor.m
//  Synopsis-Framework
//
//  Created by vade on 8/5/16.
//  Copyright © 2016 v002. All rights reserved.
//

#import "NSSortDescriptor+SynopsisMetadata.h"
#import "SynopsisStrings.h"


#pragma mark - Hash Helper Functions


// Perceptual Hash
// Calculate how alike 2 hashes are
// We use this result to compare how close 2 hashes are to a 3rd relative hash

static inline NSString* toBinaryRepresentation(unsigned long long value)
{
    long nibbleCount = sizeof(value) * 2;
    NSMutableString *bitString = [NSMutableString stringWithCapacity:nibbleCount * 5];
    
    for (long index = 4 * nibbleCount - 1; index >= 0; index--)
    {
        [bitString appendFormat:@"%i", value & (1 << index) ? 1 : 0];
    }
    
    return bitString;
}

// kind of dumb - maybe we represent our hashes as numbers? whatever
static inline float compareHashes(NSString* hash1, NSString* hash2)
{
    // Split our strings into 4 64 bit ints each.
    // has looks like int64_t-int64_t-int64_t-int64_t-
    
    NSArray* hash1Strings = [hash1 componentsSeparatedByString:@"-"];
    NSArray* hash2Strings = [hash2 componentsSeparatedByString:@"-"];
    
    //    Assert(hash1Strings.count == hash2Strings.count, @"Unable to match Hash Counts");
    
    NSString* allBinaryResult = @"";
    
    for(NSUInteger i = 0; i < hash1Strings.count; i++)
    {
        NSString* hash1String = hash1Strings[i];
        NSString* hash2String = hash2Strings[i];
        
        NSScanner *scanner1 = [NSScanner scannerWithString:hash1String];
        unsigned long long result1 = 0;
        [scanner1 setScanLocation:1]; // bypass '#' character
        [scanner1 scanHexLongLong:&result1];
        
        NSScanner *scanner2 = [NSScanner scannerWithString:hash2String];
        unsigned long long result2 = 0;
        [scanner2 setScanLocation:1]; // bypass '#' character
        [scanner2 scanHexLongLong:&result2];
        
        unsigned long long result = result1 ^ result2;
        
        NSString* resultAsBinaryString = toBinaryRepresentation(result);
        
        allBinaryResult = [allBinaryResult stringByAppendingString:resultAsBinaryString];
        
    }
    
    NSUInteger characterCount = [[allBinaryResult componentsSeparatedByString:@"1"] count];
    
    float percent = ((256 - characterCount) * 100.0) / 256.0;
    
    return percent;
}

#pragma mark -

@implementation NSSortDescriptor (SynopsisMetadata)

+ (NSSortDescriptor*)synopsisHashSortDescriptorRelativeTo:(NSString*)relativeHash;
{
    NSSortDescriptor* hashSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:kSynopsisPerceptualHashKey ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSString* hash1 = (NSString*) obj1;
        NSString* hash2 = (NSString*) obj2;
        
        float percent1 = compareHashes(hash1, relativeHash);
        float percent2 = compareHashes(hash2, relativeHash);
        
        if(percent1 > percent2)
            return  NSOrderedAscending;
        if(percent1 < percent2)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return hashSortDescriptor;
}

+ (NSSortDescriptor*)colorSortDescriptorRelativeTo:(NSColor*)color
{
    return nil;
}

@end
