//
//  BDPUIPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPUIPluginDelegate_h
#define BDPUIPluginDelegate_h

#import "BDPAddressPluginModel.h"
#import "BDPBasePluginDelegate.h"
#import "BDPDatePickerPluginModel.h"
//#import "BDPLoadingPluginModel.h"
#import "BDPModalPluginModel.h"
#import "BDPPickerPluginModel.h"
#import "BDPRegionPickerPluginModel.h"
#import "BDPToastPluginModel.h"
#import "BDPMorePanelItem.h"
#import <WebKit/WebKit.h>
#import "BDPModel.h"

#pragma mark - Toast
#pragma mark -
/****************************************************************************/
/*********                       Toast                       ****************/
/****************************************************************************/

/**
 * 显示toast接口
 * showLoading 和 showToast 同时只能显示一个
 * showToast 应与 hideToast 配对使用
 */
@protocol BDPToastPluginDelegate <BDPBasePluginDelegate>

/**
 * 显示Toast
 * @param model toast的信息
 */
- (void)bdp_showToastWithModel:(BDPToastPluginModel *)model;

/**
 * 隐藏Toast
 */
- (void)bdp_hideToast:(UIWindow * _Nullable)window;

/**
 * 显示Toast
 * @param model toast的信息
 * @param controller toast显示在的vc
 */
- (void)bdp_showToastWithModel:(BDPToastPluginModel *)model inController:(UIViewController *)controller;

@end


#pragma mark - Modal
#pragma mark -
/****************************************************************************/
/*********                       Modal                       ****************/
/****************************************************************************/

/**
 * 模态对话框
 */
@protocol BDPModalPluginDelegate <BDPBasePluginDelegate>

/**
 * 显示模态对话框
 * @param model 模态对话框要展示的内容
 * @param confirmCallback 确认的回调
 * @param cancelCallback 取消的回调
 * @param controller 当前vc
 */
- (void)bdp_showModalWithModel:(BDPModalPluginModel *)model
               confirmCallback:(void (^)(void))confirmCallback
                cancelCallback:(void (^)(void))cancelCallback
                  inController:(UIViewController *)controller;

@end

#pragma mark - Picker
#pragma mark -
/****************************************************************************/
/*********                      Picker                       ****************/
/****************************************************************************/

/**
 * 显示 picker
 */
@protocol BDPPickerPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 显示picker
 * @param model picker的信息
 * @param pickerSelectedCallback 当picker发生变化的时候会回调到这个callback里面来
 * @param completion 选择了之后会调转到这个callback里面，里面会传回来当前的模型，和当前的选择。
 */
- (void)bdp_showPickerViewWithModel:(BDPPickerPluginModel *)model
                     fromController:(UIViewController *)fromController
             pickerSelectedCallback:(void (^)(NSInteger row, NSInteger component))pickerSelectedCallback
                         completion:(void (^)(BOOL isCanceled, NSArray<NSNumber *> *selectedRow, BDPPickerPluginModel *model))completion;

/**
 * 更新picker信息
 * @param model 要更新的picker信息模型
 * @param animated 是否需要做动画
 */
- (void)bdp_updatePickerWithModel:(BDPPickerPluginModel *)model animated:(BOOL)animated;

/**
 * 显示时间选择器
 * @param model 时间选择器信息
 * @param completion 结果callback
 */
- (void)bdp_showDatePickerViewWithModel:(BDPDatePickerPluginModel *)model
                         fromController:(UIViewController *)fromController
                             completion:(void (^)(BOOL canceled, NSDate *time))completion;

/**
 *显示地址选择器
 @param model 地址选择器信息
 @param completion 结果callback
 */
- (void)bdp_showRegionPickerViewWithModel:(BDPRegionPickerPluginModel *)model
                           fromController:(UIViewController *)fromController
                               completion:(void (^)(BOOL canceled, BDPAddressPluginModel *address))completion;

@end


