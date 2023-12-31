//
//  HMDMonitorCustomSwitch.h
//  Heimdallr
//
//  Created by bytedance on 2022/2/11.
//

#import <Foundation/Foundation.h>


/// 当宿主的enable_open为0时，部分sdk仍希望针对自己的业务自定义开启监控从而通过回调获取 record
@protocol HMDMonitorCustomSwitch <NSObject>

/// 当前有多少个业务成功调用了resume方法
@property(nonatomic, assign)int refCount;

/// 手动开启 Monitor
- (void)resume;

/// 手动关闭 Monitor
- (void)suspend;

@end

