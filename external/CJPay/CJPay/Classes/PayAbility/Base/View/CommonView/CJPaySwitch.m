//
//  CJPaySwitch.m
//  Pods
//
//  Created by youerwei on 2021/7/28.
//

#import "CJPaySwitch.h"
#import "CJPayUIMacro.h"

@interface CJPaySwitch ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *spotView;

@end

@implementation CJPaySwitch
@synthesize on = _on;


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_switch)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.backgroundView];
    [self addSubview:self.spotView];
    
    CJPayMasMaker(self.backgroundView, {
        make.edges.equalTo(self);
    });
    if (self.on) {
        self.backgroundView.backgroundColor = self.onTintColor;
        CJPayMasMaker(self.spotView, {
            make.right.equalTo(self).offset(2);
            make.top.equalTo(self).offset(2);
            make.bottom.equalTo(self).offset(-2);
            make.width.equalTo(self.mas_height).offset(-4);
        });
    }
    else {
        self.backgroundView.backgroundColor = [UIColor colorWithRed:0.47 green:0.47 blue:0.5 alpha:0.16];
        CJPayMasMaker(self.spotView, {
            make.left.equalTo(self).offset(2);
            make.top.equalTo(self).offset(2);
            make.bottom.equalTo(self).offset(-2);
            make.width.equalTo(self.mas_height).offset(-4);
        });
    }
}

- (void)p_switch {
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat radius = self.frame.size.height / 2.0;
    self.backgroundView.layer.cornerRadius = radius;
    self.spotView.layer.cornerRadius = radius - 2;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [UIView new];
        _backgroundView.clipsToBounds = YES;
    }
    return _backgroundView;
}

- (UIView *)spotView {
    if (!_spotView) {
        _spotView = [UIView new];
        _spotView.backgroundColor = [UIColor whiteColor];
    }
    return _spotView;
}

- (UIColor *)onTintColor {
    if (!_onTintColor) {
        _onTintColor = [UIColor cj_colorWithHexString:@"#67DCA0"];
    }
    return _onTintColor;
}

- (void)setOn:(BOOL)on {
    _on = on;
    //animation
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        if (on) {
            self.backgroundView.backgroundColor = self.onTintColor;
            CJPayMasReMaker(self.spotView, {
                make.right.equalTo(self).offset(-2);
                make.top.equalTo(self).offset(2);
                make.bottom.equalTo(self).offset(-2);
                make.width.equalTo(self.mas_height).offset(-4);
            });
        }
        else {
            self.backgroundView.backgroundColor = [UIColor colorWithRed:0.47 green:0.47 blue:0.5 alpha:0.16];
            CJPayMasReMaker(self.spotView, {
                make.left.equalTo(self).offset(2);
                make.top.equalTo(self).offset(2);
                make.bottom.equalTo(self).offset(-2);
                make.width.equalTo(self.mas_height).offset(-4);
            });
        }
        [self layoutIfNeeded];
    } completion:nil];
}

- (BOOL)isOn {
    return _on;
}


@end
