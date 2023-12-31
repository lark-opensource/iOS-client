//
//  EMALifeCycleManager.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/4/22.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

typedef enum : NSUInteger {
    EMALifeCycleErrorCodeUnknown = 0,               // msg: unknown
    EMALifeCycleErrorCodeMetaInfoFail = 1,          // msg: meta_info_fail
    EMALifeCycleErrorCodeAppDownloadFail = 2,       // msg: app_download_fail
    EMALifeCycleErrorCodeOffline = 3,               // msg: offline
    EMALifeCycleErrorCodeJSSDKOld = 4,              // msg: jssdk_old
    EMALifeCycleErrorCodeServiceDisabled = 5,       // msg: service_disabled
    EMALifeCycleErrorCodeEnvironmentInvalid = 6,    // msg: environment_invalid
} EMALifeCycleErrorCode;

@interface EMALifeCycleBlockCallback : NSObject

/// 继续加载
- (void)continueLoading;

/// 取消加载（自动退出小程序）
- (void)cancelLoading;

@end

@class BDPModel;

@protocol EMALifeCycleListener <NSObject>

@optional

/// 小程序UI容器加载完成
- (void)onContainerLoaded:(BDPUniqueID *)uniqueID container:(UIViewController *)container;

/// 小程序开始加载
- (void)onStart:(BDPUniqueID * _Nonnull)uniqueID;

/// before小程序DomReady&setup完成
- (void)beforeLaunch:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序DomReady&setup完成
- (void)onLaunch:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序在onLaunch之前就取消
- (void)onCancel:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序 app-service.js 代码下载完成，开始加载之前
- (void)beforeLoadAppServiceJS:(nonnull BDPUniqueID *)uniqueID;

/// 小程序 page-frame.js 代码下载完成，开始加载之前
- (void)beforeLoadPageFrameJS:(nonnull BDPUniqueID *)uniqueID page:(NSInteger)appPageId;

/// 小程序 ${path}-frame.js 代码下载完成，开始加载之前
- (void)beforeLoadPageJS:(BDPUniqueID * _Nonnull)uniqueID page:(NSInteger)appPageId;

/// 小程序页面DomReady
- (void)onPageDomReady:(BDPUniqueID * _Nonnull)uniqueID page:(NSInteger)appPageId;

/// 小程序页面Crash
- (void)onPageCrashed:(BDPUniqueID * _Nonnull)uniqueID page:(NSInteger)appPageId visible:(BOOL)visible;

/// 小程序首页渲染完成
- (void)onFirstFrameRender:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序获取appModal
/// @param uniqueID uniqueID
/// @param isSilenceFetched 是否异步更新
/// @param isModelCached model是否从缓存中读取
/// @param appModel appModel
/// @param error error
- (void)onModelFetchedForUniqueID:(BDPUniqueID * _Nonnull)uniqueID isSilenceFetched:(BOOL)isSilenceFetched isModelCached:(BOOL)isModelCached appModel:(BDPModel * _Nullable)appModel error:(NSError * _Nullable)error;

/// 小程序包下载完成
- (void)onPkgFetched:(BDPUniqueID * _Nonnull)uniqueID error:(NSError * _Nullable)error;

/// 小程序从后台切回
- (void)onShow:(BDPUniqueID * _Nonnull)uniqueID startPage:(NSString * _Nullable) startPage;

/// 小程序进入后台
- (void)onHide:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序内存回收
- (void)onDestroy:(BDPUniqueID * _Nonnull)uniqueID;

/// 小程序加载失败
- (void)onFailure:(BDPUniqueID * _Nonnull)uniqueID code:(EMALifeCycleErrorCode)code msg:(NSString * _Nullable)msg;

/// 小程序onMeta前提供外部block的机会
- (void)blockLoading:(BDPUniqueID * _Nonnull)uniqueID startPage:(NSString * _Nullable) startPage callback:(EMALifeCycleBlockCallback * _Nonnull)callback;

/// 小程序容器首次viewDidAppear
- (void)onFirstAppear:(OPAppUniqueID *)uniqueID;

@end

@interface EMALifeCycleManager : NSObject

@property (nonatomic, copy, readonly, nullable) NSSet<BDPUniqueID *> *currentApps;          // 当前正在运行的小程序
@property (nonatomic, copy, readonly, nullable) BDPUniqueID *currentUniqueID;               // 最后一个正在最顶层运行的小程序
@property (nonatomic, copy, readonly, nullable) NSString *currentAppVersion;                // 最后一个正在最顶层运行的小程序版本
@property (nonatomic, copy, readonly, nullable) NSString *currentAppSceneCode;              // 最后一个正在最顶层运行的小程序场景值
@property (nonatomic, copy, readonly, nullable) NSString *currentAppSubSceneCode;           // 最后一个正在最顶层运行的小程序子场景值
@property (nonatomic, copy, readonly, nullable) NSString *currentContextID;                 // 当前小程序上下文，用于埋点追踪，通过一些计算方式保证唯一性（UUID）。

+ (nonnull instancetype)sharedInstance;

- (void)addListener:(id<EMALifeCycleListener> _Nonnull)listener forUniqueID:(BDPUniqueID * _Nonnull)uniqueID;

- (void)addListener:(id<EMALifeCycleListener> _Nonnull)listener;

- (void)removeListener:(id<EMALifeCycleListener> _Nonnull)listener;

/**
 通过uniqueID彻底杀掉小程序

 @param uniqueID uniqueID
 */
- (void)closeMicroAppWithUniqueID:(BDPUniqueID * _Nonnull)uniqueID;

@end
