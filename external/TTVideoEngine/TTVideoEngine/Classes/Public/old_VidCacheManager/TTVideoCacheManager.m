//
//  TTVideoEngineCacheInfo.m
//
//  Created by 陈代龙 on 2018/8/22.
//

#import "TTVideoCacheManager.h"
#import "TTVideoEngineUtil.h"
#include <CommonCrypto/CommonDigest.h>
#import "NSDictionary+TTVideoEngine.h"
#import "NSString+TTVideoEngine.h"
#include <sys/stat.h>
#import "ttvideoenginecacheutils.h"
#import "TTVideoEngineUtilPrivate.h"


#define KEY_NUMBER 4
#define KEY_NUMBER_ENCRYPTED 5

BOOL  TTVideoEnginecheckCacheFileComplete(NSString* cacheFilePath);

@interface TTVideoEngineCacheInfo ()
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *fileKey;
@property (nonatomic, assign) unsigned long long fileSize;
@property (nonatomic, copy) NSString *cacheKey;
@property (nonatomic, copy) NSString *spadeaKey;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@end

@implementation TTVideoEngineCacheInfo

+ (NSArray<NSString *> *)keysWithFileName:(NSString *)fileName {
    NSArray<NSString *> *items = [fileName componentsSeparatedByString:@"."];
    if (items.count > 0) {
        return [items[0] componentsSeparatedByString:@"_"];
    }
    
    return NULL;
}

