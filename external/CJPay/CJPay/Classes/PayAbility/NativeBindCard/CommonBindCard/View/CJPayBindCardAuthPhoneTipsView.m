//
//  CJPayBindCardAuthPhoneTipsView.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import "CJPayBindCardAuthPhoneTipsView.h"

#import "CJPayUIMacro.h"
#import "CJPayButton.h"


@interface CJPayBindCardAuthPhoneTipsView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayButton *closeButton;
@property (nonatomic, strong) UILabel *phoneNumberLabel;
@property (nonatomic, strong) CJPayButton *authButton;

@end

@implementation CJPayBindCardAuthPhoneTipsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updatePhoneNumber:(NSString *)phoneNumber
{
    if (!Check_ValidString(phoneNumber)) {
        return;
    }
    NSMutableString *formatPhoneNumberStr = [NSMutableString stringWithString:CJString(phoneNumber)];
    if (formatPhoneNumberStr.length >= 11) {
        [formatPhoneNumberStr insertString:@" " atIndex:3];
        [formatPhoneNumberStr insertString:@" " atIndex:8];
    }
    self.phoneNumberLabel.text = formatPhoneNumberStr;
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor cj_colorWithHexString:@"#FFFFFF"];
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4;
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor cj_161823WithAlpha:0.12].CGColor;
    
    self.layer.shadowColor = [UIColor cj_colorWithHexString:@"#000000" alpha:0.04].CGColor;
    self.layer.shadowOpacity = 0;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 8;
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.closeButton];
    [self addSubview:self.phoneNumberLabel];
    [self addSubview:self.authButton];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(8);
        make.left.equalTo(self).offset(16);
        make.right.lessThanOrEqualTo(self).offset(-28);
    });
    
    CJPayMasMaker(self.closeButton, {
        make.centerY.equalTo(self.titleLabel);
        make.width.height.mas_equalTo(16);
        make.right.equalTo(self).offset(-8);
    });
    
    CJPayMasMaker(self.phoneNumberLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(5);
        make.left.equalTo(self.titleLabel);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self).offset(-8);
    });
    
    CJPayMasMaker(self.authButton, {
        make.centerY.equalTo(self.phoneNumberLabel);
        make.left.equalTo(self.phoneNumberLabel.mas_right).offset(8);
        make.right.lessThanOrEqualTo(self).offset(-12);
    });
}

- (void)p_closeButtonTapped
{
    CJ_CALL_BLOCK(self.clickCloseButtonBlock);
}

- (void)p_authButtonTapped
{
    CJ_CALL_BLOCK(self.clickAuthButtonBlock);
}

#pragma mark - Lazy Views

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.text = CJPayLocalizedStr(@"授权支付服务获取App绑定手机号");
        _titleLabel.font = [UIFont cj_fontOfSize:12];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _titleLabel;
}

- (CJPayButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setBtnImageWithName:@"cj_close_icon"];
        [_closeButton addTarget:self action:@selector(p_closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)phoneNumberLabel
{
    if (!_phoneNumberLabel) {
        _phoneNumberLabel = [UILabel new];
        _phoneNumberLabel.textColor = [UIColor cj_161823ff];
        _phoneNumberLabel.font = [UIFont cj_boldFontOfSize:13];
    }
    return _phoneNumberLabel;
}

- (CJPayButton *)authButton
{
    if (!_authButton) {
        _authButton = [CJPayButton new];
        [_authButton cj_setBtnTitle:CJPayLocalizedStr(@"授权使用")];
        [_authButton cj_setBtnTitleColor:[UIColor cj_douyinBlueColor]];
        _authButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
        [_authButton addTarget:self action:@selector(p_authButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _authButton;
}

@end
