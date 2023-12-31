//
//  HTSBootConfiguration.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSBootNode.h"
NS_ASSUME_NONNULL_BEGIN

@interface HTSBootConfiguration : NSObject

/// 根据配置初始化
- (instancetype)initWithConfiguration:(NSDictionary *)dic;

/// 基础任务
@property (readonly) HTSBootNodeList * foundationList;

/// 只在后台启动执行的任务
@property (readonly) HTSBootNodeList * backgroundList;

/// 第一次到前台执行的任务
@property (readonly) HTSBootNodeList * firstFourgroundList;

/// 启动结束，主线程
@property (readonly) HTSBootNodeList * afterLaunchNowList;

/// 启动结束，后台线程
@property (readonly) HTSBootNodeList * afterLaunchIdleList;

/// feedReady，主线程
@property (readonly) HTSBootNodeList * feedReadyNowList;

/// feedReady，后台线程
@property (readonly) HTSBootNodeList * feedReadyIdleList;

@end

NS_ASSUME_NONNULL_END
