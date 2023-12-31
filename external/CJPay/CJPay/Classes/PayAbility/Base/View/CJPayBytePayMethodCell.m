//
//  CJPayBytePayMethodCell.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayBytePayMethodCell.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import "CJPayMethodTableViewCell.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayInComePayAlertContentView.h"
#import "CJPayAlertUtil.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayCoupleLabelView.h"
#import "CJPayDyTextPopUpViewController.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayTypeVoucherMsgV2Model.h"

@interface CJPayBytePayMethodCell()

@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong, readwrite) UILabel *rightMsgLabel;
@property (nonatomic, strong, readwrite) CJPayCoupleLabelView *voucherLabelView; //标题右侧展示
@property (nonatomic, strong, readwrite) CJPayMethodCellTagView *discountView; //副标题位置展示，居左 或者 标题右侧展示
@property (nonatomic, strong, readwrite) CJPayMethodCellTagView *cardBinView; //副标题位置展示，居右
@property (nonatomic, strong, readwrite) UIImageView *rightArrowImage;
@property (nonatomic, strong, readwrite) UIImageView *iconImgView;
@property (nonatomic, strong, readwrite) CJPaySubPayTypeIconTipModel *iconTip;
@property (nonatomic, strong ,readwrite) UILabel *tipsMsgLabel; //一级支付方式功能提示文案

@end

@implementation CJPayBytePayMethodCell

- (void)setupUI {
    [super setupUI];
    [self.contentView addSubview:self.topLineView];
    [self.contentView addSubview:self.discountView];
    [self.contentView addSubview:self.cardBinView];
    [self.contentView addSubview:self.rightArrowImage];
    [self.contentView addSubview:self.rightMsgLabel];
    [self.contentView addSubview:self.iconImgView];
    [self.contentView addSubview:self.voucherLabelView];
    [self.contentView addSubview:self.tipsMsgLabel];
    
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.subTitleLabel.font = [UIFont cj_fontOfSize:13];
    
    self.seperateView.hidden = YES;
    
    self.titleLabelTopBaseContentViewConstraint.offset = 11;
    self.titleLabelLeftBaseIconImageViewConstraint.offset = 8;
    
    CJPayMasMaker(self.topLineView, {
        make.top.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(44);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    })
    
    CJPayMasReMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.confirmImageView.mas_left).offset(-6);
    });
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    CJPayMasMaker(self.voucherLabelView, {
        make.centerY.equalTo(self.titleLabel);
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.right.lessThanOrEqualTo(self.tipsMsgLabel.mas_left).offset(-8);
    });
    [self.voucherLabelView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(3);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.cardBinView.mas_left).offset(-8);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.cardBinView, {
        make.top.height.equalTo(self.discountView);
        make.left.equalTo(self.discountView.mas_right).offset(8);
        make.right.lessThanOrEqualTo(self.rightMsgLabel.mas_left).offset(-4);
    });
    
    CJPayMasMaker(self.tipsMsgLabel, {
        make.right.equalTo(self.confirmImageView.mas_left).offset(-8);
        make.centerY.equalTo(self.confirmImageView);
    });
    [self.tipsMsgLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.rightMsgLabel, {
        make.right.equalTo(self).offset(-38);
        make.centerY.equalTo(self.contentView);
    });
    [self.rightMsgLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    CJPayMasMaker(self.rightArrowImage, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.contentView);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasReMaker(self.iconImgView, {
        make.left.equalTo(self.subTitleLabel.mas_right).offset(4);
        make.centerY.equalTo(self.subTitleLabel);
        make.width.height.mas_equalTo(16);
    });
}

