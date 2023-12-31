//
//  ACCTimingManager.h
//  ACCFoundation
//
//  Created by Stan Shan on 2018/6/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACCTimingManager : NSObject

+ (instancetype)sharedInstance;

/// 开始计时，如果key与已存在的key冲突则覆盖已存在的key
- (void)startTimingForKey:(id<NSCopying>)key;

/// 查看已有key对应的时间(毫秒)
- (NSTimeInterval)timeIntervalForKey:(id<NSCopying>)key;

/// 停止计时，并清除计时标记
- (NSTimeInterval)stopTimingForKey:(id<NSCopying>)key;

/// 取消计时
- (void)cancelTimingForKey:(id<NSCopying>)key;

@end

/// 开始计时
#define ACC_TICK(key) [[ACCTimingManager sharedInstance] startTimingForKey:key]

/// 停止计时，并清除key
#define ACC_TOCK(key) [[ACCTimingManager sharedInstance] stopTimingForKey:key]

/// 取消计时(TODO: deprecated @shanshuo)
#define ACC_CANCEL_TIMING(key) [[ACCTimingManager sharedInstance] cancelTimingForKey:key]
