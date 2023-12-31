//
//  CJPayMethodQRCodePayCell.m
//  Pods
//
//  Created by 易培淮 on 2020/10/13.
//

#import "CJPayMethodQRCodePayCell.h"
#import "CJPayPaddingLabel.h"
#import "CJPayChannelBizModel.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayLineUtil.h"
#import "CJPayMethodCellTagView.h"
#import <BDWebImage/BDWebImage.h>

@interface CJPayMethodQRCodePayCell()

@property (nonatomic, strong, readwrite) UIImageView *bankIconView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayMethodCellTagView *suggestView;
@property (nonatomic, strong) UIView *seperateView;
@property (nonatomic, strong) UIView *disableView;

@property (nonatomic, strong) CJPayChannelBizModel *model;

@property (nonatomic, strong) MASConstraint *titleLabelCenterBaseContentViewConstraint;

@property (nonatomic, strong) MASConstraint *seperateViewLeftMarginConstraint;

@end

@implementation CJPayMethodQRCodePayCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self.contentView addSubview:self.bankIconView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subTitleLabel];
    [self.contentView addSubview:self.suggestView];
    [self.contentView addSubview:self.arrowImageView];
    [self.contentView addSubview:self.seperateView];
    [self.contentView addSubview:self.disableView];

    CJPayMasMaker(self.bankIconView, {
        make.left.equalTo(self.contentView).offset(16);
        make.width.height.mas_equalTo(24);
        make.centerY.equalTo(self.contentView);
    });

    CJPayMasMaker(self.titleLabel, {
        self.titleLabelTopBaseContentViewConstraint = make.top.equalTo(self.contentView).offset(12);
        self.titleLabelCenterBaseContentViewConstraint = make.centerY.equalTo(self.contentView);
        self.titleLabelLeftBaseIconImageViewConstraint = make.left.equalTo(self.bankIconView.mas_right).offset(16);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left);
        self.titleLabelBottomBaseContentViewConstraint = make.bottom.equalTo(self.contentView).offset(-32);
    });
    [self.titleLabelCenterBaseContentViewConstraint deactivate];

    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left);
    });

    CJPayMasMaker(self.suggestView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.centerY.equalTo(self.titleLabel);
        make.height.mas_equalTo(16);
    });

    CJPayMasMaker(self.arrowImageView, {
        make.centerY.equalTo(self.bankIconView);
        make.width.height.mas_equalTo(20);
        make.right.equalTo(self.contentView).offset(-15);
    });

    CJPayMasMaker(self.seperateView, {
        make.bottom.right.equalTo(self.contentView);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        self.seperateViewLeftMarginConstraint = make.left.equalTo(self.contentView).offset(16);
    });

    CJPayMasMaker(self.disableView, {
        make.top.equalTo(self.contentView).offset(1);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-1);
    });
}

- (void)p_setViewEnable:(BOOL)enable
{
    self.disableView.hidden = enable;
    self.subTitleLabel.textColor = enable ? [UIColor cj_999999ff] : [UIColor cj_222222ff];
}

#pragma mark - CJPayMethodDataUpdateProtocol
- (void)updateContent:(CJPayChannelBizModel *)model
{
    self.model = model;

    self.seperateViewLeftMarginConstraint.offset = model.hasSub ? 56 : 16;

    [self.bankIconView cj_setImageWithURL:[NSURL URLWithString:model.iconUrl]
                              placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    self.titleLabel.text = model.title;

    self.subTitleLabel.text = CJString(model.subTitle);
    self.subTitleLabel.hidden = !Check_ValidString(model.subTitle);

    [self.suggestView updateTitle:CJString(model.channelConfig.mark)];
    self.suggestView.hidden = !Check_ValidString(model.channelConfig.mark);

    [self p_setViewEnable:model.enable];

    if (Check_ValidString(self.model.subTitle)) {
        [self.titleLabelCenterBaseContentViewConstraint deactivate];
        [self.titleLabelTopBaseContentViewConstraint activate];
        self.titleLabelBottomBaseContentViewConstraint.offset = -32;
    } else {
        [self.titleLabelTopBaseContentViewConstraint deactivate];
        [self.titleLabelCenterBaseContentViewConstraint activate];
        self.titleLabelBottomBaseContentViewConstraint.offset = -20;
    }
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data
{
    return Check_ValidString(data.subTitle) ? @(60) : @(56);
}

#pragma mark - Getter
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
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _subTitleLabel;
}

- (CJPayMethodCellTagView *)suggestView
{
    if (!_suggestView) {
        _suggestView = [CJPayMethodCellTagView new];
    }
    return _suggestView;
}

- (UIView *)seperateView
{
    if (!_seperateView) {
        _seperateView = [UIView new];
        _seperateView.backgroundColor = [UIColor cj_e8e8e8ff];
    }
    return _seperateView;
}

- (UIView *)disableView
{
    if (!_disableView) {
        _disableView = [UIView new];
        _disableView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.7];
    }
    return _disableView;
}


@end