- (void)updateContent:(CJPayChannelBizModel *)model {
    [super updateContent:model];

    self.topLineView.hidden = !model.isNeedTopLine;
    self.titleLabel.font = model.isEcommercePay ? [UIFont cj_fontOfSize:15] : [UIFont cj_boldFontOfSize:15];
    if (model.channelConfig.payChannel.signStatus == 1) {
        self.confirmImageView.enable = NO;
        self.confirmImageView.selected = NO;
        self.confirmImageView.backgroundColor = [UIColor cj_161823WithAlpha:0.05];
        [self.voucherLabelView updateCoupleLableForSignStatus];
        self.suggestView.hidden = YES;
    } else if (Check_ValidArray(model.channelConfig.marks)) {
        [self.voucherLabelView updateCoupleLabelContents:model.channelConfig.marks];
    } else if (Check_ValidString(model.channelConfig.mark)){
        [self.voucherLabelView updateCoupleLabelContents:@[model.channelConfig.mark]];
        self.suggestView.hidden = YES;
    } else {
        [self.voucherLabelView updateCoupleLabelContents:@[]];
    }
    self.rightArrowImage.hidden = YES;
    self.discountView.hidden = YES;
    self.cardBinView.hidden = YES;
    self.rightMsgLabel.hidden = YES;
    self.iconImgView.hidden = YES;
    if ([model.channelConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *infoModel = (CJPaySubPayTypeInfoModel *)model.channelConfig.payChannel;
        self.iconImgView.hidden = (!infoModel.payTypeData.iconTips || !model.enable);
        self.iconTip = infoModel.payTypeData.iconTips;
        // TODO: MSG list
        if (model.isFromCombinePay && model.enable && infoModel.payTypeData.combinePayInfo.combinePayVoucherMsgList.firstObject) {
            [self.discountView updateTitle:CJString(infoModel.payTypeData.combinePayInfo.combinePayVoucherMsgList.firstObject)];
        }
    }
    self.subTitleLabel.font = [UIFont cj_fontOfSize:13];
    
    if (Check_ValidString(model.subTitleColorStr) && [UIColor cj_colorWithHexString:model.subTitleColorStr]) {
        self.subTitleLabel.textColor = [UIColor cj_colorWithHexString:model.subTitleColorStr];
    }
    
    if ((model.type == BDPayChannelTypeBalance || model.type == BDPayChannelTypeIncomePay) && model.showCombinePay && model.enable) {
        self.rightMsgLabel.hidden = NO;
        self.rightMsgLabel.text = @"需组合支付";
    } else if (model.type == BDPayChannelTypeAddBankCard && Check_ValidString(model.selectPageGuideText)) {
        self.rightMsgLabel.hidden = NO;
        self.rightMsgLabel.text = model.selectPageGuideText;
    }

    if (!model.isFromCombinePay && model.enable && Check_ValidString(model.discountStr)) {
        self.discountView.hidden = NO;
        [self.discountView updateTitle:model.discountStr];
        if(model.isIntegerationChooseMethodSubPage && Check_ValidString(model.channelConfig.cardBinVoucher) && ![self p_tagsOverMaxPx:model.discountStr maxWidth:CJ_SCREEN_WIDTH - 52 - 43 textSize:10 height:16]) {//暂时收敛到此
            self.cardBinView.hidden = NO;
            [self.cardBinView updateTitle:model.channelConfig.cardBinVoucher];
        }
    }

    if (model.enable && model.voucherMsgV2Type == CJPayVoucherMsgTypeCardList && model.voucherMsgV2Model) {
        CJPayVoucherTagType tagType = model.isFromCombinePay ? CJPayVoucherTagTypeCombine : CJPayVoucherTagTypeDefault;
        NSArray<NSString *> *vouchers = [model.voucherMsgV2Model cardListVoucherMsgArrayWithType:tagType];
        if (vouchers.count == 1) {
            self.discountView.hidden = NO;
            self.cardBinView.hidden = YES;
            [self.discountView updateTitle:CJString(vouchers[0])];
        } else if (vouchers.count >= 2) {
            self.discountView.hidden = NO;
            [self.discountView updateTitle:CJString(vouchers[0])];
            if ([self p_tagsOverMaxPx:vouchers[0] maxWidth:CJ_SCREEN_WIDTH - 52 - 43 textSize:10 height:16]) {
                self.cardBinView.hidden = YES;
            } else {
                self.cardBinView.hidden = NO;
                [self.cardBinView updateTitle:CJString(vouchers[1])];
            }
        }
    }
    
    if (model.isChooseMethodSubPage) {
        self.confirmImageView.hidden = !(model.isConfirmed || model.hasConfirmBtnWhenUnConfirm) || !model.enable;
    } else {
        self.confirmImageView.hidden = !model.enable;
    }
    
    if (model.isEcommercePay) {
        self.rightArrowImage.hidden = !model.enable;
        self.confirmImageView.hidden = YES;
    }
    
    if (!model.isCombinePay && (model.type == BDPayChannelTypeAddBankCard || model.showCombinePay)) {
        self.rightArrowImage.hidden = !model.enable;
        self.confirmImageView.hidden = YES;
    }
    
    if (model.showCombinePay && model.isCombinePayBackToHomePage) {
        self.confirmImageView.hidden = !model.enable;
        self.rightArrowImage.hidden = YES;
    }
    
    if (model.isPaymentForOuterApp) {
        self.confirmImageView.hidden = YES;
    }
    
    if (model.type == CJPayChannelTypeQRCodePay) {
        self.confirmImageView.hidden = YES;
        self.rightArrowImage.hidden = NO;
    }
    
    if (model.enable && Check_ValidString(model.discountStr)) {
        if (model.isLineBreak || [self.class p_isDiscountLineBreakWithBizModel:model]) {
            self.subTitleLabel.hidden = YES;
            self.titleLabelTopBaseContentViewConstraint.offset = 9;
            [self.titleLabelCenterBaseContentViewConstraint deactivate];
            self.titleLabelBottomBaseContentViewConstraint.offset = -27;
            [self.titleLabelTopBaseContentViewConstraint activate];
        } else {
            if (Check_ValidString(model.subTitle)) { // 标签一行展示，但是有subtitle
                [self p_setUpSubTitleUI:model];
            } else { // 标签一行展示，但是没有subtitle
                [self.titleLabelTopBaseContentViewConstraint deactivate];
                [self.titleLabelCenterBaseContentViewConstraint activate];
                [self.titleLabelBottomBaseContentViewConstraint deactivate];
            }
            CJPayMasReMaker(self.discountView, {
                make.centerY.equalTo(self.titleLabel);
                make.left.equalTo(self.titleLabel.mas_right).offset(8);
                make.right.lessThanOrEqualTo(self.rightMsgLabel.mas_left).offset(-12);
                make.height.mas_equalTo(16);
            });
        }
    } else if (Check_ValidString(model.subTitle) && !(model.enable && Check_ValidString(model.discountStr))) {
        [self p_setUpSubTitleUI:model];
    } else {
        [self.titleLabelTopBaseContentViewConstraint deactivate];
        [self.titleLabelCenterBaseContentViewConstraint activate];
        self.titleLabelBottomBaseContentViewConstraint.offset = -16;
    }
    
    // 修复info icon在没有subtitle的时候和titlelable重叠的问题
    if (self.subTitleLabel.isHidden && !self.iconImgView.isHidden) {
        CJPayMasReMaker(self.iconImgView, {
            make.left.equalTo(self.titleLabel.mas_right).offset(4);
            make.centerY.equalTo(self.titleLabel);
            make.width.height.mas_equalTo(16);
        });
    }
    
    //当选中抖音支付且下发免密支付提示文案时才显示
    self.tipsMsgLabel.hidden = YES;
    if (model.isConfirmed && Check_ValidString(model.tipsMsg) && model.type == BDPayChannelTypeCardCategory) {
        self.tipsMsgLabel.hidden = NO;
        self.tipsMsgLabel.text = model.tipsMsg;
    }
    
    //当使用二级支付下的营销的时候
    if (model.useSubPayListVoucherMsg) {
        CJPaySubPayTypeInfoModel *firstConfig = [model.subPayTypeData cj_objectAtIndex:0];
        CJPaySubPayTypeInfoModel *secondConfig = [model.subPayTypeData cj_objectAtIndex:1];

        //当选中抖音支付 设置「是否支持一键绑卡」文案 设置营销标签
        if (model.type == BDPayChannelTypeCardCategory) {
            if (model.isConfirmed) {
                if (firstConfig.isChoosed) {
                    [self p_newCustomerUpdatetipsLabel:model subPayModel:firstConfig];
                } else {
                    [self p_newCustomerUpdatetipsLabel:model subPayModel:secondConfig];
                }
            } else {
                [self p_newCustomerUpdatetipsLabel:model subPayModel:firstConfig];
            }
        }
    }
}

- (void)p_newCustomerUpdatetipsLabel:(CJPayChannelBizModel *)model subPayModel:(CJPaySubPayTypeInfoModel *)subPayModel {
    if (!Check_ValidString(model.tipsMsg) && subPayModel.payTypeData.supportOneKeySign) {
        self.tipsMsgLabel.hidden = NO;
        self.tipsMsgLabel.text = CJPayLocalizedStr(@"可免输卡号绑卡");
    }
    
    NSMutableArray<NSString *> *tagsArr = [[NSMutableArray alloc] init];
    [subPayModel.payTypeData.bytepayVoucherMsgList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tagsArr btd_addObject:[obj valueForKey:@"label"]];
    }];
    
     if (tagsArr.count == 2) {
        NSString *firstTag = [tagsArr cj_objectAtIndex:0];
        NSString *secondTag = [tagsArr cj_objectAtIndex:1];
        
         CGFloat maxRightDistance = [self.tipsMsgLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 17) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont cj_fontOfSize:12]} context:nil].size.width + 55;
         
         CGFloat maxLeftDistance = [self.titleLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont cj_fontOfSize:16]} context:nil].size.width + 60;
         
        if ([self p_tagsOverMaxPx:firstTag maxWidth:CJ_SCREEN_WIDTH - maxRightDistance - maxLeftDistance textSize:11 height:16]) { // tag1 超长不展示tag2
            [tagsArr removeLastObject];
        } else if ([self p_tagsOverMaxPx:[NSString stringWithFormat:@"%@%@",firstTag,secondTag] maxWidth:CJ_SCREEN_WIDTH - maxRightDistance - maxLeftDistance textSize:11 height:16]) { //tag2超长不展示
            [tagsArr removeLastObject];
        }
    }
    [self.voucherLabelView updateCoupleLabelContents:[tagsArr copy]];
}

