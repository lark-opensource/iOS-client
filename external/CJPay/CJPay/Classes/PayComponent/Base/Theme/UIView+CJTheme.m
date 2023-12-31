//
//  UIView+CJTheme.m
//  Pods
//
//  Created by 易培淮 on 2021/1/28.
//

#import "UIView+CJTheme.h"
#import "UIView+CJPay.h"
#import "CJPayUIMacro.h"
#import "UIView+CJTheme.h"
#import <objc/runtime.h>
#import "CJPayUIMacro.h"

@implementation UIView (CJTheme)

- (CJPayLocalThemeStyle *)cj_getLocalTheme {
    CJPayLocalThemeStyle *theme = nil;
    if ([self cj_responseViewController].cjLocalTheme) {
        theme = [self cj_responseViewController].cjLocalTheme;
    } else {
        theme = [CJPayLocalThemeStyle defaultThemeStyle];
        [self p_reportThemeMonitor];
    }
    return theme;
}

- (void)p_reportThemeMonitor {
    [CJMonitor trackService:@"wallet_rd_multi_theme_unavailable" metric:@{} category:@{@"view_name": CJString(NSStringFromClass([self class])),@"vc_name":CJString(NSStringFromClass([[self cj_responseViewController] class])),@"default_style": @"default"} extra:@{@"call_stack":[NSThread callStackSymbols]}];
}

@end


@implementation UIScrollView(CJPay)

- (NSHashTable<UIView *> *)p_cjpayHashTable {
    NSHashTable *temHashtable = objc_getAssociatedObject(self, @selector(p_cjpayHashTable));
    if (!temHashtable) {
        temHashtable = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(self, @selector(p_cjpayHashTable), temHashtable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return temHashtable;
}

- (void)cj_bindCouldFoucsView:(UIView *)view {
    [[self p_cjpayHashTable] addObject:view];
}

- (void)cj_autoAdjustContentOffsetWhenFocus {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cj_keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cj_keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)cj_keyboardDidShow:(NSNotification *)noti {
    CGSize keyboardSize = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
    
    UIView *nextView = [self cj_nextShouldFocusViewFrom:[UIScreen mainScreen].focusedView];
    CGRect nextViewRectInWindow = [nextView convertRect:nextView.bounds toView:[self cj_responseViewController].view.window];
    CGFloat delta = (CGRectGetMaxY(nextViewRectInWindow) + keyboardSize.height - [self cj_responseViewController].view.window.cj_height);
    if (delta > 0) {
        [self setContentOffset:CGPointMake(0, self.contentOffset.y + delta + 8) animated:YES];
    }
    
    [self setContentInset:contentInsets];
    self.scrollIndicatorInsets = contentInsets;
}

- (void)cj_keyboardDidHide:(NSNotification *)noti {
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (UIView *)cj_nextShouldFocusViewFrom:(UIView *)fromView {
    if (self.window != fromView.window) {
        return nil;
    }
    CGRect fromViewRect = [fromView convertRect:fromView.frame toView:self];
    UIView *nextCloseFromView = fromView;
    CGFloat nextCloseViewYDistance = CGFLOAT_MAX;
    for (UIView *view in [self p_cjpayHashTable]) {
        if (view != fromView) {
            CGRect viewRect = [view convertRect:view.frame toView:self];
            CGFloat tmpDistance = CGRectGetMaxY(viewRect) - CGRectGetMaxY(fromViewRect);
            if (tmpDistance > 0 && tmpDistance < nextCloseViewYDistance) {
                nextCloseFromView = view;
                nextCloseViewYDistance = tmpDistance;
            }
        }
    }
    return nextCloseFromView;
}

@end
