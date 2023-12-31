//
//  HMDHTTPDetailRecord+Report.m
//  Heimdallr
//
//  Created by fengyadong on 2018/11/20.
//

#import "HMDHTTPDetailRecord+Report.h"
#import "HMDMacro.h"
#import "HMDNetworkHelper.h"
#import "Heimdallr+Private.h"
#import "NSArray+HMDSafe.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "HMDDoubleReporter.h"
#import "NSDictionary+HMDSafe.h"

typedef NS_OPTIONS(NSUInteger, HMDHTTPTrackerHitRules) {
    HMDHTTPTrackerHitRuleNone               = 0,
    HMDHTTPTrackerHitRuleAPIAll             = 1 << 0,
    HMDHTTPTrackerHitRuleOverThreshold      = 1 << 1,
    HMDHTTPTrackerHitRuleRandomSampling     = 1 << 2
};

@implementation HMDHTTPDetailRecord (Report)
+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSMutableArray *doubleUploadRecords = [NSMutableArray array];
    for (HMDHTTPDetailRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        
        long long time = MilliSecond(record.timestamp);

        if (record.customExtraValue && record.customExtraValue.count > 0) {
            [dataValue addEntriesFromDictionary:record.customExtraValue];
        }
        [dataValue setValue:@(time) forKey:@"timestamp"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];  // new
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];  // new
        [dataValue setValue:record.logType forKey:@"log_type"];
        [dataValue setValue:@(record.localID) forKey:@"log_id"];
        [dataValue setValue:record.appVersion forKey:@"app_version"];
        [dataValue setValue:record.osVersion forKey:@"os_version"];
        [dataValue setValue:record.buildVersion forKey:@"update_version_code"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];

        [dataValue setValue:@(record.isSuccess) forKey:@"isSuccess"]; // new
        [dataValue setValue:record.connetType forKey:@"connetType"];  // new
        [dataValue setValue:@(record.connetCode) forKey:@"network_type"];
        [dataValue setValue:record.radioAccessType forKey:@"network_type_code"];

        [dataValue setValue:@(record.hasTriedTimes) forKey:@"httpIndex"];  // new

        [dataValue setValue:record.method forKey:@"method"];  // new
        [dataValue setValue:record.host forKey:@"host"];  // new
        [dataValue setValue:record.absoluteURL forKey:@"uri"];
        [dataValue setValue:@(record.startTime) forKey:@"startTime"]; // new
        [dataValue setValue:@(record.endtime) forKey:@"endtime"]; // new
        [dataValue setValue:@(record.duration) forKey:@"timing_total"];
        [dataValue setValue:@(record.upStreamBytes) forKey:@"timing_totalSendBytes"]; // new
        [dataValue setValue:@(record.downStreamBytes) forKey:@"timing_totalReceivedBytes"];
        [dataValue setValue:@(record.statusCode) forKey:@"status"];
        [dataValue setValue:record.MIMEType forKey:@"MIMEType"]; // new
        [dataValue setValue:@(record.errCode) forKey:@"errCode"]; // new
        [dataValue setValue:record.errDesc forKey:@"error_desc"]; // new
        [dataValue setValue:record.requestHeader forKey:@"requestHeader"]; // new
        [dataValue setValue:record.responseHeader forKey:@"responseHeader"]; // new
        [dataValue setValue:record.responseBody forKey:@"responseBody"]; // new
        [dataValue setValue:@(record.singlePointOnly) forKey:@"single_point_only"];

        // url_session 中字段和 request_log 重复了
        if (![record.clientType isEqualToString:@"url_session"]) {
            [dataValue setValue:@(record.proxyTime) forKey:@"timing_proxy"];
            [dataValue setValue:@(record.dnsTime) forKey:@"timing_dns"];
            [dataValue setValue:@(record.connectTime) forKey:@"timing_connect"];
            [dataValue setValue:@(record.sslTime) forKey:@"timing_ssl"];
            [dataValue setValue:@(record.sendTime) forKey:@"timing_send"];
            [dataValue setValue:@(record.waitTime) forKey:@"timing_wait"];
            [dataValue setValue:@(record.receiveTime) forKey:@"timing_receive"];
        }
        // timing 相关的
        [dataValue setValue:@(record.isSocketReused) forKey:@"timing_isSocketReused"];
        [dataValue setValue:@(record.isCached) forKey:@"timing_isCached"];
        [dataValue setValue:@(record.isFromProxy) forKey:@"timing_isFromProxy"];
        /*
         SDKwarning治理
        [dataValue setValue:@(record.remotePort) forKey:@"timing_remotePort"];
         */
        [dataValue setValue:record.protocolName forKey:@"protocolName"]; // new
        [dataValue setValue:record.traceId forKey:@"ttnet_traceId"];
        if (record.aid) {
            [dataValue setValue:record.aid forKey:@"aid"];
        }
        if (record.sdkAid) {
            [dataValue setValue:record.sdkAid forKey:@"sdk_aid"];
        }

        if (record.requestLog) {
            [dataValue setValue:record.requestLog forKey:@"request_log"];
        } else {
            NSString *log = [self getRequestLogWithRecord:record];
            [dataValue setValue:log forKey:@"request_log"];
        }

        // 网络库类型
        [dataValue setValue:record.clientType forKey:@"client_type"];

        // about network_v2
        if (record.baseApiAll) {
            [dataValue setValue:record.baseApiAll forKey:@"enable_base_api_all"];
        }
        if (record.injectTracelog) {
            [dataValue setValue:record.injectTracelog forKey:@"inject_tracelog"];
        }
        if (record.netLogType) {
            [dataValue setValue:record.netLogType forKey:@"net_log_type"];
        }

        // scene
        if(record.scene.length > 0 || record.format.length > 0) {
            NSMutableDictionary *extraStatus = [NSMutableDictionary dictionaryWithCapacity:2];
            if (record.scene.length > 0) {
                [extraStatus setValue:record.scene forKey:@"response_scene"]; // new
            }
            if (record.requestScene.length > 0) {
                [extraStatus setValue:record.requestScene forKey:@"request_scene"];
            }
            if (record.format.length > 0) {
                [extraStatus setValue:record.format forKey:@"format"]; // new
            }
            [dataValue setValue:[extraStatus copy] forKey:@"extra_status"];
        }

        if (record.requestFiltersTimingInfo) {
            [dataValue setValue:record.requestFiltersTimingInfo forKey:@"request_filters_timing"];
            NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:record.requestFiltersTimingInfo];
            [dataValue setValue:array forKey:@"request_filters_timing_v2"];
        }
        if (record.requestSerializerTimingInfo) {
            [dataValue setValue:record.requestSerializerTimingInfo forKey:@"request_serializer_timing"];
            NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:record.requestSerializerTimingInfo];
            [dataValue setValue:array forKey:@"request_serializer_timing_v2"];
        }
        if (record.responseFiltersTimingInfo) {
            [dataValue setValue:record.responseFiltersTimingInfo forKey:@"response_filters_timing"];
            NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:record.responseFiltersTimingInfo];
            [dataValue setValue:array forKey:@"response_filters_timing_v2"];
        }
        if (record.responseSerializerTimingInfo) {
            [dataValue setValue:record.responseSerializerTimingInfo forKey:@"response_serializer_timing"];
            NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:record.responseSerializerTimingInfo];
            [dataValue setValue:array forKey:@"response_serializer_timing_v2"];
        }
        if (record.responseAdditionalTimingInfo) {
            [dataValue setValue:record.responseAdditionalTimingInfo forKey:@"response_additional_timing"];
            NSArray *array = [HMDHTTPDetailRecord getTimingInfoV2WithTimingInfo:record.responseAdditionalTimingInfo];
            [dataValue setValue:array forKey:@"response_additional_timing_v2"];
        }
        if (record.responseBDTuringTimingInfo) {
            [dataValue setValue:record.responseBDTuringTimingInfo forKey:@"response_bdturing_timing"];
        }
        if(record.bdwURL) {
            [dataValue setValue:record.bdwURL forKey:@"webview_url"];
        }
        if(record.bdwChannel) {
            [dataValue setValue:record.bdwChannel forKey:@"webview_channel"];
        }
        if(record.concurrentRequest) {
            [dataValue setValue:record.concurrentRequest forKey:@"concurrentRequest"];
        }
        if(record.isSerializedOnMainThread != -1) {
            [dataValue setValue:@(record.isSerializedOnMainThread) forKey:@"serialize_on_main_thread"];
        }
        if(record.isCallbackExecutedOnMainThread != -1) {
            [dataValue setValue:@(record.isCallbackExecutedOnMainThread) forKey:@"callback_on_main_thread"];
        }
        
        if(record.extraBizInfo) {
            NSDictionary *info = [[HMDHTTPRequestTracker sharedTracker] callHTTPRequestTrackerCallback:record];
            if (!HMDIsEmptyDictionary(info)){
                [dataValue setValue:info forKey:@"extra_biz_info"];
            }
        }

        // 流量相关统计字段
        [dataValue setValue:@(record.sid) forKey:@"sid"];
        [dataValue setValue:@(record.isForeground) forKey:@"front"];
        NSInteger hitRules = [HMDHTTPDetailRecord getHitRulesWithInAllowList:record.inWhiteList];
        [dataValue setValue:@(hitRules) forKey:@"hit_rules"];
        [dataValue setValue:record.logType forKey:@"net_consume_type"];

        NSArray *hitRulesTags = [HMDHTTPDetailRecord getHitRulesTagsArrayWithHitRulesTages:record.hit_rule_tags];
        if (hitRulesTags) {
            [dataValue setValue:hitRulesTags forKey:@"hit_rule_tags"];
        }
        
        if(record.doubleUpload) {
            NSMutableDictionary *dataValueCopy = [dataValue mutableCopy];
            [dataValueCopy setValue:@(record.doubleUpload) forKey:@"double_upload"];
            [doubleUploadRecords addObject:[dataValueCopy copy]];
        }
        [dataArray addObject:dataValue];
    }
    
    if(doubleUploadRecords.count) {
        [[HMDDoubleReporter sharedReporter] doubleUploadRecordArray:[doubleUploadRecords copy]];
    }
    return [dataArray copy];
}

