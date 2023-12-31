//
//  BDPAppRouteManager.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/26.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPPluginManagerAdapter/BDPJSBridgeBase.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPAppController;
@class OPContainerContext;

@interface BDPAppRouteManager : NSObject <UITabBarControllerDelegate>

+ (void)postDocumentReadyNotifWithUniqueId:(BDPUniqueID *)uniqueId appPageId:(NSInteger)appPageId;

- (instancetype)initWithAppController:(BDPAppController *)appController
                     containerContext:(OPContainerContext *)containerContext;

- (UIViewController *)reLaunch:(NSString *)url;
- (UIViewController *)goHome;
- (void)showGoHomeButtonIfNeed;
- (void)setupPlugins;

- (void)navigateTo:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback;

- (void)navigateBack:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback;

- (void)reLaunch:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback;

- (void)redirectTo:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback;

- (void)switchTab:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback;

@end

NS_ASSUME_NONNULL_END
