//
//  CJPayMethodCellTagView.h
//  CJPay
//
//  Created by wangxiaohong on 2020/7/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMethodCellTagView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *textColor;

- (void)updateTitle:(NSString *)title;
@end

NS_ASSUME_NONNULL_END
