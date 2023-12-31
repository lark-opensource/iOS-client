//
//  BDJTPageInPreloader.h
//  BDAsyncRenderKit
//
//  Created by bytedance on 2022/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 预加载策略配置
 * 0: 单线程正序加载
 * 1: 多线程正序加载
 * 2: 单线程倒序加载
 * 3: 多线程倒序加载
 */
typedef NS_OPTIONS(NSUInteger, BDJTPreloadOptions) {
    BDJTPreloadConcurrent = (1UL << 0),
    BDJTPreloadReverse = (1UL << 1),
};

/**
 * 是否正在采集 PageIn 数据
 */
BOOL bdjt_isCollectingData(void);

/**
 * 本次启动是否开启了预加载
 */
BOOL bdjt_isPreloadEnabled(void);

/**
 * 本次启动的预加载配置
 */
BDJTPreloadOptions bdjt_getPreloadOptions(void);

/**
 * 根据上次App运行时设置的配置，尝试开始预加载
 * @param pageInFilePath pageIn预加载文件路径
 */
void bdjt_startPreloadIfEnabled(NSString *pageInFilePath);

/**
 * 设置下次启动时的预加载配置
 * 防止连续启动Crash，预加载时会自动清空配置内容，所以每次成功启动后都需要重新配置
 */
void bdjt_setupPreloadForNextLaunch(BDJTPreloadOptions preloadOptions);

/**
 * 禁止下次启动时预加载
 */
void bdjt_disablePreloadForNextLaunch(void);

NS_ASSUME_NONNULL_END
