//
//  BDPLifeCyclePluginDelegate.h
//  Timor
//
//  Created by yinyuan on 2019/4/22.
//

#ifndef BDPLifeCyclePluginDelegate_h
#define BDPLifeCyclePluginDelegate_h

#import "BDPBasePluginDelegate.h"

@class BDPModel, BDPUniqueID, OPMonitorCode;

/**
 * 小程序生命周期监听
 */
@protocol BDPLifeCyclePluginDelegate <BDPBasePluginDelegate>

@optional

/// 小程序UI容器创建加载完成
- (void)bdp_onContainerLoaded:(nonnull BDPUniqueID *)uniqueID container:(UIViewController *)container;

/// 小程序开始加载
- (void)bdp_onStart:(nonnull BDPUniqueID *)uniqueID;

/// before小程序DomReady&setup完成
- (void)bdp_beforeLaunch:(nonnull BDPUniqueID *)uniqueID;

/**
 * 小程序启动加载进度
 * @param uniqueID uniqueID
 * @param progress 小程序加载进度(0.0~1.0)
 */
- (void)bdp_onLoading:(nonnull BDPUniqueID *)uniqueID progress:(CGFloat)progress;

/// 小程序DomReady&setup完成
- (void)bdp_onLaunch:(nonnull BDPUniqueID *)uniqueID;

/// 小程序在onLaunch之前就取消
- (void)bdp_onCancel:(nonnull BDPUniqueID *)uniqueID;

/// 小程序 app-service.js 代码下载完成，开始加载之前
- (void)bdp_beforeLoadAppServiceJS:(nonnull BDPUniqueID *)uniqueID;

/// 小程序 page-frame.js 代码下载完成，开始加载之前
- (void)bdp_beforeLoadPageFrameJS:(nonnull BDPUniqueID *)uniqueID page:(NSInteger)appPageId;

/// 小程序 ${path}-frame.js 代码下载完成，开始加载之前
- (void)bdp_beforeLoadPageJS:(nonnull BDPUniqueID *)uniqueID page:(NSInteger)appPageId;

/// 小程序页面代码加载完成DomReady
- (void)bdp_onPageDomReady:(nonnull BDPUniqueID *)uniqueID page:(NSInteger)appPageId;

/// 小程序页面Crash
- (void)bdp_onPageCrashed:(BDPUniqueID * _Nonnull)uniqueID page:(NSInteger)appPageId visible:(BOOL)visible;

/// 小程序首帧渲染完成
- (void)bdp_onFirstFrameRender:(nonnull BDPUniqueID *)uniqueID;

/// 小程序获取appModal
/// @param uniqueID uniqueID
/// @param isSilenceFetched 是否异步更新
/// @param isModelCached model是否从缓存中读取
/// @param appModel appModel
/// @param error error
- (void)bdp_onModelFetchedForUniqueID:(nonnull BDPUniqueID *)uniqueID isSilenceFetched:(BOOL)isSilenceFetched isModelCached:(BOOL)isModelCached appModel:(nonnull BDPModel *)appModel error:(nullable NSError *)error;

/// 小程序包下载完成
- (void)bdp_onPkgFetched:(nonnull BDPUniqueID *)uniqueID error:(nullable NSError *)error;

/// 小程序从后台切回
- (void)bdp_onShow:(nonnull BDPUniqueID *)uniqueID startPage:(nullable NSString *)startPage;

/// 小程序进入后台
- (void)bdp_onHide:(nonnull BDPUniqueID *)uniqueID;

/// 小程序内存回收
- (void)bdp_onDestroy:(nonnull BDPUniqueID *)uniqueID;

/// 小程序加载失败
- (void)bdp_onFailure:(nonnull BDPUniqueID *)uniqueID code:(nonnull OPMonitorCode *)code msg:(nonnull NSString *)msg;

/// 小程序onMeta前提供外部block的机会
- (void)bdp_blockLoading:(nonnull BDPUniqueID *)uniqueID startPage:(nullable NSString *)startPage continueCallback:(nonnull void(^ _Nonnull)(void))continueCallback cancelCallback:(nonnull void(^ _Nonnull)(OPMonitorCode * _Nullable reason))cancelCallback;

/// 小程序容器首次Appear
- (void)bdp_onFirstAppear:(nullable BDPUniqueID *)uniqueID;

@end

#endif /* BDPLifeCyclePluginDelegate_h */
