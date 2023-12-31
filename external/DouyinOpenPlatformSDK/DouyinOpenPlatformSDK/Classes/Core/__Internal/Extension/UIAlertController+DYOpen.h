//
//  UIAlertController+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIAlertController (DYOpen)

/// 显示 alert
+ (UIAlertController *)dyopen_showAlertWithTitle:(nullable NSString *)title
                                         message:(nullable NSString *)message
                                    btnTextArray:(nullable NSArray <NSString *> *)btnTextArray
                                extraConfigBlock:(nullable BOOL(^)(UIAlertController *alertVC))extraConfigBlock
                                   completeBlock:(nullable void(^)(NSInteger buttonIndex, NSString *buttonTitle, UIAlertController *alertVC))completeBlock;

/// 显示 actionsheet
+ (UIAlertController *)dyopen_showActionSheetWithTitle:(nullable NSString *)title
                                               message:(nullable NSString *)message
                                          btnTextArray:(nullable NSArray <NSString *> *)btnTextArray
                                      extraConfigBlock:(nullable BOOL(^)(UIAlertController *alertVC))extraConfigBlock
                                         completeBlock:(nullable void(^)(NSInteger buttonIndex, NSString *buttonTitle, UIAlertController *alertVC))completeBlock;

@end

NS_ASSUME_NONNULL_END
