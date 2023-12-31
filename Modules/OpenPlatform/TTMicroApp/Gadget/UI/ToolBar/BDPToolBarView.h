//
//  BDPToolBarView.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import <UIKit/UIKit.h>
#import "BDPDefineBase.h"
#import "BDPLeaveComfirmModel.h"

NS_ASSUME_NONNULL_BEGIN

// 当启用新版菜单的插件框架(目前有网页、网页应用、小程序使用)，是否允许菜单面板没有显示出来时，进行一些数据操作
// 预计时间：预计3.48版本全量
// 技术负责人：刘洋 liuyang.apple  殷源 yinyuan.0
#define kMenuPluginPrefetchEnableFGKey @"openplatform.menu.plugin.prefetch.enable"


// ToolBar主题样式
typedef NS_ENUM(NSInteger, BDPToolBarViewStyle) {
    BDPToolBarViewStyleLight = 0,   // 浅色模式下（自身图标显示为深色）
    BDPToolBarViewStyleDark,        // 深色模式下（自身图标显示为浅色）
    BDPToolBarViewStyleUnspecified, // 跟随当前 Base
};


// ToolBar脱敏样式
typedef NS_ENUM(NSInteger, BDPToolBarViewH5Style) {
    BDPToolBarViewH5StyleNone = 0,  // 无脱敏样式
    BDPToolBarViewH5StyleApp,       // 小程序脱敏样式
};


@class BDPBaseContainerController;
@protocol MenuPanelOperationHandler;

@interface BDPToolBarView : UIView

///
@property (nonatomic, assign) BOOL ready;

/// 菜单的操作句柄
@property (nonatomic, strong) id<MenuPanelOperationHandler> menuHandler;

/// 类似 H5风格的胶囊按钮，
@property (nonatomic, assign) BDPToolBarViewH5Style h5Style;

/// toolBar 的风格，@see BDPToolBarViewStyle
@property (nonatomic, assign) BDPToolBarViewStyle toolBarStyle;

@property (nonatomic, assign) BOOL forcedMoreEnable;    // 仅用于在测试版首帧渲染完成前可以点击,以便打开vConsole,从而避免之前强制isReady=YES的实现方式.
@property (nonatomic, strong, readonly, nullable) BDPUniqueID *uniqueID;

@property (nonatomic, strong, readonly) UIButton *moreButton;
@property (nonatomic, strong, readonly) UIButton *closeButton;

@property (nonatomic, assign) NSUInteger moreButtonBadgeNum;

/// 如果有BDPTask 的时候 container 不是必须的，
- (instancetype)initWithUniqueID:(nullable BDPUniqueID *)uniqueID;

- (void)updateMenuHanlderIfNeeded;
- (CGRect)closeButtonFrame; // 获取关闭按钮位置，以ToolBarView的父视图为基准，用于小游戏脱敏API
- (CGRect)moreButtonFrame;  // 获取更多按钮位置，以ToolBarView的父视图为基准，用于小游戏脱敏API
- (CGRect)originMoreButtonFrame; // 获取未经转换的原始moreButton的位置，用于收藏提示弹窗。

/// 某些情况下，e.g. 导航栏隐藏后设置rightitem，Frame被系统导航设置成0后恢复的操作
- (void)resetToAppropriateFrame;

/// iOS16下，导航栏隐藏后设置rightitem，系统导航栏有时会将rightItem的尺寸改成诡异的尺寸，如{14,0},这里用于判断当前尺寸是否正常
- (BOOL)isAppropriateSize;

/// 增加关闭
- (void)addLeaveComfirmHandler:(id<BDPNavLeaveComfirmHandler>)handler;

@end

NS_ASSUME_NONNULL_END