+ (BOOL)isValidKeys:(NSArray<NSString *> *)keys {
    if (keys.count == KEY_NUMBER || keys.count == KEY_NUMBER_ENCRYPTED) {
        for(NSString *key in keys) {
            if (key.length == 0) {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

+ (NSString *)cacheKey:(NSArray<NSString *> *)keys {
    return [[NSString alloc] initWithFormat:@"%@_%@", keys[0], keys[1], nil];
}

+ (NSString *)fileKey:(NSArray<NSString *> *)keys {
    return [[NSString alloc] initWithFormat:@"%@_%@_%@_%@", keys[0], keys[1], keys[2], keys[3], nil];
}

+ (unsigned long long)fileSize:(NSArray<NSString *> *)keys {
    return [keys[3] longLongValue];
}

+ (NSString *)md5:(NSArray<NSString *> *)keys {
    return keys[2];
}

+ (NSString *)spadeaKey:(NSArray<NSString *> *)keys {
    if (keys.count == KEY_NUMBER_ENCRYPTED) {
        return keys[4];
    }
    return nil;
}



+ (unsigned long long)localFileSize:(NSString *)filePath {
    const char *cpath = [filePath fileSystemRepresentation];
    struct stat statbuf;
    if (cpath && stat(cpath, &statbuf) == 0) {
        return statbuf.st_size;
    }
    
    return 0L;
}

+ (unsigned long long)localFileDateTime:(NSString *)filePath {
    const char *cpath = [filePath fileSystemRepresentation];
    struct stat statbuf;
    if (cpath && stat(cpath, &statbuf) == 0) {
        if (statbuf.st_mtime > 0) {
            return statbuf.st_mtime;
        }
        
        return statbuf.st_ctime;
    }
    
    return 0L;
}

- (BOOL)isInDisk {
    NSFileManager *fileManager = [NSFileManager alloc];
    return _filePath != NULL && [fileManager fileExistsAtPath:_filePath];
}

- (BOOL)checkCacheFile:(NSString *)md5 fileSize:(unsigned long long)fileSize {
    TTVideoEngineLog(@"start check md5:%@ filesize:%llu",md5,fileSize);
    if (self.fileSize == fileSize) {
        unsigned long long originFileSize = [TTVideoEngineCacheInfo localFileSize:self.filePath];
        if (originFileSize < fileSize) {
            TTVideoEngineLog(@"end check md5:%@ filesize:%llu originfilesize:%llu not match",md5,fileSize,originFileSize);
            return NO;
        }
        
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        if (handle != NULL) {
            CC_MD5_CTX ctx;
            CC_MD5_Init(&ctx);
            
            BOOL done = NO;
            
            unsigned long long readFileSize   = fileSize;
            const unsigned int readBufferSize = readFileSize < 10240 ? (const unsigned int)readFileSize : 10240;
            while(!done) {
                @autoreleasepool {
                    const unsigned int dataLength = readFileSize < readBufferSize ? (const unsigned int)readFileSize : readBufferSize;
                    NSData* fileData = [handle readDataOfLength: dataLength];
                    CC_MD5_Update(&ctx, [fileData bytes], (CC_LONG)[fileData length]);
                    if (readFileSize <= fileData.length) {
                        done = YES;
                    } else {
                        readFileSize -= fileData.length;
                    }
                }
            }
            
            unsigned char digest[CC_MD5_DIGEST_LENGTH];
            CC_MD5_Final(digest, &ctx);
            NSString *result = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                digest[0], digest[1],
                                digest[2], digest[3],
                                digest[4], digest[5],
                                digest[6], digest[7],
                                digest[8], digest[9],
                                digest[10], digest[11],
                                digest[12], digest[13],
                                digest[14], digest[15]];
            
            [handle closeFile];
            TTVideoEngineLog(@"end check md5:%@ computed md5:%@",md5,result);
            return [result isEqualToString: md5];
        }
    }
    TTVideoEngineLog(@"end check md5");
    return NO;
}

@end

@interface TTVideoCacheManager ()
@property(nonatomic, copy) NSString *dir;
@property(nonatomic, assign) unsigned long long maxSize;
@property(nonatomic, assign) unsigned long long totalSize;
- (void)loadCacheInfos;
@end

@implementation TTVideoCacheManager {
    NSMutableDictionary<NSString *, TTVideoEngineCacheInfo *> *_keyCacheInfos;
    NSMutableArray<TTVideoEngineCacheInfo *> *_cacheInfos;
    NSMutableDictionary<NSString *,  NSNumber *> *_protectedKeys;
    dispatch_queue_t _queue;
}

+ (instancetype)shared {
    static TTVideoCacheManager *TTVideoCacheManager_shared = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTVideoCacheManager_shared = [[TTVideoCacheManager alloc] init];
    });
    
    return TTVideoCacheManager_shared;
}

- (unsigned long long)videoCacheSize {
    unsigned long long videoCacheSize = 0L;
    @synchronized(self) {
        for(TTVideoEngineCacheInfo *cacheInfo in _cacheInfos) {
            if (_protectedKeys[cacheInfo.cacheKey] == NULL && [cacheInfo isInDisk]) {
                videoCacheSize += cacheInfo.fileSize;
            }
        }
    }
    
    return videoCacheSize;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _keyCacheInfos = [[NSMutableDictionary alloc] init];
        _cacheInfos = [[NSMutableArray alloc] init];
        _protectedKeys = [[NSMutableDictionary alloc] init];
        _queue = dispatch_queue_create("vclould.engine.videoCache.queue",DISPATCH_QUEUE_SERIAL);
        
        self.maxSize = 10 * 1024 * 1024;
    }
    
    return self;
}

- (void)updateCacheInfo:(TTVideoEngineCacheInfo *)cacheInfo {
    NSString *filePath = [cacheInfo.filePath copy];
    NSDate *now = [NSDate date];
    
    dispatch_async(_queue, ^{
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager setAttributes:@{NSFileModificationDate:now} ofItemAtPath:filePath error:nil];
    });
    
    cacheInfo.lastUpdateTime = [now timeIntervalSince1970];
}

- (TTVideoEngineCacheInfo*) getCacheInfo:(NSString*)key {
    @synchronized(self) {
        TTVideoEngineCacheInfo *cacheInfo = [_keyCacheInfos ttvideoengine_objectForKey:key];
        TTVideoEngineLog(@"start get cache info key:%@",key);
        if (cacheInfo != NULL) {
            cacheInfo.spadeaKey = [cacheInfo.spadeaKey ttvideoengine_transformDecode];
            NSArray<NSString *> *keys = [TTVideoEngineCacheInfo keysWithFileName:cacheInfo.fileName];
            if ([TTVideoEngineCacheInfo isValidKeys:keys]) {
                NSString *md5 = [TTVideoEngineCacheInfo md5:keys];
                unsigned long long fileSize = [TTVideoEngineCacheInfo fileSize:keys];
                if ([cacheInfo checkCacheFile:md5 fileSize:fileSize]) {
                    [_cacheInfos removeObject:cacheInfo];
                    [_cacheInfos addObject:cacheInfo];
                    
                    [self updateCacheInfo:cacheInfo];
                    TTVideoEngineLog(@"end get cache info key:%@, suc!",key);
                    return cacheInfo;
                }
            }
        }
        TTVideoEngineLog(@"end get cache info key:%@, fail!",key);
        return NULL;
    }
}

