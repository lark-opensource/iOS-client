//
//  CJPayPassPortAlertView.m
//  Pods
//
//  Created by renqiang on 2020/8/4.
//

#import "CJPayPassPortAlertView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"


@interface CJPayPassPortAlertView ()

@property (nonatomic, copy) NSString *mainTitle;
@property (nonatomic, copy) NSString *actionTitle;

@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UILabel *headLabel;
@property (nonatomic, strong) UIImageView *passPortView;
@property (nonatomic, strong) UIButton *clickButton;

@end

@implementation CJPayPassPortAlertView

+ (instancetype)alertControllerWithTitle:(NSString *)mainTitle withActionTitle:(nullable NSString *)actionTitle{
    CJPayPassPortAlertView *alertView = [[self alloc] init];
    
    alertView.mainTitle = mainTitle;
    alertView.actionTitle = actionTitle;
    [alertView animationRegister];
    
    return alertView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.alertView];
    [self.alertView addSubview:self.headLabel];
    [self.alertView addSubview:self.passPortView];
    [self.alertView addSubview:self.clickButton];
    
    CJPayMasMaker(self.alertView, {
        make.center.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(290, 346));
    });
    
    CJPayMasMaker(self.headLabel, {
        make.centerX.mas_equalTo(self.alertView);
        make.top.mas_equalTo(self.alertView).offset(20);
    });
    
    CJPayMasMaker(self.passPortView, {
        make.top.mas_equalTo(self.headLabel.mas_bottom).offset(30);
        make.left.mas_equalTo(self.alertView).offset(17);
        make.size.mas_equalTo(CGSizeMake(258, 200));
    });
    
    CJPayMasMaker(self.clickButton, {
        make.left.right.mas_equalTo(self.alertView);
        make.bottom.mas_equalTo(self.alertView);
        make.height.mas_equalTo(44);
    });
    
    [CJPayLineUtil addTopLineToView:self.clickButton marginLeft:0 marginRight:0 marginTop:0];
}

- (void)setMainTitle:(NSString *)mainTitle
{
    _mainTitle = mainTitle;
    _headLabel.text = mainTitle;
}

- (void)setActionTitle:(NSString *)actionTitle
{
    _actionTitle = actionTitle;
    [_clickButton setTitle:actionTitle forState:UIControlStateNormal];
}

- (UILabel *)headLabel
{
    if (!_headLabel) {
        _headLabel = [UILabel new];
        _headLabel.font = [UIFont cj_boldFontOfSize:17];
    }
    return _headLabel;
}

- (UIView *)alertView
{
    if (!_alertView) {
        _alertView = [UIView new];
        _alertView.backgroundColor = [UIColor cj_colorWithHexString:@"#ffffff"];
        _alertView.layer.masksToBounds = YES;
        _alertView.layer.cornerRadius = 12;
    }
    return _alertView;
}

- (UIImageView *)passPortView
{
    if (!_passPortView) {
        _passPortView = [UIImageView new];
        [_passPortView cj_setImage:@"cj_passport_info_icon"];
    }
    return _passPortView;
}

- (UIButton *)clickButton
{
    if (!_clickButton) {
        _clickButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _clickButton.titleLabel.font = [UIFont cj_fontOfSize:17];
        [_clickButton setTitleColor:[UIColor cj_colorWithHexString:@"#1a74ff"] forState:UIControlStateNormal];

        [_clickButton addTarget:self action:@selector(action:) forControlEvents:UIControlEventTouchUpInside];
        [_clickButton setBackgroundImage:[UIImage cj_imageWithColor:UIColor.cj_e8e8e8ff] forState:UIControlStateHighlighted];
    }
    return _clickButton;
}

- (void)action:(UIButton *)button
{
    CJ_CALL_BLOCK(self.actionBlock);
    // 从父view移除，销毁对象
    [self removeFromSuperview];
}

- (void)animationRegister
{
    // 动画初始态
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    self.alertView.transform = CGAffineTransformMakeScale(1.02, 1.02);
    self.alertView.alpha = 0;
    
    // 渐入动画
    @CJWeakify(self)
    [CJPayPassPortAlertView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        @CJStrongify(self)
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.alertView.transform = CGAffineTransformMakeScale(1, 1);
        self.alertView.alpha = 1;
    } completion:^(BOOL finished) {}];
}

@end
