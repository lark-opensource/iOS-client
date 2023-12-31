//
//  TTVideoEngineLoadProgress.m
//  TTVideoEngine
//
//  Created by 黄清 on 2020/7/17.
//

#import "TTVideoEngineLoadProgress.h"

@implementation TTVideoEngineCacheRange

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    TTVideoEngineCacheRange *copy = [[TTVideoEngineCacheRange alloc] init];
    copy.offset = self.offset;
    copy.size = self.size;
    return copy;
}

@end

@implementation TTVideoEngineLoadCacheInfo

- (void)setCacheSize:(NSInteger)cacheSize {
    if (_cacheRanges == nil) {
        NSMutableArray *tem = [NSMutableArray array];
        TTVideoEngineCacheRange *range = [[TTVideoEngineCacheRange alloc] init];
        [tem addObject:range];
        _cacheRanges = tem;
    }
    [_cacheRanges firstObject].offset = 0;
    [_cacheRanges firstObject].size = cacheSize;
}

- (NSInteger)maxCacheEnd {
    if (_cacheRanges != nil) {
        TTVideoEngineCacheRange *range = [_cacheRanges lastObject];
        return range.offset + range.size;
    }
    return 0;
}

- (BOOL)isFinished {
    BOOL ret = YES;
    NSInteger cacheEndSize = _preloadSize > 0 ? MIN(_preloadSize, _mediaSize) : _mediaSize;
    TTVideoEngineCacheRange *range = [_cacheRanges lastObject];
    if (_error == nil &&
        (range == nil ||
        _mediaSize <= 0 ||
        (range.offset + range.size) < cacheEndSize)) {
        ret = NO;
    }
    return ret;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    TTVideoEngineLoadCacheInfo *copy = [[TTVideoEngineLoadCacheInfo alloc] init];
    copy.cacheKey = self.cacheKey;
    copy.mediaSize = self.mediaSize;
    copy.preloadSize = self.preloadSize;
    copy.cacheState = self.cacheState;
    copy.resolution = self.resolution;
    copy.cacheRanges = [[NSArray alloc] initWithArray:self.cacheRanges copyItems:YES];
    copy.localFilePath = self.localFilePath;
    copy.error = [self.error copy];
    return copy;
}

@end

@implementation TTVideoEngineLoadProgress

- (TTVideoEngineCacheState)cacheState {
    TTVideoEngineCacheState retState = TTVideoEngineCacheStateDone;
    for (TTVideoEngineLoadCacheInfo *cacheInfo in _cacheInfos.copy) {
        if (cacheInfo.cacheState == TTVideoEngineCacheStateWirte) {
            retState = TTVideoEngineCacheStateWirte;
            break;
        }
    }
    return retState;
}

- (NSInteger)getTotalCacheSize {
    NSInteger cacheSize = 0;
    for (TTVideoEngineLoadCacheInfo *cacheInfo in _cacheInfos.copy) {
        cacheSize += cacheInfo.maxCacheEnd;
    }
    return cacheSize;
}

- (NSInteger)getTotalMediaSize {
    NSInteger mediaSize = 0;
    for (TTVideoEngineLoadCacheInfo *cacheInfo in _cacheInfos.copy) {
        mediaSize += cacheInfo.mediaSize;
    }
    return mediaSize;
}

- (BOOL)isPreloadComplete {
    if (_taskType != TTVideoEngineDataLoaderTaskTypePreload) {
        return NO;
    }
    
    BOOL ret = YES;
    for (TTVideoEngineLoadCacheInfo *cacheInfo in _cacheInfos.copy) {
        NSAssert(cacheInfo.preloadSize >= 0, @"preload size is invalid");
        if (cacheInfo.isFinished == NO) {
            ret = NO;
            break;
        }
    }
    return ret;
}

- (BOOL)isCacheEnd {
    BOOL ret = YES;
    NSInteger endCount = 0;
    for (TTVideoEngineLoadCacheInfo *cacheInfo in _cacheInfos.copy) {
        if (cacheInfo.isFinished == NO) {
            ret = NO;
        }
        else {
            endCount++;
        }
    }
    return (ret  || (endCount >= 2 && self.taskType == TTVideoEngineDataLoaderTaskTypePlay));
}

- (TTVideoEngineLoadCacheInfo *)getCahceInfo:(NSString *)key {
    TTVideoEngineLoadCacheInfo *cacheInfo = nil;
    for (TTVideoEngineLoadCacheInfo *info in self.cacheInfos.copy) {
        if ([info.cacheKey isEqualToString:key]) {
            cacheInfo = info;
            break;
        }
    }
    return cacheInfo;
}

- (void)receiveError:(NSString *)key error:(NSError *)error {
    NSAssert(key && key.length > 0 && error, @"param is invalid");
    TTVideoEngineLoadCacheInfo *cacheInfo = [self getCahceInfo:key];
    if (cacheInfo) {
        cacheInfo.error = error;
    }
}

- (NSString *)itemKey {
    if (_videoId) {
        return _videoId;
    }
    else if (self.cacheInfos.firstObject) {
        return self.cacheInfos.firstObject.cacheKey;
    }
    NSAssert(NO, @"item key is null");
    return nil;;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    TTVideoEngineLoadProgress *copy = [[TTVideoEngineLoadProgress alloc] init];
    copy.videoId = self.videoId;
    copy.taskType = self.taskType;
    copy.cacheInfos = [[NSArray alloc] initWithArray:self.cacheInfos copyItems:YES];
    return copy;
}

@end