#pragma mark - Navigation
#pragma mark -
/****************************************************************************/
/*********                    Navigation                     ****************/
/****************************************************************************/

/**
 * 导航栏相关的协议
 */
@protocol BDPNavigationPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 由于宿主方的导航栏使用的都是不一样的，所以有一些方法没有办法通用，这里就将导航栏
 * @param param 里面有两个参数 navigationBarHidden 和 navigationGestureBack， 控制navigation bar的隐藏，和 右滑返回
 * @param currentViewController 当前的界面
 */
- (void)bdp_configNavigationControllerWithParam:(NSDictionary *)param
                          currentViewController:(UIViewController *)currentViewController;

@end


#pragma mark - Permission


#pragma mark - Loading View
#pragma mark -
/****************************************************************************/
/*********               LoadingView(用于脱敏方案)             ****************/
/****************************************************************************/

#define kBDPLoadingViewConfigUniqueID @"unique_id"
/**
 * 使用宿主自定义的加载界面(用于脱敏方案)
 */
@protocol BDPLoadingViewPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 获取宿主自定义的加载界面
 * @param config 界面配置信息, kBDPLoadingViewConfigUniqueID: 小程序uniqueID
 */
- (UIView *)bdp_getLoadingViewWithConfig:(NSDictionary *)config;

/**
 * 更新自定义加载界面model信息
 * @param appModel 小程序model信息
 */
- (void)bdp_updateLoadingViewWithModel:(BDPModel *)appModel;

/**
 * 加载失败
 * @param state 小程序model信息
 * @param tipInfo 提升信息
 */
- (void)bdp_changeToFailState:(int)state withTipInfo:(NSString *)tipInfo;

@end

#pragma mark - webview
#pragma mark -
/****************************************************************************/
/*********                    webview                     ****************/
/****************************************************************************/

/**
 * webview组件相关的协议
 */
@class BDPBlankDetectConfig;
@protocol BDPWebviewPluginDelegate <BDPBasePluginDelegate>
@optional

- (NSURLRequest *)bdp_synchronizeCookieForWebview:(WKWebView *)webview
                                          request:(NSURLRequest *)request
                             uniqueID:(BDPUniqueID *)uniqueID;

- (BDPBlankDetectConfig *)bdp_getWebviewDetectConfig;

@end

#pragma mark - alert
/****************************************************************************/
/*********                    alert                     ****************/
/****************************************************************************/

/**
 * alert弹窗相关的协议
 */
@protocol BDPAlertPluginDelegate <BDPBasePluginDelegate>
@optional

/// 显示弹窗
/// @param title 标题
/// @param content 内容
/// @param confirm 确定按钮文案
/// @param confirmCallback 点击确定按钮的回调
/// @param showCancel 是否展示取消按钮
- (UIViewController*)bdp_showAlertWithTitle:(NSString *)title
                                    content:(NSString *)content
                                    confirm:(NSString *)confirm
                             fromController:(UIViewController *)fromController
                            confirmCallback:(dispatch_block_t)confirmCallback
                                 showCancel:(BOOL)showCancel;

@end

#pragma make -  Responder
// 在UI Responder Chain相关的处理过程中，依赖到一些特殊的系统容器UI（UINavigationController/UITabbarController/UISplitViewController/UIPageViewController）来处理 UI 架构；
/// 对于自定义（非继承于系统相关UI）的UI容器，则需要外部来实现对应的处理
@protocol BDPCustomResponderPluginDelegate <BDPBasePluginDelegate>
@optional

/// 获取最顶层UIViewController: 详情可以参见BDPResponderHelper的topViewControllerFor
/// 增加了对iPad present弹出popover视图的支持，使之在这种情况下可以返回正确的VC， fixForPopover表示是否开启修复
- (UIViewController *)bdp_customTopMostViewControllerFor:(UIViewController *)rootViewController fixForPopover:(BOOL)fixForPopover;

@end

#endif /* BDPUIPluginDelegate_h */
