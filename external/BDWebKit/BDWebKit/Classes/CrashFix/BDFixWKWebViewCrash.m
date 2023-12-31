//
//  BDFixWKWebViewCrash.m
//  ByteWebView
//
//  Created by 杨牧白 on 2019/8/26.
//

#import "BDFixWKWebViewCrash.h"
#import <BDWebKit/WKWebView+BDPrivate.h>
#import <BDWebKit/NSObject+BDWRuntime.h>
#import <BDWebKit/BDWebKitSettingsManger.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDWebCore/IWKUtils.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <WebKit/WebKit.h>
#import <malloc/malloc.h>

#define BASE64(STR) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:STR options:0] encoding:NSUTF8StringEncoding]

struct LegacyCustomProtocolManagerProxy {
    void *reserved;
    void *m_networkProcessProxy;
};

@implementation WKWebView (BDFixWKCrash)

#pragma mark - fix ProcessTerminate crash

static NSString *bd_killAndResetWebProcessString = nil;
static NSString *bd_didRelaunchProcessString = nil;
static NSString *bd_registerUIProcessString = nil;
- (void)bd_fixReLaunchWebContentProcess {
    
    if ([BDWebKitSettingsManger bdFixProcessTerminateCrash] && ![self bd_isPageValid]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        if ([BDWebKitSettingsManger bdFixProcessTerminateCrash] & 0x01) {
            //_killWebContentProcessAndResetState
            if (!bd_killAndResetWebProcessString) {
                bd_killAndResetWebProcessString = @"_killWebContentProcessAndResetState";
            }
            SEL selectorGet = NSSelectorFromString(bd_killAndResetWebProcessString);
            if ([self respondsToSelector:selectorGet]) {
                [self performSelector:selectorGet];
                [BDTrackerProtocol eventV3:@"wkwebview_page_is_unvalid" params:@{@"exception":@"ResetProcessState"}];
            }
        }
        
        if ([BDWebKitSettingsManger bdFixProcessTerminateCrash] & 0x02) { // iOS 11上这个方法被干掉了，用下面的方法替代
            //_didRelaunchProcess
            if (!bd_didRelaunchProcessString) {
                bd_didRelaunchProcessString = @"_didRelaunchProcess";
            }
            SEL selectorGet = NSSelectorFromString(bd_didRelaunchProcessString);
            if ([self respondsToSelector:selectorGet]) {
                [self performSelector:selectorGet];
                [BDTrackerProtocol eventV3:@"wkwebview_page_is_unvalid" params:@{@"exception":@"RelaunchProcess"}];
            }
        }
        
        if ([BDWebKitSettingsManger bdFixProcessTerminateCrash] & 0x04) { // 在iOS 11上用来替代RelaunchProcess
            if (!bd_registerUIProcessString) {
                bd_registerUIProcessString = @"_accessibilityRegisterUIProcessTokens";
            }
            // _accessibilityRegisterUIProcessTokens
            id wkContent = [self bd_contentView];
            SEL selectorGet = NSSelectorFromString(bd_registerUIProcessString);
            if ([wkContent respondsToSelector:selectorGet]) {
                [wkContent performSelector:selectorGet];
                [BDTrackerProtocol eventV3:@"wkwebview_page_is_unvalid" params:@{@"exception":@"registerUIProcess"}];
            }
        }
#pragma clang diagnostic pop
    }
}

+ (void)tryFixAddupdateCrash {
    if ([BDWebKitSettingsManger bdFixAddUpdateCrash]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            SEL orig = NSSelectorFromString(@"_addUpdateVisibleContentRectPreCommitHandler");
            IWKClassSwizzle(self, orig, @selector(bdfix_addUpdateVisibleContentRectPreCommitHandler));
        });
    }
}