- (void) addCacheInfo:(NSString*)fileName filePath:(NSString*)filePath {
    @synchronized(self) {
        NSArray<NSString *> *keys = [TTVideoEngineCacheInfo keysWithFileName:fileName];
        TTVideoEngineLog(@"start add cacheinfo, filename:%@ filepath:%@",fileName,filePath);
        if ([TTVideoEngineCacheInfo isValidKeys:keys]) {
            TTVideoEngineLog(@"key of cache info is valid");
            NSString *cacheKey = [TTVideoEngineCacheInfo cacheKey:keys];
            TTVideoEngineCacheInfo *cacheInfo = _keyCacheInfos[cacheKey];
            if (cacheInfo == NULL) {
                TTVideoEngineLog(@"cache info not exist allow add");
                cacheInfo = [[TTVideoEngineCacheInfo alloc] init];
                
                cacheInfo.cacheKey = cacheKey;
                cacheInfo.fileKey  = [TTVideoEngineCacheInfo fileKey:keys];
                cacheInfo.filePath = filePath;
                cacheInfo.fileName = fileName;
                cacheInfo.fileSize = [TTVideoEngineCacheInfo fileSize:keys];
                cacheInfo.spadeaKey = [TTVideoEngineCacheInfo spadeaKey:keys];
                
                cacheInfo.lastUpdateTime = [NSDate date].timeIntervalSince1970;
                
                _keyCacheInfos[cacheKey] = cacheInfo;
                [_cacheInfos addObject:cacheInfo];
                
                self.totalSize += cacheInfo.fileSize;
            }
            
            [self removeCacheInfoIfNeeds:NO];
        }
        TTVideoEngineLog(@"end add cacheinfo");
    }
}

- (void) setCacheParameter:(NSString*)dir maxSize:(unsigned long long)maxSize {
    self.dir = dir;
    self.maxSize = maxSize;
}

- (void) addProtectKey:(NSString *)key {
    @synchronized(self) {
        NSNumber *protectedNumber = _protectedKeys[key];
        _protectedKeys[key] = @([protectedNumber integerValue] + 1);
        TTVideoEngineLog(@"add key:%@ to prorected",key);
    }
}

- (void) removeProtectKey:(NSString *)key {
    @synchronized(self) {
        NSNumber *protectedNumber = _protectedKeys[key];
        if (protectedNumber != NULL) {
            NSInteger count = [protectedNumber integerValue];
            if (count < 2) {
                [_protectedKeys removeObjectForKey:key];
            } else {
                _protectedKeys[key] = @(count - 1);
            }
        }
        TTVideoEngineLog(@"remove key:%@ from prorected",key);
    }
}

- (void) start {
    [self loadCacheInfos];
}

- (void) compact {
    @synchronized(self) {
        [self removeCacheInfoIfNeeds:YES];
    }
}

- (void)removeCacheFiles:(NSArray<NSString *> *)filePaths {
    
    dispatch_async(_queue, ^{
        TTVideoEngineLog(@"start remove dirty paths");
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        for(NSString *filePath in filePaths) {
            [fileManager removeItemAtPath:filePath error:nil];
            TTVideoEngineLog(@"remove file path:%@",filePath);
        }
        TTVideoEngineLog(@"end remove dirty paths");
    });
}

