//
//  BDPDeviceHelper.h
//  Timor
//
//  Created by CsoWhy on 2018/9/3.
//

#import <Foundation/Foundation.h>

//设备类型
typedef NS_ENUM(NSUInteger, BDPDeviceModel)
{
    BDPDeviceModelUnknown,          // Unknown
    BDPDeviceModelPad,              // iPad
    BDPDeviceModel2688,             // iPhone XS Max
    BDPDeviceModel1792,             // iPhone XR
    BDPDeviceModel2436,             // iPhone X, iPhone XS
    BDPDeviceModel2208,             // iPhone6 Plus, iPhone6S Plus, iPhone7 Plus, iPhone8 Plus
    BDPDeviceModel1920,             // iPhone6 Plus, iPhone6S Plus, iPhone7 Plus, iPhone8 Plus
    BDPDeviceModel1334,             // iPhone6, iPhone6S, iPhone7, iPhone8
    BDPDeviceModel1136,             // iPhone5, iPhone5C, iPhone5S, iPhoneSE
    BDPDeviceModel960               // iPhone4, iPhone4s
};

@interface BDPDeviceHelper : NSObject

// 获取当前设备的类型及屏幕类型
+ (nullable NSString *)platform;
+ (BOOL)isPadDevice;
+ (BDPDeviceModel)getDeviceType;
+ (nonnull NSString *)getDeviceName;

+ (float)OSVersionNumber;
+ (nullable NSString *)MACAddress;
+ (nullable NSString *)currentLanguage;

/**
 *  返回一像素的大小，对于2x屏幕返回0.5， 1x屏幕返回1
 *
 *  @return 一像素的大小
 */
+ (CGFloat)ssOnePixel;

/**
 *  获取mainScreen的scale
 *
 *  @return scale
 */
+ (CGFloat)screenScale;

/**
 *  获取当前屏幕范围
 *
 *  @return 当前屏幕范围
 */
+ (nullable NSString *)resolutionString;

@end
