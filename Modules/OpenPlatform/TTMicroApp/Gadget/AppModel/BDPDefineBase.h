//
//  BDPDefineBase.h
//  Timor
//
//  Created by CsoWhy on 2018/10/16.
//
#import <UIKit/UIKit.h>
#import <OPFoundation/BDPMacroUtils.h>
#import <OPFoundation/BDPModuleEngineType.h>

#ifndef BDPDefineBase_h
#define BDPDefineBase_h

#define kBundleSDKVersion               @"2.46.0"               // 客户端 - 开放平台SDK版本号

#define kBDPDebugVConsoleSwitchKey      @"vConsole"             // 调试开关 Key

#pragma mark - Enum
/* ------- 开放平台基础数据 - 枚举 ------- */

// TO: OPFoundation , BDPAppDefine.h
//typedef NS_ENUM(NSUInteger, BDPAppStatus) {
//    BDPAppStatusUnpublished = 0,                    // 小程序状态 - 未发布
//    BDPAppStatusNormal = 1,                         // 小程序状态 - 已发布
//    BDPAppStatusDisable = 2                         // 小程序状态 - 已下架
//};
//
//typedef NS_ENUM(NSUInteger, BDPAppVersionStatus) {
//    BDPAppVersionStatusNormal = 0,                  //  小程序版本状态 - 正常状态
//    BDPAppVersionStatusNoPermission = 1,            //  小程序版本状态 - 当前用户无权限访问小程序
//    BDPAppVersionStatusIncompatible = 2,            //  小程序版本状态 - 小程序不支持当前宿主环境
//    BDPAppVersionStatusPreviewExpired = 4           //  预览版二维码已过期（有效期1d）
//};
//
//typedef NS_ENUM(NSUInteger, BDPAppShareLevel) {
//    BDPAppShareLevelUnknown = 0,                    // 小程序分享级别 - 未指定
//    BDPAppShareLevelGrey = 1,                       // 小程序分享级别 - 灰名单
//    BDPAppShareLevelWhite = 2,                      // 小程序分享级别 - 白名单
//    BDPAppShareLevelBlack = 3                       // 小程序分享级别 - 黑名单
//};

typedef NS_ENUM(NSUInteger, GadgetMetaOritation) {
    GadgetMetaOritationNotSet,
    GadgetMetaOritationPortrait,
    GadgetMetaOritationLandscape,
    GadgetMetaOritationAuto
};

#pragma mark - Protocol
@class OPMonitorCode;
@class OPContainerContext;
/* ------- 开放平台基础能力 - 协议 ------- */
@protocol BDPlatformContainerProtocol <NSObject>

@required
- (void)dismissSelf:(OPMonitorCode *)code;

- (CGRect)getToolBarRect;     // 获取左上角胶囊组件位置，小游戏脱敏状态下，用于获取右边"更多"按钮位置
- (CGRect)getLeftToolBarRect; // 小游戏脱敏API，用于获取左边"退出"按钮的位置
- (UIView *)topView;

- (BOOL)applyUpdateIfNeed;

- (void)startAdaptOrientation;
- (void)endAdaptOrientation;

- (nullable OPContainerContext *)containerContext;

@optional
// 小程序真机调试
- (void)onSocketDebugConnected; // 连接建立
- (void)onSocketDebugDisconnected; // 连接断开
- (void)onSocketDebugPauseInspector; // 命中断点
- (void)onSocketDebugResumeInspector; // 断点继续
- (void)onSocketDebugConnectFailed; // 连接失败

// IDE性能调试
- (void)onSocketPerformanceConnected; // 连接建立
- (void)onSocketPerformanceDisconnected; // 连接断开
- (void)onSocketPerformanceConnectFailed; // 连接失败

@optional

// TODO: 没有被用到，需要删除
//- (void)dismissSelfAndClosePresentedVC:(NSString *)exitType;

@end


@class BDPAppPageURL, BDPModel, BDPTimorLaunchParam, BDPSchema, BDPBaseContainerController, BDPAppController;

/// 用于兼容旧容器的适配器，是整个小程序旧容器迁移新容器的脚手架协议，最终目标是彻底删除旧容器，但在彻底删除之前，需要该协议来支撑局部代码迁移
/// 该协议仅用于对旧代码的适配，不允许用于新功能开发
/// 该协议方法原则上需要逐步减少并最终彻底删除
@protocol OPGadgetContainerControllerAdapterProtocol <NSObject>

@required

@property (nonatomic, strong, nullable) BDPAppPageURL *startPage;

@property (nonatomic, copy, readonly, nullable) BDPSchema *schema;

@property (nonatomic, strong, readonly, nullable) BDPTimorLaunchParam *launchParam;

@property (nonatomic, strong, readonly, nullable) BDPAppController *appController;

@property (nonatomic, assign) BOOL backFromOtherMiniProgram;

//这个属性在重启前需要标记为YES，在发送exit通知的时候会有使用, 主端的常用面板会有依赖这个属性
@property (nonatomic, assign) BOOL willReboot;

- (BOOL)loadVdomWithModel:(nullable BDPModel *)localModel;

- (nonnull BDPBaseContainerController *)asBaseContainerController;

- (void)detectBlankWebview:(void (^ _Nullable)(BOOL, NSError * _Nullable))complete;

- (void)onApplicationExitWithRestoreStatus:(BOOL)restoreStatus;

/// 新容器Ready状态通知
- (void)newContainerDidFirstContentReady;

- (void)getUpdatedMetaInfoModelCompletion:(NSError * _Nullable)error model:(BDPModel * _Nullable)model;

- (void)getUpdatedPkgCompletion:(NSError * _Nullable)error model:(BDPModel * _Nullable)model;

@end

#endif /* BDPDefineBase_h */
