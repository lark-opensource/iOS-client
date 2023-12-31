//
//  HTSBootInterface+Private.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/18.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSBootInterface.h"

NS_ASSUME_NONNULL_BEGIN


/// 如果非后台启动，那么立刻执行；如果是后台启动，回前台的时候执行
FOUNDATION_EXPORT void HTSBootRunNowOrEnterForground(HTSBootThread thread,void(^block)(void));

/// 通知后台启动回前台了
FOUNDATION_EXPORT void _HTSBootNotifyFirstEnterFourground(void);



NS_ASSUME_NONNULL_END
