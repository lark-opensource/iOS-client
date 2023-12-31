//
//  BDPBaseContainerController.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import <UIKit/UIKit.h>
#import "BDPDefineBase.h"
#import "BDPNavigationController.h"
#import "BDPPresentAnimation.h"
#import <OPFoundation/BDPTimorClient.h>
#import "BDPTimorLaunchParam.h"
#import "BDPToolBarView.h"
#import "BDPWarmBootCleanerProtocol.h"

NS_ASSUME_NONNULL_BEGIN
/// 应用启动状态
typedef NS_ENUM(NSUInteger, BDPContainerBootType){
    BDPContainerBootTypeUnknown = 0,                // 未知启动状态
    BDPContainerBootTypeCold,                       // 冷启动状态
    BDPContainerBootTypeWarm,                       // 热启动状态
};

@class BDPModel;
@class BDPMorePanelItem;
@class BDPSchema;

@class OPMonitorCode;
@class OPContainerContext;

/**
 UI容器VC，负责从TMAAppListCache中检查小程序UIDevice.currentDevice是否有cache，没有的话调用BDPAppLoadManager拉取meta和小程序UIDevice.currentDevice资源包。使用资源包创建TMAAppTask运行小程序UIDevice.currentDevice，BDPAppContainerController是它的子类。
 */
@interface BDPBaseContainerController : UIViewController <BDPlatformContainerProtocol>

/// 应用的唯一复合ID
@property (nonatomic, strong, readonly, nullable) BDPUniqueID *uniqueID;
@property (nonatomic, strong, readonly, nullable) BDPNavigationController *subNavi;
/// 应用启动状态
@property (nonatomic, assign, readonly) BDPContainerBootType bootType;
/// 小程序vc打开方式
@property (nonatomic, assign) BDPViewControllerOpenType openType;

// TODO: 放在这里不合适，即将删除
/// 小程序Schema解析对象
@property (nonatomic, copy, nullable) BDPSchema *schema;
@property (nonatomic, copy, readonly) NSString *launchFrom;
@property (nonatomic, copy, readonly, nullable) NSString *exitType; // for track
/// 启动参数
@property (nonatomic, strong, readonly, nullable) BDPTimorLaunchParam *launchParam;
/** 开始加载的时间戳, 子类埋点使用 */
@property (nonatomic, readonly) NSTimeInterval launchTime;
@property (nonatomic, strong, readonly, nullable) UIScreenEdgePanGestureRecognizer *popGesture;

@property (nonatomic, weak, nullable, readonly) OPContainerContext *containerContext;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithLaunchParam:(BDPTimorLaunchParam *)launchParam
                   containerContext:(OPContainerContext *)containerContext;

/* ------------- 🔧工具栏 ------------- */
- (void)setToolBarMoreButtonCustomMenu:(NSMutableArray<BDPMorePanelItem *> *)items;            // 增加工具栏"更多"按钮菜单 (⏰时机：工具栏点击"更多"按钮时 🙌🏻调用者：父类调用子类复写方法，在菜单中增加自定义菜单选项)

