//
//  BDPTask.h
//  Timor
//
//  Created by muhuai on 2017/11/7.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPAppPage.h"
#import "BDPAppPageManager.h"
#import "BDPAppPageURL.h"
#import "BDPJSRuntime.h"
#import <OPFoundation/BDPModel.h>
#import "BDPPerformanceMonitor.h"
#import <OPFoundation/BDPSchema.h>
#import "BDPToolBarManager.h"
#import <OPFoundation/BDPUniqueID.h>
#import "OPMicroAppJSRuntimeProtocol.h"

@class BDPWebComponentChannelManager;
@class NativeComponentConfigManager;

/**
 * 小程序任务核心抽象，每个小程序运行实例对应一个task。主要成员BDPUniqueID、BDPJSRuntime。
 */
@interface BDPTask : NSObject

// Common
@property (nonatomic, strong, readonly, nullable) BDPUniqueID *uniqueID;
@property (nonatomic, strong, readonly, nullable) id<OPMicroAppJSRuntimeProtocol> context;
@property (nonatomic, strong, readonly, nullable) BDPToolBarManager *toolBarManager;

@property (nonatomic, weak, nullable) UIViewController<BDPlatformContainerProtocol> *containerVC;

// Game
@property (nonatomic, assign, getter=isHideShareMenu) BOOL hideShareMenu;  // 是否显示分享menu按钮, for game

// App
@property (nonatomic, strong, nullable) BDPAppPageURL *currentPage;
@property (nonatomic, strong, readonly, nullable) BDPAppConfig *config;
@property (nonatomic, strong, readonly, nullable) BDPAppPageManager *pageManager;
@property (nonatomic, strong, readonly, nullable) WKProcessPool *processPool;
@property (nonatomic, assign) BOOL showGoHomeButton;

@property (nonatomic, weak, readonly, nullable) OPContainerContext *containerContext;

/// 是否被被接管了退出事件
@property (nonatomic, assign) BOOL takeoverExitEvent;


/// 稳定性和性能打点管理类
@property (nonatomic, strong, nullable) BDPPerformanceMonitor<BDPAppTiming> *performanceMonitor;
@property (nonatomic, assign) BOOL hasLaunchingReported;    // 启动结果是否已经上报

// webview组件 与 小程序 双向通信 channel
/// todo: 后续PM以小程序级别接入之后，将迁移到PM里 @doujian
@property (nonatomic, strong, readonly) BDPWebComponentChannelManager *channelManager;

@property (nonatomic, strong, nullable) NativeComponentConfigManager *componentConfigManager;


/// 通过schema 和 container创建BDPTask，这个是用于在还没有model和configData的时候，需要预先生成BDPTask的场景。
/// 比如说在vdom渲染的场景。 但是当有model 和 configData的时候，需要通过 updateTaskWithModel:configData 更新。
/// @param schema 小程序的schema
/// @param uniqueID 小程序的uniqueID
/// @param containerVC 该小程序的baseVC
- (instancetype)initWithSchema:(BDPSchema *)schema
                      uniqueId:(BDPUniqueID *)uniqueID
                   containerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
              containerContext:(OPContainerContext *)containerContext;

/// BDPTask创建的正确姿势。
/// @param model 小程序modal
/// @param configDict 小程序的配置信息，
/// @param schema 小程序的schema
/// @param containerVC 该小程序的baseVC
- (instancetype)initWithModel:(BDPModel *)model
                   configDict:(NSDictionary *)configDict
                       schema:(BDPSchema *)schema
                  containerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
             containerContext:(OPContainerContext *)containerContext;

/// 首帧前可以被延迟的操作, 可以放到这里边
- (void)doImportantOperations;

/// 通过model 和 configData更新Task。
/// 目前这个方法需要配合 initWithSchema:uniqueID:containerVC: 的方法使用，
/// @param model 小程序modal
/// @param configDict 小程序的配置信息，
- (void)updateWithModel:(BDPModel *)model configDict:(NSDictionary *)configDict;

@end
