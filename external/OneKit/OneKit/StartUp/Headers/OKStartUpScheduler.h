//
//  OKStartUpScheduler.h
//  OKStartUp
//
//  Created by bob on 2020/1/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OKStartUpTask;

/// must call from main thread
@interface OKStartUpScheduler : NSObject

+ (instancetype)sharedScheduler;

+ (void)setSyncTaskIdentifiers:(NSArray<NSString *> *)identfiers;

- (void)addTask:(OKStartUpTask *)task;

/// 调度各启动任务执行
- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions;

@end

NS_ASSUME_NONNULL_END
