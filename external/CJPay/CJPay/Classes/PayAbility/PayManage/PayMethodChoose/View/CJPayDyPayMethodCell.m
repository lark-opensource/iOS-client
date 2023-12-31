//
//  CJPayDyPayMethodCell.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/23.
//

#import "CJPayDyPayMethodCell.h"
#import "CJPayDyPayMethodCellViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayLineUtil.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayStyleCheckMark.h"

#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayLineUtil.h"
#import <BDWebImage/BDWebImage.h>

@interface CJPayDyPayMethodCell ()

@property (nonatomic, strong) UIImageView *bankIconView; //支付方式图标
@property (nonatomic, strong) UILabel *titleLabel; //支付方式名称
@property (nonatomic, strong) UILabel *subTitleLabel; //副标题

@property (nonatomic, strong) UIView *disableView; //支付方式不可用蒙层
@property (nonatomic, strong) CJPayMethodCellTagView *discountView; //营销信息
@property (nonatomic, strong) CJPayMethodCellTagView *cardbinVoucherView; //卡bin营销

@property (nonatomic, strong) UIView *rightDomainView; //右侧区域
@property (nonatomic, strong) CJPayStyleCheckMark *confirmImageView; //勾选图案
@property (nonatomic, strong) UIImageView *rightArrowImage; // 右箭头
@property (nonatomic, strong) UILabel *rightTipsMsgLabel; //支付方式提示文案
@property (nonatomic, strong) UILabel *descTitleLabel; //最下方用于固定展示背书文案

@property (nonatomic, strong) MASConstraint *titleLabelTopBaseContainerViewConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelCenterYBaseContainerViewConstraint;
@property (nonatomic, strong) MASConstraint *confirmImageViewLeftBaserightDomainViewConstraint;

@end

@implementation CJPayDyPayMethodCell

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.bankIconView];
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    [self.containerView addSubview:self.discountView];
    [self.containerView addSubview:self.cardbinVoucherView];
    [self.containerView addSubview:self.rightDomainView];
    [self.containerView addSubview:self.descTitleLabel];

    [self.rightDomainView addSubview:self.confirmImageView];
    [self.rightDomainView addSubview:self.rightArrowImage];
    [self.rightDomainView addSubview:self.rightTipsMsgLabel];
    
    [self.containerView addSubview:self.disableView];
    
    CJPayMasMaker(self.bankIconView, {
        make.left.equalTo(self.containerView).offset(16);
        make.width.height.mas_equalTo(18);
        make.centerY.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.bankIconView.mas_right).offset(10);
        make.right.lessThanOrEqualTo(self.rightDomainView.mas_left).offset(-8);
        self.titleLabelCenterYBaseContainerViewConstraint = make.centerY.equalTo(self.containerView);
        self.titleLabelTopBaseContainerViewConstraint = make.top.equalTo(self.containerView).offset(10);
    });
    [self.titleLabelTopBaseContainerViewConstraint deactivate];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.rightDomainView.mas_left).offset(-8);
    });
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.rightDomainView.mas_left).offset(-8);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.cardbinVoucherView, {
        make.left.equalTo(self.discountView.mas_right).offset(4);
        make.top.height.equalTo(self.discountView);
        make.right.lessThanOrEqualTo(self.rightDomainView.mas_left).offset(-8);
    });
    
    CJPayMasMaker(self.rightDomainView, {
        make.right.equalTo(self.containerView).offset(-16);
        make.centerY.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.confirmImageView, {
        self.confirmImageViewLeftBaserightDomainViewConstraint = make.left.equalTo(self.rightDomainView);
        make.right.equalTo(self.rightDomainView);
        make.width.height.mas_equalTo(16);
        make.top.bottom.equalTo(self.rightDomainView);
    });
    
    CJPayMasMaker(self.descTitleLabel, {
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.rightDomainView.mas_left);
        make.bottom.equalTo(self.containerView).offset(-10);
        make.height.mas_equalTo(15);
    });
    
    CJPayMasMaker(self.disableView, {
        make.top.equalTo(self.containerView).offset(1);
        make.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-1);
    });
    
}

