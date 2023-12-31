//
//  NSFileManager+IESEffectManager.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import "NSFileManager+IESEffectManager.h"

@implementation NSFileManager (IESEffectManager)

// calculates the accumulated size of a directory on the volume in bytes.
+ (BOOL)ieseffect_getAllocatedSize:(unsigned long long *)size
                  ofDirectoryAtURL:(NSURL *)directoryURL
                             error:(NSError * __autoreleasing *)error {
    // fatal assertion when size and directoryURL are not NULL
    NSParameterAssert(size != NULL);
    NSParameterAssert(directoryURL != nil);

    // define propertiesForKeys
    NSArray *prefetchedPropertiesKeys = @[
        NSURLTotalFileAllocatedSizeKey,
        NSURLFileAllocatedSizeKey,
        NSURLIsRegularFileKey,
    ];

    // save error status
    __block BOOL errorOccurred = NO;
    
    // error handler
    BOOL (^errorHandler)(NSURL *, NSError *) = ^(NSURL *url, NSError *localError) {
        // if the error callback is called, means an error has occurred
        errorOccurred = YES;
        
        if (error != NULL)
            *error = localError;
        
        return NO;
    };

    NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                                includingPropertiesForKeys:prefetchedPropertiesKeys
                                                                                   options:(NSDirectoryEnumerationOptions)0
                                                                              errorHandler:errorHandler];
    
    if (errorOccurred) {
        return NO;
    }

    // define content size
    unsigned long long contentSize = 0;
    
    for (NSURL *contentItemURL in dirEnumerator) {

        // need to get regular file
        NSNumber *isRegularFile;
        if (![contentItemURL getResourceValue:&isRegularFile
                                       forKey:NSURLIsRegularFileKey
                                        error:error]) {
            return NO;
        }
        if (![isRegularFile boolValue]) {
            continue;
        }
       
        // get file size
        NSNumber *fileSize;
        if (![contentItemURL getResourceValue:&fileSize
                                       forKey:NSURLTotalFileAllocatedSizeKey
                                        error:error]) {
            return NO;
        }
    
        if (fileSize == nil) {
            if (![contentItemURL getResourceValue:&fileSize
                                           forKey:NSURLFileAllocatedSizeKey
                                            error:error]) {
                return NO;
            }
            
            // fatal assertion when fileSize
            NSAssert(fileSize != nil,
                     @"ieseffect_getAllocatedSize: NSURLFileAllocatedSizeKey should not be nil");
        }

        // sum up content size
        contentSize += [fileSize unsignedLongLongValue];
    }
    
    *size = contentSize;
    return YES;
}

+ (BOOL)ieseffect_getFileSize:(unsigned long long *)size filePath:(NSString *)filePath error:(NSError *__autoreleasing  _Nullable *)error {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:error];
    if (attributes) {
        unsigned long long fileSize = [attributes[NSFileSize] unsignedLongLongValue];
        *size = fileSize;
        return YES;
    }
    
    return NO;
}

@end
