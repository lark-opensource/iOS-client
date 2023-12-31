//
//  BDHybridMonitor.m
//  BDAlogProtocol
//
//  Created by renpengcheng on 2020/2/4.
//

#import "BDHybridMonitor.h"
#import <Heimdallr/HMDTTMonitor.h>
#import "BDhybridCoreReporter.h"
#import "BDMonitorThreadManager.h"
#import "IESLiveMonitorUtils.h"
#import <WebKit/WKWebView.h>

NSString * const kBDHMURL = @"url";
NSString * const kBDHMPid = @"pid";
NSString * const kBDHMBid = @"bid";

#pragma mark ContainerField
NSString * const kBDHMContainerNameField = @"container_name";
NSString * const kBDHMSceneField = @"scene";
NSString * const kBDHMContainerTraceIDField = @"container_trace_id";
NSString * const kBDHMIsFallbackField = @"is_fallback";
NSString * const kBDHMInvokeFallbackField = @"invoke_fallback";
NSString * const kBDHMFallbackUrlField = @"fallback_url";
NSString * const kBDHMFallbackErrorCodeField = @"fallback_error_code";
NSString * const kBDHMFallbackErrorMsgField = @"fallback_error_msg";
NSString * const kBDHMOpenTimeField = @"open_time";
NSString * const kBDHMPageIDField = @"page_id";
NSString * const kBDHMSchemaField = @"schema";
NSString * const kBDHMTemplateResTypeField = @"template_res_type";
NSString * const kBDHMContainerInitStartField = @"container_init_start";
NSString * const kBDHMContainerInitEndField = @"container_init_end";
NSString * const kBDHMPrepareInitDataStartField = @"prepare_init_data_start";
NSString * const kBDHMPrepareInitDataEndField = @"prepare_init_data_end";
NSString * const kBDHMPrepareComponentStartField = @"prepare_component_start";
NSString * const kBDHMPrepareComponentEndField = @"prepare_component_end";
NSString * const kBDHMPrepareTemplateStartField = @"prepare_template_start";
NSString * const kBDHMPrepareTemplateEndField = @"prepare_template_end";
NSString * const kBDHMContainerLoadErrorCodeField = @"container_load_error_code";
NSString * const kBDHMContainerLoadErrorMsgField = @"container_load_error_msg";

NSString * const kBDHMContainerErrorCodeField = @"errorCode";
NSString * const kBDHMContainerErrorMsgField = @"errorMsg";
NSString * const kBDHMContainerVirtualAidField = @"virtualAid";
NSString * const kBDHMContainerBizTagField = @"bizTag";
#pragma mark -

static NSString * const kBDHMClientMetric = @"client_metric";
static NSString * const kBDHMClientCategory = @"client_category";
static NSString * const kBDHMClientExtra = @"client_extra";
static NSString * const kBDHMClientTiming = @"client_timing";
static NSString * const kBDHMEventName = @"event_name";
static NSString * const kBDHMEventType = @"ev_type";

// 存储容器打点数据
static NSMutableDictionary<NSString*, NSMutableDictionary*> *containerFieldDic = nil;

// 存储有效的容器uuid,避免清理后上报相同的uuid
static NSMutableArray<NSString *> *cachedContainerUUIDList = nil;

@implementation BDHybridMonitor

+ (NSString *)callSelectorWith:(NSString *)selName obj:(id)obj {
    SEL sel = NSSelectorFromString(selName);
    IMP imp = [obj methodForSelector:sel];
    if (imp) {
        NSString *(*func)(id, SEL) = (void *)imp;
        return func(obj,sel);
    }
    return @"";
}

/// lynx容器自定义上报接口
+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName
                             LynxView:(nonnull id)lynxView
                               metric:(nullable NSDictionary *)metric
                             category:(nullable NSDictionary *)category
                                extra:(nullable NSDictionary *)extra {
    [self lynxReportCustomWithEventName:eventName
                               LynxView:lynxView
                                 metric:metric
                               category:category
                                  extra:extra
                              maySample:NO];
}

