//
//  IESGurdFilePaths.m
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import "IESGurdFilePaths.h"

@implementation IESGurdCacheRootDirectoryPath

static NSString *kIESGurdCacheRootDirectoryPath = nil;
+ (NSString *)path
{
    return kIESGurdCacheRootDirectoryPath;
}

+ (void)setPath:(NSString *)path
{
    if (!path) {
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        path = [cachesDirectory stringByAppendingPathComponent:@"IESWebCache"];
    }
    kIESGurdCacheRootDirectoryPath = path;
}

@end

@implementation IESGurdFilePaths

+ (void)initialize
{
    NSAssert(IESGurdCacheRootDirectoryPath.path,
             @"IESGeckoKit hasn't setup, call +[IESGurdKit setupWithAppId:appVersion:cacheRootDirectory:]");
}

+ (NSString *)settingsResponsePath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".settings"];
}

+ (NSString *)settingsResponseCrc32Path
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".settings_crc32"];
}

+ (NSString *)inactiveDirectoryPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".inactive"];
}

+ (NSString *)backupDirectoryPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@"backup"];
}

+ (NSString *)backupSingleFileChannelPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@"backup_single_file"];
}

+ (NSString *)modifyTimeDirectoryPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".modify_time"];
}

+ (NSString *)inactiveMetaDataPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".inactive_meta"];
}

+ (NSString *)activeMetaDataPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".active_meta"];
}

+ (NSString *)inactiveMetadataPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".inactive_metadata"];
}

+ (NSString *)activeMetadataPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".active_metadata"];
}

+ (NSString *)packagesExtraPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".packages_extra"];
}

+ (NSString *)blocklistChannelPath
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".blocklist_channel"];
}

+ (NSString *)blocklistChannelCrc32Path
{
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:@".blocklist_channel_crc32"];
}

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey
{
    NSParameterAssert(accessKey.length > 0);
    return [self.cacheRootDirectoryPath stringByAppendingPathComponent:accessKey];
}

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSParameterAssert(accessKey.length > 0 && channel.length > 0);
    return [[self.cacheRootDirectoryPath stringByAppendingPathComponent:accessKey] stringByAppendingPathComponent:channel];
}

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path
{
    NSParameterAssert(accessKey.length > 0 && channel.length > 0 & path.length > 0);
    return [[[self.cacheRootDirectoryPath stringByAppendingPathComponent:accessKey]
             stringByAppendingPathComponent:channel]
            stringByAppendingPathComponent:path];
}

+ (NSString *)inactivePathForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    NSParameterAssert(accessKey.length > 0 && channel.length > 0);
    return [[self.inactiveDirectoryPath stringByAppendingPathComponent:accessKey] stringByAppendingPathComponent:channel];
}

+ (NSString *)inactivePathForAccessKeyAndVersion:(NSString *)accessKey channel:(NSString *)channel version:(uint64_t)version;
{
    return [[self inactivePathForAccessKey:accessKey channel:channel] stringByAppendingPathComponent:@(version).stringValue];
}

+ (NSString *)inactivePackagePathForAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                      version:(uint64_t)version
                                       isZstd:(bool)isZstd
                                          md5:(NSString *)md5
{
    NSParameterAssert(accessKey.length > 0 && channel.length > 0 && md5.length > 0);
    NSString *versionDirectory = @(version).stringValue;
    NSString *ext = isZstd ? @"zst" : @"zip";
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", md5, ext];
    return [[[self inactivePathForAccessKey:accessKey channel:channel] stringByAppendingPathComponent:versionDirectory] stringByAppendingPathComponent:fileName];
}

+ (NSString *)backupPathForMd5:(NSString *)md5
{
    NSParameterAssert(md5.length > 0);
    return [self.backupDirectoryPath stringByAppendingPathComponent:md5];
}

+ (NSString *)backupSingleFilePathForMd5:(NSString *)md5
{
    NSParameterAssert(md5.length > 0);
    return [self.backupSingleFileChannelPath stringByAppendingPathComponent:md5];
}

#pragma mark - Accessor

+ (NSString *)cacheRootDirectoryPath
{
    return IESGurdCacheRootDirectoryPath.path;
}

@end

@implementation IESGurdFilePaths (Helper)

+ (uint64_t)fileSizeAtPath:(NSString *)filePath
{
    if (filePath.length == 0) {
        return 0;
    }
    return [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL].fileSize;
}

+ (uint64_t)fileSizeAtDirectory:(NSString *)directory
{
    if (directory.length == 0) {
        return 0;
    }
    NSArray<NSURLResourceKey> *keys = @[ NSURLIsDirectoryKey, NSURLFileSizeKey ];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:directory]
                                                             includingPropertiesForKeys:keys
                                                                                options:0
                                                                           errorHandler:nil];
    uint64_t fileSize = 0;
    for (NSURL *fileURL in enumerator) {
        NSNumber *isDirectory = nil;
        if (![fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL]) {
            continue;
        }
        NSNumber *size = nil;
        if ([fileURL getResourceValue:&size forKey:NSURLFileSizeKey error:NULL]) {
            fileSize += size.longLongValue;
        }
    }
    return fileSize;
}

+ (NSString *)fileSizeStringAtPath:(NSString *)filePath
{
    uint64_t fileSize = [self fileSizeAtPath:filePath];
    if (fileSize < 1024) {
        return [NSString stringWithFormat:@"%lld B", fileSize];
    }
    uint64_t KB = fileSize / 1024;
    if (KB < 1024) {
        return [NSString stringWithFormat:@"%lld KB", KB];
    }
    uint64_t MB = KB / 1024;
    return [NSString stringWithFormat:@"%lld MB", MB];
}

+ (NSString *)briefFilePathWithFullPath:(NSString *)filePath
{
    NSString *occurrenceString = [NSString stringWithFormat:@"%@/", self.cacheRootDirectoryPath];
    if (![filePath containsString:occurrenceString]) {
        return filePath;
    }
    return [filePath stringByReplacingOccurrencesOfString:occurrenceString withString:@""];
}

@end
