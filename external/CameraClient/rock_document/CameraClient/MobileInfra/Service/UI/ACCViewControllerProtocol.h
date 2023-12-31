//
//  ACCViewControllerProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/19.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCNaviBarButtonPosition) {
    ACCNaviBarButtonPositionLeft,
    ACCNaviBarButtonPositionRight,
};

typedef NSString* ACCNaviBarButtonPresetStyle NS_TYPED_ENUM;

FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleNone;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleBack;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleForward;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleClose;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleAdd;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleCollect;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleCollected;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleScanQRCode;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleSetting;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleShare;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleInbox;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleAddFriends;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleMore;
FOUNDATION_EXPORT ACCNaviBarButtonPresetStyle const AWENaviBarButtonPresetStyleReport;

@protocol ACCViewControllerProtocol <NSObject>

- (UINavigationController *)createCornerBarNaviControllerWithRootVC:(UIViewController *)rootVC;

- (void)viewController:(UIViewController *)vc setStayTimeLabel:(NSString *)label;

- (void)viewController:(UIViewController *)vc setTrackAttributes:(NSDictionary*)attr;

/**
 *  表示进入该VC时是否隐藏导航栏
 *  子类可重写或者调用setter
 *  为了保持和prefersStatusBarHidden命名上的一致暂不加前缀
 */
- (void)viewController:(UIViewController *)vc setPrefersNavigationBarHidden:(BOOL)hidden;
- (void)viewController:(UIViewController *)vc setDisableFullscreenPopTransition:(BOOL)disable;

- (UIView *)acc_naviBarOfViewController:(UIViewController *)vc;
- (UILabel *)acc_naviBarLabelOfViewController:(UIViewController *)vc;
- (UIView *)acc_naviBarBottomLineOfViewController:(UIViewController *)vc;

- (void)addCustomNaviBarToViewController:(UIViewController *)vc;

- (UIView *)viewController:(UIViewController *)vc
addNaviBarButtonCustomView:(UIView *)view
               forPosition:(ACCNaviBarButtonPosition)position
                    target:(nullable id)target
                    action:(SEL)action;

- (UIButton *)viewController:(UIViewController *)vc addNaviBarBackButtonForPostion:(ACCNaviBarButtonPosition)position
                   withStyle:(ACCNaviBarButtonPresetStyle)presetStyle
                      target:(nullable id)target
                      action:(nullable SEL)action;

- (UIButton *)viewController:(UIViewController *)vc addNaviBarButtonForPosition:(ACCNaviBarButtonPosition)position title:(nullable NSString *)title titleColor:(nullable UIColor *)titleColor
                        font:(nullable UIFont *)font
             backgroundColor:(nullable UIColor *)backgroundColor
                cornerRadius:(CGFloat)cornerRadius
                      target:(nullable id)target
                      action:(SEL)action;

#pragma mark - AWENaviBarConfiguration
- (UIImage *)imageForButtonPresetStyle:(ACCNaviBarButtonPresetStyle)presetStyle;//适用于普通导航栏，DT深色背景，M白色背景

@end

FOUNDATION_STATIC_INLINE id<ACCViewControllerProtocol> ACCViewControllerService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCViewControllerProtocol)];
}

NS_ASSUME_NONNULL_END
