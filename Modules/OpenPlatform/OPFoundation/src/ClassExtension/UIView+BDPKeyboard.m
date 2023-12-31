//
//  UIView+BDPKeyboard.m
//  Timor
//
//  Created by dingruoshan on 2019/6/5.
//

#import "UIView+BDPKeyboard.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <objc/runtime.h>
#import <ECOInfra/OPMacroUtils.h>

#pragma mark - BDPUIViewKeyboardInfo

#define KEYBOARD_ADJUST_DELAY 0.1

@interface BDPUIViewKeyboardInfo : NSObject

@property (nonatomic, assign) CGFloat keyBoardOriginY;
@property (nonatomic, weak) UIView* view;
@property (nonatomic, weak) UIView* responderView;
@property (nonatomic, assign) BOOL isKeyboardShowFired;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*,NSNumber*>* bottomPaddingDict;

@end

@implementation BDPUIViewKeyboardInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bottomPaddingDict = [NSMutableDictionary dictionary];
        [self addKeyboardObserve];
    }
    return self;
}

#pragma mark - responder
+ (id)bdp_findFirstResponderInView:(UIView*)view
{
    if (view.isFirstResponder) {
        return view;
    }
    for (UIView *subView in view.subviews) {
        id responder = [[self class] bdp_findFirstResponderInView:subView];
        if (responder) return responder;
    }
    return nil;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)addKeyboardObserve
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (self.view) {
        UIView* view = [[self class] bdp_findFirstResponderInView:self.view];
        if (view) {
            // 键盘展示消息只能发送一次并带上键盘高度，键盘弹起后高度变化不在告知JSSDK
            if (!self.isKeyboardShowFired) {
                self.isKeyboardShowFired = YES;
                self.keyBoardOriginY = self.view.frame.origin.y;
            };
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.isKeyboardShowFired = NO;
    [self adjustAppPageFrameForKeyboardHidden:notification];
}

- (void)keyboardWillChange:(NSNotification *)notification
{
    // 将键盘遮挡部分弹起
    if (self.view) {
        UIView* view = [[self class] bdp_findFirstResponderInView:self.view];
        if (view) {
            self.responderView = view;
            [self adjustAppPageFrameForKeyboardShow:notification];
        }
    }
}

#pragma mark - Keyboard Blocking Layout
/*-----------------------------------------------*/
//     Keyboard Blocking Layout - 键盘遮挡布局
/*-----------------------------------------------*/
- (void)adjustAppPageFrameForKeyboardShow:(NSNotification *)notification
{
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 此处延迟0.1s是为了响应效果与UITextView(JS-TextArea组件)一致，不是因为有坑😂
    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(KEYBOARD_ADJUST_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        StrongSelfIfNilReturn;
        [UIView animateWithDuration:duration delay:0.f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.view.frame = [self containerThatFitsForFrame:self.view.frame
                                                keyboardFrame:keyboardFrame];
        } completion:nil];
    });
}

- (void)adjustAppPageFrameForKeyboardHidden:(NSNotification *)notification
{
    CGRect targetFrame = self.view.frame;
    targetFrame.origin.y = self.keyBoardOriginY;
    UIViewAnimationOptions options = [self animationOptions:notification];
    CGFloat duration = [notification.userInfo bdp_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:duration delay:0.f options:options animations:^{
        self.view.frame = targetFrame;
    } completion:nil];
}

- (CGRect)containerThatFitsForFrame:(CGRect)frame keyboardFrame:(CGRect)keyboardFrame
{
    CGRect targetFrame = frame;
    CGRect absFrame = self.absFrame;
    CGFloat offset = (CGRectGetMaxY(absFrame) - CGRectGetMinY(keyboardFrame));
    targetFrame.origin.y -= offset;
    targetFrame.origin.y = targetFrame.origin.y > self.keyBoardOriginY ? self.keyBoardOriginY : targetFrame.origin.y;
    return targetFrame;
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (CGRect)absFrame
{
    // Convert TextView & AppPage Frame to window Coordinate System
    CGRect appPageFrameInWindow = [self.view.superview convertRect:self.view.frame toView:nil];
    CGRect textFrameInWindow = [self.responderView.superview convertRect:self.responderView.frame toView:nil];
    if (self.bottomPaddingDict[@([self.responderView hash])] != nil) {
        textFrameInWindow.size.height += [self.bottomPaddingDict[@([self.responderView hash])] doubleValue];
    } else {
        // 超出AppPage底部的部分要删掉，计算在AppPage内的部分
        CGFloat frameOutOfAppPage = CGRectGetMaxY(textFrameInWindow) - CGRectGetMaxY(appPageFrameInWindow);
        if (frameOutOfAppPage > 0.f) {
            textFrameInWindow.size.height -= frameOutOfAppPage;
        }
    }
    return textFrameInWindow;
}

#pragma mark - Animation
/*-----------------------------------------------*/
//              Animation - 动画切换
/*-----------------------------------------------*/
- (UIViewAnimationOptions)animationOptions:(NSNotification *)notification
{
    UIViewAnimationCurve animationCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = UIViewAnimationCurveEaseIn | UIViewAnimationCurveEaseOut | UIViewAnimationCurveLinear;
    switch (animationCurve) {
        case UIViewAnimationCurveEaseInOut:
            options = UIViewAnimationOptionCurveEaseInOut;
            break;
        case UIViewAnimationCurveEaseIn:
            options = UIViewAnimationOptionCurveEaseIn;
            break;
        case UIViewAnimationCurveEaseOut:
            options = UIViewAnimationOptionCurveEaseOut;
            break;
        case UIViewAnimationCurveLinear:
            options = UIViewAnimationOptionCurveLinear;
            break;
        default:
            options = animationCurve << 16;
            break;
    }
    
    return options;
}
@end

#pragma mark - UIView (BDPKeyboard)

@interface UIView (BDPKeyboard_Private)
@property (nonatomic, strong) BDPUIViewKeyboardInfo* bdp_KeyboardInfo;
@end

@implementation UIView (BDPKeyboard_Private)
- (void)setBdp_KeyboardInfo:(BDPUIViewKeyboardInfo *)keyboardInfo {
    objc_setAssociatedObject(self, @selector(bdp_KeyboardInfo), keyboardInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BDPUIViewKeyboardInfo *)bdp_KeyboardInfo {
    return objc_getAssociatedObject(self, @selector(bdp_KeyboardInfo));
}
@end

@implementation UIView (BDPKeyboard)

- (void)bdp_enableKeyboardAutoTrackScroll:(BOOL)enabled {
    if (enabled) {
        self.bdp_KeyboardInfo = [[BDPUIViewKeyboardInfo alloc] init];
        self.bdp_KeyboardInfo.view = self;
    }
    else {
        self.bdp_KeyboardInfo.view = nil;
        self.bdp_KeyboardInfo = nil;
    }
}

- (void)bdp_setKeyboardBottomPaddingWhenAutoTrackScroll:(CGFloat)bottomPadding forView:(UIView*)targetView {
    if (self.bdp_KeyboardInfo && targetView) {
        self.bdp_KeyboardInfo.bottomPaddingDict[@([targetView hash])] = @(bottomPadding);
    }
}

- (UIResponder *)bdp_findFirstResponder {
    return (UIResponder *)[BDPUIViewKeyboardInfo bdp_findFirstResponderInView:self];
}

@end