- (void)removeCacheInfoIfNeeds:(BOOL)isCompact {
    TTVideoEngineLog(@"start remove cache info iscompat:%d",isCompact ? 1:0);
    if (self.totalSize > self.maxSize || isCompact) {
        unsigned long long remainingSize = isCompact ? 0L : self.maxSize / 2;
        
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:_cacheInfos.count];
        for (NSInteger index = 0; index < _cacheInfos.count; index++) {
            if (self.totalSize > remainingSize) {
                TTVideoEngineCacheInfo *cacheInfo = _cacheInfos[index];
                if (_protectedKeys[cacheInfo.cacheKey] == NULL) {
                    NSString *filePath = cacheInfo.filePath;
                    
                    if (filePath != NULL) {
                        NSString *deleteFilePath = [filePath stringByAppendingString:@".del"];
                        dispatch_sync(_queue, ^{
                            [fileManager moveItemAtPath:filePath toPath:deleteFilePath error:nil];
                        });
                        
                        [filePaths addObject:deleteFilePath];
                    }
                    
                    self.totalSize -= cacheInfo.fileSize;
                    [_cacheInfos removeObjectAtIndex:index--];
                    [_keyCacheInfos removeObjectForKey:cacheInfo.cacheKey];
                    
                    TTVideoEngineLog(@"add filepath:%@ tobe removed",filePath);
                }
            } else {
                break;
            }
        }
        
        [self removeCacheFiles:filePaths];
    }
    TTVideoEngineLog(@"end remove cache info iscompat:%d",isCompact ? 1:0);
}

- (void)loadCacheInfos {
    NSString *dir = self.dir;
    TTVideoEngineLog(@"start load cache infos dir is:%@",dir);
    if (dir.length > 0) {
        
        NSMutableArray<TTVideoEngineCacheInfo *> *cacheInfos = [[NSMutableArray alloc] init];
        NSMutableArray <NSString *> *dirtyFilePaths = [NSMutableArray array];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSArray<NSString *> *fileNames = [fileManager contentsOfDirectoryAtPath:dir error:nil];
        for (NSString *fileName in fileNames) {
            NSString *filePath = [dir stringByAppendingPathComponent:fileName];
            NSArray<NSString *> *keys = [TTVideoEngineCacheInfo keysWithFileName:fileName];
            if ([TTVideoEngineCacheInfo isValidKeys:keys]) {
                NSString *cacheKey                = [TTVideoEngineCacheInfo cacheKey:keys];
                NSString *fileKey                 = [TTVideoEngineCacheInfo fileKey:keys];
                NSString *spadeaKey               = [TTVideoEngineCacheInfo spadeaKey:keys];
                NSString *temFilePath = filePath;
                NSString *temFileName = fileName;
                NSString* transformSting = [spadeaKey ttvideoengine_transformEncode];
                if (transformSting && ![transformSting isEqualToString:spadeaKey]) {
                    temFilePath = [temFilePath stringByReplacingOccurrencesOfString:spadeaKey withString:transformSting];
                    temFileName = [temFileName stringByReplacingOccurrencesOfString:spadeaKey withString:transformSting];
                    [fileManager moveItemAtPath:filePath toPath:temFilePath error:nil];
                    spadeaKey = transformSting;
                }
                
                unsigned long long fileSize       = [TTVideoEngineCacheInfo fileSize:keys];
                unsigned long long lastUpdateTime = [TTVideoEngineCacheInfo localFileDateTime:filePath];
                
                TTVideoEngineCacheInfo *cacheInfo = [[TTVideoEngineCacheInfo alloc] init];
                cacheInfo.cacheKey       = cacheKey;
                cacheInfo.filePath       = temFilePath;
                cacheInfo.fileName       = temFileName;
                cacheInfo.fileKey        = fileKey;
                cacheInfo.spadeaKey      = spadeaKey;
                cacheInfo.lastUpdateTime = lastUpdateTime;
                cacheInfo.fileSize       = fileSize;
                
                [cacheInfos addObject:cacheInfo];
                TTVideoEngineLog(@"add cache info filename:%@ filepath:%@",temFileName,temFilePath);
            } else {
                [dirtyFilePaths addObject:filePath];
                TTVideoEngineLog(@"key is not valid not add info filename:%@ filepath:%@",fileName,filePath);
            }
        }
        
        
        [self removeCacheFiles:dirtyFilePaths];
        
        @synchronized(self) {
            for (TTVideoEngineCacheInfo *cacheInfo in cacheInfos) {
                if (_keyCacheInfos[cacheInfo.cacheKey] == NULL){
                    [_cacheInfos addObject:cacheInfo];
                    _totalSize += cacheInfo.fileSize;
                    _keyCacheInfos[cacheInfo.cacheKey] = cacheInfo;
                }
            }
            
            [_cacheInfos sortUsingComparator:^NSComparisonResult(TTVideoEngineCacheInfo *  _Nonnull obj1,
                                                                 TTVideoEngineCacheInfo *  _Nonnull obj2) {
                return [@(obj1.lastUpdateTime) compare:@(obj2.lastUpdateTime)];
            }];
            
            [self removeCacheInfoIfNeeds:NO];
        }
    }
    TTVideoEngineLog(@"end load cache infos totalsize:%llu",_totalSize);
}

