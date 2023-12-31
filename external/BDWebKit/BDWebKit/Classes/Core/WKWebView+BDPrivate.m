//
//  WKWebView+BDPrivate.m
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#import "WKWebView+BDPrivate.h"
#import "NSObject+BDWRuntime.h"
#import <pthread.h>
#import "BDWebKitSettingsManger.h"
#import "BDWebKitMainFrameModel.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <objc/runtime.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Heimdallr/HMDInjectedInfo.h>

#define BASE64(STR) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:STR options:0] encoding:NSUTF8StringEncoding]

@interface BDWebProtocolArray : NSObject
{
    pthread_mutex_t _mutex;
}

@property (nonatomic, strong, readwrite) NSMutableArray *innerArray;

- (void)addObject:(id)o;

- (void)removeObject:(id)o;

- (NSArray *)copyAsNSArray;

- (NSUInteger)indexOfObject:(id)o;

- (BOOL)containsObject:(id)o;

@end


@implementation WKWebView (BDPrivate)

static BDWebKitURLProtocolInterceptionStatus kBDWURLProtocolHTTPInterception = BDWebKitURLProtocolInterceptionStatusNone;

+ (void)bdw_updateURLProtocolInterceptionStatus:(BDWebKitURLProtocolInterceptionStatus)status {
    kBDWURLProtocolHTTPInterception = status;
}

- (void)setBdw_schemeHandlerInterceptionStatus:(BDWebKitSchemeHandlerInterceptionStatus)bdw_schemeHandlerInterceptionStatus {
    [self bdw_attachObject:@(bdw_schemeHandlerInterceptionStatus) forKey:@"BDW_SchemeHandlerInterceptionStatus"];
}

- (BDWebKitSchemeHandlerInterceptionStatus)bdw_schemeHandlerInterceptionStatus {
    return [[self bdw_getAttachedObjectForKey:@"BDW_SchemeHandlerInterceptionStatus"] unsignedIntegerValue];
}

- (BOOL)bdw_hasInterceptMainFrameRequest {
    // check urlprotocol status
    if (BDWebKitURLProtocolInterceptionStatusHTTP == kBDWURLProtocolHTTPInterception) {
        return YES;
    }
    
    // check schemehandler status for WebView
    if ([self bdw_schemeHandlerInterceptionStatus] == BDWebKitSchemeHandlerInterceptionStatusHTTP) {
        return YES;
    }
    
    return NO;
}

- (BDWebProtocolArray *)bdw_arrProtocol {
    if ([self bdw_getAttachedObjectForKey:@"arrProtocol"] == nil) {
        [self bdw_attachObject:[[BDWebProtocolArray alloc] init] forKey:@"arrProtocol"];
    }
    
    return  [self bdw_getAttachedObjectForKey:@"arrProtocol"];
}

- (NSArray *)bdw_urlProtocols {
    return [self.bdw_arrProtocol copyAsNSArray];
}


- (void)bdw_registerURLProtocolClass:(Class)protocol {
    if (![protocol isSubclassOfClass:NSURLProtocol.class] ) {
        return;
    }
    [self.bdw_arrProtocol addObject:protocol];
}

- (void)bdw_unregisterURLProtocolClass:(Class)protocol {
    [self.bdw_arrProtocol removeObject:protocol];
}

- (nullable WKNavigation *)bdw_loadRequest:(NSURLRequest *)request {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    // 兼容 IESWebViewMonitor 内部逻辑，避免 Crash
    SEL selector = @selector(setLastCallClass:);
    if ([self respondsToSelector:selector]) {
        [self btd_performSelectorWithArgs:selector, nil];
    }
#pragma clang diagnostic pop

    if ([BDWebKitSettingsManger bdReportLastWebURL]) {
        NSURL *url = request.URL;
        NSString *urlString = url.absoluteString;
        if (!BTD_isEmptyString(urlString) && ![urlString isEqualToString:@"about:blank"] && ![urlString hasPrefix:@"about://waitfix"]) {
            NSString *formatURL = [NSString stringWithFormat:@"%@://%@%@",
                                   url.scheme ?: @"",
                                   url.host ?: @"",
                                   url.path ?: @""];
            
            [[HMDInjectedInfo defaultInfo] setCustomContextValue:formatURL forKey:@"last_web_url"];
            [[HMDInjectedInfo defaultInfo] setCustomFilterValue:formatURL forKey:@"last_web_url"];
        }
    }
    
    return [self loadRequest:request];
}

