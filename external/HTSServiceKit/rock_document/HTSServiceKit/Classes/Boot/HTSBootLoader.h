//
//  HTSBootLoader.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSBootNodeGroup.h"
#import "HTSBootInterface.h"
#import "HTSAppContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 读取配置项，创建Stage
@interface HTSBootLoader : NSObject

/// 单例
+ (instancetype)sharedLoader;

/// 启动
- (void)bootWithConfig:(NSDictionary *)config;

/// 当前Node结束后挂起，只能在foundation阶段调用
- (BOOL)suspend;

/// 继续启动流程
- (void)resume;

/// 是否被挂起
@property(readonly) BOOL isSuspend;

@end

NS_ASSUME_NONNULL_END
