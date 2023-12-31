//
//  BDPFileSystemHelper.m
//  Timor
//
//  Created by houjihu on 2020/3/23.
//

#import "BDPFileSystemHelper.h"
// lint:disable lark_storage_check
@implementation BDPFileSystemHelper

+ (BOOL)removeFolderIfNeed:(NSString *)folderPath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:folderPath error:nil];
    }
    return YES;
}

+ (BOOL)createFolderIfNeed:(NSString *)folderPath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        return [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return YES;
}

+ (long long)folderSizeAtPath:(NSString *)folderPath {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return 0;
    //从前向后枚举器
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString *fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}

+ (long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

+ (long long)sizeWithPath:(NSString *)filePath {
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        return 0;
    }
    long long resultSize = 0;
    @try {
        // 这里有可能抛异常，先catch住。
        if (isDirectory) {
            resultSize = [self folderSizeAtPath:filePath];
        } else {
            resultSize = [self fileSizeAtPath:filePath];
        }
    } @catch (NSException *exception) {
        resultSize = 0;
    }
    return resultSize;
}

+ (void)clearFolderInBackground:(NSString *)folderPath {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:folderPath];
        for (NSString *fileName in enumerator) {
            if ([fileName length] > 0) {
                @try {
                    // 这里有可能抛异常，先catch住。
                    [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
                } @catch (NSException *exception) {}
            }
        }
    });
}

@end
// lint:enable lark_storage_check
