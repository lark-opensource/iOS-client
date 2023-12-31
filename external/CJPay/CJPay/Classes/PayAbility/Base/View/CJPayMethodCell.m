//
//  CJPayMethodCell.m
//  Pods
//
//  Created by wangxiaohong on 2020/4/9.
//

#import "CJPayMethodCell.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayLineUtil.h"
#import "CJPayStyleCheckMark.h"
#import "CJPayUIMacro.h"

@interface CJPayMethodCell()

@property (nonatomic, strong) UIImageView *bankIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleCheckMark *confirmImageView;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *disableView;
@property (nonatomic, strong) UILabel *rightMsgLabel;

@property (nonatomic, strong) CJPayChannelBizModel *model;

@property (nonatomic, strong) MASConstraint *titleLabelCenterYBaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelTopBaseSelfConstraint;

@end

@implementation CJPayMethodCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    [self.contentView addSubview:self.bankIconView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subTitleLabel];
    [self.contentView addSubview:self.rightMsgLabel];
    [self.contentView addSubview:self.confirmImageView];
    [self.contentView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.bankIconView, {
        make.left.equalTo(self.contentView).offset(16);
        make.width.height.mas_equalTo(24);
        make.centerY.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.titleLabel, {
        self.titleLabelCenterYBaseSelfConstraint = make.centerY.equalTo(self.contentView);
        self.titleLabelTopBaseSelfConstraint = make.top.equalTo(self.contentView).offset(12);
        make.left.equalTo(self.bankIconView.mas_right).offset(16);
        if ([UIFont cjpayFontMode] == CJPayFontModeLarge) {
            make.height.mas_equalTo(20);
        } else {
            make.height.mas_equalTo(16);
        }
        make.right.lessThanOrEqualTo(self.confirmImageView.mas_left).offset(-5);
    });
    [self.titleLabelCenterYBaseSelfConstraint deactivate];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.confirmImageView.mas_left).offset(-5);
        make.height.mas_equalTo(12);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
    });
    
    CJPayMasMaker(self.rightMsgLabel, {
        make.right.equalTo(self.contentView).offset(-38);
        make.centerY.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.confirmImageView, {
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-15);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self).offset(-15);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(20);
    });
    
    [self.bankIconView addSubview:self.disableView];
    CJPayMasMaker(self.disableView, {
        make.edges.equalTo(self.bankIconView);
    }); 
}

- (UIImageView *)bankIconView
{
    if (!_bankIconView) {
        _bankIconView = [UIImageView new];
    }
    return _bankIconView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_222222ff];
        _titleLabel.font = [UIFont cj_fontOfSize:16];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _subTitleLabel;
}

- (UILabel *)rightMsgLabel
{
    if (!_rightMsgLabel) {
        _rightMsgLabel = [UILabel new];
        _rightMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _rightMsgLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _rightMsgLabel;
}

- (CJPayStyleCheckMark *)confirmImageView
{
    if (!_confirmImageView) {
        _confirmImageView = [CJPayStyleCheckMark new];
        _confirmImageView.selected = NO;
    }
    return _confirmImageView;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_arrow_icon"];
        _arrowImageView.hidden = YES;
    }
    return _arrowImageView;
}

- (UIView *)disableView
{
    if (!_disableView) {
        _disableView = [UIView new];
        _disableView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
        _disableView.hidden = YES;
    }
    return _disableView;
}

- (void)p_enableCell:(BOOL)enable
{
    self.disableView.hidden = enable;
    self.titleLabel.textColor = enable? [UIColor cj_222222ff] : [UIColor cj_cacacaff];
    self.subTitleLabel.textColor = enable? [UIColor cj_999999ff] : [UIColor cj_cacacaff];
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    CJ_ModalOpenOnCurrentView;
    [self.arrowImageView cj_startLoading];
}

- (void)stopLoading {
    CJ_ModalCloseOnCurrentView;
    [self.arrowImageView cj_stopLoading];
}

#pragma mark - CJPayMethodDataUpdateProtocol
- (void)updateContent:(CJPayChannelBizModel *)model
{
    self.model = model;
    [self.bankIconView cj_setImageWithURL:[NSURL URLWithString:model.iconUrl]
                              placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    
    if (Check_ValidString(model.channelConfig.cardTailNumStr)) {
        self.titleLabel.text = [NSString stringWithFormat:@"%@(%@)", model.title, model.channelConfig.cardTailNumStr];
    } else {
        self.titleLabel.text = model.title;
    }
    
    NSString *subTitle = model.type == BDPayChannelTypeBankCard ? model.reasonStr : model.subTitle;
    if (Check_ValidString(subTitle)) {
        self.subTitleLabel.hidden = NO;
        self.subTitleLabel.text = subTitle;
        [self.titleLabelCenterYBaseSelfConstraint deactivate];
        [self.titleLabelTopBaseSelfConstraint activate];
    } else {
        self.subTitleLabel.hidden = YES;
        [self.titleLabelTopBaseSelfConstraint deactivate];
        [self.titleLabelCenterYBaseSelfConstraint activate];
    }
    
    if (model.isDYRecommendPayAgain) {
        self.arrowImageView.hidden = !model.enable;
    } else {
        self.arrowImageView.hidden = YES;
        self.confirmImageView.hidden = ![model enable];
        self.confirmImageView.selected = model.isConfirmed;
        self.rightMsgLabel.hidden = YES;

        if (model.type == BDPayChannelTypeBalance &&
            model.showCombinePay &&
            model.enable) {
            self.rightMsgLabel.hidden = NO;
            if (model.isConfirmed) {
                self.rightMsgLabel.text = CJPayLocalizedStr(@"组合支付");
                self.arrowImageView.hidden = YES;
                self.confirmImageView.hidden = NO;
            } else {
                self.rightMsgLabel.text = CJPayLocalizedStr(@"需组合支付");
                self.arrowImageView.hidden = NO;
                self.confirmImageView.hidden = YES;
            }
        }
    }
    
    [self p_enableCell:[model enable]];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data
{
    NSString *subTitle = data.type == BDPayChannelTypeBankCard ? data.reasonStr : data.subTitle;
    return Check_ValidString(subTitle) ? @(60) : @(56);
}

@end
