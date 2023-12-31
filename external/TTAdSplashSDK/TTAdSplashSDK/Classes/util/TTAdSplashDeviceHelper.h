//
//  TTDeviceHelper.h
//  Pods
//
//  Created by zhaoqin on 8/11/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIKit.h>

//分屏情况
typedef NS_ENUM(NSUInteger, TTAdSplitScreenMode) {
    TTAdSplitScreenFullMode,
    TTAdSplitScreenBigMode,
    TTAdSplitScreenMiddleMode,
    TTAdSplitScreenSmallMode
};

//设备类型
typedef NS_ENUM(NSUInteger, TTAdSplashDeviceMode) {
    //iPad
    TTAdSplashDeviceModePad,
    //iPhone 12 Pro Max
    TTAdSplashDeviceMode926,
    //iPhone 12, iPhone 12 Pro
    TTAdSplashDeviceMode844,
    //iPhone 12 Mini
    TTAdSplashDeviceMode784,
    //iPhone XS Max, iPhone XR
    TTAdSplashDeviceMode896,
    //iPhone X, iPhone XS
    TTAdSplashDeviceMode812,
    //iPhone6plus,iPhone6Splus
    TTAdSplashDeviceMode736,
    //iPhone6,iPhone6S
    TTAdSplashDeviceMode667,
    //iPhone5,iPhone5C,iPhone5S,iPhoneSE
    TTAdSplashDeviceMode568,
    //iPhone4,iPhone4s
    TTAdSplashDeviceMode480,
    // iPhone 14 pro
    TTAdSplashDeviceMode852,
    // iPhone 14 pro max
    TTAdSplashDeviceMode932,
};

@interface TTAdSplashDeviceHelper : NSObject

/**
 *  获取当前设备的类型
 *
 *  @return "iPhone"/"iPad"
 */
+ (nullable NSString *)platformName;

/**
 *  获取当前设备平台的预定义字符串信息
 *
 *  @return such as iPhone X etc.
 */
+ (nullable NSString *)platformString;

/**
 *  判断设备是iPhone4, iPhone4S
 *
 *  @return Yes or No
 */
+ (BOOL)is480Screen;

/**
 *  判断设备是iPhone5, iPhone5C, iPhone5S, iPhoneSE
 *
 *  @return Yes or No
 */
+ (BOOL)is568Screen;

/**
 *  判断设备是iPhone6,iPhone6S
 *
 *  @return Yes or No
 */
+ (BOOL)is667Screen;

/**
 *  判断设备是iPhone6plus, iPhone6Splus
 *
 *  @return Yes or No
 */
+ (BOOL)is736Screen;

/**
 判断设备是 iPhone X, iPhone XS
 */
+ (BOOL)is812Screen;

/**
 判断设备是 iPhone XS Max, iPhone XR
 */
+ (BOOL)is896Screen;

/**
 判断设备是 iPhone 12 Mini
 */
+ (BOOL)is784Screen;

/**
 判断设备是 iPhone 12, iPhone 12 Pro
 */
+ (BOOL)is844Screen;

/**
 判断设备是 iPhone12 Pro Max
 */
+ (BOOL)is926Screen;

/**
 判断设备是 iPhone14 Pro
 */
+ (BOOL)is852Screen;

/**
 判断设备是 iPhone14 Pro Max
 */
+ (BOOL)is932Screen;

/**
 *  判断设备是否是异形屏幕
 *  当前包括：iPhone X、iPhone XR、iPhone XS、iPhone XS Max
 *  @return Yes or No
 */
+ (BOOL)isAlienScreenDevice;

/// 返回屏幕底部的安全区域高度
+ (CGFloat)safeAreaBottom;

/**
 *  判断设备的宽度大于320
 *
 *  @return Yes or No
 */
+ (BOOL)isScreenWidthLarge320;

/**
 *  判断设备是iPad
 *
 *  @return Yes or No
 */
+ (BOOL)isPadDevice;

/**
 *  判断设备是iPad pro
 *
 *  @return Yes or No
 */
+ (BOOL)isIpadProDevice;

/**
 *  判断设备是否越狱
 *
 *  @return Yes or No
 */
+ (BOOL)isJailBroken;

/**
 *  获取设备类型
 *
 *  @return TTDeviceType类型
 */
+ (TTAdSplashDeviceMode)getDeviceType;

/**
 *  获取系统版本号
 *
 *  @return 系统版本号
 */
+ (float)OSVersionNumber;

/**
 *  获取当前语言种类
 *
 *  @return 语言
 */
+ (nullable NSString*)currentLanguage;

/**
 *  获取openUDID
 *
 *  @return
 */
//+ (nullable NSString*)openUDID;

/**
 *  返回一像素的大小，对于2x屏幕返回0.5， 1x屏幕返回1
 *
 *  @return one pexel
 */
+ (CGFloat)ssOnePixel;

/**
 *  获取当前屏幕范围
 *
 *  @return scale
 */
+ (CGFloat)screenScale;

/**
 *  获取mainScreen的scale
 *
 *  @return 分辨率string
 */
+ (nullable NSString *)resolutionString;


/**
 *  分屏情况
 *
 *  @param size 尺寸
 *
 *  @return 分屏类型
 */
+ (TTAdSplitScreenMode)currentSplitScreenWithSize:(CGSize)size;

// 获取当前应用的广义mainWindow
+ (nullable UIWindow *)mainWindow;

// 广义mainWindow的大小（兼容iOS7）
+ (CGSize)windowSize;

+ (CGFloat)newPadding:(CGFloat)normalPadding;

+ (CGFloat)newFontSize:(CGFloat)size;

/// 根据屏幕宽度计算字体
/// @param size 原字体
+ (CGFloat)scaleFontWithScreenWidth:(CGFloat)size;

@end

@interface TTAdSplashDeviceHelper (TTDiskSpace)

//获取硬盘大小，单位Byte
+ (long long)getTotalDiskSpace;

//获取可用空间大小，单位Byte
+ (long long)getFreeDiskSpace;

@end

@interface TTAdSplashDeviceHelper (TTAdLaunch)

/**
 * @return App的启动图，UILaunchImages
 */
+ (nullable UIImage *)appLaunchImage;

/**
 *  @return LaunchScreen.StoryBoard的实例的截图视图
 */
+ (nullable UIView *)appLaunchScreenViewWithFrame:(CGRect)viewFrame;
@end
