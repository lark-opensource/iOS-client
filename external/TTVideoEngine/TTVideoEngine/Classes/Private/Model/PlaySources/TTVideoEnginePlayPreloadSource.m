//
//  TTVideoEnginePlayPreloadSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayPreloadSource.h"

@interface TTVideoEnginePlayPreloadSource ()

@end

@implementation TTVideoEnginePlayPreloadSource
@synthesize preloadItem = _preloadItem;

- (void)setPreloadItem:(TTAVPreloaderItem *)preloadItem {
    _preloadItem = preloadItem;
    self.videoId = preloadItem.vid;
}

- (TTAVPreloaderItem *)preloadItem {
    return _preloadItem;
}

- (NSArray<NSNumber *> *)supportResolutions {
    if (self.fetchData) {
        return [super supportResolutions];
    } else if (self.preloadItem) {
        return self.preloadItem.supportedResolutionTypes;
    }
    //
    return nil;
}

- (TTVideoEngineResolutionType)currentResolution {
    if (self.fetchData) {
        return [super currentResolution];
    } else if (self.preloadItem) {
        return (TTVideoEngineResolutionType)(self.preloadItem.resolution);
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (TTVideoEngineResolutionType)autoResolution {
    if (self.fetchData) {
        return [super autoResolution];
    } else if (self.preloadItem) {
        return (TTVideoEngineResolutionType)(self.preloadItem.resolution);
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (NSString *)currentUrl {
    if (self.fetchData) {
        return [super currentUrl];
    } else if (self.preloadItem) {
        return self.preloadItem.URL;
    }
    //
    return nil;
}

- (BOOL)supportSSL {
    if (self.fetchData) {
        return [super supportSSL];
    } else if (self.preloadItem) {
        return [self.preloadItem.URL hasPrefix:@"https"];
    }
    //
    return NO;
}

- (BOOL)supportDash {
    if (self.fetchData) {
        return [super supportDash];
    } else if (self.preloadItem) {
        return [self.preloadItem.URL containsString:@".mpd"];
    }
    //
    return NO;
}

- (BOOL)isMainUrl {
    if (self.fetchData) {
        return [super isMainUrl];
    } else if (self.preloadItem) {
        return YES;
    }
    //
    return NO;
}

- (BOOL)isLocalFile {
    if (self.fetchData) {
        return [super isLocalFile];
    } else if (self.preloadItem) {
        return YES;
    }
    //
    return NO;
}

- (NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        return [super urlForResolution:resolution];
    } else if (self.preloadItem) {
        return self.preloadItem.URL;
    }
    //
    return nil;
}

- (NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    if (self.fetchData) {
        return [super allUrlsForResolution:resolution];
    } else if (self.preloadItem) {
        return self.preloadItem.URL ? @[self.preloadItem.URL] : nil;
    }
    //
    return nil;
}

- (BOOL)skipToNext {
    if (self.fetchData) {
        return [super skipToNext];
    } else if (self.preloadItem) {
        return NO;
    }
    //
    return NO;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (self.fetchData) {
        return [super retryStrategyForRetryCount:retryCount];
    } else if (self.preloadItem) {
        return TTVideoEngineRetryStrategyFetchInfo;
    }
    //
    return TTVideoEngineRetryStrategyNone;
}

- (BOOL)preloadDataIsExpire {
    if (self.preloadItem) {
        BOOL isExpire = ([[NSDate date] timeIntervalSince1970] - self.preloadItem.urlGenerateTime) > 40*60 &&
        self.preloadItem.urlGenerateTime > 0;
        return isExpire;
    }
    //
    return NO;
}

- (instancetype)deepCopy {
    TTVideoEnginePlayPreloadSource *preloadSource = [super deepCopy];
    if (self.preloadItem) {// assign valid data.
        preloadSource.preloadItem = self.preloadItem;
    }
    return preloadSource;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayPreloadSource *tem = (TTVideoEnginePlayPreloadSource *)object;
        result = [self.preloadItem isEqual:tem.preloadItem];
    }
    return result;
}

@end
