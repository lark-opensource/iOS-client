//
//  CJPayToastView.m
//  CJFXJSDK
//
//  Created by 王新华 on 2018/11/22.
//

#import "CJPayToastView.h"
#import "CJPayUIMacro.h"
#import <ByteDanceKit/UIApplication+BTDAdditions.h>

#define CJPayToastViewTag 9090
@interface CJPayToastView()

@property (nonatomic, retain)UILabel *label;
@property (nonatomic, copy)NSString *title;
@property (nonatomic, assign)CGFloat time;

@end

@implementation CJPayToastView

- (UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, self.frame.size.width - 6, 30)];
        _label.textColor = [UIColor whiteColor];
        _label.font = [CJPayToastView textFont];
        _label.adjustsFontSizeToFitWidth = YES;
        _label.text = _title;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 4;
    }
    return _label;
}

+ (CGFloat)textWidth {
    return 168;
}

+ (UIFont *)textFont {
    return [UIFont systemFontOfSize:14];
}

+ (CJPayToastView *)toast:(NSString *)title inWindow:(nullable UIWindow *)window{
    return [self toastTitle:title timestamp:1 inWindow:window];
}

+ (CJPayToastView *)toastTitle:(NSString *)title timestamp:(CGFloat)time inWindow:(nullable UIWindow *)window{
    CGSize contentSize = [title cj_sizeWithFont:[self textFont] maxSize:CGSizeMake([self textWidth], 80)];
    CJPayToastView *toast = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, MAX(contentSize.width + 32, 50), contentSize.height + 24)];
    if (toast) {
        toast.backgroundColor = [UIColor cj_colorWithHexRGBA:@"000000ea"];
        toast.time = time;
        toast.title = title;
        toast.layer.masksToBounds = YES;
        toast.layer.cornerRadius = 12;
        toast.label.frame = CGRectMake((toast.frame.size.width - contentSize.width) / 2, (toast.frame.size.height - contentSize.height) / 2, contentSize.width, contentSize.height);
        [toast addSubview:toast.label];
    }
    [toast showInWindow:window];
    return toast;
}

+ (CJPayToastView *)toast:(NSString *)title code:(NSString *)code inWindow:(nullable UIWindow *)window{
    return [self toast:title code:code duration:1 inWindow:window];
}

+ (CJPayToastView *)toast:(NSString *)title code:(NSString *)code duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window{
    NSMutableAttributedString *mutableAttributedStr = [NSMutableAttributedString new];
    [mutableAttributedStr appendAttributedStringWith:title textColor:UIColor.whiteColor font:[self textFont]];
    [mutableAttributedStr appendAttributedStringWith:[NSString stringWithFormat:@"%@", code] textColor:[UIColor cj_ffffffWithAlpha:0.2] font:[self textFont]];
    
    CGSize contentSize = [mutableAttributedStr cj_size:134];
    CJPayToastView *toast = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, MAX(contentSize.width + 32, 50), contentSize.height + 24)];
    if (toast) {
        toast.backgroundColor = [UIColor cj_colorWithHexRGBA:@"000000ea"];
        toast.time = duration;
        toast.label.attributedText = mutableAttributedStr;
        toast.layer.masksToBounds = YES;
        toast.layer.cornerRadius = 8;
        toast.label.frame = CGRectMake((toast.frame.size.width - contentSize.width) / 2, (toast.frame.size.height - contentSize.height) / 2, contentSize.width, contentSize.height);
        [toast addSubview:toast.label];
    }
    [toast showInWindow:window];
    return toast;
}

- (void)showInWindow:(UIWindow * _Nullable)inWindow{
//    CJPayLogAssert(!CJ_Pad_Support_Multi_Window || inWindow, @"Pad场景下，展示toast必须要传入Window");
    UIWindow *window = inWindow ?: [UIApplication sharedApplication].delegate.window;
    if (!window) {
        window = [UIApplication btd_mainWindow];
    }
    UIView *view = [window viewWithTag:CJPayToastViewTag];
    if (view && view.superview) {
        [view removeFromSuperview];
        view = nil;
        [UIView animateWithDuration:0.1 animations:^{
            view.alpha = 0;
        }];
    }
    self.tag = CJPayToastViewTag;
    self.alpha = 0;
    self.center = window.center;
    [window insertSubview:self atIndex:1000];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    }];
    CGFloat timeDuration = 2.5;
    if (self.time > 0) {
        timeDuration = self.time;
    }
    @CJWeakify(self)
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timeDuration target:weak_self selector:@selector(hideToast) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)hideToast{
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
