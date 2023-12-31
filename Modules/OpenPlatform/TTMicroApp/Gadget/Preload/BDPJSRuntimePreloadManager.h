//
//  BDPJSRuntimePreloadManager.h
//  Timor
//
//  Created by liubo on 2019/8/22.
//

#import "BDPJSRuntime.h"

@interface BDPJSRuntimePreloadManager : NSObject

/// 是否应该预加载 tma-core。 default 是 NO。
@property (nonatomic, assign) BOOL shouldPreloadRuntimeApp;

@property (nonatomic, strong, readonly) id<OPMicroAppJSRuntimeProtocol> preloadRuntimeApp;

+ (instancetype)sharedManager;

#pragma mark - Obtain New Runtime

/**
 @brief         获取一个可用的JSRuntime,如果没有预加载好的,则直接创建新的.
 @return        一个可用的JSRuntime
 */
- (id<OPMicroAppJSRuntimeProtocol>)runtimeWithUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate;

#pragma mark - Preload & Release Runtime

/**
 @brief         根据 Type 类型预加载 JSRuntime
 @param type         创建预加载 JSRuntime 的类型 (目前仅 NativeApp 有效)
 */
- (void)preloadRuntimeIfNeed:(BDPType)type;

/**
@brief         根据 Type 释放掉已经预加载 JSRuntime
@param type         释放预加载 JSRuntime 的类型 (目前仅 NativeApp 有效)
*/
- (void)releasePreloadRuntimeIfNeed:(BDPType)type;

/// 释放所有预加载的Runtime
+ (void)tryReleaseAllPreloadRuntime;


/// 释放preload 对象，需要给出
/// @param releaseReason <#releaseReason description#>
+ (void)releaseAllPreloadRuntimeWithReason:(NSString * _Nonnull)releaseReason;


/// 更新释放原因，warning: 只给调用releasePreloadRuntimeIfNeed 方法使用,该方法会触发预加载，释放原因也是预加载原因
/// 其他释放使用：releaseAllPreloadRuntimeWithReason 这个方法
/// 如果当前有预加载对象，或者在预加载中，就更新被释放原因；
/// @param releaseReason 释放原因:
- (void)updateReleaseReason:(NSString * _Nonnull)releaseReason;

/// 预加载来源
/// @param preloadFrom 预加载来源
- (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom;

/// js runtime 预加载状态相关信息
- (NSDictionary<NSString *, id> * _Nonnull)runtimePreloadInfo;

@end