#pragma mark - viewModel
- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:CJPayDyPayMethodCellViewModel.class]) {
        CJPayDyPayMethodCellViewModel *payMethodCellViewModel = (CJPayDyPayMethodCellViewModel *)viewModel;
        [self p_reloadContentWithViewModel:payMethodCellViewModel];
        [self p_updateLayoutWithViewModel:payMethodCellViewModel];
    }
}

- (void)p_reloadContentWithViewModel:(CJPayDyPayMethodCellViewModel *)viewModel {
    CJPayDefaultChannelShowConfig *config = viewModel.showConfig;
    [self.bankIconView cj_setImageWithURL:[NSURL URLWithString:config.iconUrl]
                              placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    self.titleLabel.text = CJString(config.title);
    self.subTitleLabel.text = CJString(config.subTitle);
    self.descTitleLabel.text = CJString(config.descTitle);
    self.rightTipsMsgLabel.text = CJString(config.payTypeData.selectPageGuideText);
    if ((config.type == BDPayChannelTypeBalance || config.type == BDPayChannelTypeIncomePay)&& config.showCombinePay && config.canUse) {
        self.rightTipsMsgLabel.text = CJPayLocalizedStr(@"需组合支付");
        if (config.isSelected) {
            self.rightTipsMsgLabel.text = CJPayLocalizedStr(@"组合支付");
        }
    }
    [self.discountView updateTitle:CJString(config.discountStr)];
    [self.cardbinVoucherView updateTitle:CJString(config.cardBinVoucher)];
}

- (void)p_updateLayoutWithViewModel:(CJPayDyPayMethodCellViewModel *)viewModel {

    // 需要展示上方分割线
    if (viewModel.needAddTopLine) {
        [CJPayLineUtil addTopLineToView:self.containerView marginLeft:44 marginRight:-16 marginTop:-6.25 color:[UIColor cj_161823WithAlpha:0.08]];
    }
    
    CJPayDefaultChannelShowConfig *config = viewModel.showConfig;
    self.subTitleLabel.hidden = YES;
    self.discountView.hidden = YES;
    self.cardbinVoucherView.hidden = YES;
    self.confirmImageView.hidden = !config.canUse;
    self.rightTipsMsgLabel.hidden = YES;
    self.rightArrowImage.hidden = YES;
    self.disableView.hidden = config.canUse;
    self.descTitleLabel.hidden = !Check_ValidString(config.descTitle);
    self.descTitleLabel.textColor = config.enable ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_161823ff];
    
    // 需要展示副标题
    if (Check_ValidString(config.subTitle)) {
        self.subTitleLabel.hidden = NO;
        if (Check_ValidString(config.subTitleColor) && [UIColor cj_colorWithHexString:config.subTitleColor]) {
            self.subTitleLabel.textColor = [UIColor cj_colorWithHexString:config.subTitleColor];
        }
    } else if (config.canUse && Check_ValidString(config.discountStr)){
        // 展示营销
        self.discountView.hidden = NO;
        // 展示卡bin营销
        if (Check_ValidString(config.cardBinVoucher)) {
            self.cardbinVoucherView.hidden = NO;
        }
    }
    
    if (Check_ValidString(config.subTitle) || (config.canUse && Check_ValidString(config.discountStr)) || Check_ValidString(config.descTitle)) {
        // 有副标题或有营销或有背书文案时不居中展示
        [self.titleLabelTopBaseContainerViewConstraint activate];
        [self.titleLabelCenterYBaseContainerViewConstraint deactivate];
    } else {
        
        [self.titleLabelTopBaseContainerViewConstraint deactivate];
        [self.titleLabelCenterYBaseContainerViewConstraint activate];
    }
    
    [self.confirmImageView setSelected:config.isSelected];
    // 需要展示右箭头（隐藏确认图标）
    if ((config.canUse && config.type == BDPayChannelTypeAddBankCard) ||
        ((config.type == BDPayChannelTypeBalance || config.type == BDPayChannelTypeIncomePay) && config.showCombinePay && config.canUse) || // 零钱&业务收入展示组合支付入口
        [config isNeedReSigning]) {
        [self.confirmImageViewLeftBaserightDomainViewConstraint deactivate];
        
        if (config.type == BDPayChannelTypeAddBankCard || [config isNeedReSigning]) {
            self.confirmImageView.hidden = YES;
            self.rightArrowImage.hidden = (viewModel.isDeduct && !config.canUse); // 轮扣的话隐藏箭头
        } else {
            self.confirmImageView.hidden = NO;
            self.rightArrowImage.hidden = YES;
        }
        
        BOOL needShowTips = Check_ValidString(config.payTypeData.selectPageGuideText);
        if (config.type == BDPayChannelTypeBalance || config.type == BDPayChannelTypeIncomePay || [config isNeedReSigning]) {
            needShowTips = YES;
        }
        
        CJPayMasReMaker(self.rightArrowImage, {
            make.top.bottom.equalTo(self.rightDomainView);
            make.right.equalTo(self.rightDomainView);
            make.width.height.mas_equalTo(16);
            if (!needShowTips) {
                make.left.equalTo(self.rightDomainView);
            }
        });
        // 需要展示引导文案
        if (needShowTips) {
            self.rightTipsMsgLabel.hidden = !config.enable;
            CJPayMasReMaker(self.rightTipsMsgLabel, {
                if (config.showCombinePay) {
                    make.right.equalTo(self.rightArrowImage.mas_left).offset(-4);
                } else {
                    make.right.equalTo(self.rightArrowImage.mas_left);
                }
                make.centerY.equalTo(self.rightDomainView);
                make.left.equalTo(self.rightDomainView);
            });
            [self.rightTipsMsgLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        }
    } else {
        [self.confirmImageViewLeftBaserightDomainViewConstraint activate];
    }
    
}

- (void)didSelect {
    if ([self.viewModel isKindOfClass:[CJPayDyPayMethodCellViewModel class]]) {
        CJPayDyPayMethodCellViewModel *payMethodModel = (CJPayDyPayMethodCellViewModel *)self.viewModel;
        CJ_CALL_BLOCK(payMethodModel.didSelectedBlock, payMethodModel.showConfig);
    }
}

#pragma mark - loading delegate
- (void)startLoading {
    [self.rightArrowImage cj_startLoading];
    [self cj_responseViewController].view.window.userInteractionEnabled = NO;
}

- (void)stopLoading {
    [self.rightArrowImage cj_stopLoading];
    [self cj_responseViewController].view.window.userInteractionEnabled = YES;
}

#pragma mark - lazy init
- (UIImageView *)bankIconView {
    if (!_bankIconView) {
        _bankIconView = [UIImageView new];
    }
    return _bankIconView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [UIColor cj_161823ff];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
    }
    return _subTitleLabel;
}

