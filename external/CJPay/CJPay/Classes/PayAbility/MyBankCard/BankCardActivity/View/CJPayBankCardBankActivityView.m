//
//  CJPayBankCardBankActivityView.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBankCardBankActivityView.h"
#import "CJPayBankActivityInfoModel.h"
#import "CJPayUIMacro.h"
#import "CJPayButton.h"

#import <BDWebImage/BDWebImage.h>

@interface CJPayBankCardBankActivityView ()

#pragma mark - view
@property (nonatomic, strong) UIImageView *bankImageView;
@property (nonatomic, strong) UILabel *bankHeaderLabel;
@property (nonatomic, strong) UILabel *promotionAmountLabel;
@property (nonatomic, strong) UILabel *promotionDescLabel;
@property (nonatomic, strong) CJPayButton *bindCardButton;

@property (nonatomic, strong) UILabel *activityInfoLabel;

#pragma mark - data
@property (nonatomic, strong) CJPayBankActivityInfoModel *activityInfoModel;

#pragma mark - MASConstraint
@property (nonatomic, weak) MASConstraint *emptyActivityInfoLabelCenterYConstraint;

@end

@implementation CJPayBankCardBankActivityView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private method

- (void)p_setupUI {
    self.clipsToBounds = YES;
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4;
    
    UIImageView *bgView = [UIImageView new];
    [bgView cj_setImage:@"cj_bindcard_promotion_background_icon"];
    [self addSubview:bgView];
    
    UIView *headerContentView = [UIView new];
    [headerContentView addSubview:self.bankImageView];
    [headerContentView addSubview:self.bankHeaderLabel];
    [self addSubview:headerContentView];
    
    UIView *promotionView = [UIView new];
    [promotionView addSubview:self.promotionDescLabel];
    [promotionView addSubview:self.promotionAmountLabel];
    [self addSubview:promotionView];
    
    [self addSubview:self.bindCardButton];
    [self addSubview:self.activityInfoLabel];
    
    CJPayMasMaker(bgView, {
        make.edges.equalTo(self);
    });

    CJPayMasMaker(headerContentView, {
        make.top.equalTo(self).offset(10);
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
    });
    
    CJPayMasMaker(self.bankImageView, {
        make.centerY.equalTo(self.bankHeaderLabel);
        make.left.equalTo(headerContentView);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.bankHeaderLabel, {
        make.top.equalTo(headerContentView);
        make.bottom.equalTo(headerContentView);
        make.left.equalTo(self.bankImageView.mas_right).offset(4);
        make.right.equalTo(headerContentView);
    });
    
    CJPayMasMaker(promotionView, {
        make.top.equalTo(headerContentView.mas_bottom).offset(11);
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
    })

    CJPayMasMaker(self.promotionAmountLabel, {
        make.top.left.bottom.equalTo(promotionView);
    })
    
    CJPayMasMaker(self.promotionDescLabel, {
        make.left.equalTo(self.promotionAmountLabel.mas_right).offset(2);
        make.centerY.equalTo(promotionView).offset(1);
        make.right.lessThanOrEqualTo(promotionView);
    })
    
    CJPayMasMaker(self.bindCardButton, {
        make.left.equalTo(self).offset(12);
        make.top.equalTo(promotionView.mas_bottom).offset(2);
        make.width.mas_equalTo(58);
        make.height.mas_equalTo(22);
    })
    
    CJPayMasMaker(self.activityInfoLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    });
}

- (void)p_backgroundClick {
    CJ_CALL_BLOCK(self.didSelectedBlock, self.activityInfoModel);
}

- (void)p_bindCardButtonClick {
    CJ_CALL_BLOCK(self.buttonClickBlock, self.activityInfoModel);
}

#pragma mark - private method
- (void)p_loadEmptyActivityView {
    self.bankImageView.hidden = YES;
    self.bankHeaderLabel.hidden = YES;
    self.promotionAmountLabel.hidden = YES;
    self.promotionDescLabel.hidden = YES;
    self.bindCardButton.hidden = YES;
    self.activityInfoLabel.hidden = NO;
}

- (void)p_loadBankActivityView {
    self.bankImageView.hidden = NO;
    self.bankHeaderLabel.hidden = NO;
    self.promotionAmountLabel.hidden = NO;
    self.promotionDescLabel.hidden = NO;
    self.bindCardButton.hidden = NO;
    self.activityInfoLabel.hidden = YES;
    
    [self.bankImageView cj_setImageWithURL:[NSURL URLWithString:CJString(self.activityInfoModel.iconUrl)]
                               placeholder:[UIImage cj_imageWithName:@"cj_backup_bank_icon"]];
    self.bankHeaderLabel.text = CJString(self.activityInfoModel.bankCardName);
    self.promotionAmountLabel.text = CJString(self.activityInfoModel.benefitAmount);
    self.promotionDescLabel.text = CJString(self.activityInfoModel.benefitDesc);
    [self.bindCardButton cj_setBtnTitle:self.activityInfoModel.buttonDesc];
}

#pragma mark - public method
- (void)bindBankActivityModel:(CJPayBankActivityInfoModel *)model {
    self.activityInfoModel = model;
    
    if (model.isEmptyResource) {
        [self p_loadEmptyActivityView];
    } else {
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_backgroundClick)];
        [self addGestureRecognizer:tapGes];
        [self.bindCardButton addTarget:self action:@selector(p_bindCardButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self p_loadBankActivityView];
    }
}

#pragma mark - lazy views

- (UIImageView *)bankImageView {
    if (!_bankImageView) {
        _bankImageView = [UIImageView new];
    }
    return _bankImageView;
}

- (UILabel *)bankHeaderLabel {
    if (!_bankHeaderLabel) {
        _bankHeaderLabel = [UILabel new];
        _bankHeaderLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _bankHeaderLabel.font = [UIFont cj_boldFontOfSize:13];
        _bankHeaderLabel.numberOfLines = 1;
        _bankHeaderLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _bankHeaderLabel;
}

- (UILabel *)activityInfoLabel {
    if (!_activityInfoLabel) {
        _activityInfoLabel = [UILabel new];
        _activityInfoLabel.font = [UIFont cj_fontOfSize:11];
        _activityInfoLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _activityInfoLabel.numberOfLines = 1;
        _activityInfoLabel.text = CJPayLocalizedStr(@"更多福利，敬请期待");
    }
    return _activityInfoLabel;
}

- (UILabel *)promotionAmountLabel {
    if (!_promotionAmountLabel) {
        _promotionAmountLabel = [UILabel new];
        _promotionAmountLabel.font = [UIFont cj_denoiseBoldFontOfSize:24];
        _promotionAmountLabel.textColor = [UIColor cj_fe2c55ff];
        _promotionAmountLabel.numberOfLines = 1;
    }
    return _promotionAmountLabel;
}

- (UILabel *)promotionDescLabel {
    if (!_promotionDescLabel) {
        _promotionDescLabel = [UILabel new];
        _promotionDescLabel.font = [UIFont cj_fontOfSize:12];
        _promotionDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _promotionDescLabel.numberOfLines = 1;
        _promotionDescLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _promotionDescLabel;
}

- (CJPayButton *)bindCardButton {
    if (!_bindCardButton) {
        _bindCardButton = [CJPayButton new];
        [_bindCardButton cj_setBtnTitleColor:[UIColor whiteColor]];
        [_bindCardButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        _bindCardButton.titleLabel.font = [UIFont cj_boldFontOfSize:11];
        _bindCardButton.layer.cornerRadius = 2;
        _bindCardButton.clipsToBounds = YES;
    }
    return _bindCardButton;
}

@end
