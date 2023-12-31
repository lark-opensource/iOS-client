//
//  CJPayBankCardView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import "CJPayBankCardView.h"
#import "CJPayUIMacro.h"
#import "CJPayBankCardModel.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayQuickPayChannelModel.h"


@interface CJPayBankCardView()

@property (nonatomic, strong) UIView *cardIconBcgView;
@property (nonatomic, strong) UIImageView *cardIconImageView;
@property (nonatomic, strong) UIImageView *channelIconImageView;
@property (nonatomic, strong) UILabel *cardNameLabel;
@property (nonatomic, strong) UIImageView *markImageView;
@property (nonatomic, strong) UILabel *cardTypeLabel;
@property (nonatomic, strong) UIImageView *dotLeftImageView;
@property (nonatomic, strong) UIImageView *dotMiddleImageView;
@property (nonatomic, strong) UIImageView *dotRightImageView;
@property (nonatomic, strong) UILabel *cardTailNumLabel;
@property (nonatomic, strong) UILabel *sendSMSLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property(nonatomic,strong) CJPayBankCardModel *cardModel;

@end

@implementation CJPayBankCardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.bounds;
    [self.layer addSublayer:self.gradientLayer];
    //设置渐变区域的起始和终止位置（范围为0-1）
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 0);
    
    [self addSubview:self.cardIconBcgView];
    [self.cardIconBcgView addSubview:self.cardIconImageView];
    [self addSubview:self.cardNameLabel];
    [self addSubview:self.channelIconImageView];
    [self addSubview:self.markImageView];
    [self addSubview:self.cardTypeLabel];
    [self addSubview:self.cardTailNumLabel];
    [self addSubview:self.dotLeftImageView];
    [self addSubview:self.sendSMSLabel];
    [self addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.cardIconBcgView, {
        make.top.left.equalTo(self).offset(22);
        make.left.equalTo(self).offset(16);
        make.width.height.mas_equalTo(36);
    });
    
    CJPayMasMaker(self.cardIconImageView, {
        make.width.height.mas_equalTo(24);
        make.center.equalTo(self.cardIconBcgView);
    });
    
    CJPayMasMaker(self.cardNameLabel, {
        make.top.equalTo(self).offset(20);
        make.left.equalTo(self.cardIconBcgView.mas_right).offset(12);
    });
    
    CJPayMasMaker(self.channelIconImageView, {
        make.left.equalTo(self.cardNameLabel.mas_right).offset(4);
        make.centerY.equalTo(self.cardNameLabel);
        make.height.width.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.cardTypeLabel, {
        make.top.equalTo(self.cardNameLabel.mas_bottom).offset(1);
        make.left.equalTo(self.cardNameLabel);
    });
    
    CJPayMasMaker(self.cardTailNumLabel, {
        make.centerY.equalTo(self.cardNameLabel).offset(2);
        make.right.equalTo(self).offset(-16);
    });
    
    CJPayMasMaker(self.dotLeftImageView, {
        make.centerY.equalTo(self.cardNameLabel);
        make.right.equalTo(self.cardTailNumLabel.mas_left).offset(-12);
        make.width.mas_equalTo(28);
        make.height.mas_equalTo(4);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.centerY.equalTo(self.cardTypeLabel);
        make.right.equalTo(self).offset(-16);
        make.size.mas_equalTo(CGSizeMake(12, 12));
    });
        
    CJPayMasMaker(self.sendSMSLabel, {
        make.centerY.equalTo(self.cardTypeLabel);
        make.right.equalTo(self.arrowImageView.mas_left);
    });
}

- (void)p_sendSMS {
    CJ_CALL_BLOCK(self.cardModel.createNormalOrderAndSendSMSBlock);
}

- (void)p_updateSendSMSLabel:(BOOL)needResign {
    if (needResign) {
        self.sendSMSLabel.hidden = NO;
        self.arrowImageView.hidden = NO;
    } else {
        [self hideSendSMSLabel];
    }
}

- (void)hideSendSMSLabel {
    self.sendSMSLabel.hidden = YES;
    self.arrowImageView.hidden = YES;
}

