//
//  UIDevice+CJPay.h
//  CJComponents
//
//  Created by 尚怀军 on 2020/10/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (CJPay)

+ (BOOL)cj_isIPhoneX;

+ (BOOL)cj_isPad;

+ (BOOL)cj_supportMultiWindow;

@end

NS_ASSUME_NONNULL_END