+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName
                             LynxView:(nonnull id)lynxView
                               metric:(nullable NSDictionary *)metric
                             category:(nullable NSDictionary *)category
                                extra:(nullable NSDictionary *)extra
                            maySample:(BOOL)maySample {
    [self lynxReportCustomWithEventName:eventName
                               LynxView:lynxView
                                 metric:metric
                               category:category
                                  extra:extra
                                 timing:nil
                              maySample:maySample];
}

+ (void)lynxReportCustomWithEventName:(NSString *)eventName
                             LynxView:(id)lynxView
                               metric:(NSDictionary *)metric
                             category:(NSDictionary *)category
                                extra:(NSDictionary *)extra
                               timing:(NSDictionary *)timing
                            maySample:(BOOL)maySample {
    NSString *url = @"";
    NSString *aid = @"";
    NSString *bizTag = @"";
    if ([lynxView isKindOfClass:NSClassFromString(@"LynxView")]) {
        if ([lynxView respondsToSelector:NSSelectorFromString(@"bdlm_fetchCurrentUrl")]) {
            url = [BDHybridMonitor callSelectorWith:@"bdlm_fetchCurrentUrl" obj:lynxView];
        }
        if ([lynxView respondsToSelector:NSSelectorFromString(@"fetchVirtualAid")]) {
            aid = [BDHybridMonitor callSelectorWith:@"fetchVirtualAid" obj:lynxView];
        }
        if ([lynxView respondsToSelector:NSSelectorFromString(@"bdlm_bizTag")]) {
            bizTag = [BDHybridMonitor callSelectorWith:@"bdlm_bizTag" obj:lynxView];
        }
    }

    [BDHybridMonitor reportWithEventName:eventName
                                  bizTag:bizTag.length>0?bizTag:@""
                            commonParams:@{kBDHMURL:url.length>0?url:@""}
                                  metric:metric
                                category:category
                                   extra:extra
                                  timing:timing
                                    type:BDHybridCustomReportDirectly
                                platform:BDCustomReportLynx
                                     aid:aid
                               maySample:maySample];
}

/// web容器自定义上报接口
+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra {
    [self webReportCustomWithEventName:eventName
                               webView:webView
                                metric:metric
                              category:category
                                 extra:extra
                                timing:nil
                             maySample:NO];
}

+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra
                           maySample:(BOOL)maySample {
    [self webReportCustomWithEventName:eventName
                               webView:webView
                                metric:metric
                              category:category
                                 extra:extra
                                timing:nil
                             maySample:maySample];

}

+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName
                             webView:(nonnull id)webView
                              metric:(nullable NSDictionary *)metric
                            category:(nullable NSDictionary *)category
                               extra:(nullable NSDictionary *)extra
                              timing:(nullable NSDictionary *)timing
                           maySample:(BOOL)maySample {
    NSString *url = @"";
    NSString *aid = @"";
    NSString *bizTag = @"";
    if ([webView isKindOfClass:NSClassFromString(@"WKWebView")]) {
        if ([webView respondsToSelector:NSSelectorFromString(@"bdlm_fetchCurrentUrl")]) {
            url = [BDHybridMonitor callSelectorWith:@"bdlm_fetchCurrentUrl" obj:webView];
        }
        if ([webView respondsToSelector:NSSelectorFromString(@"fetchVirtualAid")]) {
            aid = [BDHybridMonitor callSelectorWith:@"fetchVirtualAid" obj:webView];
        }
        if ([webView respondsToSelector:NSSelectorFromString(@"bdlm_fetchBizTag")]) {
            bizTag = [BDHybridMonitor callSelectorWith:@"bdlm_fetchBizTag" obj:webView];
        }
    }

    [BDHybridMonitor reportWithEventName:eventName
                                  bizTag:bizTag.length>0?bizTag:@""
                            commonParams:@{kBDHMURL:url.length>0?url:@""}
                                  metric:metric
                                category:category
                                   extra:extra
                                  timing:timing
                                    type:BDHybridCustomReportDirectly
                                platform:BDCustomReportWebView
                                     aid:aid
                               maySample:maySample];
}

