//
//  HMDSDKInjected.h
//  Heimdallr-iOS13.0
//
//  Created by zhangxiao on 2019/10/31.
//

#import <Foundation/Foundation.h>
#import "HMDTTMonitorUserInfo.h"

@class HMDTTMonitor;



@interface HMDSDKMonitorManager : NSObject

+ (nonnull instancetype)sharedInstance;
#pragma mark --- sdk_aid 初始化SDK监控的方法
/// 初始化 SDKMonitor 监控 该监控包含:SDK 的事件监控和网络监控,如果只使用事件监控,请使用 HMDTTMonitor 的SDK 监控 ; 每次初始化该方法都会产生一个 TTMonitor 的实例;  使用详情请参考:https://slardar.bytedance.net/docs/115/150/23421/
/// @param sdkAid sdk_aid
/// @param userInfo sdk 监控的一些初始化内容
/// @param products 产物, 初始化 sdk 后获取到的SDK 对应的事件监控实例,每次都会重新生成一个 HMDTTMonitor 的实例; 目前只暴露了 事件监控
- (void)setupSDKMonitorWithSDKAid:(nonnull NSString *)sdkAid monitorUserInfo:(nonnull HMDTTMonitorUserInfo *)userInfo productions:(nullable void(^)(HMDTTMonitor *_Nullable))products;

@end