/* ------------- ⏳加载与启动 ------------- */
- (void)becomeReadyStatus;                                                          // 加载完毕事件处理 (⏰时机：小程序DocumentReadyUIDevice.currentDevice第一帧渲染时 🙌🏻调用者：外部调用该方法)
- (void)firstFrameDidShow;                                                          // 首帧已展示
- (BOOL)checkDeviceAvailable;                                                       // 判断设备是否在黑名单 (⏰时机：冷启动时 🙌🏻调用者：父类调用子类复写方法，判断是否可以继续加载小程序)
- (BOOL)checkEnvironmentAvailable;                                                  // 判断加载环境是否可以加载 (⏰时机：冷启动时 🙌🏻调用者：父类调用子类复写方法，判断是否可以继续加载小程序)
- (BOOL)checkModelStatus:(BDPModel *)model isAsyncUpdate:(BOOL)isAsyncUpdate;       // 判断Meta状态是否可以加载 (⏰时机：冷启动时 🙌🏻调用者：父类调用子类复写方法，判断是否可以继续加载小程序)
- (void)excuteColdBootDone;                                                         // 冷启动加载完毕 (⏰时机：冷启动ViewController装载完成时 🙌🏻调用者：父类调用子类复写方法)
- (void)excuteWarmBootDone;                                                         // 热启动加载完毕 (⏰时机：热启动ViewController装载完成时 🙌🏻调用者：父类调用子类复写方法)
- (void)setupTaskDone;                                                              // Task准备完毕 (⏰时机：冷启动Task安装完成时/热启动Task缓存读取完成时 🙌🏻调用者：父类调用子类复写方法)
- (void)forceReboot:(OPMonitorCode *)code;                                                                // 强制重启
- (void)forceClose:(OPMonitorCode *)code;
/// 强制停止运行, 子类若复写实现, 务必代码块`末尾`添加[super forceStopRunning]
- (void)forceStopRunning;
- (UIViewController<BDPWarmBootCleanerProtocol> *)childRootViewController;          // RootViewController获取 (⏰时机：冷启动ViewController装载时 🙌🏻调用者：父类调用子类复写方法，获取ChildSubNavi需要用的RootVC)
- (void)updateSchema:(BDPSchema *)schema;                                           // 更新schema，当小程序在导航栈里被热启，需要调用这个方法。
/// 加载失败，请不要手动i调用，子类复写。
- (void)loadDoneWithError:(nullable NSError *)error;

/* ------------- 💡前后台切换 ------------- */
- (void)onAppEnterForeground;                                                       // 小程序进入前台 (⏰时机：ContainerVC - WillAppear, 系统进入前台通知 🙌🏻调用者：父类调用子类复写方法)
- (void)onAppEnterBackground;                                                       // 小程序进入后台 (⏰时机：ContainerVC - DidDisAppear, 系统进入后台通知 🙌🏻调用者：父类调用子类复写方法)
- (void)updateLoadingViewFailState:(NSInteger)state withInfo:(NSString *)info;

/* ------------- 下面函数都是为了迁移新架构支持的，可能是临时的代码，不是最终形态，将会逐步优化 ------------- */

// TODO: 临时代码，待迁移
- (void)showNeedUpdateGadgetApp;

// TODO: 临时代码，待迁移
- (BOOL)setupChildViewController:(UIViewController *)childVC;

// TODO: 临时代码，待迁移
- (void)invokeAppTaskBlks;

// TODO: 临时代码，待迁移
- (BDPWarmBootCleaner)rootVCCleaner;

// TODO: 代码还需要优化
- (void)bindSubNavi:(BDPNavigationController *)subNavi;

// TODO: 临时代码，待迁移
- (BOOL)loadVdomWithModel:(nullable BDPModel *)localModel;

// TODO: 临时代码，待迁移
- (void)detectBlankWebview:(void (^ _Nullable)(BOOL, NSError * _Nullable))complete;

- (void)onApplicationExitWithRestoreStatus:(BOOL)restoreStatus;

@property (nonatomic, assign) BOOL backFromOtherMiniProgram;

//这个属性在重启前需要标记为YES，在发送exit通知的时候会有使用, 主端的常用面板会有依赖这个属性
@property (nonatomic, assign) BOOL willReboot;

// 埋点逻辑暂时保留，待确认和迁移
- (void)newContainerDidFirstContentReady;

// TODO: 临时代码，待迁移
- (void)getUpdatedMetaInfoModelCompletion:(NSError * _Nullable)error model:(BDPModel * _Nullable)model;

// TODO: 临时代码，待迁移
- (void)getUpdatedPkgCompletion:(NSError * _Nullable)error model:(BDPModel * _Nullable)model;

// TODO: 间接牵涉到firstFrame相关的逻辑，待优化
- (void)eventMpLoadStart;

// 从老容器内获取老容器的运行时异常，需要用于新容器unmount时判断是否清理热缓存
@property (nonatomic, strong, readonly) OPMonitorCode *loadResultType;

@property (nonatomic, assign) BOOL launchSuccess;

// iPad下在临时区打开的标记
@property (nonatomic, assign) BOOL shouldOpenInTemporaryTab;

@end

NS_ASSUME_NONNULL_END
