//
//  Heimdallr+ModuleCallback.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/17.
//

#import "Heimdallr.h"
#import "HeimdallrModule.h"

/// 在该模块启动之前 module 可能为 nil 望注意 ⚠️
typedef void (^ HMDModuleCallback)(id<HeimdallrModule> _Nullable module,
                                  BOOL isWorking);

@interface Heimdallr (ModuleCallback)

/**
 监控一个 Module 生命周期的 开启/关闭

 @param moduleName 监听模块名称
 @param callback 异步回调的方法, 当返回之前会立即调用一次, 之后每次改变都会调一次
 @return 一个观察者令牌 参考NSNotification 用它来移除 observer
 */
- (id<NSObject> _Nullable)addObserverForModule:(NSString * _Nullable)moduleName usingBlock:(HMDModuleCallback _Nullable)callback;

- (void)removeObserver:(id<NSObject> _Nullable)blockIdentifier;

@end
