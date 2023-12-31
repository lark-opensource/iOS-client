//
//  HMDCPUExceptionMonitor.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/4/23.
//

#import "HeimdallrModule.h"
#import "HMDCPUExceptionConfig.h"


@interface HMDCPUExceptionMonitor : HeimdallrModule

+ (nonnull instancetype)sharedMonitor;

/// 进入用户的特定场景, 使用指定的配置
/// @param config 用户在当前场景下的特殊配置
- (void)enterSpecificalSceneWithExceptionConfig:(nonnull HMDCPUExceptionConfig *)config;

/// 用户离开当前的特定的场景
- (void)leaveSpecificalScene;

- (void)enterCustomSceneWithUniq:(NSString *_Nonnull)scene;
- (void)leaveCustomSceneWithUniq:(NSString *_Nonnull)scene;

@end


