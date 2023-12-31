//
//  BDImageDiskFileCache.m
//  BDWebImage
//
//  Created by 陈奕 on 2019/9/27.
//

#import "BDImageDiskFileCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#if __has_include(<MMKV/MMKV.h>)
#import <MMKV/MMKV.h>
#endif

#define BDDiskCacheWeakSelf __weak typeof(self) wself = self
#define BDDiskCacheStrongSelf __strong typeof(wself) self = wself
#define dispatch_sync_safe(queue , block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_sync(queue, block);\
    }
#define dispatch_async_safe(queue , block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
        block();\
    } else {\
        dispatch_async(queue, block);\
    }


static NSString *const kBDDiskCacheName = @"com.bd.file.cache";
static NSString *const kBDDiskCacheDefaultName = @"com.bd.image.defaults";

@interface BDImageDiskFileCache ()

@property (nonatomic, strong, nonnull) BDImageCacheConfig *config;
@property (nonatomic, copy) NSString *diskCachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;
@property (nonatomic, strong) dispatch_queue_t ioQueue;

@end

@implementation BDImageDiskFileCache

- (instancetype)init
{
    NSAssert(NO, @"Use `initWithCachePath:` with the disk cache path");
    return nil;
}

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath
{
    if (self = [super init]) {
        _diskCachePath = [cachePath stringByAppendingPathComponent:kBDDiskCacheName];
        _config = [BDImageCacheConfig new];
        _fileManager = [NSFileManager defaultManager];
        _ioQueue = dispatch_queue_create("com.bd.image.cache.disk", DISPATCH_QUEUE_SERIAL);
#if __has_include(<MMKV/MMKV.h>)
        [MMKV setLogLevel:MMKVLogNone];
        dispatch_async(_ioQueue, ^{
            NSString *oldInfoPath = [MMKV mmkvBasePath];
            [[NSFileManager defaultManager] removeItemAtPath:[oldInfoPath stringByAppendingPathComponent:@"com.bd.image.defaults"]
                                                       error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[oldInfoPath stringByAppendingPathComponent:@"com.bd.image.defaults.crc"]
                                                       error:nil];
        });
#endif
    }
    return self;
}

- (NSString *)path
{
    return self.diskCachePath;
}

- (void)setConfig:(nonnull BDImageCacheConfig *)config
{
    _config = config;
}

- (BOOL)bd_containsDataForKey:(nonnull NSString *)key
{
    if (!key) return NO;
    NSString *filePath = [self cachePathForKey:key];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    
    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    if (!exists) {
        exists = [self.fileManager fileExistsAtPath:filePath.stringByDeletingPathExtension];
    }
    
    return exists;
}

- (BOOL)containsDataForKey:(nonnull NSString *)key
{
    __block BOOL contains = NO;
    dispatch_sync_safe(_ioQueue, ^{
        contains = [self bd_containsDataForKey:key];
    });
    return contains;
}

- (void)containsDataForKey:(NSString *)key
                 withBlock:(void (^)(NSString * _Nonnull, BOOL))block
{
    if (!block) {
        return;
    }
    BDDiskCacheWeakSelf;
    dispatch_async(_ioQueue, ^{
        BDDiskCacheStrongSelf;
        BOOL contains = [self bd_containsDataForKey:key];
        block(key, contains);
    });
}

- (nullable NSData *)bd_dataForKey:(nonnull NSString *)key
{
    if (!key) return nil;
    NSString *filePath = [self cachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:nil];

    if (!data) {
        // checking the key with and without the extension
        data = [NSData dataWithContentsOfFile:filePath.stringByDeletingPathExtension
                                      options:0
                                        error:nil];
    }
    
    return data;
}

- (nullable NSData *)dataForKey:(nonnull NSString *)key
{
    __block NSData *data = nil;
    dispatch_sync_safe(_ioQueue, ^{
        data = [self bd_dataForKey:key];
    });
    return data;
}

- (void)dataForKey:(NSString *)key
         withBlock:(void (^)(NSString * _Nonnull, NSData * _Nullable))block
{
    if (!block) {
        return;
    }
    BDDiskCacheWeakSelf;
    dispatch_async(_ioQueue, ^{
        BDDiskCacheStrongSelf;
        NSData * data = [self bd_dataForKey:key];
        block(key, data);
    });
}