- (BOOL)p_tagsOverMaxPx:(NSString *)str maxWidth:(CGFloat)maxWidth textSize:(CGFloat)textSize height:(CGFloat)height {
    CGFloat width = [str boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont cj_fontOfSize:textSize]} context:nil].size.width;
    
    CGFloat insetsWidth = 16;
    return width + insetsWidth >= maxWidth;
}

- (void)p_setUpSubTitleUI:(CJPayChannelBizModel *)model {
    if (model.isChooseMethodSubPage) {
        self.titleLabelTopBaseContentViewConstraint.offset = 9;
        self.titleLabelBottomBaseContentViewConstraint.offset = -27;
    } else {
        self.titleLabelTopBaseContentViewConstraint.offset = 11;
        self.titleLabelBottomBaseContentViewConstraint.offset = -29;
    }
    [self.titleLabelCenterBaseContentViewConstraint deactivate];
    [self.titleLabelTopBaseContentViewConstraint activate];
}

- (void)p_setUpSubTitleUIByShowConfigModel:(CJPayDefaultChannelShowConfig *)configModel {
    if (configModel.isChooseMethodSubPage) {
        self.titleLabelTopBaseContentViewConstraint.offset = 9;
        self.titleLabelBottomBaseContentViewConstraint.offset = -27;
    } else {
        self.titleLabelTopBaseContentViewConstraint.offset = 11;
        self.titleLabelBottomBaseContentViewConstraint.offset = -29;
    }
    [self.titleLabelCenterBaseContentViewConstraint deactivate];
    [self.titleLabelTopBaseContentViewConstraint activate];
}

