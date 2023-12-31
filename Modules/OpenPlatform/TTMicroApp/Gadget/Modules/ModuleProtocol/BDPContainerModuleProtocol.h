//
//  BDPContainerModuleProtocol.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#ifndef BDPContainerModuleProtocol_h
#define BDPContainerModuleProtocol_h

#import <OPFoundation/BDPModuleProtocol.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>

NS_ASSUME_NONNULL_BEGIN

/// 容器模块协议
/// 容器模块功能：应用vc、页面vc、导航栏vc、TabBar vc、关于vc相关功能
@protocol BDPContainerModuleProtocol <BDPModuleProtocol>

/** 示例：只能定义实例方法
- (void)exampleMethod;
 */

/// 设置导航栏标题
/// @param title 标题
/// @param context 上下文
- (BOOL)setNavigationBarTitle:(NSString * _Nonnull)title context:(BDPPluginContext)context;

/// 设置导航栏颜色
/// @param frontColor 前景颜色
/// @param backgroundColor 背景颜色
/// @param context 上下文
- (BOOL)setNavigationBarColorWithFrontColor:(NSString * _Nonnull)frontColor
                            backgroundColor:(NSString * _Nonnull)backgroundColor
                                    context:(BDPPluginContext)context;

/// 获取容器大小
/// @param context 上下文
- (CGSize)containerSizeWithContext:(BDPPluginContext)context;

/// 小程序容器大小
/// @param vc 视图控制器
/// @param type 类型
/// @param uniqueID 小程序某数据对象
- (CGSize)containerSize:(nullable UIViewController *)vc type:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID;

/// 小程序是否在前台的强校验
/// @param context 上下文
- (BOOL)isVCInForgoundContext:(BDPPluginContext)context;

/// 小程序是否在活跃
/// @param context 上下文
- (BOOL)isVCActiveContext:(BDPPluginContext)context;

@end

NS_ASSUME_NONNULL_END


#endif /* BDPContainerModuleProtocol_h */
