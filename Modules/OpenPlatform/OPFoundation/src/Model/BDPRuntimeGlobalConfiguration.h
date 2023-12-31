//
//  BDPRuntimeGlobalConfiguration.h
//  Timor
//
//  Created by 王浩宇 on 2019/3/5.
//

#import <Foundation/Foundation.h>

@class BDPScopeConfig;

@interface BDPRuntimeGlobalConfiguration : NSObject

/**
 @enum          maxWarmBootCacheCount
 @brief         小程序后台(热启动缓存)最大容纳数量
 @return        默认值：5, 取值范围[1, 5]
 @discussion    后台策略：每个小程序关闭时会放入后台，累加一个后台占用数量，数量增加到 [maxWarmBootCacheCount] 时会自动释放最早放入后台的小程序。
*/
@property (nonatomic, assign) NSInteger maxWarmBootCacheCount;

/**
 @enum          shouldDismissShareLoading
 @brief         分享数据从服务端回调时，是否隐藏Loading弹窗
 @return        默认值：YES
 @discussion    分享调用后，您可能需要将SDK的Loading动画与宿主的其他Loading动画结合，此时可设置此变量。
 */
@property (nonatomic, assign) BOOL shouldDismissShareLoading;

/**
 @enum          shouldAutoUpdateRelativeData
 @brief         小程序 SDK 是否需要自动更新相关数据 (基础库、Settings、离线资源等逻辑)
 @return        默认值：YES
 @discussion    小程序会在 + (void)load 的 7s 后执行 BDPTimorClient -> updateRelativeDataIfNeed，会更新基础库、Settings、离线资源等操作
 @warning       ⚠️该变量需要尽可能在较早时机去设置 (较早时机：+ (void)load 方法之后的 7s 内)
 */
@property (nonatomic, assign) BOOL shouldAutoUpdateRelativeData;

/**
 @enum          shouldNotUpdateSettingsData
 @brief         小程序 SDK 是否需要更新Settings数据。兼容宿主Lark不需要更新setings的情况
 @return        默认值：NO
 @discussion    小程序会在 + (void)load 的 7s 后执行 BDPTimorClient -> updateRelativeDataIfNeed，会更新基础库、Settings、离线资源等操作
 @warning       ⚠️该变量需要尽可能在较早时机去设置 (较早时机：+ (void)load 方法之后的 7s 内)
 */
@property (nonatomic, assign, readonly) BOOL shouldNotUpdateSettingsData;

/**
 @enum          shouldNotUpdateJSSDK
 @brief         小程序 SDK 是否需要更新基础库。兼容宿主Lark不需要使用头条js sdk更新逻辑的情况
 @return        默认值：NO
 @discussion    小程序会在 + (void)load 的 7s 后执行 BDPTimorClient -> updateRelativeDataIfNeed，会更新基础库、Settings、离线资源等操作
 @warning       ⚠️该变量需要尽可能在较早时机去设置 (较早时机：+ (void)load 方法之后的 7s 内)
 */
@property (nonatomic, assign, readonly) BOOL shouldNotUpdateJSSDK;

/**
 @enum          hideMenu
 @brief         隐藏菜单
 @return        默认值：NO
 @discussion    如果设置为YES，将只有关闭小程序按钮，没有菜单按钮
 */
@property (nonatomic, assign) BOOL hideMenu;

/**
 @enum          scopeConfig
 @brief         定义各个权限弹窗的标题，主要是提供给宿主自定义标题
 */
@property (nonatomic, strong) BDPScopeConfig *scopeConfig;

/// 是否支持 debug vdom 的能力。默认在DEBUG 和 local_test 渠道下打开。
/// 不建议你在正式渠道打开这个功能.
@property (nonatomic, assign) BOOL debugVdomEnable;

// Initialize
+ (instancetype)defaultConfiguration;
- (instancetype)initWithConfiguration:(BDPRuntimeGlobalConfiguration *)configuration;

@end
