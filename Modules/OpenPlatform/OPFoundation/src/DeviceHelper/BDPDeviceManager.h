//
//  BDPDeviceManager.h
//  Timor
//
//  Created by CsoWhy on 2018/10/20.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface BDPDeviceManager : NSObject

/**
 @brief                 获取屏幕方向
 @return                屏幕方向 (UIInterfaceOrientation)
 */
+ (UIInterfaceOrientation)deviceInterfaceOrientation;

/**
 @brief                 将屏幕旋转至「指定旋转方向 (UIInterfaceOrientation)」
 @param orientation     指定旋转方向 (UIInterfaceOrientation)
 */
+ (void)deviceInterfaceOrientationAdaptTo:(UIInterfaceOrientation)orientation;

/**
 @brief                 将屏幕旋转至「指定旋转方向 (UIInterfaceOrientationMask)」
 @param orientation     指定旋转方向 (UIInterfaceOrientation)
 */
+ (void)deviceInterfaceOrientationAdaptToMask:(UIInterfaceOrientationMask)orientation;

/**
 @brief                 判断屏幕方向是否与指定旋转方向 (UIInterfaceOrientationMask)相同
 @param orientation     指定旋转方向 (UIInterfaceOrientationMask)
 @return                方向是否相同
 */
+ (BOOL)deviceInterfaceOrientationIsEqualToOrientationMask:(UIInterfaceOrientationMask)orientation;

/**
 @brief                 应用程序是否支持屏幕旋转 (根据 UISupportedInterfaceOrientations)
 @return                是否支持转屏
 */
+ (BOOL)shouldAutorotate;

/**
 @brief                 获取应用程序支持的屏幕旋转方向 (根据 UISupportedInterfaceOrientations)
 @return                屏幕方向 (UIInterfaceOrientationMask)
 */
+ (UIInterfaceOrientationMask)infoPlistSupportedInterfaceOrientationsMask;

/**
 @brief                 将屏幕旋转至「指定旋转方向 (UIInterfaceOrientationMask)」,iOS16 以下系统使用
 @param orientation     指定旋转方向 (UIInterfaceOrientation)
 */
+ (void)deprecated_deviceInterfaceOrientationAdaptTo:(UIInterfaceOrientation)orientation;
@end
