//
//  HTSBootTask.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSBootLoader+Private.h"
#import "HTSBootInterface.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HTSBootNode <NSObject>

/// 执行
- (void)run;

/// 主线程
@property (readonly) BOOL isMainThread;

@end

typedef NSArray<id<HTSBootNode>> HTSBootNodeList;

/// 启动任务
@interface HTSBootNode : NSObject<HTSBootNode>

/// 根据配置初始化
- (instancetype)initWithDictionary:(NSDictionary *)dic;

/// 任务的id，用来做数据统计
@property (readonly) NSString * uniqueId;

/// 任务的描述
@property (readonly) NSString * desc;

/// 是否是主线程执行
@property (readonly) BOOL isMainThread;

/// 实现HTSBootTask的类
@property (readonly) Class<HTSBootTask> taskClass;

- (void)run;

@end

NS_ASSUME_NONNULL_END
