//
//  LynxView+PublicInterface.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/10/21.
//

#import "LynxView+PublicInterface.h"
#import "LynxView+Monitor.h"
#import "IESLynxPerformanceDictionary.h"
#import "BDMonitorThreadManager.h"

@implementation LynxView (PublicInterface)

// 绑定kv到上报的nativebase中去，注意，此处配置建议kv都是用string类型，是可枚举的值，如bizId，ABTest等，避免识别问题，此处block会被持有，避免在内部使用webview造成循环引用。
- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block {
    id copyBlock = [block copy];
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        [self.performanceDic attachNativeBaseContextBlock:copyBlock];
    }];
}

// 绑定容器UUID到实例
- (void)attachContainerUUID:(NSString *)containerUUID {
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        [self.performanceDic attachContainerUUID:containerUUID];
    }];
}

// 上报ContainerError事件
- (void)reportContainerError:(NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(NSString *)msg bizTag:(NSString *)bizTag {
    [self.performanceDic reportContainerError:virtualAid errorCode:code errorMsg:msg bizTag:bizTag];
}

// 绑定虚拟aid到对应容器上
- (void)attachVirtualAid:(NSString *)virtualAid {
    self.performanceDic.bdwm_virtualAid = virtualAid;
}

- (NSString *)fetchVirtualAid {
    return self.performanceDic.bdwm_virtualAid;
}

- (NSString *)bdlm_fetchCurrentUrl {
    return [self.performanceDic fetchCurrentUrl];
}

@end
