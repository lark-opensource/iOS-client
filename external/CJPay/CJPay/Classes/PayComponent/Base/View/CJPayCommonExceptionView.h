//
//  CJPayCommonExceptionView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCommonExceptionView : UIView

@property (nonatomic, copy) void(^actionBlock)(void);
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIButton *actionButton;

- (instancetype)initWithFrame:(CGRect)frame
                    mainTitle:(nullable NSString *)mainTitle
                     subTitle:(nullable NSString *)subTitle
                  buttonTitle:(nullable NSString *)buttonTitle;

@end

NS_ASSUME_NONNULL_END
