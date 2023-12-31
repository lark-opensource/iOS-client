//
//  TTVideoEnginePlayUrlSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayUrlSource.h"

@implementation TTVideoEnginePlayUrlSource

- (NSString *)videoId {
    return [_mediaInfo objectForKey:@"vid"];
}

- (NSString *)currentUrl {
    return self.url;
}

- (BOOL)isMainUrl {
    return self.url && self.url.length > 0;
}

- (NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    return self.currentUrl;
}

- (NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    return self.currentUrl ? @[self.currentUrl] : nil;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (retryCount > 2 || !self.currentUrl) {
        return TTVideoEngineRetryStrategyNone;
    }
    return TTVideoEngineRetryStrategyRestartPlayer;
}

- (BOOL)preloadDataIsExpire {
    return NO;
}

- (BOOL)isSingleUrl {
    return YES;
}

- (instancetype)deepCopy {
    TTVideoEnginePlayUrlSource *urlSource = [super deepCopy];
    if (self.url) {// assign valid data.
        urlSource.url = self.url;
    }
    return urlSource;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayUrlSource *tem = (TTVideoEnginePlayUrlSource *)object;
        result = [self.url isEqualToString:tem.url];
    }
    return result;
}

/// Tools
+ (NSDictionary *)mediaInfo:(NSString *)videoId key:(NSString *)key urls:(NSArray *)urls {
    NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
    [temDict setObject:videoId ?: key forKey:@"vid"];
    //
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setValue:urls forKey:@"urls"];
    [infoDict setValue:key forKey:@"file_hash"];
    //
    [temDict setObject:@[infoDict] forKey:@"infos"];
    return temDict.copy;
}

@end


@implementation TTVideoEnginePlayLocalSource

- (BOOL)isLocalFile {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayLocalSource *tem = (TTVideoEnginePlayLocalSource *)object;
        result = [self.url isEqualToString:tem.url];
    }
    return result;
}

@end
