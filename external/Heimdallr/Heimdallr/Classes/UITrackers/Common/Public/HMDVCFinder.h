//
//  HMDVCFinder.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/6/4.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface HMDVCFinder : NSObject

#pragma mark - 当前的 UIViewController 信息

@property(class, readonly, nonnull) __kindof HMDVCFinder *finder;   // 单例在这里

@property(atomic, readonly, nullable) NSString *scene;                        // 留给 KVO 的地方
@property(atomic, readonly, nullable) NSString *previousScene;                // 留给 KVO 的地方

@property(atomic, readonly, nullable) NSString *sceneWithUpdate;              // 在紧急情况下直接刷新访问【 不要 KVO 这是无效的 】

- (void)triggerUpdate;                                              // 动态刷新
- (void)triggerUpdateImmediately;                                   // 无需延时，将动态刷新操作立刻放入主队列，解决第一次上报场景为 unknown 的问题

@property(atomic, readonly, nullable) void *scene_vc_unsafe;                  // 专门为 heimdallr 定制参数 ⚠️ 业务方不可以用

@end


