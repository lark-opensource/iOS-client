//
//  BDPRouterPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/5.
//

#ifndef BDPRouterPluginDelegate_h
#define BDPRouterPluginDelegate_h

#import "BDPBasePluginDelegate.h"
#import "BDPModuleEngineType.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDPOpenSchemaResult) {
    BDPOpenSchemaResultSuccess,
    BDPOpenSchemaResultAuthFailed,
    BDPOpenSchemaResultOtherFailed
};

/**
 * 路由功能
 */
@protocol BDPRouterPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 打开端上界面的功能，比如打开个人主页、
 * @param url - schema url
 * @param uniqueID - 唯一标志，同一个appid并不一定相同uniqueID
 * @param appType - 应用类型
 * @param external - 是否打开外部app，比如打开safari
 * @param whiteListChecker - url白名单校验器
 * @return 是否打开成功
 */
- (BDPOpenSchemaResult)bdp_openSchemaWithURL:(NSURL *)url
                     uniqueID:(BDPUniqueID * _Nullable)uniqueID
                      appType:(BDPType)appType
                     external:(BOOL)external
               fromController:(UIViewController * _Nullable)fromController
             whiteListChecker:(BDPAuthorization * _Nullable)whiteListChecker;

/**
 * 拦截WebView请求
 * @param url url adress
 * @param BDPUniqueID 应用唯一标志
 * @return 是否拦截请求
 */
- (BOOL)bdp_interceptWebViewRequest:(NSURL *)url
                           uniqueID:(BDPUniqueID *)uniqueID
                           fromView:(UIView * _Nullable)fromView;


/**
* 关闭小程序
* 会针对小程序的打开方式，进行dismiss、pop或showDetail 空页面(ipad)
* @param container 关闭的小程序容器vc
* @param completion 完成回调
*/
- (void)bdp_closeMiniParam:(UIViewController *)container completion:(nullable void(^)(BOOL))completion;

/**
 * 打开小程序关于页面，目前只有半屏小程序调用，其他流程调用请先沟通确认
 * @param uniqueID 小程序唯一标识
*/
- (void)aboutHandlerForUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END

#endif /* BDPRouterPluginDelegate_h */
