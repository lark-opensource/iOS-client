//
//  BDPAppController.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/26.
//

#import <UIKit/UIKit.h>
#import "BDPWarmBootCleanerProtocol.h"
#import <OPFoundation/BDPUniqueID.h>

@class BDPAppPageController;
@class BDPAppPageURL;
@class BDPAppRouteManager;
@class BDPNavigationController;
@class OPContainerContext;

/**
 * 每个视图view的VC，调用task的pageManager成员[BDPAppPageManager dequeueAppPage]创建页面view（BDPAppPage）
 */
@interface BDPAppController : UIViewController <BDPWarmBootCleanerProtocol>

@property (nonatomic, strong) BDPUniqueID *uniqueID;
//@property (nonatomic, strong) BDPNavigationController *subNavi;
@property (nonatomic, strong) UIViewController *contentVC;
@property (nonatomic, strong, nullable) BDPAppRouteManager *routeManager;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                containerContext:(OPContainerContext *)containerContext;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                            vdom:(NSDictionary *)vdom
                containerContext:(OPContainerContext *)containerContext;

- (void)onAppEnterForeground;
- (void)onAppEnterBackground;
- (void)forceStopRunning;
- (void)setupBottomBarIfNeed;

///
+ (BDPAppPageController * _Nullable)currentAppPageController:(UIViewController *)viewController fixForPopover:(BOOL)fixForPopover;
/// 获得当前可见的 界面， 肯定是一个BDPAppPageController
- (BDPAppPageController * _Nullable)currentAppPage;

/// 更新contentVC, switchTab接口有可能会改变contentVC。
- (void)updateContentVC:(UIViewController *)content;

- (void)layoutAnchorShareButton;

- (void)loadAppContent;

#pragma mark - XScreen
- (void)updateProviderTipWithAppName:(NSString *)appName appIcon:(NSString *)iconUrl;

@end
