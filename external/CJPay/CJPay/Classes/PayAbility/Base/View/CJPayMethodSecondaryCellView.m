//
//  CJPayMethodSecondaryCellView.m
//  CJPay
//
//  Created by 王新华 on 9/4/19.
//

#import "CJPayMethodSecondaryCellView.h"
#import "CJPayCurrentTheme.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayChannelBizModel.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"

@interface CJPayMethodSecondaryCellView()

@property (nonatomic, strong) CJPayStyleImageView *rightArrowImage;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayMethodCellTagView *markLabel;
@property (nonatomic, strong) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong) UIView *seperateView;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIView *disableView;
@property (nonatomic, strong) CJPayChannelBizModel *model;

@end

@implementation CJPayMethodSecondaryCellView

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}


- (void)setupUI
{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subTitleLabel];
    [self.contentView addSubview:self.markLabel];
    [self.contentView addSubview:self.discountView];
    [self.contentView addSubview:self.rightArrowImage];
    [self.contentView addSubview:self.seperateView];
    [self.contentView addSubview:self.disableView];
    
    CJPayMasMaker(self.titleLabel, {
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(14));
        self.titleLabelLeftBaseSelfConstraint = make.left.equalTo(self.contentView).offset(56);
        self.titleLabelCenterYBaseSelfConstraint = make.centerY.equalTo(self.contentView);
        self.titleLabelTopBaseSelfConstraint = make.top.equalTo(self.contentView).offset(10);
    });
    [self.titleLabelCenterYBaseSelfConstraint deactivate];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(5);
    });
    
    CJPayMasMaker(self.markLabel, {
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.centerY.equalTo(self.titleLabel);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.seperateView, {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.discountView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.height.mas_equalTo(16);
        make.right.equalTo(self).offset(-47);
        make.centerY.equalTo(self.titleLabel);
    });
   
    CJPayMasMaker(self.rightArrowImage, {
        make.right.equalTo(self).offset(-15);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.disableView, {
        make.top.equalTo(self).offset(1);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-1);
    });
    self.disableView.hidden = YES;
}

// 获取二级标题内容
- (NSString *)p_subTitleContent {
    return self.model.type == BDPayChannelTypeBankCard ? self.model.reasonStr : self.model.subTitle;
}

- (void)p_refreshStyle
{
    BOOL isDiscountLineBreak = [self.class p_isDiscountLineBreakWithBizModel:self.model];
    
    if (isDiscountLineBreak) {
        CJPayMasReMaker(self.discountView, {
            make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
            make.left.equalTo(self.titleLabel);
            make.right.lessThanOrEqualTo(self.rightArrowImage.mas_left).offset(-8);
            make.height.mas_equalTo(16);
        });
    } else {
        CJPayMasReMaker(self.discountView, {
            make.left.equalTo(self.titleLabel.mas_right).offset(8);
            make.height.mas_equalTo(16);
            make.right.lessThanOrEqualTo(self).offset(-47);
            make.centerY.equalTo(self.titleLabel);
        });
    }
    
    if (!self.model.enable) {
        self.markLabel.hidden = YES;
        self.discountView.hidden = YES;
        self.subTitleLabel.hidden = !Check_ValidString([self p_subTitleContent]);
    } else {
        if (self.model.isNoActive) { //未激活，隐藏所有营销信息
            self.markLabel.hidden = NO;
            self.discountView.hidden = YES;
            self.subTitleLabel.hidden = !Check_ValidString([self p_subTitleContent]);
        } else {
            self.markLabel.hidden = YES;
            self.discountView.hidden = !Check_ValidString(self.model.discountStr);
            self.subTitleLabel.hidden = isDiscountLineBreak || !Check_ValidString([self p_subTitleContent]);
        }
    }
    
    if ([self.class p_isMultiLineWithBizModel:self.model]) {
        [self.titleLabelCenterYBaseSelfConstraint deactivate];
        [self.titleLabelTopBaseSelfConstraint activate];
    } else {
        [self.titleLabelTopBaseSelfConstraint deactivate];
        [self.titleLabelCenterYBaseSelfConstraint activate];
    }
    self.disableView.hidden = self.model.enable;
    self.markLabel.hidden = YES;
}

+ (BOOL)p_isDiscountLineBreakWithBizModel:(CJPayChannelBizModel *)bizModel
{
    CGSize titleLabelSize = [bizModel.title sizeWithAttributes:@{NSFontAttributeName:[UIFont cj_fontOfSize:14]}];
    CGSize discountSize = [bizModel.discountStr sizeWithAttributes:@{NSFontAttributeName:[UIFont cj_fontOfSize:14]}];
    return (56 + titleLabelSize.width + discountSize.width + 47) > CJ_SCREEN_WIDTH;
}

+ (BOOL)p_isMultiLineWithBizModel:(CJPayChannelBizModel *)data
{
    BOOL isDiscountLineBreak = [self p_isDiscountLineBreakWithBizModel:data];
    BOOL isMultiLine = NO;
    NSString *subTitle = data.type == BDPayChannelTypeBankCard ? data.reasonStr : data.subTitle;
    if (data.isNoActive || !data.enable) {
        isMultiLine = Check_ValidString(subTitle);
    } else {
        BOOL isDiscountShow = Check_ValidString(data.discountStr);
        BOOL isSubTitleShow = !isDiscountLineBreak && Check_ValidString(subTitle);
        isMultiLine =  (isDiscountShow && isDiscountLineBreak) || isSubTitleShow;
    }
    return isMultiLine;
}

#pragma mark - CJPayMethodDataUpdateProtocol

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return [self p_isMultiLineWithBizModel:data] ? @(56) : @(46);
}

- (void)updateContent:(CJPayChannelBizModel *)model {
    
    self.model = model;
    
    NSString *titleString = Check_ValidString(model.channelConfig.cardTailNumStr) ? [NSString stringWithFormat:@"%@(%@)",model.title, model.channelConfig.cardTailNumStr] : model.title;
    self.titleLabel.text = titleString;
       
    // 营销标签
    [self.discountView updateTitle:CJString(model.discountStr)];
    if (model.channelConfig.type == BDPayChannelTypeCreditPay && [model.channelConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)model.channelConfig.payChannel;
        [self.discountView updateTitle:CJString(payChannel.payTypeData.voucherMsgList.firstObject)];
        model.discountStr = payChannel.payTypeData.voucherMsgList.firstObject;
    }
    
    // 副标题
    self.subTitleLabel.text = [self p_subTitleContent];
    self.subTitleLabel.textColor = model.enable ? [UIColor cj_999999ff] : [UIColor cj_222222ff];
    
    [self p_refreshStyle];
}

#pragma mark - Getter
- (CJPayStyleImageView *)rightArrowImage
{
    if (!_rightArrowImage) {
        _rightArrowImage = [CJPayStyleImageView new];
        _rightArrowImage.image = [UIImage cj_imageWithName:@"cj_arrow_icon"];
        _rightArrowImage.backgroundColor = [UIColor whiteColor];
    }
    return _rightArrowImage;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:14];
        _titleLabel.textColor = [UIColor cj_222222ff];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
    }
    return _subTitleLabel;
}

- (CJPayMethodCellTagView *)markLabel
{
    if (!_markLabel) {
        _markLabel = [CJPayMethodCellTagView new];
        [_markLabel updateTitle:CJPayLocalizedStr(@"未激活")];
    }
    return _markLabel;
}

- (CJPayMethodCellTagView *)discountView
{
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
    }
    return _discountView;
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
