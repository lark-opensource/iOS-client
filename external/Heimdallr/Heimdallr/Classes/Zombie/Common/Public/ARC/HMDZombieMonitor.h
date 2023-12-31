//
//  HMDZombieMonitor.h
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMDZombieDefines.h"
#import "HeimdallrModule.h"
#import "HMDZombieTrackerConfig.h"


@interface HMDZombieMonitor : HeimdallrModule


@property (nonatomic, strong, readonly, nullable)HMDZombieTrackerConfig * zombieConfig;
// 当前状态
@property (nonatomic, assign, readonly) BOOL isMonitor;
// 检测类型 默认HMDZombieTypeDefault
@property (nonatomic, assign) HMDZombieType monitorType;
// 缓存大小 默认10MB
@property (nonatomic, assign) NSUInteger maxCacheSize;
// 检测数量 默认80 * 1024
@property (nonatomic, assign) NSUInteger maxCacheCount;

/* 监控CF对象，默认NO，无法热生效，需重启监控;
 由于现有监控CF对象，可能触发崩溃，这里仅在debug环境生效，release环境失效！！！
 */
@property (nonatomic, assign) BOOL needMonitorCFObject;
// 监测到zombie时是否触发crash，默认YES
@property (nonatomic, assign) BOOL crashWhenDetectedZombie;
// 自定义回调
@property (nonatomic, copy) void (^ _Nullable detectedHandle)(NSString * _Nonnull originalClassName, NSString * _Nonnull currentCallSel);

// 单例
+ (instancetype _Nonnull )sharedInstance;

// 根据上次运行app的配置来控制是否开启，无需手动开启关闭
//// 开始监控
//- (void)startMonitor;
//// 停止监控
//- (void)stopMonitor;
// 清空缓存
- (void)cleanupZombieCache;

@end

