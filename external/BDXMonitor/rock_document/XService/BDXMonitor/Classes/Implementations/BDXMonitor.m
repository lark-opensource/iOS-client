//
//  BDXSchema.m
//  Bullet-BulletXResource
//
//  Created by bytedance on 2021/3/5.
//

#import "BDXMonitor.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <IESWebViewMonitor/BDHybridMonitor.h>
#import <IESWebViewMonitor/LynxView+PublicInterface.h>
#import <IESWebViewMonitor/WKWebView+PublicInterface.h>
#import <Lynx/LynxView.h>

@BDXSERVICE_REGISTER(BDXMonitor)

    @interface BDXMonitor()

@property(nonatomic, strong) NSMutableDictionary *innerLifeCycleDictionary;
@property(nonatomic, assign) BOOL lifeCycleDicfreeze;
@property(nonatomic, assign) CFAbsoluteTime baselineTimeStamp;

@end

@implementation BDXMonitor

@synthesize lifeCycleDictionary;

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeMonitor;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

- (instancetype)init
{
    if (self = [super init]) {
        _innerLifeCycleDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)reportWithEventName:(nonnull NSString *)eventName bizTag:(nullable NSString *)bizTag commonParams:(nullable NSDictionary *)commonParams metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra platform:(BDXMonitorReportPlatform)platform aid:(NSString *)aid maySample:(BOOL)maySample
{
    NSMutableDictionary *newCategory = [category mutableCopy];
    newCategory[@"_container"] = @"bullet";
    return [BDHybridMonitor reportWithEventName:eventName bizTag:bizTag commonParams:commonParams metric:metric category:[newCategory copy] extra:extra type:BDHybridCustomReportDirectly platform:(BDHybridCustomReportPlatform)platform aid:aid maySample:maySample];
}

- (void)reportResourceStatus:(nullable __kindof UIView *)containerView resourceStatus:(BDXMonitorResourceStatus)resourceStatus resourceType:(BDXMonitorResourceType)resourceType resourceURL:(NSString *)resourceUrl resourceVersion:(NSString *)resourceVersion extraInfo:(NSDictionary *_Nullable)extraInfo extraMetrics:(NSDictionary *_Nullable)extraMetrics
{
    if (!containerView) {
        return;
    }

    NSString *status;
    NSString *container;
    NSString *type;
    if (resourceStatus == BDXMonitorResourceStatusGecko) {
        status = @"gecko";
    } else if (resourceStatus == BDXMonitorResourceStatusCdn) {
        status = @"cdn";
    } else if (resourceStatus == BDXMonitorResourceStatusCdnCache) {
        status = @"cdnCache";
    } else if (resourceStatus == BDXMonitorResourceStatusBuildIn) {
        status = @"buildIn";
    } else if (resourceStatus == BDXMonitorResourceStatusOffline) {
        status = @"offline";
    } else if (resourceStatus == BDXMonitorResourceStatusFail) {
        status = @"fail";
    }

    if (resourceType == BDHM_ResourceTypeTemplate) {
        type = @"template";
    } else if (resourceType == BDHM_ResourceTypeRes) {
        type = @"res";
    }

    NSString *eventName = @"bd_monitor_get_resource";
    NSMutableDictionary *category = [[NSMutableDictionary alloc] init];
    [category setValue:status ?: @"" forKey:@"res_status"];
    [category setValue:type ?: @"" forKey:@"res_type"];
    [category setValue:resourceUrl ?: @"" forKey:@"res_url"];
    [category setValue:@"true" forKey:@"hasFail"];
    if (resourceVersion.length > 0) {
        [category setValue:resourceVersion forKey:@"res_version"];
    } else {
        [category setValue:@"0" forKey:@"res_version"];
    }

    [category addEntriesFromDictionary:extraInfo];

    Class lynxClass = NSClassFromString(@"LynxView");
    if ([containerView isKindOfClass:WKWebView.class]) {
        container = @"web";
        [category setValue:container ?: @"" forKey:@"container"];
        [BDXMonitor webReportCustomWithEventName:eventName webView:containerView metric:nil category:category extra:nil maySample:YES];
    } else if (lynxClass && [containerView isKindOfClass:lynxClass]) {
        container = @"lynx";
        [category setValue:container ?: @"" forKey:@"container"];
        [BDXMonitor lynxReportCustomWithEventName:eventName LynxView:containerView metric:[extraMetrics copy] category:[category copy] extra:nil maySample:YES];
    }
}

- (void)attachVirtualAid:(NSString *)virtualAid toView:(__kindof UIView *)view
{
    if ([view isKindOfClass:[LynxView class]]) {
        [(LynxView *)view attachVirtualAid:virtualAid];
    } else if ([view isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)view attachVirtualAid:virtualAid];
    }
}

