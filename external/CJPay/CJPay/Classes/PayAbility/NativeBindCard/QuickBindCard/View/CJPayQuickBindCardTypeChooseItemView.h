//
//  CJPayQuickBindCardTypeChooseItemView.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayQuickBindCardTypeChooseItemView : UIView

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL enable;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)updateTitle:(NSString *)title withColor:(UIColor *)color;
- (void)updateTitle:(NSString *)title;
- (void)updateVoucherStr:(NSString *)voucherStr;
- (void)showInputHintLabel:(BOOL)isShow;

@end

NS_ASSUME_NONNULL_END
