//
//  BDPAppPageController.h
//  Timor
//
//  Created by 王浩宇 on 2018/11/18.
//

#import "BDPBaseViewController.h"
#import "BDPAppPage.h"
#import <OPFoundation/BDPUniqueID.h>
#import "BDPAppConfig.h"
#import "BDPPageConfig.h"
#import "BDPAppPageURL.h"
#import "BDPToolBarView.h"
#import "BDPDefineBase.h"

@class OPContainerContext;
@class OPNoticeModel;

@interface BDPAppPageController : BDPBaseViewController<BDPAppPageDataLoadErrorHandleDelegate,BDPNavLeaveComfirmHandler>

///2019-3-21 该值用于记录(setNavigationBarTitle or webview通过document.title获取)设置的title,在BDPAppPageController的生命周期内使用设置过的值,防止左滑返回一半时取消掉导致title更新不正确
@property (nonatomic, copy) NSString *customNavigationBarTitle;
@property (nonatomic, assign) BOOL isAppeared;
@property (nonatomic, strong, readonly) BDPAppPageURL *page;
@property (nonatomic, strong, nullable) BDPAppPage *appPage;
@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, strong, nullable) BDPPageConfig *pageConfig;
@property (nonatomic, strong, nullable) BDPToolBarView *toolBarView;
@property (nonatomic, strong) BDPPerformanceMonitor<TMAPageTiming> *performanceMonitor;
/// 支持小程序维持当前页面发生页面切换时显示左侧返回按钮并支持点击后返回
@property (nonatomic, copy) void (^canGoBackChangedBlock)(BOOL canGoBack);
/// 主要用于主端那边的底bar需求。
@property (nonatomic, weak) UIView *bottomBar;
@property (nonatomic, assign) BOOL statusBarHidden;
/// 当导航栏可显示返回首页按钮时，是否显示按钮，默认YES
@property (nonatomic, assign) BOOL canShowHomeButton;
/// 当前页面是否触发FailedRefreshWrapperView
@property (nonatomic, assign) BOOL failedRefreshViewIsOn;
/// 当前页面方向配置(这个配置是结合当前页面配置和全局配置得出来的结果)
@property (nonatomic, assign) GadgetMetaOritation pageOrientation;
/// 当前页面方向
@property (nonatomic, assign) UIInterfaceOrientation pageInterfaceOrientation;

@property (nonatomic, assign) BOOL forceAutorotate;
/// 当前页面已经展示过(在viewDidAppear设置为true(不会在viewDidDisappear重置为false), 代表这个VC已经显示过; 该值在小程序横竖屏功能中使用)
@property (nonatomic, assign) BOOL hadDidAppeared;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID page:(BDPAppPageURL *)page containerContext:(OPContainerContext *)containerContext;
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID pageURL:(NSString *)pageURL containerContext:(OPContainerContext *)containerContext;
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID page:(BDPAppPageURL *)page vdom:(NSDictionary *)vdom containerContext:(OPContainerContext *)containerContext;

- (void)updateNavigationBarStyle:(BOOL)animated;

- (void)onAppRoute:(NSString *)openType;

-(void)setupNoticeViewWithModel:(OPNoticeModel *)model;


/// 点击返回或关闭时，弹出提醒框二次确认
/// @param title 标题
/// @param content 正文内容
/// @param confirmText 确定按钮文案
/// @param cancelText 取消按钮文案
/// @param effect 作用效果<NSString *> 1.”back“ 返回按钮 2.'close' 关闭按钮
/// @param confirmColor 确定按钮文字颜色
/// @param cancelColor 取消按钮文字颜色
- (void)addLeaveComfirmTitle:(NSString *)title
                     content:(NSString *)content
                 confirmText:(NSString *)confirmText
                  cancelText:(NSString *)cancelText
                      effect:(NSArray *)effect
                confirmColor:(NSString *)confirmColor
                 cancelColor:(NSString *)cancelColor;

/// 取消弹出提醒框二次确认
- (void)cancelLeaveComfirm;


/// 处理点击返回/关闭事件
/// @param action 事件类型
/// @param callback 点击了取消的弹框
- (BOOL)handleLeaveComfirmAction:(BDPLeaveComfirmAction)action confirmCallback:(void (^)(void))callback;


/// 标记页面返回事件被托管
- (void)takeoverBackEvent;

/// 处理小程序申请托管返回页面，返回值为是否被托管，true: 小程序已经申请托管
- (BOOL)handleTakeoverBackEventIfRegisted;

@end

@interface BDPAppPageController (XScreen)

/// 更新半屏导航栏标题
/// @param title 导航栏标题
- (void)updateXscreenNavigationBarTitle:(NSString *)title;

@end
