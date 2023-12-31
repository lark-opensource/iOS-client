//
//  BDWebViewGeneralReporter.m
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2020/1/17.
//

#import "BDWebViewGeneralReporter.h"
#import "BDWebView+BDWebViewMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>
#import "BDHybridMonitorDefines.h"

static NSString *const BDWMsubclassSuffix = @"_BDWM_";

static Class getORIGClassIfNeeded(NSObject *obj) {
    Class statedClass = obj.class;
    Class baseClass = object_getClass(obj);
    NSString *className = NSStringFromClass(baseClass);
    // Already subclassed
    if ([className hasSuffix:BDWMsubclassSuffix]) {
        return baseClass;
        // We swizzle a class object, not a single object.
    } else if (class_isMetaClass(baseClass)) {
        return (Class)obj;
        // Probably a KVO'ed class. Swizzle in place. Also swizzle meta classes in place.
    } else if (statedClass != baseClass) {
        return baseClass;
    }
    return nil;
}

static Class _getTargetDelegateClass(NSObject *delegate) {
    return getORIGClassIfNeeded(delegate) ?: object_getClass(delegate);
}

static void _bdwm_hookedGetClass(Class class, Class statedClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

static Class _bdwm_hookClass(NSObject *self, NSError **error) {
    NSCParameterAssert(self);
    Class statedClass = self.class;
    Class baseClass = object_getClass(self);
    NSString *className = NSStringFromClass(baseClass);
    
    Class ORIGCls = getORIGClassIfNeeded(self);
    if (ORIGCls) {
        return ORIGCls;
    }
    // Default case. Create dynamic subclass.
    const char *subclassName = [className stringByAppendingString:BDWMsubclassSuffix].UTF8String;
    Class subclass = objc_getClass(subclassName);

    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseClass, subclassName, 0);
        if (subclass == nil) {
#if DEBUG
            NSString *errrorDesc = [NSString stringWithFormat:@"objc_allocateClassPair failed to allocate class %s.", subclassName];
            NSLog(@"%@", errrorDesc);
#endif
            return nil;
        }

        _bdwm_hookedGetClass(subclass, statedClass);
        _bdwm_hookedGetClass(object_getClass(subclass), statedClass);
        objc_registerClassPair(subclass);
    }

    object_setClass(self, subclass);
    return subclass;
}


static NSMutableDictionary<Class, NSMutableDictionary<NSString*, NSValue*>*> *_ORIGImpDic = nil;
static NSMutableDictionary<Class, NSPointerArray*> *_insertedDelegateIMPs = nil;

static NSPointerArray* _getDelegateIMPs(Class cls) {
    while (cls) {
        if (_insertedDelegateIMPs[cls]) {
            return _insertedDelegateIMPs[cls];
        }
        cls = [cls superclass];
    }
#if DEBUG
    assert(NO); // not find ORIG IMP
#endif
    return nil;
}

static void _prepareORIGForClass(Class cls) {
    if (!(_ORIGImpDic[cls])) {
        _ORIGImpDic[(id<NSCopying>)cls] = [NSMutableDictionary dictionary];
    }
}

@implementation BDWebViewGeneralReporter

#pragma mark - ORIGImpDic & insertedDelegateIMPs
+ (void)prepareForClass:(Class)cls {
    if (!_insertedDelegateIMPs) {
        _insertedDelegateIMPs = [NSMutableDictionary dictionary];
    }
    if (!(_insertedDelegateIMPs[cls])) {
        _insertedDelegateIMPs[(id<NSCopying>)cls] = [NSPointerArray strongObjectsPointerArray];
    }
    if (!_ORIGImpDic) {
        _ORIGImpDic = [NSMutableDictionary dictionary];
    }
    if (!(_ORIGImpDic[cls])) {
        _ORIGImpDic[(id<NSCopying>)cls] = [NSMutableDictionary dictionary];
    }
}

+ (void)prepareORIGForClass:(Class)cls {
    _prepareORIGForClass(cls);
}

+ (NSPointerArray *)getDelegateIMPs:(Class)cls {
    return _getDelegateIMPs(cls);
}

#pragma mark - getter and setter
+ (NSMutableDictionary<Class,NSMutableDictionary<NSString *,NSValue *> *> *)ORIGImpDic {
    return _ORIGImpDic;
}

+ (void)setORIGImpDic:(NSMutableDictionary<Class,NSMutableDictionary<NSString *,NSValue *> *> *)ORIGImpDic {
    _ORIGImpDic = ORIGImpDic;
}

+ (NSMutableDictionary<Class, NSPointerArray*> *)insertedDelegateIMPs {
    return _insertedDelegateIMPs;
}

+ (void)setInsertedDelegateIMPs:(NSMutableDictionary<Class,NSPointerArray *> *)insertedDelegateIMPs {
    _insertedDelegateIMPs = insertedDelegateIMPs;
}

#pragma mark - public Api
+ (Class)getTargetDelegateClass:(NSObject *)delegate {
    if (!delegate) {
        return nil;
    }
    return _getTargetDelegateClass(delegate);
}

+ (Class)bdwm_hookClass:(NSObject *)obj error:(NSError **)error {
    if (!obj) {
        return nil;
    }
    return _bdwm_hookClass(obj, error);
}


