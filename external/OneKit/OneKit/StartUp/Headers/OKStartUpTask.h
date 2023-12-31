//
//  OKStartUpTask.h
//  OKStartUp
//
//  Created by bob on 2020/1/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger OKStartUpTaskPriority NS_TYPED_ENUM;

FOUNDATION_EXTERN OKStartUpTaskPriority const OKStartUpTaskPriorityDefault; /// 默认优先级
FOUNDATION_EXTERN OKStartUpTaskPriority const OKStartUpTaskPriorityLow; /// 低优先级
FOUNDATION_EXTERN OKStartUpTaskPriority const OKStartUpTaskPriorityHigh; /// 高优先级


/// 自定义Task 参考如下,在OKAppAddStartUpTaskFunction中
/// 仅做简单配置，请勿进行耗时操作
///
/**
#import <OneKit/OKStartUpGaia.h>
#import <OneKit/OKStartUpTask.h>
 
 OKAppAddStartUpTaskFunction() {
    task = xx
    task.xx = xxx
    [task scheduleTask];
 }
 */

@interface OKStartUpTask : NSObject

@property (nonatomic, assign) OKStartUpTaskPriority priority;       /// default 0,优先级高的先执行
@property (nonatomic, copy) NSString *taskIdentifier;   /// default =className
@property (nonatomic, assign) BOOL enabled; /// default YES，用于可以配置下掉该模块

/// OKStartUpTask 执行之前和之后的自定义block。执行顺序如下图示。增加这两个block是方便业务扩展
/**
    customTaskBeforeBlock();
    -[OKStartUpTask startWithLaunchOptions:]
    customTaskAfterBlock();
 */
@property(nonatomic, copy, nullable) dispatch_block_t customTaskBeforeBlock;
@property(nonatomic, copy, nullable) dispatch_block_t customTaskAfterBlock;

- (void)start __deprecated_msg("已过期，为了兼容性保留。继承说明：派生类只实现`startWithLaunchOptions:`即可。");

- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions;

- (void)scheduleTask NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
