//
//  OPMonitorFlushTask.h
//  ECOProbe
//
//  Created by qsc on 2021/5/23.
//

#import <Foundation/Foundation.h>
@class OPMonitorEvent;

NS_ASSUME_NONNULL_BEGIN

typedef void (^FlushTaskBlock)(OPMonitorEvent * _Nullable);

@interface OPMonitorFlushTask : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) FlushTaskBlock task;

/// FlushTask，在 OPMonitor.flush() 前会被调用
- (instancetype)initTaskWithName:(NSString *)name task:(FlushTaskBlock) task;

/// 禁用默认初始化方法
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


/// 执行 task
/// @param monitor task 入参，task 可操作传入的 monitor 
- (void)executeOnMonitor:(OPMonitorEvent *)monitor;

@end

NS_ASSUME_NONNULL_END