- (void)logWithTag:(NSString *)tag level:(BDXMonitorLogLevel)level format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4)
{
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    BDALOG_PROTOCOL_TAG((kBDLogLevel)level, tag, str);
}

- (void)trackLifeCycleWithEvent:(NSString *)eventName
{
    [self trackLifeCycleWithEvent:eventName timeStamp:[[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000];
}

- (void)trackLifeCycleWithEvent:(NSString *)eventName timeStamp:(NSTimeInterval)timeStamp
{
    if(self.lifeCycleDicfreeze){
        return;
    }
    if ([eventName isEqualToString:@"view_did_initialized"]) {
        self.innerLifeCycleDictionary[@"baseline"] = @(timeStamp);
    }
    if([eventName isEqualToString:@"view_will_load_url"] && self.innerLifeCycleDictionary[@"view_will_load_url"]){
        //ignore second time load
        self.lifeCycleDicfreeze = YES;
        return;
    }
    if(!self.innerLifeCycleDictionary[eventName]){
        self.innerLifeCycleDictionary[eventName] = @(timeStamp);
    }
}

- (NSDictionary *)lifeCycleDictionary
{
    return [_innerLifeCycleDictionary copy];
}

- (void)setLifeCycleDictionary:(NSDictionary *)lifeCycleDictionary
{
    _innerLifeCycleDictionary = [lifeCycleDictionary mutableCopy];
}

- (void)clearLifeCycleEventDic
{
    _innerLifeCycleDictionary = [NSMutableDictionary dictionary];
}

#pragma mark - util

+ (NSString *)callSelectorWith:(NSString *)selName obj:(id)obj
{
    SEL sel = NSSelectorFromString(selName);
    IMP imp = [obj methodForSelector:sel];
    if (imp) {
        NSString *(*func)(id, SEL) = (void *)imp;
        return func(obj, sel);
    }
    return @"";
}

+ (void)lynxReportCustomWithEventName:(nonnull NSString *)eventName LynxView:(nonnull id)lynxView metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra maySample:(BOOL)maySample
{
    NSString *url = @"";
    NSString *aid = @"";
    NSString *bizTag = @"";
    if ([lynxView isKindOfClass:NSClassFromString(@"LynxView")]) {
        if ([lynxView respondsToSelector:NSSelectorFromString(@"bdlm_fetchCurrentUrl")]) {
            url = [BDXMonitor callSelectorWith:@"bdlm_fetchCurrentUrl" obj:lynxView];
        }
        if ([lynxView respondsToSelector:NSSelectorFromString(@"fetchVirtualAid")]) {
            aid = [BDXMonitor callSelectorWith:@"fetchVirtualAid" obj:lynxView];
        }
        if ([lynxView respondsToSelector:NSSelectorFromString(@"bdlm_bizTag")]) {
            bizTag = [BDXMonitor callSelectorWith:@"bdlm_bizTag" obj:lynxView];
        }
    }

    [BDHybridMonitor reportWithEventName:eventName bizTag:bizTag.length > 0 ? bizTag : @"" commonParams:@{kBDHMURL: url.length > 0 ? url : @""} metric:metric category:category extra:extra type:BDHybridCustomReportDirectly platform:BDCustomReportLynx aid:aid maySample:maySample];
}

+ (void)webReportCustomWithEventName:(nonnull NSString *)eventName webView:(nonnull id)webView metric:(nullable NSDictionary *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extra maySample:(BOOL)maySample
{
    NSString *url = @"";
    NSString *aid = @"";
    NSString *bizTag = @"";
    if ([webView isKindOfClass:NSClassFromString(@"WKWebView")]) {
        if ([webView respondsToSelector:NSSelectorFromString(@"bdlm_fetchCurrentUrl")]) {
            url = [BDXMonitor callSelectorWith:@"bdlm_fetchCurrentUrl" obj:webView];
        }
        if ([webView respondsToSelector:NSSelectorFromString(@"fetchVirtualAid")]) {
            aid = [BDXMonitor callSelectorWith:@"fetchVirtualAid" obj:webView];
        }
        if ([webView respondsToSelector:NSSelectorFromString(@"bdlm_fetchBizTag")]) {
            bizTag = [BDXMonitor callSelectorWith:@"bdlm_fetchBizTag" obj:webView];
        }
    }

    [BDHybridMonitor reportWithEventName:eventName bizTag:bizTag.length > 0 ? bizTag : @"" commonParams:@{kBDHMURL: url.length > 0 ? url : @""} metric:metric category:category extra:extra type:BDHybridCustomReportDirectly platform:BDCustomReportWebView aid:aid maySample:maySample];
}

@end
