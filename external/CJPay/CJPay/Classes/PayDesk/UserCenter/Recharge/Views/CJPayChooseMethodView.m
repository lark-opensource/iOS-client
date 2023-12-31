//
//  BDPayRechargeMethodView.m
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import "CJPayChooseMethodView.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayLineUtil.h"
#import "CJPayServerThemeStyle.h"
#import "UIView+CJTheme.h"
#import "CJPayMethodCellTagView.h"

@interface CJPayChooseMethodView ()

@property (nonatomic, strong) UILabel *leftTitleLabel;
@property (nonatomic, strong) UIImageView *rightArrow;
@property (nonatomic, strong) UIImageView *cardIconView;
@property (nonatomic, strong) UILabel *cardLabel;
@property (nonatomic, strong) UILabel *cardDescLabel;
@property (nonatomic, strong) UIView *clickView;
@property (nonatomic, strong) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong) MASConstraint *bottomBaseCardLabelConstraint;
@property (nonatomic, strong) MASConstraint *bottomBaseCardDescConstraint;
@property (nonatomic, strong) MASConstraint *bottomBaseDisountViewConstraint;


@end

@implementation CJPayChooseMethodView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

#pragma mark: get methods
- (UILabel *)cardLabel {
    if (!_cardLabel) {
        _cardLabel = [UILabel new];
        _cardLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _cardLabel;
}

- (UIImageView *)cardIconView {
    if (!_cardIconView) {
        _cardIconView = [UIImageView new];
    }
    return _cardIconView;
}

- (UIImageView *)rightArrow {
    if (!_rightArrow) {
        _rightArrow = [UIImageView new];
    }
    return _rightArrow;
}

- (UILabel *)leftTitleLabel {
    if (!_leftTitleLabel) {
        _leftTitleLabel = [UILabel new];
        _leftTitleLabel.font = [UIFont cj_fontOfSize:15];
        _leftTitleLabel.textColor = [UIColor cj_161823ff];
    }
    return _leftTitleLabel;
}

- (UILabel *)cardDescLabel {
    if (!_cardDescLabel) {
        _cardDescLabel = [UILabel new];
        _cardDescLabel.font = [UIFont cj_fontOfSize:13];
        _cardDescLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _cardDescLabel.adjustsFontSizeToFitWidth = YES;
        _cardDescLabel.numberOfLines = 2;
//        _cardDescLabel.backgroundColor = [UIColor purpleColor];
    }
    return _cardDescLabel;
}
- (UIView *)clickView {
    if (!_clickView) {
        _clickView = [UIView new];
        _clickView.backgroundColor = UIColor.clearColor;
    }
    return _clickView;
}

- (CJPayMethodCellTagView *)discountView {
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
        _discountView.hidden = YES;
    }
    return _discountView;
}

#pragma mark: setupView
- (void)setupView {
    [self addSubview:self.leftTitleLabel];
    [self addSubview:self.cardIconView];
    [self addSubview:self.cardLabel];
    [self addSubview:self.cardDescLabel];
    [self addSubview:self.rightArrow];
    [self addSubview:self.clickView];
    [self addSubview:self.discountView];
    [self.clickView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(click)]];
    
    CJPayMasMaker(self.leftTitleLabel, {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(24);
    });
    
    CJPayMasMaker(self.rightArrow, {
        make.right.equalTo(self).offset(-4);
        make.centerY.equalTo(self.leftTitleLabel);
        make.width.height.equalTo(@(20));
    });
    
    CJPayMasMaker(self.cardIconView, {
        make.left.mas_greaterThanOrEqualTo(92);
        make.width.height.mas_equalTo(16);
        make.centerY.equalTo(self.leftTitleLabel);
    });
    
    CJPayMasMaker(self.cardLabel, {
        make.centerY.equalTo(self.cardIconView);
        make.left.equalTo(self.cardIconView.mas_right).offset(4);
        make.right.equalTo(self.rightArrow.mas_left);
        self.bottomBaseCardLabelConstraint = make.bottom.equalTo(self).offset(-24);
    });
    
    CJPayMasMaker(self.cardDescLabel, {
        make.right.equalTo(self.cardLabel.mas_right);
        make.top.equalTo(self.cardLabel.mas_bottom).offset(3);
        self.bottomBaseCardDescConstraint = make.bottom.equalTo(self).offset(-24);
    });
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.cardLabel.mas_bottom).offset(2);
        make.right.equalTo(self.cardLabel);
        self.bottomBaseDisountViewConstraint = make.bottom.equalTo(self).offset(-24);
    });
    
    CJPayMasMaker(self.clickView, {
        make.top.right.bottom.equalTo(self);
        make.left.equalTo(self.cardLabel);
    });
    
}

