//
//  UIDevice+AWEAdditions.h
//  Aweme
//
//  Created by hanxu on 2017/4/6.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AWEScreenWidthCategoryiPhone5,
    AWEScreenWidthCategoryiPhone6,
    AWEScreenWidthCategoryiPhone6Plus,
    
    AWEScreenWidthCategoryiPad9_7,
    AWEScreenWidthCategoryiPad10_5,
    AWEScreenWidthCategoryiPad12_9,
} AWEScreenWidthCategory;

typedef enum : NSUInteger {
    AWEScreenHeightCategoryiPhone4s,
    AWEScreenHeightCategoryiPhone5,
    AWEScreenHeightCategoryiPhone6,
    AWEScreenHeightCategoryiPhone6Plus,
    AWEScreenHeightCategoryiPhoneX,
    AWEScreenHeightCategoryiPhoneXSMax,
    
    AWEScreenHeightCategoryiPad9_7,
    AWEScreenHeightCategoryiPad10_5,
    AWEScreenHeightCategoryiPad12_9,
} AWEScreenHeightCategory;

typedef enum : NSUInteger {
    AWEScreenRatoCategoryiPhoneX,
    AWEScreenRatoCategoryiPhone16_9,
    AWEScreenRatoCategoryiPhone4_3,
} AWEScreenRatoCategory;

typedef NS_ENUM(NSUInteger, AWEDeviceCarrierCodeType) {
    AWEDeviceCarrierCodeTypeUnknown,
    AWEDeviceCarrierCoceTypeTelecom,
    AWEDeviceCarrierCodeTypeUnicom,
    AWEDeviceCarrierCodeTypeMobile,
};

@interface UIDevice (AWEAdditions)

+ (NSString *)awe_machineModel;
+ (BOOL)awe_isPoorThanIPhone6S;
+ (BOOL)awe_isPoorThanIPhone6;
+ (BOOL)awe_isPoorThanIPhone5s;
+ (BOOL)awe_isPoorThanIPhone5;

+ (BOOL)awe_isBetterThanIPhone7;
+ (BOOL)awe_isIPhone7Plus;
+ (BOOL)awe_isIPhone;

+ (AWEScreenWidthCategory)awe_screenWidthCategory;
+ (AWEScreenHeightCategory)awe_screenHeightCategory;
+ (AWEScreenRatoCategory)awe_screenRatoCategory;

+ (BOOL)awe_isIPhoneX NS_EXTENSION_UNAVAILABLE("unavailable in Extension");
+ (BOOL)awe_isIPhoneXsMax NS_EXTENSION_UNAVAILABLE("unavailable in Extension");

+ (AWEDeviceCarrierCodeType)awe_deviceCarrierCode;
@end
