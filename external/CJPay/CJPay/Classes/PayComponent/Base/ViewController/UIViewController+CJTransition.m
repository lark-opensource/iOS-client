//
//  UIViewController+CJTransition.m
//  CJPay
//
//  Created by 王新华 on 11/17/19.
//

#import "UIViewController+CJTransition.h"
#import <objc/runtime.h>

@implementation UIViewController(CJTransition)

- (BOOL)cjAllowTransition {
    return [objc_getAssociatedObject(self, @selector(cjAllowTransition)) boolValue];
}

- (void)setCjAllowTransition:(BOOL)cjAllowTransition {
    objc_setAssociatedObject(self, @selector(cjAllowTransition), @(cjAllowTransition), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CJTransitionDirection)cjTransitionDirection {
    id direction = objc_getAssociatedObject(self, @selector(cjTransitionDirection));
    if (!direction) {
        return CJTransitionDirectionNone;
    }
    if ([direction isKindOfClass:[NSNumber class]]) {
        return (CJTransitionDirection)(((NSNumber *)direction).intValue);
    }
    return CJTransitionDirectionNone;
}

- (void)setCjTransitionDirection:(CJTransitionDirection)cjTransitionDirection {
    objc_setAssociatedObject(self, @selector(cjTransitionDirection), @(cjTransitionDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cjTransitionNeedShowMask {
    return [objc_getAssociatedObject(self, @selector(cjTransitionNeedShowMask)) boolValue];
}

- (void)setCjTransitionNeedShowMask:(BOOL)cjTransitionNeedShowMask {
    objc_setAssociatedObject(self, @selector(cjTransitionNeedShowMask), @(cjTransitionNeedShowMask), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cjNeedAnimation {
    return [objc_getAssociatedObject(self, @selector(cjNeedAnimation)) boolValue];
}

- (void)setCjNeedAnimation:(BOOL)cjNeedAnimation {
     objc_setAssociatedObject(self, @selector(cjNeedAnimation), @(cjNeedAnimation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cjShouldShowBottomView {
    return [objc_getAssociatedObject(self, @selector(cjShouldShowBottomView)) boolValue];
}

- (void)setCjShouldShowBottomView:(BOOL)cjShouldShowBottomView {
     objc_setAssociatedObject(self, @selector(cjShouldShowBottomView), @(cjShouldShowBottomView), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (NSString *)cjVCIdentify {
    return objc_getAssociatedObject(self, @selector(cjVCIdentify));
}

- (void)setCjVCIdentify:(NSString *)cjWebviewIdentify {
    objc_setAssociatedObject(self, @selector(cjVCIdentify), cjWebviewIdentify, OBJC_ASSOCIATION_COPY);
}


@end