+ (void)reportWithEventName:(nonnull NSString *)eventName
                        url:(nonnull NSString *)url
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                   platform:(BDHybridCustomReportPlatform)platform {
    [BDHybridMonitor reportWithEventName:eventName
                                  bizTag:@""
                            commonParams:@{kBDHMURL:url.length>0?url:@""}
                                  metric:metric
                                category:category
                                   extra:extra
                                    type:BDHybridCustomReportDirectly
                                platform:platform];
}

+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform {
    [BDHybridMonitor reportWithEventName:eventName bizTag:bizTag commonParams:commonParams metric:metric category:category extra:extra type:reportType platform:platform
                                     aid:@""];
}

+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform
                        aid:(NSString *)aid {
    [self reportWithEventName:eventName bizTag:bizTag commonParams:commonParams metric:metric category:category extra:extra type:reportType platform:platform aid:aid
                    maySample:NO];
}

+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform
                        aid:(NSString *)aid
                  maySample:(BOOL)maySample {
    [self reportWithEventName:eventName
                       bizTag:bizTag
                 commonParams:commonParams
                       metric:metric
                     category:category
                        extra:extra
                       timing:nil
                         type:reportType
                     platform:platform
                          aid:aid
                    maySample:maySample];
}

+ (void)reportWithEventName:(nonnull NSString *)eventName
                     bizTag:(nullable NSString *)bizTag
               commonParams:(nullable NSDictionary *)commonParams
                     metric:(nullable NSDictionary *)metric
                   category:(nullable NSDictionary *)category
                      extra:(nullable NSDictionary *)extra
                     timing:(nullable NSDictionary *)timing
                       type:(BDHybridCustomReportType)reportType
                   platform:(BDHybridCustomReportPlatform)platform
                        aid:(NSString *)aid
                  maySample:(BOOL)maySample {
    if (eventName.length
        && [commonParams isKindOfClass:[NSDictionary class]]
        && commonParams[kBDHMURL]) {
        NSMutableDictionary *muteExtra = [extra ?: @{} mutableCopy];
        muteExtra[kBDHMEventName] = eventName;
        NSMutableDictionary *record = [@{
            kBDHMClientMetric : metric ?: @{},
            kBDHMClientCategory : category ?: @{},
            kBDHMClientTiming: timing ?: @{},
            kBDHMClientExtra : [muteExtra copy] ?: @{},
        } mutableCopy];
        if ([commonParams isKindOfClass:[NSDictionary class]]) {
            [record addEntriesFromDictionary:commonParams];
        }
        record[@"platform"] = @(platform);
        record[kBDHMEventType] = @"custom";
        NSString *urlStr = record[kBDHMURL];
        NSURL *url = [NSURL URLWithString:urlStr];
        !(url.host.length) ?: [record setObject:url.host forKey:@"host"];
        !(url.path.length) ?: [record setObject:url.path forKey:@"path"];
        if (aid.length > 0) {
            [record setObject:aid forKey:@"virtual_aid"];
        }
        
        //是否可能采样，用于上报量比较大的，允许采样的那种接口
        NSString *serviceName = maySample ? [NSString stringWithFormat:@"bd%@_hybrid_monitor_custom_sample_service", bizTag ?: @""] : [NSString stringWithFormat:@"bd%@_hybrid_monitor_custom_service", bizTag ?: @""];
        [MonitorReporterInstance reportSingleDic:[record copy] forService:serviceName];
    } else {
        NSCAssert(NO, @"commonParams must contain the 'url' key");
    }
}

