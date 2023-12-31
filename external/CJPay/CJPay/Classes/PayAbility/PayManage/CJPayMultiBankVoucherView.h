//
//  CJPayMultiBankVoucherView.h
//  Pods
//
//  Created by youerwei on 2021/9/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMultiBankVoucherView : UIView

@property (nonatomic, strong) UIColor *iconBgColor;
@property (nonatomic, assign) NSUInteger iconRadius;

- (void)updateWithUrls:(NSArray *)urls
           voucherDesc:(nullable NSString *)voucherDesc
         voucherDetail:(nullable NSString *)voucherDetail
          voucherColor:(nullable UIColor *)color;

- (void)updateWithUrls:(NSArray *)urls
           voucherDesc:(nullable NSString *)voucherDesc
      voucherDescColor:(nullable UIColor *)voucherDescColor
         voucherDetail:(nullable NSString *)voucherDetail
    voucherDetailColor:(nullable UIColor *)voucherDetailColor
           voucherFont:(nullable UIFont *)font;
@end

NS_ASSUME_NONNULL_END
