//
//  BDWebViewUIManager.m
//  Aweme
//
//  Created by wuxi on 2023/5/31.
//

#import "BDWebViewUAManager.h"
#import <WebKit/WebKit.h>
#import "BDWebKitSettingsManger.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

#define BDSAFE_BLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

@implementation BDWebViewUAManager

static NSString *const _systemUserAgentKey = @"BDWWebKit.systemUserAgentKey";
static NSString *const _applicationNameForUserAgentKey = @"BDWWebKit.applicationNameForUserAgentKey";
static NSString *_systemUserAgent = nil;
static NSString *_applicationNameForUserAgent = nil;
static NSString *_cachedSystemUserAgent = nil;
static NSString *_cachedApplicationNameForUserAgent = nil;
static BOOL _uaFetching = NO;
static NSArray *_fetchCallbacks = nil;

+ (BOOL)enableUAFetch
{
    return [BDWebKitSettingsManger bdEnableUAFetch];
}

+ (BDWebViewUAFetchTime)uaFetchTime
{
    return [BDWebKitSettingsManger bdUAFetchTime];
}

+ (BOOL)bdEnableUAFetchWithKV {
    return [BDWebKitSettingsManger bdEnableUAFetchWithKV];
}

+ (void)fetchSystemUserAgentWithCompletion:(void (^)(NSString * _Nullable, NSString * _Nullable, NSError * _Nullable))completion
{
    if (![self enableUAFetch]) {
        BDSAFE_BLOCK_INVOKE(completion, nil, nil, [NSError errorWithDomain:@"BDWebKit.fetchUAError" code:103 userInfo:@{NSLocalizedDescriptionKey: @"not enable, check the AB switch"}]);
        return;
    }
    NSString *cacheUA = [self fetchSystemUserAgentFromeCache];
    if (!BTD_isEmptyString(cacheUA) && !BTD_isEmptyString(_applicationNameForUserAgent)) {
        BDSAFE_BLOCK_INVOKE(completion, cacheUA, _applicationNameForUserAgent, nil);
        return;
    }
    [self fetchLastestSystemUserAgentWithCompletion:completion];
}

