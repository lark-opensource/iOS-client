//
//  NSBundleResourceRequest+CrashProtect.m
//  LarkCrashSanitizer
//
//  Created by Saafo on 2023/10/18.
//

#import <LKLoadable/Loadable.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>
#import "LKHookUtil.h"

//https://code.byted.org/ugc/IESCrash/blob/master/IESCrash/Modules/Shield/Crash/ICHShieldFixODRException.m
//参考 IESCrash 内部 crash修复实现
//https://bytedance.feishu.cn/docs/doccnajLxdLgD5UJMoCwxFEdLY4

@interface NSBundleResourceRequest (CrashShield)
- (instancetype)initWithMachServiceName:(NSString *)name options:(NSInteger)options;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NSBundleResourceRequest (CrashShield)

static NSException *_exception;
static NSObject *_connection;

static inline void getConnection(void) {
    [NSBundleResourceRequest performSelector:NSSelectorFromString(@"_connection")];
}

static inline void setConnection(NSObject *object) {
    (void)[NSBundleResourceRequest performSelector:NSSelectorFromString(@"_setConnection:") withObject:object];
}

+ (NSObject *)crashshield_connection {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            Class clazz = NSClassFromString(@"NSXPCConnection");
            _connection = [[clazz alloc] initWithMachServiceName:@"com.apple.ondemandd.client" options:0];
            setConnection(_connection);
        } @catch(NSException *exception) {
            _exception = exception;
        }
    });
    return _connection;
}

- (void)crashshield_beginAccessingResourcesWithCompletionHandler:(void (^)(NSError *))completionHandler {
    getConnection();
    if (_exception) {
        NSError *error = [NSError errorWithDomain:@"ICHShieldFixODRException" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: [_exception description]
        }];
        if (completionHandler) {
            completionHandler(error);
        }
    } else {
        [self crashshield_beginAccessingResourcesWithCompletionHandler:completionHandler];
    }
}

- (void)crashshield_conditionallyBeginAccessingResourcesWithCompletionHandler:(void (^)(BOOL))completionHandler {
    getConnection();
    if (_exception) {
        [WMFSwiftLogger warnWithMessage:[NSString stringWithFormat:@"[NSBundleResourceRequest+CrashProtect] "
                                         "There is an exception(%@) when connect odr service, "
                                         "just callback with NO for "
                                         "`conditionallyBeginAccessingResourcesWithCompletionHandler:` function.",
                                         [_exception description]]];
        if (completionHandler) {
            completionHandler(NO);
        }
    } else {
        [self crashshield_conditionallyBeginAccessingResourcesWithCompletionHandler:completionHandler];
    }
}
@end

#pragma clang diagnostic pop

LoadableDidFinishLaunchFuncBegin(NSBundleResourceRequestHook)
if (@available(iOS 15, *)) { // 10~14 才有问题
    return;
}
SwizzleClassMethod([NSBundleResourceRequest class],
                   NSSelectorFromString(@"_connection"), @selector(crashshield_connection));
SwizzleMethod([NSBundleResourceRequest class], @selector(beginAccessingResourcesWithCompletionHandler:),
              [NSBundleResourceRequest class], @selector(crashshield_beginAccessingResourcesWithCompletionHandler:));
SwizzleMethod([NSBundleResourceRequest class], @selector(conditionallyBeginAccessingResourcesWithCompletionHandler:),
              [NSBundleResourceRequest class], @selector(crashshield_conditionallyBeginAccessingResourcesWithCompletionHandler:));
LoadableDidFinishLaunchFuncEnd(NSBundleResourceRequestHook)
