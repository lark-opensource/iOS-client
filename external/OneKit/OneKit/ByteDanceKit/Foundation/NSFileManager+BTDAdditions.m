//
//  NSFileManager+BTDAdditions.m
//  Aweme
//
//  Created by willorfang on 16/9/8.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import "NSFileManager+BTDAdditions.h"
#import "BTDMacros.h"

@implementation NSFileManager (BTDAdditions)

+ (NSString *)btd_cachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)btd_documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)btd_libraryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *)btd_mainBundlePath
{
    return [[NSBundle mainBundle] bundlePath];
}

+ (long long)btd_fileSizeAtPath:(NSString *)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

+ (long long)btd_folderSizeAtPath:(NSString *)folderPath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) {
        return 0;
    }
    
    long long folderSize = 0;
    NSArray *childFiles = [manager subpathsAtPath:folderPath];
    for (NSString *fileName in childFiles) {
        NSString *absolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self btd_fileSizeAtPath:absolutePath];
    }
    
    return folderSize;
}

+ (void)btd_printFolderDetailSizeAtPath:(NSString *)folderPath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) {
        return;
    }
    
    NSArray<NSString *> *contentArray = [manager contentsOfDirectoryAtPath:folderPath error:NULL];
    [contentArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *absolutePath = [folderPath stringByAppendingPathComponent:obj];
        //
        BOOL isDictionary = NO;
        [manager fileExistsAtPath:absolutePath isDirectory:&isDictionary];
        //
        long long fileSize = 0;
        if (isDictionary) {
            fileSize = [self btd_folderSizeAtPath:absolutePath];
        } else {
            fileSize = [self btd_fileSizeAtPath:absolutePath];
        }
        BTDLog(@"FOLDER DETAIL %@, %.2fK", obj, ((float)fileSize) / 1024);
    }];
}

+ (void)btd_clearFolderAtPath:(NSString *)folderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:folderPath]) {
        NSArray *childFiles=[fileManager subpathsAtPath:folderPath];
        for (NSString *fileName in childFiles) {
            NSString *absolutePath = [folderPath stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:absolutePath error:nil];
        }
    }
}

+ (NSArray<NSString *> *)btd_allDirsInPath:(NSString *)path
{
    NSMutableArray *retArray = [@[] mutableCopy];
    NSArray *resourceKeys = @[NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:path]
                                       includingPropertiesForKeys:resourceKeys
                                                          options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                     errorHandler:nil];
    for (NSURL *url in fileEnumerator) {
        NSDictionary *resourceValues = [url resourceValuesForKeys:resourceKeys error:NULL];
        if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
            [retArray addObject:url.path];
        }
    }
    return retArray;
}

@end
