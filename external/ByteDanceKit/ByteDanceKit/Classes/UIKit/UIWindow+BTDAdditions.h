//Copyright © 2021 Bytedance. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (BTDAdditions)

/**
 * For iOS 13- devices, find the key window of the app.
 *
 * For iOS 13+ devices, find the key window from the first active connected scene in foreground.
 * In cases where multiple connected scenes are active in foreground (e.g. two windows side by side on iPad),
 * this method will return the key window from the currently focused window scene. If this is not the desired behavior,
 * please try UIView's window property to get the currently focused window if you have access to the view-related objects.
 *
 * @return the key window of the app
 */
/**
  If btd_useNewBTDKeyWindow is NO, btd_keyWindow will return [UIApplication sharedApplication].keyWindow in iOS 14 and 15.
 */
@property(nonatomic, assign, class) BOOL btd_useNewBTDKeyWindow;

+ (nullable UIWindow *)btd_keyWindow NS_EXTENSION_UNAVAILABLE_IOS("Not available in Extension Target");

/**
 The height of statusBar for window.
 */
- (CGFloat)btd_statusBarHeight;

/**
 The default height of statusBar for key window. If the statusBar is hidden, it will also return default height in device instead of 0. 
 */
+ (CGFloat)btd_defaultStatusBarHeight API_AVAILABLE(ios(3.2));

@end

NS_ASSUME_NONNULL_END
