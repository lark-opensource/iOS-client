//
//  NSObject+MemoryUse.h
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/2/19.
//  Copyright © 2019 zeposhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HMDThreadBacktrace;

@interface TTMLFObjectWrapper : NSObject

@property (nonatomic, strong) HMDThreadBacktrace *backtrace;

@property (nonatomic, weak) id objWeakRef;

@end

@interface NSObject (TTUseCount)

// 开始统计每种class的实例个数
+ (void)tt_startMonitorInsOfClasses:(NSArray<Class>*)classes;

+ (void)tt_stopMonitorInsOfClasses:(NSArray<Class>*)classes;

+ (void)tt_stopMonitor;

/**
 Description
获取某种class的实例个数
 @param cls 要获取的classs
 @param completion 返回class实例的数组，其中实例以TTObjectWrapper装箱
 */
+ (void)tt_getInsOfClass:(Class)cls
           completion:(void(^)(NSArray<TTMLFObjectWrapper*>*))completion;

/**
 周期性上报监控结果（注：内部会调用startMonitor，开启相关类的监控）

 @param classes 要上报的class列表
 @param interval 上报间隔时间（周期）
 @param reportBlock 上报的回调
 */
+ (void)tt_reportInsOfClasses:(NSArray<Class>*)classes
            reportInterval:(NSTimeInterval)interval
               reportBlock:(void(^)(Class cls, NSArray<TTMLFObjectWrapper*>*))reportBlock;

@end

NS_ASSUME_NONNULL_END