- (void)bdfix_addUpdateVisibleContentRectPreCommitHandler {
    BOOL (*allowsWeakReference)(id, SEL) =
        (BOOL(*)(id, SEL))
        class_getMethodImplementation([self class],
                                       @selector(allowsWeakReference));
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating =
            ! (*allowsWeakReference)(self, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            [BDTrackerProtocol eventV3:@"wkwebview_WKReloadFrameErrorRecoveryAttempter_crash" params:@{@"exception":@"fix addUpdateVisibleContentRectPreCommitHandler crash"}]; //  暂时用同一个，不用额外申请
            return;
        }
    }
    
    [self bdfix_addUpdateVisibleContentRectPreCommitHandler];
}

@end

@implementation NSObject (BDFixWKCrash)
+ (void)tryFixOfflineCrash {
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue >= 11 && version.doubleValue < 13) {
        if ([BDWebKitSettingsManger bdWKWebViewFixEnable]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                Class instanceClass = NSClassFromString(@"WKCustomProtocolLoader");
                IWKClassSwizzle(instanceClass, @selector(connection:didFailWithError:), @selector(fix_connection:didFailWithError:));
                IWKClassSwizzle(instanceClass, @selector(connection:didReceiveData:), @selector(fix_connection:didReceiveData:));
                IWKClassSwizzle(instanceClass, @selector(connection:didReceiveResponse:), @selector(fix_connection:didReceiveResponse:));
                IWKClassSwizzle(instanceClass, @selector(connectionDidFinishLoading:), @selector(fix_connectionDidFinishLoading:));
            });
        }
    }
    
}

+ (void)tryFixWKReloadFrameErrorRecoveryAttempter {
    if ([BDWebKitSettingsManger bdFixWKReloadFrameErrorRecoveryAttempter]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class instanceClass = NSClassFromString(@"WKReloadFrameErrorRecoveryAttempter");
            SEL orig = NSSelectorFromString(@"initWithWebView:frameHandle:urlString:");
            IWKClassSwizzle(instanceClass, orig, @selector(fix_initAttempter:frameHandle:urlString:));
        });
    }
}

- (void)fix_connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([BDWebKitSettingsManger bdWKWebViewFixEnable] && [self shouldFix]) {
        [BDTrackerProtocol eventV3:@"try_fix_protocol_crash" params:nil];
        return;
    }
    [self fix_connection:connection didFailWithError:error];
}

- (void)fix_connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([BDWebKitSettingsManger bdWKWebViewFixEnable] && [self shouldFix]) {
        [BDTrackerProtocol eventV3:@"try_fix_protocol_crash" params:nil];
        return;
    }
    [self fix_connection:connection didReceiveData:data];
}

- (void)fix_connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([BDWebKitSettingsManger bdWKWebViewFixEnable] && [self shouldFix]) {
        [BDTrackerProtocol eventV3:@"try_fix_protocol_crash" params:nil];
        return;
    }
    
    [self fix_connection:connection didReceiveResponse:response];
}

- (void)fix_connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([BDWebKitSettingsManger bdWKWebViewFixEnable] && [self shouldFix]) {
        [BDTrackerProtocol eventV3:@"try_fix_protocol_crash" params:nil];
        return;
    }
    
    [self fix_connectionDidFinishLoading:connection];
}

