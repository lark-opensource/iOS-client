//
//  UIDevice+ACCHardware.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,ACCScreenWidthCategory)  {
    ACCScreenWidthCategoryiPhone5,
    ACCScreenWidthCategoryiPhone6,
    ACCScreenWidthCategoryiPhone6Plus,
    
    ACCScreenWidthCategoryiPad9_7,
    ACCScreenWidthCategoryiPad10_5,
    ACCScreenWidthCategoryiPad12_9,
};

typedef NS_ENUM(NSUInteger,ACCScreenHeightCategory) {
    ACCScreenHeightCategoryiPhone4s,
    ACCScreenHeightCategoryiPhone5,
    ACCScreenHeightCategoryiPhone6,
    ACCScreenHeightCategoryiPhone6Plus,
    ACCScreenHeightCategoryiPhoneX,
    ACCScreenHeightCategoryiPhoneXSMax,
    
    ACCScreenHeightCategoryiPad9_7,
    ACCScreenHeightCategoryiPad10_5,
    ACCScreenHeightCategoryiPad12_9,
};

typedef NS_ENUM(NSUInteger,ACCScreenRatoCategory) {
    ACCScreenRatoCategoryiPhoneX,
    ACCScreenRatoCategoryiPhone16_9,
    ACCScreenRatoCategoryiPhone4_3,
};

@interface UIDevice (ACCHardware)

// Is it a mobile phone less than 6S
+ (BOOL)acc_isPoorThanIPhone6S;
+ (BOOL)acc_isPoorThanIPhone6;
+ (BOOL)acc_isPoorThanIPhone5s;
+ (BOOL)acc_isPoorThanIPhone5;

+ (BOOL)acc_isBetterThanIPhone7;
+ (BOOL)acc_isIPhone7Plus;
+ (BOOL)acc_isIPhone;
+ (BOOL)acc_isIPad;

+ (ACCScreenWidthCategory)acc_screenWidthCategory;
+ (ACCScreenHeightCategory)acc_screenHeightCategory;
+ (ACCScreenRatoCategory)acc_screenRatoCategory;

// Don't use this method until you have to. Use the safe layout guide for adaptation
+ (BOOL)acc_isIPhoneX;
+ (BOOL)acc_isIPhoneXsMax;
+ (BOOL)acc_isNotchedScreen;

@end

NS_ASSUME_NONNULL_END
