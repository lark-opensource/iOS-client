//
//  CJPayHybridMonitorPluginImpl.m
//  cjpay_hybrid
//
//  Created by shanghuaijun on 2023/3/23.
//

#import "CJPayHybridMonitorPluginImpl.h"
#import <HybridKit/HybridKitViewProtocol.h>
#import <HybridKit/HybridContext.h>
#import <HybridKit/HybridSchemaParam.h>
#import "CJPaySDKMacro.h"
#import "CJPayHybridLifeCycleSubscribeCenter.h"
#import "CJPayHybridPerformanceMonitor.h"


@interface CJPayHybridMonitorPluginImpl()

@property (nonatomic, strong) NSMutableDictionary<NSString *, CJPayHybridPerformanceMonitor *> *monitorDic;

@end

@implementation CJPayHybridMonitorPluginImpl

CJPAY_REGISTER_COMPONENTS({
    [[CJPayHybridLifeCycleSubscribeCenter defaultService] addSubscriber:[CJPayHybridMonitorPluginImpl defaultService]];
})

+ (instancetype)defaultService {
    static CJPayHybridMonitorPluginImpl *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayHybridMonitorPluginImpl new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _monitorDic = [NSMutableDictionary new];
    }
    return self;
}

- (void)viewDidCreate:(id<HybridKitViewProtocol>)view {
    [[self getMonitorWithView:view] trackPerformanceStage:CJPayHybridPerformanceStageInitFinished defaultTimeStamp:0];
    [self p_trackWithEvent:@"wallet_rd_hybrid_init"
                    params:@{}
                      view:view];
}

- (void)viewWillStartLoading:(id<HybridKitViewProtocol>)view {
    [[self getMonitorWithView:view] trackPerformanceStage:CJPayHybridPerformanceStageStartLoadURL defaultTimeStamp:0];
}

- (void)viewDidStartLoading:(id<HybridKitViewProtocol>)view {
    [[self getMonitorWithView:view] trackPerformanceStage:CJPayHybridPerformanceStagePageStarted defaultTimeStamp:0];
}

- (void)view:(id<HybridKitViewProtocol>)view didFinishLoadWithURL:(NSString *)url {
    [[self getMonitorWithView:view] trackPerformanceStage:CJPayHybridPerformanceStagePageFinished defaultTimeStamp:0];
}

- (void)view:(id<HybridKitViewProtocol>)view didLoadFailedWithURL:(NSString *)url error:(NSError *)error {
    [self p_trackWithEvent:@"wallet_rd_hybrid_error"
                    params:@{@"stage": @"hybrid_kit",
                             @"error_code": @(error.code),
                             @"error_msg": CJString(error.description)}
                      view:view];
}

- (void)view:(id<HybridKitViewProtocol>)view didRecieveError:(NSError *)error {
    [self p_trackWithEvent:@"wallet_rd_hybrid_error"
                    params:@{@"stage": @"hybrid_kit",
                             @"error_code": @(error.code),
                             @"error_msg": CJString(error.description)}
                      view:view];
}

- (void)viewWillDealloc:(id<HybridKitViewProtocol>)view {
    [self.monitorDic removeObjectForKey:CJString(view.containerID)];
}

- (void)p_trackWithEvent:(NSString *)event
                  params:(NSDictionary *)paramsDic
                    view:(id<HybridKitViewProtocol>)view {
    NSMutableDictionary *params = [[self p_getCommonHybridParamsWithView:view] mutableCopy];
    [params addEntriesFromDictionary:paramsDic];
    [CJTracker event:event params:params];
}

- (NSDictionary *)p_getCommonHybridParamsWithView:(id<HybridKitViewProtocol>)view {
    NSMutableDictionary *paramsDic = [NSMutableDictionary new];
    HybridContext *hybridContext = view.params.context;
    HybridEngineType engineType = hybridContext.schemaParams.engineType;
    NSString *typeStr = @"";
    switch (engineType) {
        case HybridEngineTypeWeb:
            typeStr = @"web";
            break;
        case HybridEngineTypeLynx:
            typeStr = @"lynx";
            break;
        default:
            typeStr = @"unknown";
            break;
    }
    [paramsDic cj_setObject:CJString(typeStr) forKey:@"type"];
    [paramsDic cj_setObject:CJString(hybridContext.schemaParams.originURL.absoluteString) forKey:@"url"];
    [paramsDic cj_setObject:CJString(hybridContext.schemaParams.originURL.absoluteString) forKey:@"schema"];
    [paramsDic cj_setObject:@"hybridkit" forKey:@"kernel_type"];
    return [paramsDic copy];
}

- (nullable CJPayHybridPerformanceMonitor *)getMonitorWithView:(id<HybridKitViewProtocol>)view {
    if (!Check_ValidString(view.containerID)) {
        return nil;
    }
    
    CJPayHybridPerformanceMonitor *currentContainerMonitor = [self.monitorDic cj_objectForKey:CJString(view.containerID)];
    if (currentContainerMonitor) {
        return currentContainerMonitor;
    }
    
    NSTimeInterval callAPITime = CFAbsoluteTimeGetCurrent();
    NSDictionary *schemaParamsDic = [CJPayCommonUtil parseScheme:CJString(view.context.schemaParams.originURL.absoluteString)];
    NSString *httpUrlStr = [schemaParamsDic cj_stringValueForKey:@"url"];
    CJPayHybridPerformanceMonitor *webPerformanceMonitor = [[CJPayHybridPerformanceMonitor alloc] initWith:CJString(httpUrlStr) callAPITime:callAPITime];
    webPerformanceMonitor.kernelTypeStr = @"hybridkit";
    [self.monitorDic cj_setObject:webPerformanceMonitor
                           forKey:CJString(view.containerID)];
    return webPerformanceMonitor;
}

@end
