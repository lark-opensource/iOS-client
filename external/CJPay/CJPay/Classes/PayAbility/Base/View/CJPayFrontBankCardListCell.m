//
//  CJPayFrontBankCardListCell.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/23.
//

#import "CJPayFrontBankCardListCell.h"

#import "CJPayChannelBizModel.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayLineUtil.h"
#import "CJPayStyleCheckMark.h"


@interface CJPayFrontBankCardListCell()

@property (nonatomic, strong) UIImageView *bankIconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleCheckMark *selectImageView;
@property (nonatomic, strong) UIView *disableView;

@property (nonatomic, strong) CJPayChannelBizModel *model;

@end

@implementation CJPayFrontBankCardListCell

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
    [self.contentView addSubview:self.selectImageView];
    [self.contentView addSubview:self.disableView];
    
    CJPayMasMaker(self.bankIconView, {
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(24);
        make.left.equalTo(self.contentView).offset(15);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentView).offset(9);
        make.left.equalTo(self.bankIconView.mas_right).offset(12);
        make.right.equalTo(self.selectImageView.mas_right).offset(-15);
        make.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.right.equalTo(self.titleLabel);
        make.bottom.equalTo(self.contentView).offset(-9);
        make.height.mas_equalTo(18);
    });
    
    CJPayMasMaker(self.selectImageView, {
        make.centerY.equalTo(self);
        make.height.width.mas_equalTo(20);
        make.right.equalTo(self.contentView).offset(-16);
    });
    
    CJPayMasMaker(self.disableView, {
        make.edges.equalTo(self.bankIconView);
    });
}

- (void)p_enableCell:(BOOL)enable
{
    self.disableView.hidden = enable;
    if (enable) {
        self.titleLabel.textColor = [UIColor cj_222222ff];
        self.subTitleLabel.textColor = [UIColor cj_999999ff];
        self.bankIconView.alpha = 1;
    } else {
        self.titleLabel.textColor = [UIColor cj_cacacaff];
        self.subTitleLabel.textColor = [UIColor cj_cacacaff];
        self.bankIconView.alpha = 0.7;
    }
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
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:15];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
    }
    return _subTitleLabel;
}

- (CJPayStyleCheckMark *)selectImageView
{
    if (!_selectImageView) {
        _selectImageView = [CJPayStyleCheckMark new];
    }
    return _selectImageView;
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

#pragma mark - CJPayMethodDataUpdateProtocol
- (void)updateContent:(CJPayChannelBizModel *)model
{
    self.model = model;
    
    [self.bankIconView cj_setImageWithURL:[NSURL URLWithString:model.iconUrl]
                              placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    
    if (Check_ValidString(model.channelConfig.cardTailNumStr)) {
        self.titleLabel.text = [NSString stringWithFormat:@"%@ (%@)", model.title, model.channelConfig.cardTailNumStr];
    } else {
        self.titleLabel.text = model.title;
    }
    
    if (model.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw) {
        self.subTitleLabel.text = [model enable] ? CJString(model.WithDrawMsgStr) : CJString(model.reasonStr);
    }else{
        self.subTitleLabel.text = [model enable] ? CJString(model.limitMsgStr) : CJString(model.reasonStr);
    }
    if (!Check_ValidString(self.subTitleLabel.text)) {
         CJPayMasReMaker(self.titleLabel, {
               make.centerY.equalTo(self.contentView);
               make.left.equalTo(self.bankIconView.mas_right).offset(12);
               make.right.equalTo(self.selectImageView.mas_right).offset(-15);
               make.height.mas_equalTo(16);
         });
           
        self.subTitleLabel.hidden = YES;
    } else {
        CJPayMasReMaker(self.titleLabel, {
           make.top.equalTo(self.contentView).offset(9);
           make.left.equalTo(self.bankIconView.mas_right).offset(12);
           make.right.equalTo(self.selectImageView.mas_right).offset(-15);
           make.height.mas_equalTo(20);
       });
           
       CJPayMasReMaker(self.subTitleLabel, {
           make.left.right.equalTo(self.titleLabel);
           make.bottom.equalTo(self.contentView).offset(-9);
           make.height.mas_equalTo(18);
       });
        self.subTitleLabel.hidden = NO;
    }
    
    if (model.comeFromSceneType == CJPayComeFromSceneTypeBalanceWithdraw ||
        model.comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge) {
        self.selectImageView.selected = model.isConfirmed;
        self.selectImageView.hidden = ![model enable];
    } else {
        self.selectImageView.hidden = !(model.isConfirmed && [model enable]);
    }
    
    [self p_enableCell:model.enable];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data
{
    return @(56);
}

@end