- (void)setComeFromSceneType:(CJPayComeFromSceneType)comeFromSceneType {
    _comeFromSceneType = comeFromSceneType;
    _leftTitleLabel.text = _comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge ? CJPayLocalizedStr(@"充值方式"): CJPayLocalizedStr(@"到账方式");
}

- (void)updateWithDefaultDiscount:(NSString *)discountStr {
    // 仅无可用支付方式时展示
    if (!Check_ValidString(discountStr) || [self p_isSelectConfigValid]) {
        self.discountView.hidden = YES;
        [self.bottomBaseDisountViewConstraint deactivate];
        [self updateContent];
        return;
    }
    
    [self.discountView updateTitle:discountStr];
    [self addSubview:self.discountView];
    self.discountView.hidden = NO;
    [self.bottomBaseCardLabelConstraint deactivate];
    [self.bottomBaseCardDescConstraint deactivate];
    [self.bottomBaseDisountViewConstraint activate];
}

- (BOOL)p_isSelectConfigValid {
    return self.selectConfig && ![self.selectConfig.status isEqualToString:@"0"];
}

- (void)p_adapterTheme {
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    
    self.cardDescLabel.textColor = localTheme.withdrawSubTitleTextColor;
    self.leftTitleLabel.textColor = localTheme.withdrawTitleTextColor;
    
    if (![self p_isSelectConfigValid]) {
        self.cardLabel.textColor = localTheme.withdrawSubTitleTextColor;
    } else {
        self.cardLabel.textColor = localTheme.withdrawTitleTextColor;
    }
    
    [self.rightArrow cj_setImage:localTheme.withdrawArrowImageName];
    self.discountView.borderColor = localTheme.promotionTagColor;
    self.discountView.textColor = localTheme.promotionTagColor;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        [self p_adapterTheme];
    }
}

- (void)setSelectConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    _selectConfig = selectConfig;
    [self updateContent];
}

- (void)updateContent {
    if (self.selectConfig) {
        if ([self.selectConfig.status isEqualToString:@"0"]) {
            self.cardLabel.text = [self p_addBankDesc];
            self.cardLabel.textAlignment = NSTextAlignmentRight;
            self.cardIconView.image = nil;
            self.cardDescLabel.text = CJPayLocalizedStr(@"");
            self.cardDescLabel.textAlignment = NSTextAlignmentRight;
            [self.bottomBaseCardDescConstraint deactivate];
            [self.bottomBaseCardLabelConstraint activate];
        } else {
            self.cardLabel.textAlignment = NSTextAlignmentLeft;
            NSString *title = [NSString stringWithFormat:@"%@(%@)", self.selectConfig.title, CJString(self.selectConfig.cardTailNumStr)];
            self.cardLabel.text = title;
            self.cardDescLabel.text = self.selectConfig.limitMsg;
            self.cardDescLabel.textAlignment = NSTextAlignmentLeft;
            [self.cardIconView cj_setImageWithURL:[NSURL URLWithString:self.selectConfig.iconUrl]];
            [self.bottomBaseCardLabelConstraint deactivate];
            [self.bottomBaseCardDescConstraint activate];
        }
    } else {
        self.cardLabel.text = [self p_addBankDesc];
        self.cardLabel.textAlignment = NSTextAlignmentRight;
        self.cardIconView.image = nil;
        [self.bottomBaseCardLabelConstraint deactivate];
        [self.bottomBaseCardLabelConstraint activate];
        if (self.cardNum != 0) {
            self.cardDescLabel.text = CJPayLocalizedStr(@"你绑定的卡当前均不可用");
            self.cardDescLabel.textAlignment = NSTextAlignmentRight;
            [self.bottomBaseCardLabelConstraint deactivate];
            [self.bottomBaseCardDescConstraint activate];
        }
    }
    
    [self p_adapterTheme];
}

- (NSString *)p_addBankDesc {
    return self.comeFromSceneType == CJPayComeFromSceneTypeBalanceRecharge ? CJPayLocalizedStr(@"添加银行卡充值") : CJPayLocalizedStr(@"添加银行卡提现");
}

- (void)click {
    CJ_DelayEnableView(self.clickView);
    CJ_CALL_BLOCK(self.clickBlock);
}

- (void)startLoading {
    [self.rightArrow cj_startLoading];
}

- (void)stopLoading {
    [self.rightArrow cj_stopLoading];
}

@end
