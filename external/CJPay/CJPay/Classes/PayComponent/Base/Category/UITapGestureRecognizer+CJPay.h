//
//  UITapGestureRecognizer+CJPay.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITapGestureRecognizer (CJPay)

- (BOOL)cj_didTapAttributedTextInLabel:(UILabel *)label inRange:(NSRange)targetRange;

@end

NS_ASSUME_NONNULL_END