- (BOOL)shouldFix {
    unsigned int count;
    Ivar *ivars= class_copyIvarList(self.class, &count);
    Ivar targetIvar = NULL;
    
    for (int i = 0; i < count; i++) {
        const char *name = ivar_getName(ivars[i]);
        if (name!=NULL && strcmp(name, "_customProtocolManagerProxy") == 0) {
            targetIvar = ivars[i];
            break;
        }
    }
    
    // 找不到对应的Ivar 不使用fix
    if (targetIvar == NULL) {
        free(ivars);
        return NO;
    }
    // managerProxy为空则fix
    struct LegacyCustomProtocolManagerProxy *legacyCustomProtocolManagerProxy = (__bridge void *)object_getIvar(self, targetIvar);
    // 无需使用ivars,则free掉
    free(ivars);
    
    if (legacyCustomProtocolManagerProxy == NULL) {
        return YES;
    }
    
#if __LP64__
    // m_networkProcessProxy(ivar + sizeof(ptr))为空则fix
    if (legacyCustomProtocolManagerProxy -> m_networkProcessProxy == NULL) {
        return YES;
    }
    
    if ([BDWebKitSettingsManger bdValidPointerCheckEnable]) {
        // The largest realistic memory address varies by platform.
        // Only 48 bits are used by 64 bit machines while
        // 32 bit machines use all bits.
        static uintptr_t MAX_REALISTIC_ADDRESS = 0x0000FFFFFFFFFFFF;
        uintptr_t pointerValue = (uintptr_t)(legacyCustomProtocolManagerProxy -> m_networkProcessProxy);
        if(pointerValue > MAX_REALISTIC_ADDRESS) {
            return YES;
        }
        
        if (@available(iOS 12.2, *)) {
            if (@available(iOS 13, *)) {
                
            } else {
                if ([BDWebKitSettingsManger bdValidObjectCheckEnable] ) {
                    size_t objectSize = malloc_size(legacyCustomProtocolManagerProxy -> m_networkProcessProxy);
                    // test it in 12.2, 12.3.1, 12.4, the objectSize shouldbe 592
                    // 12.1.2 以下为 0，13.0以上为  0
                    BOOL validPointer = objectSize > 500;
                    if (!validPointer) {
                        return YES;
                    }
                }
            }
        }
    }
#endif
    
    // 默认不fix
    return NO;
}

- (id)fix_initAttempter:(WKWebView *)webView frameHandle:(void *)frameHandle urlString:(void*)urlString {
    BOOL (*allowsWeakReference)(id, SEL) =
    (BOOL(*)(id, SEL))
    class_getMethodImplementation([webView class],
                                  @selector(allowsWeakReference));
    __unsafe_unretained WKWebView *tmpWebView = webView;
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating =
        ! (*allowsWeakReference)(webView, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            tmpWebView = nil;
            [BDTrackerProtocol eventV3:@"wkwebview_WKReloadFrameErrorRecoveryAttempter_crash" params:@{@"exception":@"fix WKReloadFrameErrorRecoveryAttempter crash"}];
        }
    }
    return [self fix_initAttempter:tmpWebView frameHandle:frameHandle urlString:urlString];
}

@end


@implementation NSObject (BDFixWKBackGroundHang)

+ (void)tryFixBackGroundHang {
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue >= 10 && version.doubleValue < 13) {
        if ([BDWebKitSettingsManger bdFixWebViewBackGroundTaskHangEnable]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                Class instanceClass = NSClassFromString(@"WKProcessAssertionBackgroundTaskManager");
                //_updateBackgroundTask
                SEL updateBT = NSSelectorFromString(@"_updateBackgroundTask");
                //_notifyClientsOfImminentSuspension
                SEL notifyBT = NSSelectorFromString(@"_notifyClientsOfImminentSuspension");
                IWKClassSwizzle(instanceClass, @selector(init), @selector(initFix));
                IWKClassSwizzle(instanceClass, updateBT, @selector(_fixUpdateBackgroundTask));
                IWKClassSwizzle(instanceClass, notifyBT, @selector(_fixNotifyClientsOfImminentSuspension));
            });
        }
    }
    
}

static BOOL _applicationIsEnterForeground = NO;
- (instancetype)initFix {
    id obj = [self initFix];
    if (obj) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    }
    return obj;
}

- (void)handleEnterForegroundNotification:(NSNotification*)notification {
    _applicationIsEnterForeground = YES;
    CGFloat timeout = [BDWebKitSettingsManger bdFixWebViewBackGroundTaskTimeout];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _applicationIsEnterForeground = NO;
    });
    if ([self respondsToSelector:@selector(_fixUpdateBackgroundTask)]) {
        // We've received the invalidation warning after the app has become foreground again. In this case, we should not
        // warn clients of imminent suspension. To be safe (avoid potential killing), we end the task right away and call
        // _updateBackgroundTask asynchronously to start a new task if necessary.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _fixUpdateBackgroundTask];
        });
    }
}

