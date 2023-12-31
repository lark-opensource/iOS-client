//
//  TSPKRuleEngineSubscriber.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/30.
//

#import "TSPKRuleEngineSubscriber.h"
#import "TSPKEvent.h"
#import "TSPKUtils.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKUploadEvent.h"
#import "TSPKReporter.h"
#import "TSPKHostEnvProtocol.h"
#import "TSPKRuleExecuteResultModel.h"
#import "TSPKConfigs.h"
#import "TSPKEntryManager.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import "TSPKSignalManager+public.h"
#import <ByteDanceKit/ByteDanceKit.h>

NSString *const TSPKRuleEngineAction = @"action";

NSString *const TSPKRuleEngineActionFuse = @"fuse";
NSString *const TSPKRuleEngineActionReport = @"report";
NSString *const TSPKRuleEngineActionDowngrade = @"downgrade";
NSString *const TSPKRuleEngineActionCache = @"cache";

NSString *const TSPKMethodGuardFuseField = @"guardFuseField";
NSString *const TSPKMethodGuardField = @"guardField";

@implementation TSPKRuleEngineSubscriber

- (NSString *)uniqueId {
    return @"TSPKRuleEngineSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return [[TSPKEntryManager sharedManager] canHandleEventModel:event.eventData.apiModel];
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    return nil;
}

- (NSDictionary *)convertEventDataToParams:(TSPKEventData *)eventData source:(NSString *)source {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"source"] = source ?: @"";
    dict[@"api_id"] = @(eventData.apiModel.apiId) ?: @0;
    dict[@"api"] = [TSPKUtils concateClassName:eventData.apiModel.apiClass method:eventData.apiModel.apiMethod joiner:@"_"] ?: @"";
    dict[@"pipeline_type"] = eventData.apiModel.pipelineType ?: @"";
    NSString *dataType = eventData.apiModel.dataType;
    if (dataType) {
        dict[@"data_types"] = @[dataType];
    } else {
        dict[@"data_types"] = @[];
    }
    dict[TSPKWarningTypeUnReleaseCheck] = @([eventData.warningTypes containsObject:TSPKWarningTypeUnReleaseCheck]);
    dict[TSPKWarningTypeDelayReleaseCheck] = @([eventData.warningTypes containsObject:TSPKWarningTypeDelayReleaseCheck]);
    dict[@"top_page_name"] = eventData.topPageName ?: @"";
    [eventData.apiModel.params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        dict[key] = obj;
    }];
    if (eventData.bpeaContext) {
        [dict addEntriesFromDictionary:eventData.bpeaContext];
    }
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)appendExecuteResult:(id<PNSRuleResultProtocol>)results
                toEventData:(TSPKEventData *)eventData
                      input:(NSDictionary *)input
{
    TSPKRuleExecuteResultModel *ruleExecuteResult = [[TSPKRuleExecuteResultModel alloc] init];
    ruleExecuteResult.strategyMD5 = results.signature;
    ruleExecuteResult.scene = results.scene;
    ruleExecuteResult.strategies = results.ruleSetNames;
    ruleExecuteResult.input = input;
    ruleExecuteResult.usedStateParams = results.usedParameters;
    if (results.values.count == 0) {
        [eventData.ruleExecuteResults addObject:ruleExecuteResult];
        return;
    }
    NSMutableArray *hitRules = [[NSMutableArray alloc] init];
    for (id<PNSSingleRuleResultProtocol> singleRuleResult in results.values) {
        TSPKSingleRuleExecuteResultModel *model = [[TSPKSingleRuleExecuteResultModel alloc] init];
        model.key = singleRuleResult.key;
        model.config = singleRuleResult.conf;
        [hitRules addObject:model];
    }
    ruleExecuteResult.hitRules = [hitRules copy];
    [eventData.ruleExecuteResults addObject:ruleExecuteResult];
}

