//
//  CJPayTouchIdManager.h
//  CJPay
//
//  Created by 王新华 on 2019/1/6.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CJPayBioPaymentType) {
    CJPayBioPaymentTypeNone,
    CJPayBioPaymentTypeFinger,
    CJPayBioPaymentTypeFace,
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^TouchIdFallBackBlock)(void);
typedef void(^TouchIdResultBlock)(BOOL useable, BOOL success, NSError *error, NSInteger policy);

@interface CJPayTouchIdManager : NSObject

// 是否支持指纹识别
+ (CJPayBioPaymentType)currentSupportBiopaymentType;

/**
 设置当前身份用于绑定touchIdData的操作
 @param identity 数据标识
 */
+ (void)setCurrentTouchIdDataIdentity:(NSString *)identity;

/**
 获取当前touchIdData绑定的身份
 
 @return 当前ID
 */
+ (NSString*)currentTouchIdDataIdentity;

/**
 检测当前身份的touchId信息是否变更，需先设置setCurrentTouchIdDataIdentity绑定身份
 
 @return 指纹是否改变
 */
+ (BOOL)touchIdInfoDidChange;

/**
检测当前身份的touchId信息是否被锁定
@return 指纹或面容是否锁定
*/
+ (BOOL)isErrorBiometryLockout;

// 当前的指纹信息
+ (nullable NSData*)currentOriTouchIdData;

// 指纹或面容数据是否未录入(注：被锁定的情况下是拿不到touchID数据的)
+ (BOOL)isTouchIDNotEnrolled;

// App的指纹或面容权限是否关闭
+ (BOOL)isBiometryNotAvailable;

/**
 显示指纹解锁
 
 @param localizedReason 指纹解锁副标题(原因)
 @param falllBackTitle fallBack标题
 @param fallBackBlock fallBack回调
 @param resultBlock 解锁回调
 */
+ (void)showTouchIdWithLocalizedReason:(NSString *)localizedReason
                        falldBackTitle:(NSString *)falllBackTitle
                         fallBackBlock:(TouchIdFallBackBlock)fallBackBlock
                           resultBlock:(TouchIdResultBlock)resultBlock;

+ (void)showTouchIdWithLocalizedReason:(NSString *)localizedReason
                           cancelTitle:(nullable NSString *)cancelTitle
                        falldBackTitle:(NSString *)falllBackTitle
                         fallBackBlock:(TouchIdFallBackBlock)fallBackBlock
                           resultBlock:(TouchIdResultBlock)resultBlock;

+ (NSString *)currentBioType;

@end

NS_ASSUME_NONNULL_END