- (void)handleDidEnterBackgroundNotification:(NSNotification*)notification {
    _applicationIsEnterForeground = NO;
}

- (void)_fixUpdateBackgroundTask {
    if (_applicationIsEnterForeground) {
        return ;
    }
    
    Class managerClz = NSClassFromString(@"WKProcessAssertionBackgroundTaskManager");
    Ivar targetIvar = class_getInstanceVariable(managerClz, "_backgroundTask");
    if (targetIvar) {
        typedef UIBackgroundTaskIdentifier (*GetNSUIntegerFunction)(id _Nullable obj, Ivar _Nonnull ivar);
        GetNSUIntegerFunction func = (GetNSUIntegerFunction)object_getIvar;
        UIBackgroundTaskIdentifier backgroundTask = func(self, targetIvar);
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            // Ignored request to start a new background task because the application is already in the background
            if (backgroundTask == UIBackgroundTaskInvalid) {
                return ;
            }
            if ([BDWebKitSettingsManger bdFixWebViewBackGroundTaskAfterReleaseEnable]) {
                // This gives some time to our child processes to process the ProcessWillSuspendImminently IPC but makes sure we release
                // the background task before the UIKit timeout (We get killed if we do not release the background task within 5 seconds
                // on the expiration handler getting called).
                if (backgroundTask != UIBackgroundTaskInvalid) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication endBackgroundTask:backgroundTask];
                        object_setIvar(self, targetIvar, NULL);
                    });
                }
            }
        }
    }
    
    [self _fixUpdateBackgroundTask];
}


- (void)_fixNotifyClientsOfImminentSuspension {
    if ([BDWebKitSettingsManger bdFixWebViewBackGroundNotifyHangEnable] && _applicationIsEnterForeground) {
        [BDTrackerProtocol eventV3:@"wkwebview_background_task_hang" params:@{@"exception":@"fix NotifyClientsOfImminentSuspension enterForeground"}];
        return;
    }
    if (@available(iOS 12, *)) {
        //iOS 12以上[[UIApplication sharedApplication] backgroundTimeRemaining] 是个很大的数
        if ([BDWebKitSettingsManger bdFixWebViewBackGroundNotifyTimeOutEnable] &&
            [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [BDTrackerProtocol eventV3:@"wkwebview_background_task_hang" params:@{@"exception":@"fix NotifyClientsOfImminentSuspension timeout"}];
            return;
        }
    } else {
        if ([BDWebKitSettingsManger bdFixWebViewBackGroundNotifyTimeOutEnable] &&
            [UIApplication sharedApplication].applicationState == UIApplicationStateBackground &&
            [[UIApplication sharedApplication] backgroundTimeRemaining] <= 1) {
            [BDTrackerProtocol eventV3:@"wkwebview_background_task_hang" params:@{@"exception":@"fix NotifyClientsOfImminentSuspension timeout"}];
            return;
        }
    }
    [self _fixNotifyClientsOfImminentSuspension];
}

@end

@implementation WKWebView (BDFixWKGetURLCrash)

#pragma mark - fix get URL crash
+ (void)tryFixGetURLCrash {
    if ([BDWebKitSettingsManger bdFixRequestURLCrashEnable]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            IWKClassSwizzle(self, @selector(initWithFrame:configuration:), @selector(fix_initWithFrame:configuration:));
            IWKClassSwizzle(self, NSSelectorFromString(@"URL"), NSSelectorFromString(@"fix_URL"));
        });
    }
}