+ (void)reportResourceStatus:(UIView *)containerView
              resourceStatus:(BDHM_ResourceStatus)resourceStatus
                resourceType:(BDHM_ResourceType)resourceType
                 resourceURL:(NSString *)resourceUrl {
    [self reportResourceStatus:containerView resourceStatus:resourceStatus resourceType:resourceType resourceURL:resourceUrl
               resourceVersion:@"0"];
}

+ (void)reportResourceStatus:(UIView *)containerView
              resourceStatus:(BDHM_ResourceStatus)resourceStatus
                resourceType:(BDHM_ResourceType)resourceType
                 resourceURL:(NSString *)resourceUrl
             resourceVersion:(NSString *)resourceVersion {
    NSString *status;
    NSString *container;
    NSString *type;
    
    if (resourceStatus == BDHM_ResourceStatusGurd) {
        status = @"gecko";
    } else if (resourceStatus == BDHM_ResourceStatusCdn) {
        status = @"cdn";
    } else if (resourceStatus == BDHM_ResourceStatusCdnCache) {
        status = @"cdnCache";
    } else if (resourceStatus == BDHM_ResourceStatusBuildIn) {
        status = @"buildIn";
    } else if (resourceStatus == BDHM_ResourceStatusOffline) {
        status = @"offline";
    } else if (resourceStatus == BDHM_ResourceStatusFail) {
        status = @"fail";
    }
    
    if (resourceType == BDHM_ResourceTypeTemplate) {
        type = @"template";
    } else if (resourceType == BDHM_ResourceTypeRes) {
        type = @"res";
    }
    
    NSString *eventName = @"bd_monitor_get_resource";
    NSMutableDictionary *category = [[NSMutableDictionary alloc] init];
    [category setValue:status?:@"" forKey:@"res_status"];
    [category setValue:type?:@"" forKey:@"res_type"];
    [category setValue:resourceUrl?:@"" forKey:@"res_url"];
    if (resourceVersion.length > 0) {
        [category setValue:resourceVersion forKey:@"res_version"];
    } else {
        [category setValue:@"0" forKey:@"res_version"];
    }
    
    Class lynxClass = NSClassFromString(@"LynxView");
    if ([containerView isKindOfClass:WKWebView.class]) {
        container = @"web";
        [category setValue:container?:@"" forKey:@"container"];
        [self webReportCustomWithEventName:eventName
                                   webView:containerView
                                    metric:nil
                                  category:category
                                     extra:nil
                                 maySample:YES];
    } else if (lynxClass && [containerView isKindOfClass:lynxClass]) {
        container = @"lynx";
        [category setValue:container?:@"" forKey:@"container"];
        [self lynxReportCustomWithEventName:eventName
                                   LynxView:containerView
                                     metric:nil
                                   category:category
                                      extra:nil
                                  maySample:YES];
    } else {
        NSCAssert(NO, @"container is not lynxView or webView");
    }
}

+ (void)reportFallBack:(BDHM_FallBackType)fallBackType sourceUrl:(NSString *)sourceUrl sourceContainer:(BDHM_ContainerType)sourceContainer targetUrl:(NSString *)targetUrl targetContainer:(BDHM_ContainerType)targetContainer aid:(NSString *)aid {
    NSString *sourceCT = @"";
    NSString *targetCT = @"";
    sourceCT = [self transformContainerType:sourceContainer];
    targetCT = [self transformContainerType:targetContainer];
    
    BDHybridCustomReportPlatform platform = BDCustomReportWebView;
    if (sourceContainer == BDHM_ContainerTypeLynx) {
        platform = BDCustomReportLynx;
    }
    
    NSMutableDictionary *category = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"fallbak_type": fallBackType == BDHM_FallBackTypeSchema ? @"schemaError" : @"loadError",
        @"source_container":sourceCT.length>0?sourceCT:@"",
        @"source_url":sourceUrl?:@"",
        @"target_container":targetCT.length>0?targetCT:@"",
        @"target_url":targetUrl?:@"",
    }];
    [self reportWithEventName:@"bd_monitor_fallback_page"
                       bizTag:nil
                 commonParams:@{kBDHMURL:sourceUrl?:@""}
                       metric:nil
                     category:category
                        extra:nil
                         type:BDHybridCustomReportDirectly
                     platform:platform
                          aid:aid
                    maySample:NO];
}

