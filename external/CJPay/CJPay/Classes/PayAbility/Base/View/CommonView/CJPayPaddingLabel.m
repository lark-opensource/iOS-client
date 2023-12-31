//
//  CJPayPaddingLabel.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/18.
//

#import "CJPayPaddingLabel.h"

@implementation CJPayPaddingLabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines{
    CGRect insetRect = UIEdgeInsetsInsetRect(bounds, self.textInsets);
    CGRect textRect = [super textRectForBounds:insetRect limitedToNumberOfLines:numberOfLines];
    UIEdgeInsets invertedInsets = UIEdgeInsetsMake(-self.textInsets.top, -self.textInsets.left, -self.textInsets.bottom, -self.textInsets.right);
    return UIEdgeInsetsInsetRect(textRect, invertedInsets);
}

- (void)drawTextInRect:(CGRect)rect{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (CGSize)intrinsicContentSize{
    CGSize size = [super intrinsicContentSize];
    size.width  += self.textInsets.left + self.textInsets.right;
    size.height += self.textInsets.top + self.textInsets.bottom;
    return size;
}
@end