-(void)updateCardView:(CJPayBankCardModel *)model{
    self.cardModel = model;
    
    self.cardNameLabel.text = CJString(model.bankName);
    self.cardTypeLabel.text = CJString([self p_getBankTypeNameWithBankType:self.cardModel.cardType]);
    [self p_updateSendSMSLabel:model.needResign];
    
    NSString *tailText = @"";
    if (model.cardNoMask && model.cardNoMask.length >= 4) {
        tailText = [model.cardNoMask substringFromIndex:model.cardNoMask.length - 4];
    }
    self.cardTailNumLabel.text = CJString(tailText);
    [self.cardIconImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.iconUrl)] placeholder:[self p_bankPlaceholderImage]];
    
    self.channelIconImageView.hidden = YES;
    if(Check_ValidString(model.channelIconUrl)) {
        self.channelIconImageView.hidden = NO;
        [self.channelIconImageView cj_setImageWithURL:[NSURL URLWithString:model.channelIconUrl]];
    }

    if ([model.status isEqualToString:@"available"]) {
        self.alpha = 1;
    } else {
        self.alpha = 0.3;
    }
    
    NSArray <NSString *>* colors = [self.cardModel.cardBackgroundColor componentsSeparatedByString:@","];
    
    UIColor *startColor = [UIColor cj_colorFromHexString:[colors cj_objectAtIndex:0] defaultColor:[UIColor cj_colorWithHexString:@"#dd4a51"]];
    UIColor *endColor = [UIColor cj_colorFromHexString:[colors cj_objectAtIndex:1] defaultColor:[UIColor cj_colorWithHexString:@"#e95259"]];
    //设置渐变颜色数组
    self.gradientLayer.colors = @[(__bridge id)startColor.CGColor,
                                  (__bridge id)endColor.CGColor];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.gradientLayer.frame = bounds;
}

- (UIImage *)p_bankPlaceholderImage {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    CGSize size = self.cardIconImageView.frame.size;
    UIImage *defaultIcon = [[UIImage cj_imageWithColor:[UIColor cj_ffffffWithAlpha:0.9]] cj_scaleToSize:size];
    return [defaultIcon bd_imageByRoundCornerRadius:size.width / 2];
}

- (NSString *)p_getBankTypeNameWithBankType:(NSString *)bankType
{
    if ([bankType isEqualToString:@"DEBIT"]) {
        return CJPayLocalizedStr(@"储蓄卡");
    } else if ([bankType isEqualToString:@"CREDIT"]){
        return CJPayLocalizedStr(@"信用卡");
    }
    return @"";
}

- (UIView *)cardIconBcgView {
    if (!_cardIconBcgView) {
        _cardIconBcgView = [[UIView alloc] init];
        [_cardIconBcgView cj_showCornerRadius:18];
        _cardIconBcgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    }
    return _cardIconBcgView;
}

- (UIImageView *)cardIconImageView {
    if (!_cardIconImageView) {
        _cardIconImageView = [[UIImageView alloc] init];
    }
    return _cardIconImageView;
}

- (UIImageView *)channelIconImageView {
    if (!_channelIconImageView) {
        _channelIconImageView = [[UIImageView alloc] init];
    }
    return _channelIconImageView;
}

- (UILabel *)cardNameLabel {
    if (!_cardNameLabel) {
        _cardNameLabel = [[UILabel alloc] init];
        _cardNameLabel.font = [UIFont cj_semiboldFontOfSize:15];
        _cardNameLabel.textColor = [UIColor whiteColor];
    }
    return _cardNameLabel;
}

- (UIImageView *)markImageView {
    if (!_markImageView) {
        _markImageView = [[UIImageView alloc] init];
        if ([CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageZhhans) {
            [_markImageView cj_setImage:@"cj_pm_quick_pay_icon"];
        } else {
            _markImageView.hidden = YES;
        }
    }
    return _markImageView;
}

- (UILabel *)cardTypeLabel {
    if (!_cardTypeLabel) {
        _cardTypeLabel = [[UILabel alloc] init];
        _cardTypeLabel.font = [UIFont cj_fontOfSize:12];
        _cardTypeLabel.textColor = [UIColor whiteColor];
    }
    return _cardTypeLabel;
}

- (UILabel *)cardTailNumLabel {
    if (!_cardTailNumLabel) {
        _cardTailNumLabel = [[UILabel alloc] init];
        _cardTailNumLabel.font = [UIFont cj_boldByteNumberFontOfSize:17];
        _cardTailNumLabel.textColor = [UIColor whiteColor];
    }
    return _cardTailNumLabel;
}

- (UIImageView *)dotLeftImageView {
    if (!_dotLeftImageView) {
        _dotLeftImageView = [UIImageView new];
        [_dotLeftImageView cj_setImage:@"cj_pm_four_dots_icon"];
    }
    return _dotLeftImageView;
}

- (UILabel *)sendSMSLabel {
    if (!_sendSMSLabel) {
        _sendSMSLabel = [UILabel new];
        _sendSMSLabel.font = [UIFont cj_fontOfSize:10];
        _sendSMSLabel.textColor = [UIColor cj_colorWithHexString:@"#FFFFFF"];
        _sendSMSLabel.text = CJPayLocalizedStr(@"验证银行预留手机号");
        _sendSMSLabel.hidden = YES;
        [_sendSMSLabel cj_viewAddTarget:self action:@selector(p_sendSMS) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendSMSLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_white_arrow_icon"];
        _arrowImageView.hidden = YES;
        [_arrowImageView cj_viewAddTarget:self action:@selector(p_sendSMS) forControlEvents:UIControlEventTouchUpInside];
    }
    return _arrowImageView;
}

@end