- (void)bd_setData:(nullable NSData *)data forKey:(nonnull NSString *)key
{
    if (!key) return;
    if (!data) {
        [self removeDataForKey:key];
        return;
    }

    if (![self.fileManager fileExistsAtPath:self.diskCachePath]) {
        [self.fileManager createDirectoryAtPath:self.diskCachePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:NULL];
    }
    
    // get cache Path for image key
    NSString *cachePathForKey = [self cachePathForKey:key];
    // transform to NSUrl
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
    
    [data writeToURL:fileURL options:NSDataWritingAtomic error:nil];

    // ignore iCloud backup resource value error
    [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
}

- (void)setData:(nullable NSData *)data forKey:(nonnull NSString *)key
{
    dispatch_sync_safe(_ioQueue, ^{
        [self bd_setData:data forKey:key];
    });
}

- (void)setData:(NSData *)data
         forKey:(NSString *)key
      withBlock:(void (^)(void))block
{
    BDDiskCacheWeakSelf;
    dispatch_async(_ioQueue, ^{
        BDDiskCacheStrongSelf;
        [self bd_setData:data forKey:key];
        if (block) {
            block();
        }
    });
}

- (void)bd_removeDataForKey:(nonnull NSString *)key
{
    if (!key) return;
    NSString *filePath = [self cachePathForKey:key];
    [self.fileManager removeItemAtPath:filePath error:nil];
}

- (void)removeDataForKey:(nonnull NSString *)key
{
    dispatch_sync_safe(_ioQueue, ^{
        [self bd_removeDataForKey:key];
    });
}

- (void)removeDataForKey:(nonnull NSString *)key
               withBlock:(nullable void (^)(NSString *))block
{
    BDDiskCacheWeakSelf;
    dispatch_async(_ioQueue, ^{
        BDDiskCacheStrongSelf;
        [self bd_removeDataForKey:key];
        if (block) {
            block(key);
        }
    });
}

- (void)bd_removeAllData
{
    [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
    [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
}

- (void)removeAllData
{
    dispatch_sync_safe(_ioQueue, ^{
        [self bd_removeAllData];
    });
}

- (void)removeAllDataWithBlock:(nullable void (^)(void))block
{
    BDDiskCacheWeakSelf;
    dispatch_async(_ioQueue, ^{
        BDDiskCacheStrongSelf;
        [self bd_removeAllData];
        if (block) {
            block();
        }
    });
}

- (void)removeExpiredData
{
    dispatch_sync_safe(_ioQueue, ^{
        [self bd_removeExpiredData];
    });
}

- (void)bd_removeExpiredData
{
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    
    // Compute content date key to be used for tests
    NSURLResourceKey cacheContentDateKey = NSURLContentModificationDateKey;
    
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, cacheContentDateKey, NSURLTotalFileAllocatedSizeKey];
    
    // This enumerator prefetches useful properties for our cache files.
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
    NSTimeInterval diskAgeLimit = self.config.diskAgeLimit;
    NSDate *expirationDate = (diskAgeLimit < 0) ? nil: [NSDate dateWithTimeIntervalSinceNow:-diskAgeLimit];
    NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
    NSUInteger currentCacheSize = 0;
    
    // Enumerate all of the files in the cache directory.  This loop has two purposes:
    //
    //  1. Removing files that are older than the expiration date.
    //  2. Storing file attributes for the size-based cleanup pass.
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        
        // Skip directories and errors.
        if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        // Remove files that are older than the expiration date;
        NSDate *modifiedDate = resourceValues[cacheContentDateKey];
        if (expirationDate && [[modifiedDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
        
        // Store a reference to this file and account for its total size.
        NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
        currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
        cacheFiles[fileURL] = resourceValues;
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [self.fileManager removeItemAtURL:fileURL error:nil];
        NSString *pathKey = [fileURL.absoluteString lastPathComponent];
        if (pathKey) {
            self.trimBlock(pathKey);
        }
    }
    
    // If our remaining disk cache exceeds a configured maximum size, perform a second
    // size-based cleanup pass.  We delete the oldest files first.
    NSUInteger maxDiskSize = self.config.diskSizeLimit;
    if (maxDiskSize > 0 && currentCacheSize > maxDiskSize) {
        // Target half of our maximum cache size for this cleanup pass.
        const NSUInteger desiredCacheSize = maxDiskSize / 2;
        
        // Sort the remaining cache files by their last modification time or last access time (oldest first).
        NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                     return [obj1[cacheContentDateKey] compare:obj2[cacheContentDateKey]];
                                                                 }];
        
        // Delete files until we fall below our desired cache size.
        for (NSURL *fileURL in sortedFiles) {
            if ([self.fileManager removeItemAtURL:fileURL error:nil]) {
                
                NSString *pathKey = [fileURL.absoluteString lastPathComponent];
                if (pathKey) {
                    self.trimBlock(pathKey);
                }
                
                NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                
                if (currentCacheSize < desiredCacheSize) {
                    break;
                }
            }
        }
    }
}

- (nullable NSString *)cachePathForKey:(nonnull NSString *)key
{
    NSParameterAssert(key);
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

- (NSUInteger)totalSize
{
    __block NSUInteger size = 0;
    dispatch_sync_safe(_ioQueue, (^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary<NSString *, id> *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    }));
    return size;
}

- (NSUInteger)totalCount
{
    __block NSUInteger count = 0;
    dispatch_sync_safe(_ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
        count = fileEnumerator.allObjects.count;
    });
    return count;
}

- (BOOL)trimDiskInBG
{
    return YES;
}

#pragma mark - Cache paths

- (nullable NSString *)cachePathForKey:(nullable NSString *)key
                                inPath:(nonnull NSString *)path
{
    NSString *filename = BDDiskCacheFileNameForKey(key);
    return [path stringByAppendingPathComponent:filename];
}

#pragma mark - Hash

#define BD_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

static inline NSString * _Nonnull BDDiskCacheFileNameForKey(NSString * _Nullable key)
{
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15]];
    return filename;
}

@end