+ (NSArray <NSDictionary *>*)getTimingInfoV2WithTimingInfo:(NSDictionary *)timingInfo {
    NSMutableArray *array = [NSMutableArray array];
    [timingInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        if ([value isKindOfClass:[NSNumber class]] && [key isKindOfClass:[NSString class]]) {
            [dic hmd_setObject:key forKey:@"name"];
            [dic hmd_setObject:value forKey:@"timing"];
        }
        [array hmd_addObject:[dic copy]];
    }];
    return [array copy];
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSString *)getRequestLogWithRecord:(HMDHTTPDetailRecord *)record {
    NSMutableDictionary *logDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    [responseDictionary setValue:@(record.statusCode) forKey:@"code"];
    [responseDictionary setValue:@(record.upStreamBytes) forKey:@"sent_bytes"];
    [responseDictionary setValue:@(record.downStreamBytes) forKey:@"received_bytes"];

    NSMutableDictionary *baseDictionary = [NSMutableDictionary dictionary];
    [baseDictionary setValue:record.absoluteURL forKey:@"url"];
    [baseDictionary setValue:record.method forKey:@"method"];
    if (record.isSuccess) {
        [baseDictionary setValue:@"SUCCESS" forKey:@"status"];
    } else {
        [baseDictionary setValue:@"FAILED" forKey:@"status"];
    }
    [baseDictionary setValue:@(record.redirectCount) forKey:@"redirect_times"];
    // 当 redirect_times == 0 或者 redirectList 的数量不大于 0 没有 redirect_list 这个字段
    if (record.redirectCount > 0 && record.redirectList && record.redirectList.count > 0) {
        [baseDictionary setValue:record.redirectList forKey:@"redirect_list"];
    }

    NSMutableDictionary *timingDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *requestDictionary = [NSMutableDictionary dictionary];
    [requestDictionary setValue:@(record.startTime) forKey:@"start_time"];
    [requestDictionary setValue:@(record.duration) forKey:@"duration"];
    [requestDictionary setValue:@(record.requestSendTime) forKey:@"request_sent_time"];
    [requestDictionary setValue:@(record.responseRecTime) forKey:@"response_recv_time"];

    NSMutableDictionary *detailedDurationDictionary = [NSMutableDictionary dictionary];
    [detailedDurationDictionary setValue:@(record.proxyTime) forKey:@"proxy"];
    [detailedDurationDictionary setValue:@(record.dnsTime) forKey:@"dns"];
    if (record.tcpTime > 0) {
        [detailedDurationDictionary setValue:@(record.tcpTime) forKey:@"tcp"];
    } else { // 兼容老版本数据库数据, 如果在数据库中取出的字段没有 tcp 时间,则还是使用 connectTime
        [detailedDurationDictionary setValue:@(record.connectTime) forKey:@"tcp"];
    }
    [detailedDurationDictionary setValue:@(record.sslTime) forKey:@"ssl"];
    [detailedDurationDictionary setValue:@(record.sendTime) forKey:@"send"];
    [detailedDurationDictionary setValue:@(record.waitTime) forKey:@"ttfb"];
    [detailedDurationDictionary setValue:@(record.receiveTime) forKey:@"body_recv"];
    
    if (record.serverTiming) {
        NSInteger innerTime = -1;
        NSInteger edgeTime = -1;
        NSInteger originTime = -1;
        NSString *timingString = [record.serverTiming stringByReplacingOccurrencesOfString:@" " withString:@""]; // 去掉里面的空格 由于serverTiming是网络请求中链路加的所以 会有时候莫名的多一个空格
        NSArray *timeingArray = [timingString componentsSeparatedByString:@","];
        for (NSString *str in timeingArray) {
            // 只是取出来对应的值，没有相关容错处理，比如计算值小于0是不是应该给默认值-1; (来自网络架构的 CodeReview 建议)
            if ([str containsString:@"inner;dur="]) {
                NSString *timeValue = [[str componentsSeparatedByString:@"="] objectAtIndex:1];
                innerTime = [self httpRecordServerTimingItemToInt:timeValue];
                [detailedDurationDictionary setValue:@(innerTime) forKey:@"inner"];
            }
            if ([str containsString:@"edge;dur="]) {
                NSString *timeValue = [[str componentsSeparatedByString:@"="] objectAtIndex:1];
                edgeTime = [self httpRecordServerTimingItemToInt:timeValue];
                [detailedDurationDictionary setValue:@(edgeTime) forKey:@"edge"];
            }
            if ([str containsString:@"origin;dur="]) {
                NSString *timeValue = [[str componentsSeparatedByString:@"="] objectAtIndex:1];
                originTime = [self httpRecordServerTimingItemToInt:timeValue];
                [detailedDurationDictionary setValue:@(originTime) forKey:@"origin"];
            }
            if ([str containsString:@"cdn-cache;desc="]) {
                NSString *value = [[str componentsSeparatedByString:@"="] objectAtIndex:1];
                NSInteger isCache = 1;
                if ([value isEqualToString:@"MISS"]) {
                    isCache = 0;
                }
                [detailedDurationDictionary setValue:@(isCache) forKey:@"cdn-cache"];
            }
        }
        NSInteger rttTime = -1;
        if (record.waitTime >= 0 && edgeTime >= 0 && originTime >= 0) {
            rttTime = record.waitTime - edgeTime - originTime;
        }
        [detailedDurationDictionary setValue:@(rttTime) forKey:@"rtt"];
    }

    NSMutableDictionary *socketDictionary = [NSMutableDictionary dictionary];
    [socketDictionary setValue:@(record.sessionConnectReuse) forKey:@"socket_reused"];

    [timingDictionary setValue:requestDictionary forKey:@"request"];
    [timingDictionary setValue:detailedDurationDictionary forKey:@"detailed_duration"];
    
    NSMutableDictionary *otherDictionary = [NSMutableDictionary dictionary];
    [otherDictionary setValue:record.clientType forKey:@"libcore"];
    [otherDictionary setValue:@"1" forKey:@"is_main_process"];
    
    NSMutableDictionary *headerDictionary = [NSMutableDictionary dictionary];
    [headerDictionary setValue:record.ttTraceID forKey:@"x-tt-trace-id"];
    [headerDictionary setValue:record.ttTraceHost forKey:@"x-tt-trace-host"];
    [headerDictionary setValue:record.ttTraceTag forKey:@"x-tt-trace-tag"];
    [headerDictionary setValue:record.contentEncoding forKey:@"x-tt-content-encoding"];
    
    [logDictionary setValue:otherDictionary forKey:@"other"];
    [logDictionary setValue:timingDictionary forKey:@"timing"];
    [logDictionary setValue:baseDictionary forKey:@"base"];
    [logDictionary setValue:responseDictionary forKey:@"response"];
    [logDictionary setValue:headerDictionary forKey:@"header"];
    [logDictionary setValue:socketDictionary forKey:@"socket"];

    if (logDictionary) {
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:logDictionary options:NSJSONWritingPrettyPrinted error:&error];
        if (data) {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    return @"";
}

+ (NSInteger) httpRecordServerTimingItemToInt:(NSString *)timeString  {
    NSInteger timeInt = [timeString integerValue];
    return timeInt < 0 ? -1 : timeInt;
}

+ (NSInteger)getHitRulesWithInAllowList:(BOOL)inAllowList {
    NSInteger hitRules = HMDHTTPTrackerHitRuleNone;
    if ([HMDHTTPRequestTracker sharedTracker].trackerConfig.enableAPIAllUpload || inAllowList) {
        hitRules = hitRules | HMDHTTPTrackerHitRuleAPIAll;
    }
    return hitRules;
}

+ (NSArray *)getHitRulesTagsArrayWithHitRulesTages:(NSArray <NSString *> *)originHitRulesTags {

    NSMutableArray *hitRulesTags = [NSMutableArray array];
    if (originHitRulesTags && originHitRulesTags.count > 0) {
        [hitRulesTags addObjectsFromArray:originHitRulesTags];
    }
    if ([HMDHTTPRequestTracker sharedTracker].trackerConfig.enableAPIAllUpload) {
        [hitRulesTags hmd_addObject:@"api_all"];
    }
    return [hitRulesTags copy];
}


@end