- (BOOL)checkCacheFileComplete:(NSString *)cacheFilePath {
    return TTVideoEnginecheckCacheFileComplete(cacheFilePath);
}

- (BOOL)checkCacheFileIntegrity:(NSString *)filePath fileHash:(NSString *)fileHash fileSize:(uint64_t)fileSize {
    return (ttvideoengine_check_cache_file_integrity(filePath.fileSystemRepresentation, fileSize, fileHash.UTF8String) > 0);
}

+ (NSString *)cacheFilePath:(NSString *)fileName dir:(NSString *)cacheDir {
    // No cache dir
    if (!cacheDir  || cacheDir.length < 1) {
        return nil;
    }
    // NO file name
    if (!fileName || fileName.length < 1) {
        return nil;
    }
    //
    if([fileName characterAtIndex:fileName.length-1] == '/') {
        return [NSString stringWithFormat:@"%@%@.ttmp",cacheDir,fileName];
    }else {
        return [NSString stringWithFormat:@"%@/%@.ttmp",cacheDir,fileName];
    }
}

@end


////////////////
#define TTVIDEOENGINE_MKTAG(a,b,c,d) ((a) | ((b) << 8) | ((c) << 16) | ((unsigned)(d) << 24))
typedef struct TTVIDEOENGINECACHEMFBOX{
    int32_t length;
    int32_t head;
    int32_t crc;
    int32_t num;
    uint32_t file_size[2];
    int32_t rv1;
    int32_t rv2;
}TTVIDEOENGINECACHEMFBox;

BOOL TTVideoEnginecheckCacheFileComplete(NSString* cacheFilePath){
    if (!cacheFilePath) {
        return NO;
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:cacheFilePath];
    if (!handle) {
        TTVideoEngineMethodLog(@"open file error file at path:%@",cacheFilePath);
        return NO;
    }
    unsigned long long readBegin = 0;
    unsigned long long originFileSize = [TTVideoEngineCacheInfo localFileSize:cacheFilePath];
    
    int headSize = sizeof(uint32_t)*2;
    readBegin = originFileSize - headSize;
    if (readBegin <= 0 || originFileSize < sizeof(TTVIDEOENGINECACHEMFBox)+headSize) {
        [handle closeFile];
        TTVideoEngineMethodLog(@"cache file error at path:%@",cacheFilePath);
        return NO;
    }
    [handle seekToFileOffset:readBegin];
    NSData* temData = [handle readDataOfLength:headSize];
    int32_t headInfo[2];
    [temData getBytes:headInfo range:NSMakeRange(0, headSize)];
    int32_t tem = TTVIDEOENGINE_MKTAG('t','t','m','f');
    if (headInfo[0] <= 0 || headInfo[1] != tem) {
        [handle closeFile];
        TTVideoEngineMethodLog(@"cache file structure(file tail) error, at path:%@",cacheFilePath);
        return NO;
    }
    
    readBegin = originFileSize - headInfo[0];
    [handle seekToFileOffset:readBegin];
    TTVIDEOENGINECACHEMFBox box;
    temData = [handle readDataOfLength:sizeof(TTVIDEOENGINECACHEMFBox)];
    [temData getBytes:&box range:NSMakeRange(0, sizeof(TTVIDEOENGINECACHEMFBox))];
    [handle closeFile];
    if (box.length <= 0 || box.head != TTVIDEOENGINE_MKTAG('t','t','m','f') || box.num == 0) {
        TTVideoEngineMethodLog(@"cache file structure error(box struct error), at path:%@",cacheFilePath);
        return NO;
    }
    
    int64_t entitySize = box.file_size[1];
    entitySize <<= 32;
    entitySize |= box.file_size[0];
    
    return  (originFileSize == (entitySize + box.length));
}
////////////////
