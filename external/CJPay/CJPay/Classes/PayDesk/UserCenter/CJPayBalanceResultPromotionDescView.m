//
//  CJPayBalanceResultPromotionDescView.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import "CJPayBalanceResultPromotionDescView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayBalanceResultPromotionModel.h"
#import "CJPayWebViewUtil.h"

@interface CJPayBalanceResultPromotionDescView ()

@property (nonatomic, strong) UIImageView *rightTopIconView;
@property (nonatomic, strong) UILabel *rightTopDescLabel;
@property (nonatomic, strong) UILabel *rightBottomDescLabel;
@property (nonatomic, strong) UILabel *endTimeLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) UIImageView *tipsImageView;

@property (nonatomic, copy) NSString *jumpUrl;

@end

@implementation CJPayBalanceResultPromotionDescView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.rightTopIconView];
    [self addSubview:self.tipsImageView];
    [self addSubview:self.confirmButton];
    UIView *descContainerView = UIView.new;
    [self addSubview:descContainerView];
    CJPayMasMaker(descContainerView, {
        make.left.equalTo(self).offset(12);
        make.centerY.equalTo(self);
        make.top.greaterThanOrEqualTo(self);
        make.bottom.lessThanOrEqualTo(self);
    });
    [descContainerView addSubview:self.rightTopDescLabel];
    [descContainerView addSubview:self.rightBottomDescLabel];
    [descContainerView addSubview:self.endTimeLabel];
    CJPayMasMaker(self.rightTopIconView, {
        make.height.width.mas_equalTo(13);
        make.left.equalTo(descContainerView);
    });
    CJPayMasMaker(self.tipsImageView, {
        make.top.right.equalTo(self);
        make.width.mas_equalTo(43);
        make.height.mas_equalTo(18);
    });
    CJPayMasMaker(self.confirmButton, {
        make.centerY.equalTo(self);
        make.right.equalTo(self).offset(-12);
        make.width.mas_equalTo(64);
        make.height.mas_equalTo(24);
    });
    CJPayMasMaker(self.rightTopDescLabel, {
        make.left.equalTo(self.rightTopIconView.mas_right).offset(2);
        make.centerY.equalTo(self.rightTopIconView);
        make.right.lessThanOrEqualTo(self.tipsImageView.mas_left).offset(-12);
        make.right.lessThanOrEqualTo(descContainerView);
        make.top.equalTo(descContainerView);
    });
    CJPayMasMaker(self.rightBottomDescLabel, {
        make.left.equalTo(self.rightTopIconView);
        make.top.equalTo(self.rightTopDescLabel.mas_bottom).offset(4);
        make.right.lessThanOrEqualTo(self.confirmButton.mas_left).offset(-12);
        make.right.lessThanOrEqualTo(descContainerView);
    });
    CJPayMasMaker(self.endTimeLabel, {
        make.left.equalTo(self.rightTopIconView);
        make.top.equalTo(self.rightBottomDescLabel.mas_bottom).offset(4);
        make.bottom.equalTo(descContainerView);
        make.right.lessThanOrEqualTo(self).offset(-12);
        make.right.lessThanOrEqualTo(descContainerView);
    });
}

- (void)updateWithPromotionModel:(CJPayBalanceResultPromotionModel *)promotionModel {
    self.rightTopDescLabel.text = CJString(promotionModel.rightTopDesc);
    self.rightBottomDescLabel.text = CJString(promotionModel.rightBottomDesc);
    self.endTimeLabel.text = [NSString stringWithFormat:@"有效期至%@", promotionModel.voucherEndTime];
    self.jumpUrl = promotionModel.jumpUrl;
}

- (void)p_buttonClick {
    CJPayLogAssert(Check_ValidString(self.jumpUrl), @"voucher jump url not valid");
    [[CJPayWebViewUtil sharedUtil] openCJScheme:self.jumpUrl];
}

- (UIImageView *)rightTopIconView {
    if (!_rightTopIconView) {
        _rightTopIconView = [UIImageView new];
        [_rightTopIconView cj_setImage:@"cj_result_success_icon"];
    }
    return _rightTopIconView;
}

- (UILabel *)rightTopDescLabel {
    if (!_rightTopDescLabel) {
        _rightTopDescLabel = [UILabel new];
        _rightTopDescLabel.font = [UIFont cj_fontOfSize:11];
        _rightTopDescLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _rightTopDescLabel.numberOfLines = 1;
    }
    return _rightTopDescLabel;
}

- (UILabel *)rightBottomDescLabel {
    if (!_rightBottomDescLabel) {
        _rightBottomDescLabel = [UILabel new];
        _rightBottomDescLabel.font = [UIFont cj_boldFontOfSize:14];
        _rightBottomDescLabel.textColor = [UIColor cj_161823WithAlpha:0.85];
        _rightBottomDescLabel.numberOfLines = 2;
    }
    return _rightBottomDescLabel;
}

- (UILabel *)endTimeLabel {
    if (!_endTimeLabel) {
        _endTimeLabel = [UILabel new];
        _endTimeLabel.font = [UIFont cj_fontOfSize:11];
        _endTimeLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _endTimeLabel.numberOfLines = 1;
    }
    return _endTimeLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontWithoutFontScaleOfSize:12];
        _confirmButton.layer.cornerRadius = 4;
        _confirmButton.titleLabel.text = CJPayLocalizedStr(@"立即使用");
        [_confirmButton addTarget:self action:@selector(p_buttonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIImageView *)tipsImageView {
    if (!_tipsImageView) {
        _tipsImageView = [UIImageView new];
        [_tipsImageView cj_setImage:@"cj_balance_promotion_tips_icon"];
    }
    return _tipsImageView;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