#pragma mark - update WKWebView & OtherWebView monitor
+ (void)updateMonitorOfWKWebView:(WKWebView *)webView
                      statusCode:(NSNumber *)statusCode
                           error:(NSError * __nullable)error
                        withType:(BDWebViewGeneralType)type {
    if (webView.bdwm_disableMonitor) {
        return;
    }
    if (type == BDNavigationPreFinishType && statusCode) {
        objc_setAssociatedObject(webView, &BDWMsubclassSuffix, statusCode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (type == BDNavigationFinishType) {
        statusCode = objc_getAssociatedObject(webView, &BDWMsubclassSuffix);
    }
    [self updateMonitorWithDict:webView.performanceDic urlString:webView.URL.absoluteString?:@"" statusCode:statusCode error:error type:type isWK:YES];
}

+ (void)updateMonitorWithDict:(IESLiveWebViewPerformanceDictionary *)performanceDict
                    urlString:(NSString *)urlString
                   statusCode:(NSNumber * __nullable)statusCode
                        error:(NSError * __nullable)error
                         type:(BDWebViewGeneralType)type
                         isWK:(BOOL)isWK {
    switch (type) {
        case BDRequestStartType: {
            if (isWK) {
                [performanceDict setNavigationID:[NSUUID UUID].UUIDString];
                [performanceDict setUrl:urlString];
                [performanceDict coverClientParamsOnce:@{@"request_start" : @([IESLiveMonitorUtils formatedTimeInterval])}];
                if (performanceDict.bdwm_loadStartTS > 0) { // 生成 navigation id 时再插入 load_start, 防止 load_start 插入到前一个navigation id 中
                    [performanceDict coverClientParams:@{@"load_start": @(performanceDict.bdwm_loadStartTS)}];
                    // 设置成 0 , 直到下次 loadrequest 调用后才再次设置load_start
                    performanceDict.bdwm_loadStartTS = 0;
                }
                [performanceDict updateClickStartTs];
                [performanceDict reportNavigationStart];
            }
            break;
        }
        case BDNavigationStartType: {
            if (!isWK) {
                [performanceDict setNavigationID:[NSUUID UUID].UUIDString];
                [performanceDict setUrl:urlString];
                [performanceDict coverClientParamsOnce:@{@"clientRequestStart" : @([IESLiveMonitorUtils formatedTimeInterval])}];
                if (performanceDict.bdwm_loadStartTS > 0) { // 生成 navigation id 时再插入 load_start, 防止 load_start 插入到前一个navigation id 中
                    [performanceDict coverClientParams:@{@"load_start": @(performanceDict.bdwm_loadStartTS)}];
                    // 设置成 0 , 直到下次 loadrequest 调用后才再次设置load_start
                    performanceDict.bdwm_loadStartTS = 0;
                }
                [performanceDict updateClickStartTs];
                [performanceDict reportNavigationStart];
            } else {
                [performanceDict coverClientParamsOnce:@{@"navigation_start" : @([IESLiveMonitorUtils formatedTimeInterval])}];
            }
            break;
        }
        case BDRequestFailType: {
            [performanceDict coverClientParams:@{@"request_fail" : @([IESLiveMonitorUtils formatedTimeInterval])}];
            !urlString.length ?: [performanceDict coverClientParams:@{kBDWebViewMonitorURL : urlString ?: @""}];
            [performanceDict reportPVWithStageDic:@{
                @"stage" : vBDWMNavigationFail,
                kBDWebViewMonitorURL : urlString ?: @"",
            }];
            [performanceDict reportRequestError:error withURLStr:urlString];
            break;
        }
        case BDRedirectStartType: {
            long long ts = [IESLiveMonitorUtils formatedTimeInterval];
            [performanceDict coverClientParamsOnce:@{@"redirect_start" : @(ts)}];
            [performanceDict accumulateWithDic:@{kBDWebViewMonitorEvent: @{@"redirect_count" : @(1)}}];
            [performanceDict appendParams:@{@"ts" : @(ts), kBDWebViewMonitorURL: urlString} path:@"nativeInfo.redirect_detail"];
            break;
        }
        case BDNavigationPreFinishType:
            break;
        case BDNavigationFinishType: { // ui wk
            [performanceDict coverClientParams:@{@"http_status_code" : statusCode ?: @0}];
            [performanceDict coverClientParams:@{@"navigation_finish" : @([IESLiveMonitorUtils formatedTimeInterval])}];
            [performanceDict coverClientParams:@{kBDWebViewMonitorURL : urlString ?: @""}];
            [performanceDict reportPVWithStageDic:@{@"stage": vBDWMFinishNavigation}];
            if (statusCode && [statusCode integerValue] >= 400) {
                [performanceDict reportRequestError:[NSError errorWithDomain:@"status code error" code:0 userInfo:@{@"httpStatusCode" : statusCode}] withURLStr:urlString];
            }
            break;
        }
        case BDNavigationFailType: {
            [performanceDict coverClientParams:@{@"navigation_fail" : @([IESLiveMonitorUtils formatedTimeInterval])}];
            [performanceDict reportPVWithStageDic:@{
                @"stage" : vBDWMNavigationFail,
                kBDWebViewMonitorURL : urlString ?: @"",
            }];
            [performanceDict reportRequestError:error withURLStr:urlString];
            break;
        }
        case BDNavigationTerminateType: {
            [performanceDict coverClientParams:@{@"process_terminate" : @([IESLiveMonitorUtils formatedTimeInterval])}];
            [performanceDict reportTerminate:error];
            break;
        }
        case BDNavigationResponseType:
            break;
        default:
            break;
    }
}

@end
