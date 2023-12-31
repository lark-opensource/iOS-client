//
//  TTVideoEnginePlayUrlsSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayUrlsSource.h"

@interface TTVideoEnginePlayUrlsSource ()

@property (nonatomic, assign) NSInteger urlIndex;

@end

@implementation TTVideoEnginePlayUrlsSource

- (instancetype)init {
    if (self = [super init]) {
        _urlIndex = 0;
    }
    return self;
}

- (NSString *)currentUrl {
    if (self.urls && self.urlIndex >= 0 && self.urlIndex < self.urls.count) {
        return self.urls[self.urlIndex];
    }
    //
    return nil;
}

- (BOOL)isMainUrl {
    return (self.urlIndex == 0) && self.currentUrl;
}

- (BOOL)isSingleUrl {
    return self.urls && (self.urls.count == 1);
}

- (NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    return self.currentUrl;
}

- (NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    return self.urls;
}

- (BOOL)skipToNext {
    if ([self _canSkipToNext]) {
        self.urlIndex = self.urlIndex + 1;
        return YES;
    }
    //
    return NO;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if ([self _canSkipToNext]) {
        return TTVideoEngineRetryStrategyChangeURL;
    }
    return TTVideoEngineRetryStrategyRestartPlayer;
}

- (BOOL)preloadDataIsExpire {
    return NO;
}

- (BOOL)_canSkipToNext {
    if (self.urls && self.urlIndex >= 0 && self.urlIndex < self.urls.count) {
        NSInteger temIndex = self.urlIndex;
        temIndex++;
        return (temIndex < self.urls.count);
    }
    //
    return NO;
}

- (instancetype)deepCopy {
    TTVideoEnginePlayUrlsSource *urlsSource = [super deepCopy];
    if (self.urls) {// assign valid data.
        urlsSource.urls = self.urls.copy;
        urlsSource.urlIndex = self.urlIndex;
    }
    
    return urlsSource;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayUrlsSource *tem = (TTVideoEnginePlayUrlsSource *)object;
        if (!self.urls || !tem.urls || self.urls.count != tem.urls.count) {
            result = NO;
        } else {
            result = YES;
            for (NSInteger i = 0; i < tem.urls.count; i++) {
                NSString *temS1 = self.urls[i];
                NSString *temS2 = tem.urls[i];
                if (![temS1 isEqualToString:temS2]) {
                    result = NO;
                    break;
                }
            }
        }
    }
    return result;
}
@end
