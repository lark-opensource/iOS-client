//
//  NSMutableAttributedString+CJExtension.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "NSMutableAttributedString+CJPay.h"
#import "UIFont+CJPay.h"
#import <objc/runtime.h>

@implementation NSMutableAttributedString(CJPay)

- (NSMutableAttributedString *)appendAttributedStringWith:(NSString *)content textColor:(UIColor *)color font:(UIFont *)font {
    NSDictionary *attributes = @{NSForegroundColorAttributeName: color, NSFontAttributeName: font};
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes: attributes];
    [self appendAttributedString:attributedString];
    return self;
}

@end


@implementation NSAttributedString(CJPay)

- (CGSize)cj_size:(CGFloat)maxWidth {
    return [self boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
}

@end

static NSString *cjMaximumLineHeightKey = @"cjMaximumLineHeightKey";
static NSString *cjMinimumLineHeightKey = @"cjMinimumLineHeightKey";
@implementation NSMutableParagraphStyle (CJPay)

- (CGFloat)cjMaximumLineHeight {
    NSNumber *cjMaximumLineHeightNumber = objc_getAssociatedObject(self, &cjMaximumLineHeightKey);
    return [cjMaximumLineHeightNumber floatValue] * [UIFont cjpayFontScale];
}

- (void)setCjMaximumLineHeight:(CGFloat)cjMaximumLineHeight {
    
    self.maximumLineHeight = cjMaximumLineHeight * [UIFont cjpayFontScale];
    
    NSNumber *cjMaximumLineHeightNumber = [NSNumber numberWithFloat:cjMaximumLineHeight];
    
    objc_setAssociatedObject(self, &cjMaximumLineHeightKey, cjMaximumLineHeightNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)cjMinimumLineHeight {
    NSNumber *cjMinimumLineHeightNumber = objc_getAssociatedObject(self, &cjMinimumLineHeightKey);
    return [cjMinimumLineHeightNumber floatValue] * [UIFont cjpayFontScale];
}

- (void)setCjMinimumLineHeight:(CGFloat)cjMinimumLineHeight {
    self.minimumLineHeight = cjMinimumLineHeight * [UIFont cjpayFontScale];
    
    NSNumber *cjMinimumLineHeightNumber = [NSNumber numberWithFloat:cjMinimumLineHeight];
    
    objc_setAssociatedObject(self, &cjMinimumLineHeightKey, cjMinimumLineHeightNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
