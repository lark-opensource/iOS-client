//
//  IESLiveWebViewOfflineMonitor.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/21.
//

#import "IESLiveWebViewOfflineMonitor.h"
#import "IESLiveWebViewPerformanceDictionary.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveMonitorUtils.h"
#import <objc/runtime.h>
#import "BDHybridMonitorDefines.h"

static NSMutableArray *pOfflineArr = nil;
static IMP ORIGCallingOutFalconInterceptedRequest = nil;
static BOOL offlineMonitorStarted = NO;
static NSLock *pOfflineArrLock = nil;
static NSArray *offlinePathExtensionArr = nil;
// resource timing 加入后需要调整
static NSInteger maxCount = 30;

static BOOL needMonitor(NSString *pathExtension) {
    for (NSString *ext in offlinePathExtensionArr) {
        if ([pathExtension containsString:ext]) {
            return YES;
        }
    }
    return NO;
};

static void ieslive_callingOutFalconInterceptedRequest(id slf, SEL sel, NSURLRequest *request, BOOL fromCache) {
    if (ORIGCallingOutFalconInterceptedRequest) {
        ((void(*)(id, SEL, NSURLRequest*,BOOL))ORIGCallingOutFalconInterceptedRequest)(slf, sel, request, fromCache);
    }
    
    if (fromCache
        && needMonitor(request.URL.pathExtension)) {
        NSDictionary *record = @{@"url": request.URL.absoluteString,
                                 @"path": request.URL.path,
                                 @"host": request.URL.host,
                                 @"offline": @(fromCache ? 1 : 0)
                                 };
        [pOfflineArrLock lock];
        [pOfflineArr addObject:record];
        if (pOfflineArr.count > maxCount) {
            NSInteger trimIndex = pOfflineArr.count / 2;
            for (NSInteger i = 0; i < trimIndex; ++i) {
                [pOfflineArr removeObjectAtIndex:i];
            }
        }
        [pOfflineArrLock unlock];
    }
}

@implementation IESLiveWebViewOfflineMonitor

+ (NSDictionary*)fetchRecordForUrlStr:(NSString*)urlStr {
    __block NSDictionary *result = nil;
    if (urlStr.length > 0) {
        if (needMonitor(urlStr)) {
            NSURL *url = [NSURL URLWithString:urlStr ?: @""];
            [pOfflineArrLock lock];
            __block NSInteger targetIndex = -1;
            [pOfflineArr enumerateObjectsUsingBlock:^(NSDictionary *record, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([record[@"path"] isEqualToString:url.path]
                    && [record[@"host"] isEqualToString:url.host]) {
                    result = [record copy];
                    targetIndex = idx;
                    *stop = YES;
                }
            }];
            !(targetIndex >= 0) ?: [pOfflineArr removeObjectAtIndex:targetIndex];
            [pOfflineArrLock unlock];
        }
    }
    return result;
}

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting {
    if (![setting[kBDWMOfflineMonitor] boolValue]
        && ![setting[kBDWMOnlyMonitorOffline] boolValue]) {
        return;
    }
    if (offlineMonitorStarted) {
        return;
    }
    Class cls = NSClassFromString(@"IESFalconManager");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL sel = @selector(callingOutFalconInterceptedRequest:willLoadFromCache:);
    SEL offlineSDKEnableSEL = @selector(interceptionEnable);
    Method offlineMethod = class_getClassMethod(cls, offlineSDKEnableSEL);
    IMP offlineImp = method_getImplementation(offlineMethod);
#pragma clang diagnostic pop
    offlineMonitorStarted = YES;
    [IESLiveWebViewPerformanceDictionary registerInitParamsBlock:^NSDictionary * _Nonnull(NSString * _Nonnull navigationID) {
        return @{@"offline": @(0)};
    }];
    [IESLiveWebViewPerformanceDictionary registerFormatBlock:^NSDictionary * _Nonnull(NSDictionary * _Nonnull record, NSString **key) {
        NSDictionary *nativeBase = record[kBDWebViewMonitorNativeBase];
        if ([nativeBase isKindOfClass:[NSDictionary class]]) {
            NSString *urlStr = nativeBase[kBDWebViewMonitorURL];
            NSString *serviceType = record[kBDWebViewMonitorServiceType];
            if ([serviceType isEqualToString:@"overview"]) {
                *key = kBDWebViewMonitorClientParams;
                NSDictionary *offlineDic = [IESLiveWebViewOfflineMonitor fetchRecordForUrlStr:urlStr];
                NSMutableDictionary *clientParams = [record[kBDWebViewMonitorClientParams] mutableCopy];
                [clientParams addEntriesFromDictionary:offlineDic];
                [clientParams addEntriesFromDictionary:@{@"offlineSDK" : (!!offlineImp
                                                                           && [cls respondsToSelector:offlineSDKEnableSEL]
                                                                           && ((BOOL(*)(Class, SEL))offlineImp)(cls, offlineSDKEnableSEL)) ? @(1) : @(0)}];
                return [clientParams copy];
            }
        }
        
        return nil;
    }];
    // 暂时不监控资源离线化情况
    // 目前资源类走离线化后获取不到 resource timing ，所以用排除法，获取不走离线化。
    if (cls
        && [cls respondsToSelector:sel]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            pOfflineArr = [[NSMutableArray alloc] init];
            offlinePathExtensionArr = @[@"htm"];
            pOfflineArrLock = [[NSLock alloc] init];
            IMP ORIGCallingOut = [IESLiveMonitorUtils
                                  hookMethod:object_getClass(cls)
                                  sel:sel
                                  imp:(IMP)ieslive_callingOutFalconInterceptedRequest];
            if (ORIGCallingOut) {
                ORIGCallingOutFalconInterceptedRequest = ORIGCallingOut;
            }
        });
    }
}

@end

