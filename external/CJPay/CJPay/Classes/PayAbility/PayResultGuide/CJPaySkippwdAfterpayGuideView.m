//
//  CJPaySkippwdAfterpayGuideView.m
//  Pods
//
//  Created by 利国卿 on 2022/4/6.
//

#import "CJPaySkippwdAfterpayGuideView.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"

@interface CJPaySkippwdAfterpayGuideView ()

@property (nonatomic, strong) CJPayBDOrderResultResponse *orderResultResponse;

@end

@implementation CJPaySkippwdAfterpayGuideView

#pragma mark - Lifecycle

- (instancetype)initWithOrderResponse:(CJPayBDOrderResultResponse *)orderResponse {
    self = [super init];
    if (self) {
        self.orderResultResponse = orderResponse;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.topImageView];
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.confirmButton];
    [self addSubview:self.protocolView];
    [self addSubview:self.tipsStackView];
    
    CJPayMasMaker(self.topImageView, {
        make.top.equalTo(self).offset(60);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(88);
    });
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.topImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(16);
        make.right.lessThanOrEqualTo(self).offset(-16);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(44);
    });
    
    if ([self p_shouldShowProtocolView]) {
        CJPayMasMaker(self.protocolView, {
            make.left.equalTo(self).offset(16);
            make.right.equalTo(self).offset(-16);
            make.bottom.equalTo(self.confirmButton.mas_top).offset(-12);
        });
    }
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self addSubview:self.safeGuardTipView];

        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self);
            make.height.mas_equalTo(18);
        });

        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-16);
        });
        
    } else {
        CJPayMasMaker(self.confirmButton, {
            make.bottom.equalTo(self).offset(-24 - CJ_TabBarSafeBottomMargin);
        });
    }
}

- (BOOL)p_shouldShowProtocolView {
    return self.orderResultResponse.skipPwdGuideInfoModel.protocoList && self.orderResultResponse.skipPwdGuideInfoModel.protocolGroupNames;
}

#pragma mark - lazy View

- (UIImageView *)topImageView {
    if (!_topImageView) {
        _topImageView = [UIImageView new];
        [_topImageView cj_setImage:@"cj_safe_key_denoise_icon"];
    }
    return _topImageView;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _mainTitleLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    }
    return _confirmButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}


- (UIStackView *)tipsStackView
{
    if (!_tipsStackView) {
        _tipsStackView = [[UIStackView alloc] init];
        _tipsStackView.axis = UILayoutConstraintAxisVertical;
        _tipsStackView.distribution = UIStackViewDistributionFillProportionally;
        _tipsStackView.spacing = 6;
    }
    return _tipsStackView;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
        commonModel.guideDesc = self.orderResultResponse.skipPwdGuideInfoModel.guideMessage;
        commonModel.agreements = self.orderResultResponse.skipPwdGuideInfoModel.protocoList;
        commonModel.groupNameDic = self.orderResultResponse.skipPwdGuideInfoModel.protocolGroupNames;
        commonModel.protocolFont = [UIFont cj_fontOfSize:12];
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:commonModel];        
    }
    return _protocolView;
}

@end
