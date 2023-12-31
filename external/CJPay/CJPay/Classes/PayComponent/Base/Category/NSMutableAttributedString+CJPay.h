//
//  NSMutableAttributedString+CJPay.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString(CJPay)

- (NSMutableAttributedString *)appendAttributedStringWith:(NSString *)content textColor:(UIColor *)color font:(UIFont *)font;

@end

@interface NSAttributedString(CJPay)

- (CGSize)cj_size:(CGFloat)maxWidth;

@end

@interface NSMutableParagraphStyle (CJPay)

@property (nonatomic, assign) CGFloat cjMaximumLineHeight;
@property (nonatomic, assign) CGFloat cjMinimumLineHeight;



@end

NS_ASSUME_NONNULL_END