+ (void)fetchLastestSystemUserAgentWithCompletion:(void (^)(NSString * _Nullable, NSString * _Nullable, NSError * _Nullable))completion
{
    if (![self enableUAFetch]) {
        BDSAFE_BLOCK_INVOKE(completion, nil, nil, [NSError errorWithDomain:@"BDWebKit.fetchUAError" code:103 userInfo:@{NSLocalizedDescriptionKey: @"not enable, check the AB switch"}]);
        return;
    }
    btd_dispatch_async_on_main_queue(^{
        if (!completion) {
            return;
        }
        if (!BTD_isEmptyString(_systemUserAgent) && !BTD_isEmptyString(_applicationNameForUserAgent)) {
            BDSAFE_BLOCK_INVOKE(completion, _systemUserAgent, _applicationNameForUserAgent, nil);
            return;
        }
        
        dispatch_block_t task = ^{
            if (_uaFetching) {
                // 暂存 callback
                NSMutableArray *callbacks = [(_fetchCallbacks ?: @[]) mutableCopy];
                [callbacks addObject:completion];
                _fetchCallbacks = [callbacks copy];
                return;
            }
            
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            static WKWebView *webView; // 回调到来前必须持有该 WKWebView
            _uaFetching = YES;
            webView = [[WKWebView alloc] init];
            
            if ([self bdEnableUAFetchWithKV]) {
                NSString *_ua = [webView valueForKey:@"userAgent"];
                NSString *_appName = webView.configuration.applicationNameForUserAgent;
                if (!BTD_isEmptyString(_ua) && !BTD_isEmptyString(_appName)) {
                    _systemUserAgent = _ua;
                    _applicationNameForUserAgent = _appName;
                    BDSAFE_BLOCK_INVOKE(completion, _systemUserAgent, _applicationNameForUserAgent, nil);
                    [[NSUserDefaults standardUserDefaults] setObject:_systemUserAgent forKey:_systemUserAgentKey];
                    [[NSUserDefaults standardUserDefaults] setObject:_applicationNameForUserAgent forKey:_applicationNameForUserAgentKey];
                    webView = nil;
                    _uaFetching = NO;
                    [self consumeCallbacks];
                    CFAbsoluteTime start1 = CFAbsoluteTimeGetCurrent();
                    BDALOG_PROTOCOL_DEBUG(@"bdua:: fetch ua from WK1 [%.1fms, %@, %@]", 1000*(start1 - start), _ua, _appName);
                    return;
                }
            }
            
            [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *_Nullable error) {
                if (error) {
                    BDSAFE_BLOCK_INVOKE(completion, nil, nil, error);
                    webView = nil;
                    _uaFetching = NO;
                    [self consumeCallbacks];
                    return;
                }
                if (![result isKindOfClass:[NSString class]]) {
                    BDSAFE_BLOCK_INVOKE(completion, nil, nil, [NSError errorWithDomain:@"BDWebKit.fetchUAError" code:100 userInfo:@{NSLocalizedDescriptionKey: @"UA type wrong"}]);
                    webView = nil;
                    _uaFetching = NO;
                    [self consumeCallbacks];
                    return;
                }
                NSString *resultStr = (NSString *)result;
                if (BTD_isEmptyString(resultStr)) {
                    BDSAFE_BLOCK_INVOKE(completion, nil, nil, [NSError errorWithDomain:@"BDWebKit.fetchUAError" code:101 userInfo:@{NSLocalizedDescriptionKey: @"UA is empty"}]);
                    webView = nil;
                    _uaFetching = NO;
                    [self consumeCallbacks];
                    return;
                }
                _systemUserAgent = resultStr;
                _applicationNameForUserAgent = webView.configuration.applicationNameForUserAgent ?: @"";
                BDSAFE_BLOCK_INVOKE(completion, resultStr, _applicationNameForUserAgent, nil);
                [[NSUserDefaults standardUserDefaults] setObject:_systemUserAgent forKey:_systemUserAgentKey];
                [[NSUserDefaults standardUserDefaults] setObject:_applicationNameForUserAgent forKey:_applicationNameForUserAgentKey];
                webView = nil;
                _uaFetching = NO;
                [self consumeCallbacks];
                CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
                BDALOG_PROTOCOL_DEBUG(@"bdua:: fetch ua from WK2 [%.1fms, %@, %@]", 1000*(end - start), resultStr, _applicationNameForUserAgent);
            }];
        };
        
        switch ([self uaFetchTime]) {
            case BDWebViewUAFetchTimeMainAsync:
                task();
                break;
            case BDWebViewUAFetchTimeMainIdle:
                [self executeWhenIdleWithTask:task];
                break;
        }
        
    });
}

+ (NSString *)fetchSystemUserAgentFromeCache
{
    if (!BTD_isEmptyString(_systemUserAgent) && !BTD_isEmptyString(_applicationNameForUserAgent)) {
        _cachedSystemUserAgent = _systemUserAgent;
        _cachedApplicationNameForUserAgent = _applicationNameForUserAgent;
        return _systemUserAgent;
    }
    if (!BTD_isEmptyString(_cachedSystemUserAgent) && !BTD_isEmptyString(_cachedApplicationNameForUserAgent)) {
        return _cachedSystemUserAgent;
    }
    _cachedSystemUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:_systemUserAgentKey];
    _cachedApplicationNameForUserAgent = [[NSUserDefaults standardUserDefaults] objectForKey:_applicationNameForUserAgentKey];
    return _cachedSystemUserAgent;
}

+ (void)consumeCallbacks
{
    NSMutableArray *callbacks = [(_fetchCallbacks ?: @[]) mutableCopy];
    while([callbacks count] > 0) {
        void (^callback)(NSString * _Nullable, NSString * _Nullable, NSError * _Nullable) = [callbacks lastObject];
        if (!BTD_isEmptyString(_systemUserAgent)) {
            BDSAFE_BLOCK_INVOKE(callback, _systemUserAgent, _applicationNameForUserAgent, nil);
        } else {
            BDSAFE_BLOCK_INVOKE(callback, nil, nil, [NSError errorWithDomain:@"BDWebKit.fetchUAError" code:102 userInfo:@{NSLocalizedDescriptionKey: @"UA is empty"}]);
        }
        [callbacks removeLastObject];
    }
    _fetchCallbacks = nil;
}

/// Runloop 空闲时执行任务
+ (void)executeWhenIdleWithTask:(dispatch_block_t)task {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        // 处理空闲时的任务
        BDALOG_PROTOCOL_DEBUG(@"bdua:: Runloop 闲时...")
        task ? task() : nil;
        CFRunLoopRemoveObserver(runLoop, observer, kCFRunLoopDefaultMode);
        CFRelease(observer);
    });
    
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
}

@end
