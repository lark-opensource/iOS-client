//
//  CJPayBytePayMethodSecondaryCellView.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayBytePayMethodSecondaryCell.h"

#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayAlertUtil.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayChannelModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayInComePayAlertContentView.h"
#import "CJPayDyTextPopUpViewController.h"

@interface CJPayBytePayMethodSecondaryCell()

@property (nonatomic, strong, readwrite) UIImageView *iconImgView;
@property (nonatomic, strong, readwrite) CJPaySubPayTypeIconTipModel *iconTip;

@end

@implementation CJPayBytePayMethodSecondaryCell

- (void)setupUI {
    [super setupUI];
    self.titleLabel.font = [UIFont cj_boldFontOfSize:14];
    self.titleLabel.textColor = [UIColor cj_161823ff];
    [self.contentView addSubview:self.rightMsgLabel];
    [self.contentView addSubview:self.iconImgView];
    
    CJPayMasMaker(self.rightMsgLabel, {
        make.right.equalTo(self).offset(-32);
        make.left.greaterThanOrEqualTo(self.titleLabel.mas_right).offset(32);
        make.centerY.equalTo(self.titleLabel);
    });
    
    CJPayMasReMaker(self.rightArrowImage, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.titleLabel);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasReMaker(self.iconImgView, {
        make.left.equalTo(self.subTitleLabel.mas_right).offset(4);
        make.centerY.equalTo(self.subTitleLabel);
        make.width.height.mas_equalTo(16);
    });
}



- (void)updateContent:(CJPayChannelBizModel *)data {
    [super updateContent:data];
    CJPaySubPayTypeInfoModel *model = (CJPaySubPayTypeInfoModel *)data.channelConfig.payChannel;
    self.iconTip = model.payTypeData.iconTips;
    self.seperateView.hidden = YES;
    self.discountView.hidden = YES;
    self.iconImgView.hidden = self.subTitleLabel.hidden;
    
    self.titleLabelLeftBaseSelfConstraint.offset = 52;
    self.rightMsgLabel.text = @"更换";
    
    if (data.channelConfig.isShowRedDot) {
        [self p_refreshVoucherLabel:data];
        [self.rightArrowImage setStyleImage:@"cj_combine_pay_arrow_with_dot_denoise_icon"];
    } else {
        [self.rightArrowImage setImage:@"cj_combine_pay_arrow_denoise_icon" backgroundColor:UIColor.whiteColor];
    }
    
    if (Check_ValidString(data.discountStr)) {
        [self p_refreshDiscountView:data];
    }
}

- (void)p_refreshDiscountView:(CJPayChannelBizModel *)data {
    BOOL isDiscountLineBreak = [self.class p_isDiscountLineBreakWithBizModel:data];
    self.discountView.hidden = NO;
    
    if (isDiscountLineBreak) {
        CJPayMasReMaker(self.discountView, {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
            make.left.equalTo(self.titleLabel);
            make.right.lessThanOrEqualTo(self.rightArrowImage.mas_left).offset(-8);
            make.height.mas_equalTo(14);
        });
    } else {
        CJPayMasReMaker(self.discountView, {
            make.left.equalTo(self.titleLabel.mas_right).offset(8);
            make.height.mas_equalTo(14);
            make.right.lessThanOrEqualTo(self).offset(-47);
            make.centerY.equalTo(self.titleLabel);
        });
    }
}

- (void)p_refreshVoucherLabel:(CJPayChannelBizModel *)data {
    self.rightMsgLabel.text = data.channelConfig.voucherMsg;
}

- (UILabel *)rightMsgLabel {
    if (!_rightMsgLabel) {
        _rightMsgLabel = [UILabel new];
        _rightMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _rightMsgLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _rightMsgLabel;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [UIImageView new];
        [_iconImgView cj_setImage:@"cj_income_pay_about_icon"];
        _iconImgView.userInteractionEnabled = YES;
        [_iconImgView cj_viewAddTarget:self action:@selector(p_tapIncomePayAboutImageView) forControlEvents:UIControlEventTouchUpInside];
    }
    return _iconImgView;
}

- (void)p_tapIncomePayAboutImageView {
    CJPayInComePayAlertContentView *alertContentView = [[CJPayInComePayAlertContentView alloc] initWithIconTips:self.iconTip];
    CJPayDyTextPopUpModel *model = [CJPayDyTextPopUpModel new];
    model.type = CJPayTextPopUpTypeDefault;
    CJPayDyTextPopUpViewController *alertVC = [[CJPayDyTextPopUpViewController alloc] initWithPopUpModel:model contentView:alertContentView];
    [alertVC showOnTopVC:[UIViewController cj_topViewController]];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    if ([self p_isDisplayDiscountLabel:data] && [self p_isDiscountLineBreakWithBizModel:data]) {
        return @(52);
    } else {
        return @(48);
    }
}

+ (BOOL)p_isDiscountLineBreakWithBizModel:(CJPayChannelBizModel *)bizModel {
    CGFloat titleLabelWidth = [bizModel.title cj_sizeWithFont:[UIFont cj_fontOfSize:14] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    CGFloat discountLabelWidth = [bizModel.discountStr cj_sizeWithFont:[UIFont cj_fontOfSize:10] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    CGFloat voucherMsgWidth = Check_ValidString(bizModel.channelConfig.voucherMsg) ? [bizModel.channelConfig.voucherMsg cj_sizeWithFont:[UIFont cj_fontOfSize:12] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width : 24;
    return (52 + titleLabelWidth + 8 + discountLabelWidth + 6 + 32 + voucherMsgWidth + 32) > CJ_SCREEN_WIDTH;
}

+ (BOOL)p_isDisplayDiscountLabel:(CJPayChannelBizModel *)bizModel {
    if (Check_ValidString(bizModel.discountStr)) {
        if (bizModel.type == BDPayChannelTypeAddBankCard) {
            return !Check_ValidString(bizModel.channelConfig.voucherMsg);
        }
        return YES;
    }
    return NO;
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    CJ_ModalOpenOnCurrentView;
    [self.rightArrowImage cj_startLoading];
}

- (void)stopLoading {
    CJ_ModalCloseOnCurrentView;
    [self.rightArrowImage cj_stopLoading];
}

@end