- (BDWebViewOfflineType)bdw_offlineType {
    return [[self bdw_getAttachedObjectForKey:@"BDW_OfflineType"] unsignedIntegerValue];
}

- (void)setBdw_offlineType:(BDWebViewOfflineType)bdw_offlineType {
    [self bdw_attachObject:@(bdw_offlineType) forKey:@"BDW_OfflineType"];
}

- (BDWebKitMainFrameModel *)bdw_mainFrameModelRecord {
    if ([self bdw_getAttachedObjectForKey:@"BDW_MainFrameModelRecord"] == nil) {
        [self bdw_attachObject:[[BDWebKitMainFrameModel alloc] init] forKey:@"BDW_MainFrameModelRecord"];
    }
    
    return  [self bdw_getAttachedObjectForKey:@"BDW_MainFrameModelRecord"];
}

- (void)setBdw_mainFrameModelRecord:(BDWebKitMainFrameModel *)bdw_mainFrameModelRecord {
    if (bdw_mainFrameModelRecord != nil) {
        [self bdw_attachObject:bdw_mainFrameModelRecord forKey:@"BDW_MainFrameModelRecord"];
    }
}

#pragma mark - fix webpage invalid crash
static BOOL bd_fixWKWebViewCrashSetting = NO;
static NSString *bd_isValidString = nil;
void doInitFixWKCrashSetting (void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bd_fixWKWebViewCrashSetting = [BDWebKitSettingsManger bdFixWKWebViewSchemeTaskCrash];
        bd_isValidString = @"_isValid";
    });
}
typedef BOOL (*GetFuc)(id, SEL);
- (BOOL)bd_isPageValid {
    if (!bd_isValidString) {
        doInitFixWKCrashSetting();
    }
    if (!bd_fixWKWebViewCrashSetting) {
        return YES;
    }
    if (!self || ![self isKindOfClass:[WKWebView class]]) {
        return NO;
    }
    BOOL bRet = YES;
    //_isValid
    SEL selectorGet = NSSelectorFromString(bd_isValidString);
    if ([self respondsToSelector:selectorGet]) {
        IMP impGet = [self methodForSelector:selectorGet];
        GetFuc funcGet = (GetFuc)impGet;
        BOOL val = funcGet(self, selectorGet);
        bRet = (val == YES);
    }
    return bRet;
}


- (UIView*)bd_contentView {
    UIView* contentView = [self bdw_getAttachedObjectForKey:@"aWKContentView"];
    if(!contentView) {
        for (UIView* view in self.scrollView.subviews) {
            if([NSStringFromClass(view.class) isEqualToString:@"WKContentView"]) {
                contentView = view;
                [self bdw_attachObject:contentView forKey:@"aWKContentView"];
                break;
            }
        }
    }
    
    return contentView;
}

@end

@implementation BDWebProtocolArray

- (void)dealloc
{
    pthread_mutex_destroy(&_mutex);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_mutex, 0);
        _innerArray = [NSMutableArray arrayWithCapacity:3];
    }
    return self;
}

- (void)addObject:(id)o {
    pthread_mutex_lock(&_mutex);
    if (![_innerArray containsObject:o]) {
        [_innerArray addObject:o];
    }
    pthread_mutex_unlock(&_mutex);
}

- (void)removeObject:(id)o {
    pthread_mutex_lock(&_mutex);
    [_innerArray removeObject:o];
    pthread_mutex_unlock(&_mutex);
}

- (NSArray *)copyAsNSArray {
    pthread_mutex_lock(&_mutex);
    id arr = [_innerArray copy];
    pthread_mutex_unlock(&_mutex);
    return arr;
}

- (NSUInteger)indexOfObject:(id)o {
    pthread_mutex_lock(&_mutex);
    NSUInteger idx = [_innerArray indexOfObject:o];
    pthread_mutex_unlock(&_mutex);
    return idx;
}

- (BOOL)containsObject:(id)o {
    pthread_mutex_lock(&_mutex);
    BOOL isContain = [_innerArray containsObject:o];
    pthread_mutex_unlock(&_mutex);
    return isContain;
}

@end

@implementation NSURLRequest (WebKitSupport)

- (void)setUseURLProtocolOnlyLocal:(BOOL)useURLProtocolOnlyLocal {
    objc_setAssociatedObject(self, @selector(useURLProtocolOnlyLocal), @(useURLProtocolOnlyLocal), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)useURLProtocolOnlyLocal
{
    NSNumber* useURLProtocolOnlyLocal = objc_getAssociatedObject(self, _cmd);
    return [useURLProtocolOnlyLocal boolValue];
}

@end
