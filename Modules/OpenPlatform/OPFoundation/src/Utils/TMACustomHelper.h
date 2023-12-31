//
//  TMAHelper.h
//  Timor
//
//  Created by CsoWhy on 2018/8/29.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface TMACustomHelper : NSObject

+ (void)showCustomToast:(NSString *)content icon:(NSString *)icon window:(UIWindow * _Nullable)window;
+ (void)showCustomLoadingToast:(NSString *)content window:(UIWindow * _Nullable)window;
+ (void)hideCustomLoadingToast:(UIWindow * _Nullable)window;

+ (void)configNavigationController:(UIViewController *)currentViewController innerNavigationController:(UINavigationController *)innerNavigationController barHidden:(BOOL)isBarHidden dragBack:(BOOL)dragBack;
+ (BOOL)currentNavigationControllerHidden:(UIViewController *)currentViewController innerNavigationController:(UINavigationController *)innerNavigationController;

+ (BOOL)isInTabBarController:(UIViewController *)appController;

//从TTMicroAppNetwork抽离的方法
+ (NSString*)urlCustomEncodeWithUrl:(NSString*)url;

+ (NSURL *)URLWithString:(NSString *)str relativeToURL:(NSURL *)url;

+ (nullable NSString *)contentTypeForImageData:(NSData *)data;

// 根据屏幕旋转方向调整Size，解决特殊情况下width和height不正确的情况
+ (CGSize)adjustSize:(CGSize)size orientation:(BOOL)orientation;
+ (CGFloat)adjustHeight:(CGFloat)height maxHeight:(CGFloat)maxHeight minHeight:(CGFloat)minHeight;
+ (NSString *)randomString;

+ (void)showAlertVC:(UIViewController *)alertVC inController:(UIViewController *)controller;

@end
