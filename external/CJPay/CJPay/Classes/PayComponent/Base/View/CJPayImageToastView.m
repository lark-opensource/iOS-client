//
//  CJPayImageToastView.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/22.
//

#import "CJPayImageToastView.h"
#import "CJPayUIMacro.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface CJPayImageToastView ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) CGFloat time;

@end

@implementation CJPayImageToastView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.imageView];
    [self.backgroundView addSubview:self.label];
    
    CJPayMasMaker(self.backgroundView, {
        make.edges.equalTo(self);
    });
    CJPayMasMaker(self.imageView, {
        make.height.width.mas_equalTo(28);
        make.centerX.equalTo(self);
        make.top.equalTo(self.backgroundView).offset(12);
        make.left.greaterThanOrEqualTo(self.backgroundView).offset(16);
        make.right.lessThanOrEqualTo(self.backgroundView).offset(-16);
    });
    CJPayMasMaker(self.label, {
        make.top.equalTo(self.imageView.mas_bottom).offset(4);
        make.centerX.equalTo(self);
        make.left.equalTo(self.backgroundView).offset(16);
        make.right.equalTo(self.backgroundView).offset(-16);
        make.bottom.equalTo(self.backgroundView).offset(-12);
    });
}

+ (void)toastImage:(NSString *)imageName title:(NSString *)title duration:(NSTimeInterval)duration inWindow:(UIWindow *)window {
    CJPayImageToastView *toastView = [CJPayImageToastView new];
    toastView.time = duration;
    toastView.label.text = CJString(title);
    [toastView.imageView cj_setImage:imageName];
    [toastView showInWindow:window];
}

- (void)showInWindow:(UIWindow *)inWindow {
    UIWindow *window = inWindow ?: [UIApplication sharedApplication].delegate.window;
    if (!window) {
        window = [UIApplication btd_mainWindow];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [window addSubview:self];
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
    }];
    CJPayMasMaker(self, {
        make.centerX.equalTo(window);
        make.centerY.equalTo(window);
    });
    [self setNeedsLayout];
    [self layoutIfNeeded];
    @CJWeakify(self)
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.time target:weak_self selector:@selector(hideToast) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)hideToast {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
    }
    return _imageView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [UILabel new];
        _label.font = [UIFont cj_fontOfSize:14];
        _label.textColor = UIColor.whiteColor;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
    }
    return _label;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [UIView new];
        _backgroundView.backgroundColor = UIColor.cj_393b44ff;
        _backgroundView.layer.cornerRadius = 12;
    }
    return _backgroundView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
