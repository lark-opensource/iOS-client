//
//  WKWebView+PublicInterface.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/7/28.
//

#import "WKWebView+PublicInterface.h"
#import "BDWebView+BDWebViewMonitor.h"
#import "IESLiveWebViewPerformanceDictionary.h"
#import "BDMonitorThreadManager.h"

@implementation WKWebView (PublicInterface)

- (void)updatePerfExt:(BDWebViewMonitorPerfExtType)perfExtType withValue:(BDWebViewMonitorPerfExtValue)perfExtValue {
    switch (perfExtType) {
        case BDWebViewMonitorPerfExtType_preloadContainer:
            self.performanceDic.bdwm_isPreload = (int)perfExtValue;
            break;
            
        case BDWebViewMonitorPerfExtType_prefetchData:
            self.performanceDic.bdwm_isPrefetch = (int)perfExtValue;
            break;
            
        case BDWebViewMonitorPerfExtType_isOffline:
            self.performanceDic.bdwm_isOffline = (int)perfExtValue;
            break;
            
        default:
            break;
    }
}

- (void)chooseReportTime:(BDWebViewPerfReportTime)reportTime {
    NSUInteger tt = (NSUInteger)reportTime;
    self.performanceDic.bdwm_reportTime = (BDWebViewMonitorPerfReportTime)tt;
}

- (void)customTriggerReportPerf {
    if (self.performanceDic.bdwm_reportTime == BDWebViewMonitorPerfReportTime_Custom) {
        [self.performanceDic reportCurrentNavigationPagePerf];
    }
}

- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block {
    if (block) {
        id copyBlock = [block copy];
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            [self.performanceDic.contextBlockList addObject:copyBlock];
        }];
    }
}

- (void)attachContainerUUID:(NSString *)containerUUID {
    if (containerUUID) {
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            [self.performanceDic.containerUUIDList addObject:containerUUID];
        }];
    }
}

- (void)attachVirtualAid:(NSString *)virtualAid {
    self.performanceDic.bdwm_virtualAid = virtualAid;
}

- (void)reportContainerError:(NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(NSString *)msg bizTag:(NSString *)bizTag {
    [self.performanceDic reportContainerError:virtualAid errorCode:code errorMsg:msg bizTag:bizTag];
}

- (NSString *)fetchVirtualAid {
    return self.performanceDic.bdwm_virtualAid;
}

- (NSString *)bdlm_fetchCurrentUrl {
    return [self.performanceDic fetchCurrentUrl];
}

- (NSString *)bdlm_fetchBizTag {
    return [self.performanceDic fetchBizTag];
}

@end