- (instancetype)fix_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    id obj = [self fix_initWithFrame:frame configuration:configuration];
    if (obj) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(1);
        [obj bdw_attachObject:sema forKey:@"WK_URL_LOCK"];
    }
    return obj;
}


- (NSURL *)fix_URL {
    NSURL *wkURL = nil;
    dispatch_semaphore_t sema = [self bdw_getAttachedObjectForKey:@"WK_URL_LOCK"];
    if (sema) {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        wkURL = [self fix_URL];
        dispatch_semaphore_signal(sema);
    }
    return wkURL?:[self fix_URL];
}

@end

@implementation BDFixWKWebViewCrash

+ (void)tryFixBlobCrash {
    // https://slardar.bytedance.net/node/app_detail/?aid=13&os=iOS&region=cn&lang=zh-Hans#/abnormal/detail/crash/13_2a33fb501f881033a0be438bf3e16061
    // https://stackoverflow.com/questions/60198551/ios-wkwebview-wkurlschemehandler-crash-on-posting-body-exc-bad-access
    
    if (![BDWebKitSettingsManger bdFixBlobCrashEnable]) {
        return ;
    }
    // WebView
    id webView = NSClassFromString(@"WebView");
    // _setLoadResourcesSerially:
    SEL sel = NSSelectorFromString(@"_setLoadResourcesSerially:");
    if ([webView respondsToSelector:sel]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(webView, sel, NO);
    }
}

@end

@implementation WKScriptMessage (BDFixWKCrash)

+ (void)tryFixWKScriptMessageCrash {
    if ([BDWebKitSettingsManger bdFixWKScriptMessageCrash]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //iOS 14 以上增加了world字段
            if (@available(iOS 14, *)) {
                SEL orig = NSSelectorFromString(@"_initWithBody:webView:frameInfo:name:world:");
                
                IWKClassSwizzle(self, orig, @selector(fix_scriptMessageBody:webView:frameInfo:name:world:));
            }
            else {
                SEL orig = NSSelectorFromString(@"_initWithBody:webView:frameInfo:name:");
                
                IWKClassSwizzle(self, orig, @selector(fix_scriptMessageBody:webView:frameInfo:name:));
            }
        });
    }
}

- (NSString *)fetchBodyContentWithBody:(id)body {
    NSString *bodyContent = @"unknown";
    if ([body isKindOfClass:[NSDictionary class]]) {
        NSError *err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingPrettyPrinted error:&err];
        if (jsonData) {
            bodyContent = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (bodyContent.length > 200) {
                bodyContent = [bodyContent substringToIndex:200];
            }
        }
    } else if ([body isKindOfClass:[NSString class]]) {
        bodyContent = body;
    }
    return bodyContent;
}

//为了不改变栈的上下文，把代码都写在一个方法里面

- (instancetype)fix_scriptMessageBody:(id)body webView:(WKWebView *)webView frameInfo:(WKFrameInfo *)frameInfo name:(NSString *)name world:(id)world {
    BOOL (*allowsWeakReference)(id, SEL) =
    (BOOL(*)(id, SEL))
    class_getMethodImplementation([webView class],
                                  @selector(allowsWeakReference));
    __unsafe_unretained WKWebView *tmpWebView = webView;
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating =
        ! (*allowsWeakReference)(webView, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            tmpWebView = nil;
            NSString *bodyContent = [self fetchBodyContentWithBody:body];
            NSString *url = frameInfo.request.URL.absoluteString;
            [BDTrackerProtocol eventV3:@"wkwebview_wkscriptmessage_crash" params:@{@"exception":@"fix WKScriptMessage crash"
                                                                                   ,@"body":bodyContent
                                                                                   ,@"url":url?url:@""
                                                                                   ,@"name":name?name:@""
            }];
        }
    }
    return [self fix_scriptMessageBody:body webView:tmpWebView frameInfo:frameInfo name:name world:world];
}