#pragma mark - CJPayMethodDataUpdateProtocol

- (UIView *)topLineView {
    if (!_topLineView) {
        _topLineView = [UIView new];
        _topLineView.backgroundColor = [UIColor cj_161823WithAlpha:0.08];
    }
    return _topLineView;
}

- (CJPayCoupleLabelView *)voucherLabelView {
    if (!_voucherLabelView) {
        _voucherLabelView = [CJPayCoupleLabelView new];
    }
    return _voucherLabelView;
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

- (CJPayMethodCellTagView *)discountView
{
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
    }
    return _discountView;
}

- (CJPayMethodCellTagView *)cardBinView {
    if (!_cardBinView) {
        _cardBinView = [CJPayMethodCellTagView new];
    }
    return _cardBinView;
}

- (UILabel *)tipsMsgLabel {
    if (!_tipsMsgLabel) {
        _tipsMsgLabel = [UILabel new];
        _tipsMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
        _tipsMsgLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _tipsMsgLabel;
}

- (UIImageView *)rightArrowImage
{
    if (!_rightArrowImage) {
        _rightArrowImage = [UIImageView new];
        [_rightArrowImage cj_setImage:@"cj_combine_pay_arrow_denoise_icon"];
    }
    return _rightArrowImage;
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
    [alertVC showOnTopVC:[self cj_responseViewController]];
    
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    BOOL isDiscountStrBreakLine = data.enable && Check_ValidString(data.discountStr) && (data.isLineBreak || [self p_isDiscountLineBreakWithBizModel:data]);
    if (data.isChooseMethodSubPage && (Check_ValidString(data.subTitle) || isDiscountStrBreakLine)) {
        return @56;
    } else if (!data.isChooseMethodSubPage && Check_ValidString(data.subTitle)) {
        return @60;
    }
    return @52;
}

+ (BOOL)p_isDiscountLineBreakWithBizModel:(CJPayChannelBizModel *)bizModel
{
    CGFloat titleLabelWidth = [bizModel.title cj_sizeWithFont:[UIFont cj_fontOfSize:15] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    CGFloat discountLabelWidth = [bizModel.discountStr cj_sizeWithFont:[UIFont cj_fontOfSize:10] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    return (52 + titleLabelWidth + 8 + discountLabelWidth + 6 + 32) > CJ_SCREEN_WIDTH;
}

+ (BOOL)p_isDiscountLineBreakWithShowConfigModel:(CJPayDefaultChannelShowConfig *)configModel
{
    CGFloat titleLabelWidth = [configModel.title cj_sizeWithFont:[UIFont cj_fontOfSize:15] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    CGFloat discountLabelWidth = [configModel.discountStr cj_sizeWithFont:[UIFont cj_fontOfSize:10] maxSize:CGSizeMake(CJ_SCREEN_WIDTH, CGFLOAT_MAX)].width;
    return (52 + titleLabelWidth + 8 + discountLabelWidth + 6 + 32) > CJ_SCREEN_WIDTH;
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
