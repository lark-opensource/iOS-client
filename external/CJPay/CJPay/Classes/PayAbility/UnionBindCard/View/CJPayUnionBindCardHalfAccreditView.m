//
//  CJPayUnionBindCardHalfAccreditView.m
//  Pods
//
//  Created by chenbocheng on 2021/9/27.
//

#import "CJPayUnionBindCardHalfAccreditView.h"

#import "CJPayUnionBindCardAuthenticationView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayUnionBindCardAuthorizationResponse.h"

@interface CJPayUnionBindCardHalfAccreditView ()

@property (nonatomic, strong) UIImageView *changeIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIView *divideLine;
@property (nonatomic, strong) CJPayUnionBindCardAuthenticationView *authView;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayUnionBindCardAuthorizationResponse *authorizationResponse;

@end

@implementation CJPayUnionBindCardHalfAccreditView

- (instancetype)initWithResponse:(CJPayUnionBindCardAuthorizationResponse *)response {
    self = [super init];
    if (self) {
        self.authorizationResponse = response;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.protocolView];
    [self addSubview:self.confirmButton];
    [self addSubview:self.changeIconView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.divideLine];
    [self addSubview:self.authView];
        
    CJPayMasMaker(self.changeIconView, {
        make.top.centerX.equalTo(self);
        make.height.mas_equalTo(52);
        make.width.mas_equalTo(152);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.changeIconView.mas_bottom).offset(17);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(30);
        make.left.equalTo(self).offset(16);
        make.right.lessThanOrEqualTo(self).offset(-16);
    });
    
    CJPayMasMaker(self.divideLine, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(14);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.authView, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self.divideLine).offset(14);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.left.equalTo(self).offset(16);
        make.right.greaterThanOrEqualTo(self).offset(-16);
        make.bottom.equalTo(self.confirmButton.mas_top).offset(-8);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.bottom.equalTo(self).offset(CJ_IPhoneX ? -CJ_TabBarSafeBottomMargin - 16 : -16);
        make.height.mas_equalTo(44);
    });
    
    [self.authView updateContentName:self.authorizationResponse.nameMask
                               idNum:self.authorizationResponse.idCodeMask
                            phoneNum:self.authorizationResponse.mobileMask];
}

#pragma mark - lazyView
- (UIImageView *)changeIconView {
    if (!_changeIconView) {
        _changeIconView = [UIImageView new];
        [_changeIconView cj_setImageWithURL:[NSURL URLWithString:CJString(self.authorizationResponse.authorizationIconUrl)]];
    }
    return _changeIconView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:16];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.text = CJPayLocalizedStr(@"抖音支付绑定云闪付账户");
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _subTitleLabel.numberOfLines = 2;
        _subTitleLabel.text = CJPayLocalizedStr(@"授权云闪付获取你的以下信息用于绑定对应的云闪付账户");
    }
    return _subTitleLabel;
}

- (UIView *)divideLine {
    if (!_divideLine) {
        _divideLine = [UIView new];
        _divideLine.backgroundColor = [UIColor cj_divideLineColor];
    }
    return _divideLine;
}

- (CJPayUnionBindCardAuthenticationView *)authView {
    if (!_authView) {
        _authView = [CJPayUnionBindCardAuthenticationView new];
    }
    return _authView;
}


- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        CJPayCommonProtocolModel *model = [CJPayCommonProtocolModel new];
        model.agreements = self.authorizationResponse.agreements;
        model.guideDesc = self.authorizationResponse.guideMessage;
        model.groupNameDic = self.authorizationResponse.protocolGroupNames;
        model.supportRiskControl = YES;
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:model];
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.protocolClickBlock);
        };
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        [_confirmButton setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _confirmButton.backgroundColor = [UIColor cj_colorWithHexString:@"FE2C55"];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.layer.cornerRadius = 2;
    }
    return _confirmButton;
}

@end
