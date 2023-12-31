//
//  EMADebugLaunchTracing.h
//  EEMicroAppSDK
//
//  Created by Limboy on 2020/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMADebugLaunchTracing : NSObject

+ (instancetype)sharedInstance;

- (void)updateDebugConfig;

- (void)processIfNeeded:(NSString *)name attributes:(NSDictionary *)attributes;

// 主要用于调试阶段可视化查看启动的 Tracing 信息
- (void)launchTracingStart;
// 如果没有传 tid 和 pid，默认使用「当前线程名字」和「Main」
- (void)launchTracingWithName:(NSString *)name attributes:(NSDictionary *)attributes;
// tid 可以将一类事件串起来
- (void)launchTracingWithName:(NSString *)name
                               tid:(NSString *)tid
                        attributes:(NSDictionary *)attributes;
// pid 可以表示某个大类，tid 表示该x类下的更小的单元
- (void)launchTracingWithName:(NSString *)name
                               pid:(NSString *)pid
                               tid:(NSString *)tid
                        attributes:(NSDictionary *)attributes;
- (void)launchTracingStop;
@end

NS_ASSUME_NONNULL_END
