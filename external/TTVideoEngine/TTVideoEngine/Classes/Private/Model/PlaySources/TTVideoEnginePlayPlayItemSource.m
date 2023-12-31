//
//  TTVideoEnginePlayPlayItemSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayPlayItemSource.h"

@implementation TTVideoEnginePlayPlayItemSource

- (void)setPlayItem:(TTVideoEnginePlayItem *)playItem {
    _playItem = playItem;
    self.videoId = playItem.vid;
}

- (NSArray<NSNumber *> *)supportResolutions {
    if (self.fetchData) {
        return [super supportResolutions];
    } else if (self.playItem) {
        return @[@(self.playItem.resolution)];
    }
    //
    return nil;
}

- (TTVideoEngineResolutionType)currentResolution {
    if (self.fetchData) {
        return [super currentResolution];
    } else if (self.playItem) {
        return self.playItem.resolution;
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (TTVideoEngineResolutionType)autoResolution {
    if (self.fetchData) {
        return [super autoResolution];
    } else if (self.playItem) {
        return self.playItem.resolution;
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (NSString *)currentUrl {
    if (self.fetchData) {
        return [super currentUrl];
    } else if (self.playItem) {
        return self.playItem.playURL;
    }
    //
    return nil;
}

- (BOOL)supportSSL {
    if (self.fetchData) {
        return [super supportSSL];
    } else if (self.playItem) {
        return [self.playItem.playURL hasPrefix:@"https"];
    }
    //
    return NO;
}

- (BOOL)supportDash {
    if (self.fetchData) {
        return [super supportDash];
    } else if (self.playItem) {
        return [self.playItem.playURL containsString:@".mpd"];
    }
    //
    return NO;
}

- (BOOL)isMainUrl {
    if (self.fetchData) {
        return [super isMainUrl];
    } else if (self.playItem) {
        return YES;
    }
    //
    return NO;
}

- (NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        return [super urlForResolution:resolution];
    } else if (self.playItem) {
        return self.playItem.playURL;
    }
    //
    return nil;
}

- (NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    if (self.fetchData) {
        return [super allUrlsForResolution:resolution];
    } else if (self.playItem) {
        return self.playItem.playURL ? @[self.playItem.playURL] : nil;
    }
    //
    return nil;
}

- (BOOL)skipToNext {
    if (self.fetchData) {
        return [super skipToNext];
    } else if (self.playItem) {
        return NO;
    }
    //
    return NO;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (self.fetchData) {
        return [super retryStrategyForRetryCount:retryCount];
    } else if (self.playItem) {
        return TTVideoEngineRetryStrategyFetchInfo;
    }
    //
    return TTVideoEngineRetryStrategyNone;
}

- (BOOL)preloadDataIsExpire {
    return NO;
}

- (instancetype)deepCopy {
    TTVideoEnginePlayPlayItemSource *playItemSource = [super deepCopy];
    if (self.playItem) {// assign valid data.
        playItemSource.playItem = self.playItem;
    }
    return playItemSource;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayPlayItemSource *tem = (TTVideoEnginePlayPlayItemSource *)object;
        result = [self.playItem isEqual:tem.playItem];
    }
    return result;
}

@end
