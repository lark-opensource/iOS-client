//
// Created by 张海阳 on 2019/11/4.
//

#import "CJPayFixKeyboardView.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayAccountInsuranceTipView.h"

@interface CJPayFixKeyboardView ()

@property (nonatomic, strong) CJPaySafeKeyboard *safeKeyboard;
@property (nonatomic, strong) UIImageView *safeGuardImageView;
@property (nonatomic, strong) CJPaySafeKeyboardStyleConfigModel *model;
@property (nonatomic,   copy) NSString *safeGuardIconUrl;
@property (nonatomic, assign) CJPayViewType viewStyle;

@end


@implementation CJPayFixKeyboardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewStyle = CJPayViewTypeNormal;
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithFrameForDenoise:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewStyle = CJPayViewTypeDenoise;
        [self p_setupUIForDenoise];
    }
    return self;
}

- (instancetype)initWithSafeGuardIconUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        _safeGuardIconUrl = url;
        _viewStyle = CJPayViewTypeDenoise;
        _notShowSafeguard = NO;
        [self p_setupUIForDenoise];
    }
    return self;
}

- (UIView *)snapshot {
    if (@available(iOS 10.0, *)) {
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:self.bounds];
        return [[UIImageView alloc] initWithImage:[renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
            [self.layer renderInContext:rendererContext.CGContext];
        }]];
    } else {
        CGSize size = CGSizeMake(self.layer.bounds.size.width, self.layer.bounds.size.height);
        UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:image];
    }
}

- (void)p_setupUI {
    [self addSubview:self.bottomSafeAreaView];
    [self addSubview:self.safeKeyboard];
    [self addSubview:self.completeButton];
    [self addSubview:self.safeGuardImageView];
    
    CJPayMasMaker(self.bottomSafeAreaView, {
        make.height.mas_equalTo(50);
        make.left.right.equalTo(self);
        make.top.equalTo(self.mas_bottom);
    });
    
    self.completeButton.hidden = YES;
    
    self.safeGuardImageView.hidden = YES;
    // 数字键盘有顶部控件
    if (!self.notShowSafeguard || !self.completeButton){
        [self setupWithSafeguard];
    }
}

- (void)p_setupUIForDenoise {
    [self addSubview:self.bottomSafeAreaView];
    [self addSubview:self.safeKeyboard];
    [self addSubview:self.completeButton];
    [self addSubview:self.safeGuardImageView];
    
    CJPayMasMaker(self.bottomSafeAreaView, {
        make.height.mas_equalTo(50);
        make.left.right.equalTo(self);
        make.top.equalTo(self.mas_bottom);
    });
    
    self.completeButton.hidden = YES;
    self.safeGuardImageView.hidden = YES;
    // 数字键盘有顶部控件
    if (!self.notShowSafeguard || !self.completeButton){
        [self setupWithSafeguard];
    }
}

- (void)setupWithSafeguard {

    CJPayMasReMaker(self.safeGuardImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(12);
        make.size.mas_equalTo(CGSizeMake(183, 12));
    });
    
    CJPayMasReMaker(self.completeButton, {
        make.centerY.equalTo(self.mas_top).offset(20);
        make.right.equalTo(self).offset(-6);
    });
    
    if (!self.safeGuardIconUrl && [CJPayAccountInsuranceTipView shouldShow]) {
        self.safeGuardIconUrl = [CJPayAccountInsuranceTipView keyboardLogo];
    }
    if (self.safeGuardIconUrl) {
        self.safeGuardImageView.hidden = CJ_Pad;
        [self.safeGuardImageView cj_setImageWithURL:[NSURL URLWithString:self.safeGuardIconUrl] placeholder:nil completion:^(UIImage * _Nonnull image, NSData * _Nonnull data, NSError * _Nonnull error) {
            if (image && !error) {
                //self.safeGuardImageView.hidden = NO;
            }
        }];
    }

}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.viewStyle == CJPayViewTypeNormal) {
        [self layoutKeyboard];
    } else {
        [self layoutKeyboardForDenoise];
    }
}

- (void)layoutKeyboard {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.safeKeyboard.frame = CGRectMake(0, self.cj_size.height - 220 - CJ_TabBarSafeBottomMargin, self.cj_width, 208);
    if (self.model) {
        [self.safeKeyboard setupUIWithModel:self.model];
    } else {
        [self.safeKeyboard setupUI];
    }
    [CATransaction commit];
    self.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
    self.bottomSafeAreaView.backgroundColor = self.safeKeyboard.backgroundColor;
}

- (void)layoutKeyboardForDenoise {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.safeKeyboard.frame = CGRectMake(0, self.cj_size.height - 208 - CJ_NewTabBarSafeBottomMargin, self.cj_width, 208);
    if (self.safeKeyboard.keyboardType == CJPaySafeKeyboardTypeDenoiseV2) {
        self.safeKeyboard.frame = CGRectMake(0, self.cj_size.height - 200 - CJ_NewTabBarSafeBottomMargin, self.cj_width, 200);
    }
    if (self.safeKeyboard.keyboardType != CJPaySafeKeyboardTypeDenoiseV2 &&
        self.safeKeyboard.keyboardType != CJPaySafeKeyboardTypeDenoise) {
        self.safeKeyboard.keyboardType = CJPaySafeKeyboardTypeDenoise;
    }
    if (self.model) {
        [self.safeKeyboard setupUIWithModel:self.model];
    } else {
        [self.safeKeyboard setupUI];
    }
    [CATransaction commit];
    self.backgroundColor = [UIColor cj_colorWithHexString:@"F1F1F2"];
}

- (CJPayStyleButton *)completeButton {
    if (!_completeButton) {
        _completeButton = [CJPayStyleButton buttonWithType:UIButtonTypeCustom];
        _completeButton.isVerticalGradientFilling = YES;
        _completeButton.layer.cornerRadius = 5;
        [_completeButton setTitle:CJPayLocalizedStr(@"完成") forState:UIControlStateNormal];
        [_completeButton setTitleColor:[UIColor cj_161823ff] forState:UIControlStateNormal];
        [_completeButton setNormalBackgroundColorStart:[UIColor clearColor]];
        [_completeButton setNormalBackgroundColorEnd:[UIColor clearColor]];
        _completeButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _completeButton.tag = kButtonCompleteTag;
        [_completeButton addTarget:self action:@selector(p_buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _completeButton;
}

- (UIView *)bottomSafeAreaView {
    if (!_bottomSafeAreaView) {
        _bottomSafeAreaView = [UIView new];
    }
    return _bottomSafeAreaView;
}

- (CJPaySafeKeyboard *)safeKeyboard {
    if (!_safeKeyboard) {
        _safeKeyboard = [CJPaySafeKeyboard new];
    }
    return _safeKeyboard;
}

- (UIImageView *)safeGuardImageView {
    if (!_safeGuardImageView) {
        _safeGuardImageView = [UIImageView new];
        _safeGuardImageView.backgroundColor = [UIColor clearColor];
        _safeGuardImageView.hidden = YES;
    }
    return _safeGuardImageView;
}

- (void)p_buttonClicked:(id)sender {
    CJ_CALL_BLOCK(self.safeKeyboard.completeClickedBlock);
}

- (void)setNotShowSafeguard:(BOOL)notShowSafeguard{
    if (_notShowSafeguard != notShowSafeguard){
        _notShowSafeguard = notShowSafeguard;
        [self p_setupUI];
    }
    return;
}

@end