+(NSString *)transformContainerType:(BDHM_ContainerType)containerType {
    NSString *containerStr = @"";
    if (containerType == BDHM_ContainerTypeLynx) {
        containerStr = @"lynx";
    } else if (containerType == BDHM_ContainerTypeWeb) {
        containerStr = @"web";
    } else if (containerType == BDHM_ContainerTypeNative) {
        containerStr = @"native";
    }
    return containerStr;
}

+ (nonnull NSString *)generateIDForContainer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        containerFieldDic = [NSMutableDictionary dictionary];
        cachedContainerUUIDList = [NSMutableArray array];
    });
    NSString * uuid = [NSUUID UUID].UUIDString;
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        [cachedContainerUUIDList addObject:uuid];
    }];
    return uuid;
}

+ (void)attach:(nonnull NSString *)uuid webView:(nonnull id)webView {
    if ([webView isKindOfClass:NSClassFromString(@"WKWebView")]) {
        if ([webView respondsToSelector:NSSelectorFromString(@"attachContainerUUID:")]) {
            SEL sel = NSSelectorFromString(@"attachContainerUUID:");
            IMP imp = [webView methodForSelector:sel];
            if (imp) {
                void(*func)(id, SEL, NSString *) = (void *)imp;
                func(webView, sel, uuid);
            }
        }
    }
}

+ (void)attach:(nonnull NSString *)uuid LynxView:(nonnull id)lynxView {
    if ([lynxView isKindOfClass:NSClassFromString(@"LynxView")]) {
        if ([lynxView respondsToSelector:NSSelectorFromString(@"attachContainerUUID:")]) {
            SEL sel = NSSelectorFromString(@"attachContainerUUID:");
            IMP imp = [lynxView methodForSelector:sel];
            if (imp) {
                void(*func)(id, SEL, NSString *) = (void *)imp;
                func(lynxView, sel, uuid);
            }
        }
    }
}

