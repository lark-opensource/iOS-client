//
//  HMDUITrackerTool.h
//  Pods
//
//  Created by bytedance on 2022/1/21.
//

#import <Foundation/Foundation.h>
#import "HMDUITrackerManagerSceneProtocol.h"
#include "HMDPublicMacro.h"

HMD_EXTERN id<HMDUITrackerManagerSceneProtocol> _Nullable hmd_get_uitracker_manager(void);

@interface HMDUITrackerTool : NSObject

#pragma mark - keyWindow

/*!@property keyWindow
 * @discussion 该 API 兼容 iOS 13 以后的 UIScene 环境，会返回最适合的 @p keyWindow
 * @warning @p Main_Thread_Only @b 只允许在【主线程】访问该方法
 * @note 首先我们要明确在 iOS 13+ 以后的确会存在，同时有多个 keyWindow 的情况，那么
 * 如果非要选取一个 window 的话，上报哪一个呢？首先要明确，Heimdallr 为什么需要 keyWindow
 * 是为了在崩溃，卡死发生的时刻，能够知道这是来自哪一个场景导致的问题，但是现在 iOS 13
 * 的确可以同时支持多场景，所以我们会选取最有可能的 window 作为 keyWindow 进行返回，
 * 在崩溃界面上通过聚类依然可以大致定位到具体发生崩溃的 window 是哪一个
 */
@property(class, nonatomic, readonly, nullable) UIWindow *keyWindow;

/*!@property sceneBasedSupport
 * @discussion 当前 APP 是否开启 UIScene 支持
 * @note Thread-Safe
 */
@property(class, atomic, readonly) BOOL sceneBasedSupport;

/*!@property sceneBackground
 * @discussion 当前 APP 所有的 scene 是否在后台中
 * @warning @p Main_Thread_Only @b 只允许在【主线程】访问该方法
 * @note UIApplication.sharedApplication.applicationState 并没有被废弃使用
 */
@property(class, nonatomic, readonly, getter=isSceneBackground) BOOL sceneBackground;

@end
