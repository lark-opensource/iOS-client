//
//  CJPayTouchLabel.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CJPayTouchLabelTapBlock)(UILabel * label, NSString *string, NSRange range, NSInteger index);

@interface CJPayTouchLabel : UILabel
/**
 *  @param strings  需要添加点击事件的字符串数组
 *  @param tapClick 点击事件回调
 */
- (void)cj_addAttributeTapActionWithStrings:(NSArray <NSString *> *)strings
                                 tapClicked:(CJPayTouchLabelTapBlock)tapClick;

@end

NS_ASSUME_NONNULL_END
