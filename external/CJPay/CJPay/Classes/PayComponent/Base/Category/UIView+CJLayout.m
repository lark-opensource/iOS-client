//
//  UIView+CJLayout.m
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import "UIView+CJLayout.h"
#import <objc/runtime.h>
#import "CJPayDynamicLayoutModel.h"

@implementation UIView (CJLayout)

- (void)setCj_left:(CGFloat)cj_left{
    
    CGRect frame = self.frame;
    frame.origin.x = cj_left;
    self.frame = frame;
}

- (CGFloat)cj_left{
    
    return self.frame.origin.x;
}

- (void)setCj_top:(CGFloat)cj_top{
    
    CGRect frame = self.frame;
    frame.origin.y = cj_top;
    self.frame = frame;
}

- (CGFloat)cj_top {
    return self.frame.origin.y;
}


- (void)setCj_bottom:(CGFloat)cj_bottom {
    
    CGRect frame = self.frame;
    frame.origin.y = cj_bottom - self.frame.size.height;
    self.frame = frame;
}

- (CGFloat)cj_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setCj_right:(CGFloat)cj_right {
    CGRect frame = self.frame;
    frame.origin.x = cj_right - self.frame.size.width;
    self.frame = frame;
}

- (CGFloat)cj_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setCj_width:(CGFloat)cj_width {
    CGRect frame = self.frame;
    frame.size.width = cj_width;
    self.frame = frame;
}

- (CGFloat)cj_width {
    return self.frame.size.width;
}

- (void)setCj_height:(CGFloat)cj_height {
    CGRect frame = self.frame;
    frame.size.height = cj_height;
    self.frame = frame;
}

- (void)setCj_centerX:(CGFloat)cj_centerX {
    CGPoint center = self.center;
    center.x = cj_centerX;
    self.center = center;
}

- (CGFloat)cj_centerX {
    return self.center.x;
}

- (void)setCj_centerY:(CGFloat)cj_centerY {
    CGPoint center = self.center;
    center.y = cj_centerY;
    self.center = center;
}

- (CGFloat)cj_centerY {
    return self.center.y;
}

- (CGFloat)cj_height {
    return self.frame.size.height;
}

- (void)setCj_size:(CGSize)cj_size {
    CGRect frame = self.frame;
    frame.size = cj_size;
    self.frame = frame;
}

- (CGSize)cj_size {
    return self.frame.size;
}

#pragma mark - dynamic layout property

- (CJPayDynamicLayoutModel *)cj_dynamicLayoutModel {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setCj_dynamicLayoutModel:(CJPayDynamicLayoutModel *)dynamicModel {
  objc_setAssociatedObject(self, @selector(cj_dynamicLayoutModel), dynamicModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
