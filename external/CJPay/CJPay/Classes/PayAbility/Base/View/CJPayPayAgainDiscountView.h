//
//  CJPayPayAgainDiscountView.h
//  Pods
//
//  Created by bytedance on 2022/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPayAgainDiscountView : UIView

- (_Nonnull instancetype)initWithFrame:(CGRect)frame;
- (_Nonnull instancetype)initWithFrame:(CGRect)frame hiddenImageView:(BOOL)hidden;

- (void)setDiscountStr:(NSString *_Nonnull)discountStr;

@end

NS_ASSUME_NONNULL_END
