//
//  HMDCrashLoadSync.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <Foundation/Foundation.h>

@interface HMDCrashLoadSync : NSObject

// 任何时间访问都是安全的单例
+ (instancetype _Nonnull)sync;

// 如果 CrashTracker 完成咯，那么调用 callback
- (void)tackerCallback;

// 是否 CrashLoad 正在启动 (begin)
@property(nonatomic, readonly) BOOL starting;

// 是否 CrashLoad 启动标记 (end)
@property(nonatomic, readonly) BOOL started;

#pragma mark - 以下内容需要在 HMDCrashLoadSync.sync.started = YES 前提下访问

@property(nonatomic, readonly, nullable) NSString *currentDirectory;

@end