- (CJPayStyleCheckMark *)confirmImageView {
    if (!_confirmImageView) {
        _confirmImageView = [[CJPayStyleCheckMark alloc] initWithDiameter:16];
        _confirmImageView.backgroundColor = [UIColor whiteColor];
    }
    return _confirmImageView;
}

- (UIView *)disableView {
    if (!_disableView) {
        _disableView = [UIView new];
        _disableView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    }
    return _disableView;
}

- (CJPayMethodCellTagView *)discountView
{
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
    }
    return _discountView;
}

- (CJPayMethodCellTagView *)cardbinVoucherView {
    if (!_cardbinVoucherView) {
        _cardbinVoucherView = [CJPayMethodCellTagView new];
    }
    return _cardbinVoucherView;
}

- (UIView *)rightDomainView {
    if (!_rightDomainView) {
        _rightDomainView = [UIView new];
        _rightDomainView.backgroundColor = [UIColor clearColor];
    }
    return _rightDomainView;
}

- (UILabel *)rightTipsMsgLabel {
    if (!_rightTipsMsgLabel) {
        _rightTipsMsgLabel = [UILabel new];
        _rightTipsMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
        _rightTipsMsgLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _rightTipsMsgLabel;
}

- (UIImageView *)rightArrowImage {
    if (!_rightArrowImage) {
        _rightArrowImage = [UIImageView new];
        [_rightArrowImage cj_setImage:@"cj_combine_pay_arrow_denoise_icon"];
    }
    return _rightArrowImage;
}

- (UILabel *)descTitleLabel {
    if (!_descTitleLabel) {
        _descTitleLabel = [UILabel new];
        _descTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _descTitleLabel.font = [UIFont cj_fontOfSize:11];
    }
    return _descTitleLabel;
}

@end
