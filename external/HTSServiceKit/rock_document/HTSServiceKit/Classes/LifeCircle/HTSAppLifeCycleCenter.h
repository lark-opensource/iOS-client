//
//  HTSAppLifeCycleCenter.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTSAppLifeCycle.h"

NS_ASSUME_NONNULL_BEGIN

/// 一对多的关系
@interface HTSAppLifeCycleCenter : NSObject<HTSAppLifeCycle>

+ (instancetype)sharedCenter;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
