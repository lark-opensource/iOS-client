//
//  NSObject+CJPay.h
//  Pods
//
//  Created by 王新华 on 2021/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject(CJPay)

@property (nonatomic, weak) UIViewController *cjpay_referViewController;

- (id)cjpay_wrapperReferViewController:(UIViewController *)referViewController;

@end

NS_ASSUME_NONNULL_END
