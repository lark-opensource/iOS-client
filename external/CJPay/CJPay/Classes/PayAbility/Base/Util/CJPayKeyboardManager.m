//
//  CJPayKeyboardManager.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/7/11.
//

#import "CJPayKeyboardManager.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"

@interface CJPayKeyboardManager()

@property (nonatomic, assign) BOOL keyboardShowIsAllowed;
@property (nonatomic, weak) UIView *currentResponderView;

@end

@implementation CJPayKeyboardManager

+ (instancetype)sharedInstance {
    static CJPayKeyboardManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayKeyboardManager alloc];
        manager.keyboardShowIsAllowed = YES;
    });
    return manager;
}

- (BOOL)becomeFirstResponder:(UIView *)view {
    CJPayLogInfo(@"%@ becomeFirstResponder  isFirstReponder = %@,  allowed = %@", view, view.isFirstResponder ? @"1" : @"0", self.keyboardShowIsAllowed ? @"1" : @"0");
    if (view.isFirstResponder) {
        return NO;
    }
    if (![self keyboardShowIsPermited]) {
        return NO;
    }
    BOOL result = [view becomeFirstResponder];
    if (result) {
        self.currentResponderView = view;
    }
    return result;
}
 
- (BOOL)resignFirstResponder:(UIView *)view {
    CJPayLogInfo(@"%@ resignFirstResponder", view);
    BOOL result = [view resignFirstResponder];
    return result;
}

- (void)delayPermitKeyboardShow:(CGFloat)delayTime {
    CJPayLogInfo(@"delayPermitKeyboardShow, %f", delayTime);
    [self p_delayPermitKeyboardShow:delayTime];
}

- (void)prohibitKeyboardShow {
    CJPayLogInfo(@"prohibitKeyboardShow");

    self.keyboardShowIsAllowed = NO;
}

- (void)permitKeyboardShow {
    CJPayLogInfo(@"permitKeyboardShow");
    self.keyboardShowIsAllowed = YES;
}

- (BOOL)keyboardShowIsPermited {
    return self.keyboardShowIsAllowed && ![[CJPayLoadingManager defaultService] isLoading];// 因为目前的loading是用window实现的，会导致页面依据presentedViewController判断不准确。
}

- (BOOL)recoverFirstResponder {
    return [self becomeFirstResponder:self.currentResponderView];
}

- (void)p_delayPermitKeyboardShow:(CGFloat)delayTime {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(permitKeyboardShow) object:nil];
    if (delayTime <= 0) {
        [self permitKeyboardShow];
    } else {
        [self performSelector:@selector(permitKeyboardShow) withObject:nil afterDelay:delayTime];
    }
}

@end
