//
//  CJPayAlertUtil.h
//  CJPay
//
//  Created by 尚怀军 on 2020/10/21.
//

#import <Foundation/Foundation.h>
#import "CJPayNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayAlertBoldPosition) {
//    支付和提现
    CJPayAlertBoldlLeft = 0,   // 左
    CJPayAlertBoldRight,   // 右

};

@interface CJPayAlertUtil : NSObject

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
              cancelPosition:(CJPayAlertBoldPosition)position
                       useVC:(UIViewController *)useVC;

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
            styleWithMessage:(NSString *)msg
                       useVC:(UIViewController *)useVC;

+ (UIViewController *)doubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
                       useVC:(UIViewController *)useVC;

+ (UIViewController *)singleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
                  buttonDesc:(NSString *)buttonDesc
                 actionBlock:(nullable void (^)(void))actionBlock
            styleWithMessage:(NSString *)msg
                       useVC:(UIViewController *)useVC;

+ (UIViewController *)singleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
                  buttonDesc:(NSString *)buttonDesc
                 actionBlock:(nullable void (^)(void))actionBlock
                       useVC:(UIViewController *)useVC;

+ (UIViewController *)customSingleAlertWithTitle:(nullable NSString *)title
                           content:(nullable NSString *)content
                        buttonDesc:(NSString *)buttonDesc
                       actionBlock:(nullable void (^)(void))actionBlock
                             useVC:(UIViewController *)useVC;

+ (UIViewController *)customDoubleAlertWithTitle:(nullable NSString *)title
                     content:(nullable NSString *)content
              leftButtonDesc:(nullable NSString *)leftButtonDesc
             rightButtonDesc:(nullable NSString *)rightButtonDesc
             leftActionBlock:(nullable void(^)(void))leftActionBlock
             rightActioBlock:(nullable void(^)(void))rightActioBlock
                       useVC:(UIViewController *)useVC;
@end



NS_ASSUME_NONNULL_END
