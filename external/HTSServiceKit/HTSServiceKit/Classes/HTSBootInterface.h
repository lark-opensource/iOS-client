//
//  HTSBootInterface.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/26.
//  Copyright © 2019 bytedance. All rights reserved.
//

#ifndef HTSBootInterface_h
#define HTSBootInterface_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 标记启动任务
@protocol HTSBootTask <NSObject>

+ (void)execute;

@end

typedef NS_ENUM(NSInteger,HTSBootThread){
    HTSBootThreadMain,
    HTSBootThreadBackground
};

/// 延迟到feedready执行，如果阶段过了那么立刻执行
FOUNDATION_EXPORT void HTSBootRunFeedReady(HTSBootThread thread, void(^block)(void));
/// 延迟到启动结束执行执行，如果阶段过了那么立刻执行
FOUNDATION_EXPORT void HTSBootRunLaunchCompletion(HTSBootThread thread,void(^block)(void));
/// 标记FeedReady
FOUNDATION_EXPORT void HTSBootMarkFeedReady(void);
/// 标记启动结束
FOUNDATION_EXPORT void HTSBootMarkLaunchCompletion(void);

FOUNDATION_EXPORT BOOL HTSIsLaunchCompletionAutoMarked(void);

NS_ASSUME_NONNULL_END

#endif /* HTSBootInterface_h */