- (void)reportInfoWithParams:(NSDictionary *)params
                ruleSetNames:(NSArray<NSString *> *)ruleSetNames
                  ruleResult:(id <PNSSingleRuleResultProtocol>)ruleResult
              usedParameters:(NSDictionary *)usedParameters
                    needFuse:(BOOL)needFuse
                  backtraces:(NSArray *)backtraces
                   eventData:(TSPKEventData *)eventData
                   signature:(NSString *)signature
{
    TSPKUploadEvent *uploadEvent = [TSPKUploadEvent new];

    uploadEvent.eventName = [NSString stringWithFormat:@"PrivacyBadcase-%@-%@", params[@"pipeline_type"], ruleResult.key];
    uploadEvent.backtraces = backtraces;

    uploadEvent.params = [[eventData formatDictionary] mutableCopy];
    [uploadEvent.params addEntriesFromDictionary:params];
    uploadEvent.params[TSPKMonitorSceneKey] = ruleResult.key;
    uploadEvent.params[TSPKRuleEngineAction] = ruleResult.conf[TSPKRuleEngineAction];
    uploadEvent.params[TSPKPermissionTypeKey] = eventData.apiModel.dataType;
    uploadEvent.params[@"strategies"] = [ruleSetNames componentsJoinedByString:@","];
    // 将规则引擎的运算数据加入到上报数据中
    [usedParameters enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        uploadEvent.params[key] = obj;
    }];

    if (eventData.uuid) {
        uploadEvent.params[@"uuid"] = eventData.uuid;
    }
    
    uploadEvent.params[@"last_enter_background_timestamp"] = @(eventData.lastEnterBackgroundTimestamp);
    
    // add extra info
    uploadEvent.params = [self addExtraInfoForParams:uploadEvent.params].mutableCopy;
    
    if ([ruleResult.conf[@"app_scenes"] boolValue]){
        NSDictionary *context = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) contextInfo];
        [uploadEvent.params addEntriesFromDictionary:context];
    }

    uploadEvent.filterParams = [[eventData formatFilterDictionary] mutableCopy];
    [uploadEvent.filterParams addEntriesFromDictionary:[self buildDefaultFilterParameter:uploadEvent.params]];
    // 通过conf追加过滤字段
    NSDictionary *uploadParams = [ruleResult.conf btd_dictionaryValueForKey:@"upload_params"];
    
    [uploadEvent addExtraFilterParams:[uploadParams btd_arrayValueForKey:@"filter_extra_info"]];
    uploadEvent.filterParams = [self addExtraInfoForParams:uploadEvent.filterParams].mutableCopy;
    uploadEvent.isALogUpload = [uploadParams btd_boolValueForKey:@"upload_alog"];
    // add enable_multiple_stacks info
    BOOL isMultipleAsyncStackTraceEnabled = [PNS_GET_INSTANCE(PNSBacktraceProtocol) isMultipleAsyncStackTraceEnabled];
    NSString *enablesMultipleStackKey = @"enable_multiple_stacks";
    uploadEvent.params[enablesMultipleStackKey] = @(isMultipleAsyncStackTraceEnabled);
    uploadEvent.filterParams[enablesMultipleStackKey] = @(isMultipleAsyncStackTraceEnabled);
    
    // add signature
    uploadEvent.params[@"dsl_signature"] = signature;
    uploadEvent.filterParams[@"dsl_signature"] = signature;

    // add signal with delay
    NSInteger uploadDelay = [uploadParams btd_integerValueForKey:@"upload_delay"];
    BOOL uploadSignal = [uploadParams btd_boolValueForKey:@"upload_signal"];
    NSString *dataType = eventData.apiModel.dataType;
    if (uploadSignal) {
        uploadEvent.params[@"uploadSignal"] = @(YES);
        uploadEvent.filterParams[@"uploadSignal"] = @(YES);
    }
    
    if (uploadDelay > 0 && uploadSignal) {
        uploadEvent.uploadDelay = uploadDelay;
        uploadEvent.params[@"uploadDelay"] = @(uploadDelay);
        uploadEvent.filterParams[@"uploadDelay"] = @(uploadDelay);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(uploadDelay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *signalInfo = [TSPKSignalManager signalInfoWithPermissionType:dataType instanceAddress:[uploadEvent.params btd_stringValueForKey:@"unreleaseAddress"]];
            if (signalInfo) {
                [uploadEvent.params addEntriesFromDictionary:signalInfo];
            }
            [[TSPKReporter sharedReporter] report:uploadEvent];
        });
    } else {
        if (uploadSignal) {
            NSDictionary *signalInfo = [TSPKSignalManager signalInfoWithPermissionType:dataType instanceAddress:[uploadEvent.params btd_stringValueForKey:@"unreleaseAddress"]];
            if (signalInfo) {
                [uploadEvent.params addEntriesFromDictionary:signalInfo];
            }
        }
        [[TSPKReporter sharedReporter] report:uploadEvent];
    }
}

- (NSDictionary *)buildDefaultFilterParameter:(NSDictionary *)params {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if (params[@"api"]) {
        result[@"api"] = params[@"api"];
    }
    
    if (params[TSPKRuleEngineAction]) {
        result[TSPKRuleEngineAction] = params[TSPKRuleEngineAction];
    }
    
    if (params[TSPKPermissionTypeKey]) {
        result[TSPKPermissionTypeKey] = params[TSPKPermissionTypeKey];
    }
    
    if (params[TSPKMonitorSceneKey]) {
        result[TSPKMonitorSceneKey] = params[TSPKMonitorSceneKey];
    }
    
    return result;
}

- (NSDictionary *)addExtraInfoForParams:(NSDictionary *)params
{
    NSString *permissionType = [NSString stringWithFormat:@"%@", params[TSPKPermissionTypeKey]];
    NSString *monitorScene = [NSString stringWithFormat:@"%@", params[TSPKMonitorSceneKey]];
    
    NSMutableDictionary *mutableResult = params.mutableCopy;
    // add extra info for business
    // special info, build new key to be distinguished
    id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
    if ([hostEnv respondsToSelector:@selector(extraBizInfoWithGuardScene:permissionType:)]) {
        NSDictionary <NSString *, NSDictionary *> *bizInfos = [hostEnv extraBizInfoWithGuardScene:monitorScene permissionType:permissionType];
        
        if (bizInfos.count > 0) {
            [bizInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull bizInfo, BOOL * _Nonnull stop) {
                NSString *newKey = [NSString stringWithFormat:@"%@_biz", key];
                mutableResult[newKey] = bizInfo;
            }];
        }
    }
    
    // common info, add info without additional operations
    if ([hostEnv respondsToSelector:@selector(extraCommonBizInfoWithGuardScene:permissionType:)]) {
        NSDictionary <NSString *, NSString *> *commonBizInfos = [hostEnv extraCommonBizInfoWithGuardScene:monitorScene permissionType:permissionType];
        
        if (commonBizInfos.count > 0) {
            [commonBizInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                mutableResult[key] = obj;
            }];
        }
    }
    return mutableResult;
}

@end
