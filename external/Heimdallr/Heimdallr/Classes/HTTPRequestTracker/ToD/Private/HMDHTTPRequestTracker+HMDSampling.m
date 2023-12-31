//
//  HMDHTTPRequestTracker+HMDSampling.m
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/6.
//

#import "HMDHTTPRequestTracker+HMDSampling.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDALogProtocol.h"
#import "HMDHTTPDetailRecord.h"
#import "NSString+HDMUtility.h"

@implementation HMDHTTPRequestTracker (HMDSampling)

- (BOOL)checkIfRequestCanceled:(NSURL *)url withError:(NSError *)error andNetType:(NSString *)netType {
    BOOL shouldIgnore = self.ignoreCancelError;
    BOOL cancelErrorHappened = error && error.code == NSURLErrorCancelled;
    if(shouldIgnore && cancelErrorHappened) {
        if (hmd_log_enable()) {
            NSString *cancelLog = [NSString stringWithFormat:@"net_type:%@, uri:%@ has been cancelled by purpose，errcode:-999", netType, url.absoluteString];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"%@",cancelLog);
        }
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)checkIfURLInBlockList:(NSURL *)url {
    HMDHTTPTrackerConfig *netMonitorConfig = self.trackerConfig;
    BOOL enableBaseApiAll = netMonitorConfig.baseApiAll.floatValue > 0;
    // 过滤本地测试接口和 base_api_all
    if ([url.host hasPrefix:@"10."] || [url.host hasPrefix:@"192.168."]) {
        return YES;
    } else if(enableBaseApiAll) {
        return NO;
    } else {
        return [netMonitorConfig isURLInBlockListWithSchme:url.scheme host:url.host path:url.path];
    }
}

- (BOOL)checkIfURLInWhiteList:(NSURL *)url {
    return [self.trackerConfig isURLInAllowListWithScheme:url.scheme host:url.host path:url.path];
}

- (void)sampleAllowHeaderToRecord:(HMDHTTPDetailRecord *)record withRequestHeader:(NSDictionary *)requestHeader andResponseHeader:(NSDictionary *)responseHeader isMovingLine:(BOOL)isMovingLine {
    HMDHTTPTrackerConfig *netMonitorConfig = self.trackerConfig;
    // V2 过滤 header allowList
    NSDictionary *requestAllowHeader = [netMonitorConfig requestAllowHeaderWithHeader:requestHeader isMovingLine:isMovingLine];
    if (requestAllowHeader) {
        record.requestHeader = [NSString hmd_stringWithJSONObject:requestAllowHeader];
    }

    NSDictionary *responseAllowHeader = [netMonitorConfig responseAllowHeaderWitHeader:responseHeader isMovingLine:isMovingLine];
    if (responseAllowHeader) {
        record.responseHeader = [NSString hmd_stringWithJSONObject:responseAllowHeader];
    }
}

- (void)sampleAllowHeaderToRecord:(HMDHTTPDetailRecord *)record withRequestHeader:(NSDictionary *)requestHeader andResponseHeader:(NSDictionary *)responseHeader {
    [self sampleAllowHeaderToRecord:record withRequestHeader:requestHeader andResponseHeader:responseHeader isMovingLine:NO];
}

@end
