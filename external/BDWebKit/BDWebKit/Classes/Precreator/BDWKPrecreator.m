//
//  BDWKProvider.m
//  BDWebKit
//
//  Created by Nami on 2019/11/13.
//

#import "BDWKPrecreator.h"

@interface BDWKPrecreator () <WKNavigationDelegate>

@property (nonatomic, strong) NSMutableArray *arrOfInstances;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, assign) NSTimeInterval lastMemoryWarningTime;

@end

@implementation BDWKPrecreator

+ (instancetype)defaultPrecreator {
    static BDWKPrecreator *provider;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provider = [[BDWKPrecreator alloc] init];
    });
    return provider;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _arrOfInstances = [NSMutableArray arrayWithCapacity:3];
        _lock = [[NSRecursiveLock alloc] init];
        _memoryWarningProtectDuration = 60 * 5;
        _precreateWKDelaySeconds = 3;
        _isClearPrecreateWKWhenMemoryWarning = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    if (!self.isClearPrecreateWKWhenMemoryWarning) {
        return;
    }
    self.lastMemoryWarningTime = [NSDate date].timeIntervalSince1970;
    [self adjustmentWKIfNeed];
}

- (WKWebView *)generateWKWebView {
    WKWebViewConfiguration *configuration = self.webViewConfiguration;
    if (self.generateHandler) {
        return self.generateHandler(configuration);
    } else {
        if (!configuration) {
            configuration = [[WKWebViewConfiguration alloc] init];
        }
        return [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
}

- (BOOL)needAddInstance {
    return self.maxNumberOfInstances > 0 && [self.arrOfInstances count] < self.maxNumberOfInstances;
}

- (BOOL)needRemoveInstance {
    return self.maxNumberOfInstances >= 0 && [self.arrOfInstances count] > self.maxNumberOfInstances;
}

- (void)adjustmentWKIfNeed {
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (self.lastMemoryWarningTime + self.memoryWarningProtectDuration >= now) {
        if (self.lastMemoryWarningTime > now) {
            self.lastMemoryWarningTime = now;
        }
        [self.lock lock];
        [self.arrOfInstances removeAllObjects];
        [self.lock unlock];
        return;
    }
    self.lastMemoryWarningTime = 0;
    [self.lock lock];
    if ([self needAddInstance]) {
        NSTimeInterval seconds = self.precreateWKDelaySeconds;
        if (seconds > 0) {
            __weak __typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) self = weakSelf;
                [self produceWKWhenMainThreadIdle];
            });
        } else {
            [self produceWKWhenMainThreadIdle];
        }
    }
    if ([self needRemoveInstance]) {
        for (NSUInteger i = 0; i < [self.arrOfInstances count] - self.maxNumberOfInstances; i++) {
            [self.arrOfInstances removeLastObject];
        }
    }
    [self.lock unlock];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self.lock lock];
    if (webView) {
        [self.arrOfInstances removeObject:webView];
    }
    [self.lock unlock];
}

- (WKWebView *)takeWebView {
    return [self takeWebViewWithIsFromCache:NULL];
}

- (WKWebView *)takeWebViewWithIsFromCache:(BOOL *)isFromCache {
    WKWebView *wk;

    [self.lock lock];
    if ([self.arrOfInstances count] > 0) {
        wk = [self.arrOfInstances firstObject];
        [self.arrOfInstances removeObject:wk];
        wk.navigationDelegate = nil;
        [self.lock unlock];
        if (isFromCache) {
            *isFromCache = YES;
        }
    } else {
        [self.lock unlock];

        wk = [self generateWKWebView];
        if (isFromCache) {
            *isFromCache = NO;
        }
    }
    [self adjustmentWKIfNeed];

    return wk;
}

- (void)produceWKWhenMainThreadIdle {
    __weak __typeof(self) weakSelf = self;
    id handler = ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopBeforeWaiting: {
                // create normal wk
                __strong __typeof(weakSelf) self = weakSelf;
                for (NSUInteger i = [self.arrOfInstances count]; i < self.maxNumberOfInstances; i++) {
                    WKWebView *wk = [self generateWKWebView];
                    [self.lock lock];
                    [self.arrOfInstances addObject:wk];
                    [self.lock unlock];
                    wk.navigationDelegate = self;
                }

                CFRunLoopRemoveObserver([NSRunLoop mainRunLoop].getCFRunLoop, observer, kCFRunLoopDefaultMode);
                break;
        }
            default:
                break;
        }
    };
    CFRunLoopObserverRef obs = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, true, 0 /* order */, handler);
    CFRunLoopAddObserver([NSRunLoop mainRunLoop].getCFRunLoop, obs, kCFRunLoopDefaultMode);
    CFRelease(obs);
}

- (void)_clearManualPreCreateWK {
    [self.lock lock];
    [self.arrOfInstances removeAllObjects];
    [self.lock unlock];
}

- (void)setWebViewConfiguration:(WKWebViewConfiguration *)webViewConfiguration {
    _webViewConfiguration = webViewConfiguration;
    [self _clearManualPreCreateWK];
}

- (void)setGenerateHandler:(BDWKGenerateHandler)generateHandler {
    _generateHandler = generateHandler;
    [self _clearManualPreCreateWK];
}

- (void)setMaxNumberOfInstances:(NSInteger)maxNumberOfInstances {
    _maxNumberOfInstances = maxNumberOfInstances;
    [self adjustmentWKIfNeed];
}

- (NSUInteger)cachedCount {
    return self.arrOfInstances.count;
}

@end