+ (void)reportContainerError:(id)view withID:(NSString *)uuid withError:(NSDictionary *)errorInfo {
    if (!errorInfo || ![errorInfo isKindOfClass:[NSDictionary class]]) {
        // If errorInfo is nil or not Dictionary, just return
        return;
    }
    NSInteger errorCode = [[errorInfo allKeys] containsObject:kBDHMContainerErrorCodeField] ? [errorInfo[kBDHMContainerErrorCodeField] intValue] : 0;
    NSString * errorMsg = [[errorInfo allKeys] containsObject:kBDHMContainerErrorMsgField] ? errorInfo[kBDHMContainerErrorMsgField] : @"";
    NSString * virtualAid = [[errorInfo allKeys] containsObject:kBDHMContainerVirtualAidField] ? errorInfo[kBDHMContainerVirtualAidField] : @"";
    NSString * bizTag = [[errorInfo allKeys] containsObject:kBDHMContainerBizTagField] ? errorInfo[kBDHMContainerBizTagField] : @"";
    if (view != nil && ![view isEqual:[NSNull null]]) {
        if ([view isKindOfClass:NSClassFromString(@"WKWebView")] || [view isKindOfClass:NSClassFromString(@"LynxView")]) {
            if ([view respondsToSelector:NSSelectorFromString(@"reportContainerError:errorCode:errorMsg:bizTag:")]) {
                SEL sel = NSSelectorFromString(@"reportContainerError:errorCode:errorMsg:bizTag:");
                IMP imp = [view methodForSelector:sel];
                if (imp) {
                    void(*func)(id, SEL, NSString *, NSInteger, NSString *, NSString *) = (void *)imp;
                    func(view, sel, virtualAid?:@"", errorCode, errorMsg?:@"", bizTag?:@"");
                    return;
                }
            }
        }
    }
    // View is nil Or neither WebView nor LynxView
    if (!uuid) {
        return;
    }
    [BDHybridMonitor fetchContainerData:uuid block:^(NSDictionary * _Nonnull containerBase, NSDictionary * _Nonnull containerInfo) {
        NSMutableDictionary *extraDic = [NSMutableDictionary dictionary];
        NSString * eventType = @"containerError";
        extraDic[@"event_type"] = eventType;
        extraDic[@"containerBase"] = [containerBase copy];

        NSMutableDictionary *nativeBaseDic = [NSMutableDictionary dictionary];
        nativeBaseDic[@"sdk_version"] = [IESLiveMonitorUtils iesWebViewMonitorVersion];
        nativeBaseDic[@"virtual_aid"] = virtualAid?:@"";
        extraDic[@"nativeBase"] = [nativeBaseDic copy];

        NSMutableDictionary *containerInfoDic = [NSMutableDictionary dictionary];
        [containerInfoDic addEntriesFromDictionary:containerInfo];
        containerInfoDic[@"container_load_error_code"] = @(errorCode);
        containerInfoDic[@"container_load_error_msg"] = errorMsg?:@"";
        extraDic[@"containerInfo"] = [containerInfoDic copy];

        NSString *serviceName = [NSString stringWithFormat:@"bd_hybrid_monitor_service_%@_%@"
                                 ,eventType?:@""
                                 ,bizTag?:@""];
        [MonitorReporterInstance reportSingleDic:[extraDic copy]
                                      forService:serviceName];
    }];
}

static BOOL findInContainerUUIDList(NSString *uuid) {
    BOOL result = NO;
    if (!uuid) {
        return result;
    }
    if (cachedContainerUUIDList) {
        NSString *obj;
        for (obj in cachedContainerUUIDList) {
            if ([uuid isEqualToString:obj]) {
                result = YES;
                break;
            }
        }
    }
    return result;
}

static NSDictionary * fetchDataWithUUID(NSString * uuid) {
    if (!uuid) {
        return nil;
    }
    NSDictionary * origDic = containerFieldDic[uuid];
    if (!origDic || ![origDic isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [origDic copy];
}

static void fetchDataByContainerKey(NSMutableDictionary * destDic, NSDictionary * oriDic, NSString * key) {
    if (!destDic || !oriDic || !key) {
        return;
    }
    if (![destDic isKindOfClass:[NSMutableDictionary class]]) {
        return;
    }
    if ([[oriDic allKeys] containsObject:key]) {
        if ([oriDic[key] isKindOfClass:[NSString class]]) {
            destDic[key] = oriDic[key];
        }
    }
}

static NSDictionary * fetchContainerBaseDic(NSDictionary * dic) {
    if (!dic) {
        return nil;
    }
    NSMutableDictionary * baseDic = [NSMutableDictionary dictionary];
    fetchDataByContainerKey(baseDic, dic, kBDHMContainerNameField);
    fetchDataByContainerKey(baseDic, dic, kBDHMContainerTraceIDField);
    fetchDataByContainerKey(baseDic, dic, kBDHMSchemaField);
    fetchDataByContainerKey(baseDic, dic, kBDHMTemplateResTypeField);
    return [baseDic copy];
}

/// 容器上报接口
+ (void)collectBoolean:(nonnull NSString *)uuid
                 field:(nonnull NSString *)field
                  data:(BOOL)data {
    if (uuid) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            if (findInContainerUUIDList(uuid)) {
                NSMutableDictionary *origDic = containerFieldDic[uuid];
                if (!origDic) {
                    origDic = [NSMutableDictionary dictionary];
                }
                [origDic setObject:@(data) forKey:field];
                [containerFieldDic setObject:origDic forKey:uuid];
            }
        }];
    }
}