- (instancetype)fix_scriptMessageBody:(id)body webView:(WKWebView *)webView frameInfo:(WKFrameInfo *)frameInfo name:(NSString *)name {
    BOOL (*allowsWeakReference)(id, SEL) =
    (BOOL(*)(id, SEL))
    class_getMethodImplementation([webView class],
                                  @selector(allowsWeakReference));
    __unsafe_unretained WKWebView *tmpWebView = webView;
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating =
        ! (*allowsWeakReference)(webView, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            tmpWebView = nil;
            NSString *bodyContent = [self fetchBodyContentWithBody:body];
            NSString *url = frameInfo.request.URL.absoluteString;
            [BDTrackerProtocol eventV3:@"wkwebview_wkscriptmessage_crash" params:@{@"exception":@"fix WKScriptMessage crash"
                                                                                   ,@"body":bodyContent
                                                                                   ,@"url":url?url:@""
                                                                                   ,@"name":name?name:@""
            }];
        }
    }
    return [self fix_scriptMessageBody:body webView:tmpWebView frameInfo:frameInfo name:name];
}

@end

@interface BDWKWebViewKeeper : NSObject

@property (nonatomic, strong) NSMutableArray *webViewList;
@property (nonatomic, assign) float keepTs;
@property (nonatomic, strong) NSTimer *timer;

+ (instancetype)shareInstance;

- (void)keepWebView:(WKWebView *)webView;

@end

@implementation BDWKWebViewKeeper

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDWKWebViewKeeper *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDWKWebViewKeeper alloc] init];
        instance.webViewList = [[NSMutableArray alloc] init];
    });
    return instance;
}

- (void)keepWebView:(WKWebView *)webView {
    if (webView && [webView isKindOfClass:WKWebView.class]) {
        [self.webViewList addObject:webView];
        float ts = self.keepTs>=0?self.keepTs:0;
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:ts target:self selector:@selector(checkWebList) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    }
}

- (void)checkWebList {
    if (!self.webViewList || self.webViewList.count <= 0) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    NSMutableArray *removeList = [[NSMutableArray alloc] init];
    long ts = (long)([[NSDate date] timeIntervalSince1970] * 1000);
    long validateTs = self.keepTs * 1000;
    for (WKWebView *webView in self.webViewList) {
        long beginTs = [webView BDCF_removeTs];
        long duraion = ts - beginTs;
        if (duraion < 0) { //异常数据清理
            [removeList addObject:webView];
        } else if (duraion >=0 && duraion >= validateTs) { //到时间释放
            [removeList addObject:webView];
        } else if (duraion >= 15*1000) { //大于15s的也清理，避免配置持有时间过长
            [removeList addObject:webView];
        }
    }
    [self.webViewList removeObjectsInArray:removeList];
}

@end

@implementation WKWebView (BDFixWKReleaseEarlyCrash)

+(void)load {
    [self tryFixWKReleaseEarlyCrash];
}

+ (void)tryFixWKReleaseEarlyCrash {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IWKClassSwizzle(self, NSSelectorFromString(@"removeFromSuperview"), NSSelectorFromString(@"bd_crashfix_removeFromSuperview"));
    });
}

- (void)bd_crashfix_removeFromSuperview {
    if ([BDWebKitSettingsManger bdFixWKReleaseEarlyCrash]) {
        [BDWKWebViewKeeper shareInstance].keepTs = [BDWebKitSettingsManger bdFixWKReleaseEarlyCrashKeeperTs];
        long ts = (long)([[NSDate date] timeIntervalSince1970] * 1000);
        [self setBDCF_removeTs:ts];
        [[BDWKWebViewKeeper shareInstance] keepWebView:self];
    }
    [self bd_crashfix_removeFromSuperview];
}

- (void)setBDCF_removeTs:(long)ts {
    objc_setAssociatedObject(self, @selector(BDCF_removeTs), @(ts), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (long)BDCF_removeTs {
    return [objc_getAssociatedObject(self, _cmd) longValue];
}

@end
