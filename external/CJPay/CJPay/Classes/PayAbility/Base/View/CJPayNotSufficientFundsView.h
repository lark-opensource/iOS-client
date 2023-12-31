//
//  CJPayNotSufficientFundsView.h
//  CJPay
//
//  Created by 王新华 on 2/12/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNotSufficientFundsView : UIView

@property (nonatomic, copy) void(^iconClickBlock)(void);
@property (nonatomic, strong, readonly) UIImageView *iconImgView;

- (void)updateTitle:(NSString *)title;

- (CGSize)calSize;

@end

NS_ASSUME_NONNULL_END