+ (void)collectString:(nonnull NSString *)uuid
                field:(nonnull NSString *)field
                 data:(nullable NSString *)data {
    if (uuid) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            if (findInContainerUUIDList(uuid)) {
                NSMutableDictionary *origDic = containerFieldDic[uuid];
                if (!origDic) {
                    origDic = [NSMutableDictionary dictionary];
                }
                [origDic setObject:data forKey:field];
                [containerFieldDic setObject:origDic forKey:uuid];
            }
        }];
    }
}

+ (void)collectLong:(nonnull NSString *)uuid
              field:(nonnull NSString *)field
               data:(long long)data {
    if (uuid) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            if (findInContainerUUIDList(uuid)) {
                NSMutableDictionary *origDic = containerFieldDic[uuid];
                if (!origDic) {
                    origDic = [NSMutableDictionary dictionary];
                }
                [origDic setObject:@(data) forKey:field];
                [containerFieldDic setObject:origDic forKey:uuid];
            }
        }];
    }
}

+ (void)collectInt:(nonnull NSString *)uuid
             field:(nonnull NSString *)field
              data:(int)data {
    if (uuid) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            if (findInContainerUUIDList(uuid)) {
                NSMutableDictionary *origDic = containerFieldDic[uuid];
                if (!origDic) {
                    origDic = [NSMutableDictionary dictionary];
                }
                [origDic setObject:@(data) forKey:field];
                [containerFieldDic setObject:origDic forKey:uuid];
            }
        }];
    }
}

+ (void)deleteData:(NSString *)uuid isForce:(BOOL)isForce {
    if (uuid) {
        void (^deleteDataBlock)(NSString *containerUUID, BOOL isForce) = ^(NSString *containerUUID, BOOL isForce) {
            // Delete data for uuid
            BOOL willDelete = !findInContainerUUIDList(containerUUID);
            if (isForce || willDelete) {
                if (containerFieldDic) {
                    [containerFieldDic removeObjectForKey:containerUUID];
                }
            }
        };
        if ([BDMonitorThreadManager isMonitorThread]) {
            deleteDataBlock(uuid, isForce);
        } else {
            [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
                deleteDataBlock(uuid, isForce);
            }];
        }
    }
}

+ (void)invalidateID:(NSString *)uuid andData:(BOOL)willDelete {
    if (uuid) {
        void (^invalidateBlock)(NSString *containerUUID, BOOL willDeleteData) = ^(NSString *containerUUID, BOOL willDeleteData) {
            // Delete uuid from valid list
            if (cachedContainerUUIDList) {
                [cachedContainerUUIDList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isEqualToString:containerUUID]) {
                        *stop = YES;
                        [cachedContainerUUIDList removeObject:obj];
                    }
                }];
            }

            // Delete data for uuid
            if (willDeleteData) {
                if (containerFieldDic) {
                    [containerFieldDic removeObjectForKey:containerUUID];
                }
            }
        };
        if ([BDMonitorThreadManager isMonitorThread]) {
            invalidateBlock(uuid, willDelete);
        } else {
            [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
                invalidateBlock(uuid, willDelete);
            }];
        }
    }
}

+ (void)fetchContainerData:(NSString *)uuid block:(void (^)(NSDictionary * _Nonnull, NSDictionary * _Nonnull))dataBlock {
    if (!dataBlock) {
        return;
    }
    if ([BDMonitorThreadManager isMonitorThread]) {
        if (dataBlock) {
            NSDictionary * dic = fetchDataWithUUID(uuid);
            dataBlock(fetchContainerBaseDic(dic), [dic copy]);
        }
    } else {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            if (dataBlock) {
                NSDictionary * dic = fetchDataWithUUID(uuid);
                dataBlock(fetchContainerBaseDic(dic), [dic copy]);
            }
        }];
    }
}

@end
