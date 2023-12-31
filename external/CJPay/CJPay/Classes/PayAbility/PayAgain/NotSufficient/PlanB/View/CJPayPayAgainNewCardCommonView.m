//
//  CJPayPayAgainNewCardCommonView.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainNewCardCommonView.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"

@interface CJPayPayAgainNewCardCommonView()

@property (nonatomic, strong) UIImageView *firstImageView;
@property (nonatomic, strong) UIImageView *secondImageView;
@property (nonatomic, strong) UIImageView *thirdImageView;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIView *discountContentView;
@property (nonatomic, strong) UILabel *discountLabel;

@property (nonatomic, assign) CJPayNotSufficientNewCardCommonViewType type;

@property (nonatomic, strong) MASConstraint *selfLeftBaseFirstImageViewLeftConstraint;
@property (nonatomic, strong) MASConstraint *selfLeftBaseDiscountLeftConstraint;

@end

@implementation CJPayPayAgainNewCardCommonView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithType:(CJPayNotSufficientNewCardCommonViewType)type {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _type = type;
        [self p_setupUI];
    }
    return self;
}

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo {
    if (hintInfo.voucherBankIcons.count >= 3) {
        
        [self.selfLeftBaseDiscountLeftConstraint deactivate];
        [self.selfLeftBaseFirstImageViewLeftConstraint activate];
        
        self.firstImageView.hidden = NO;
        self.secondImageView.hidden = NO;
        self.thirdImageView.hidden = NO;
        [self.firstImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.voucherBankIcons[0]]];
        [self.secondImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.voucherBankIcons[1]]];
        [self.thirdImageView cj_setImageWithURL:[NSURL URLWithString:hintInfo.voucherBankIcons[2]]];
    } else {
        
        [self.selfLeftBaseFirstImageViewLeftConstraint deactivate];
        [self.selfLeftBaseDiscountLeftConstraint activate];
       
        self.firstImageView.hidden = YES;
        self.secondImageView.hidden = YES;
        self.thirdImageView.hidden = YES;
    }
    
    NSString *descStr = hintInfo.voucherBankIcons.count >= 3 ? CJPayLocalizedStr(@"等多家银行优惠，") : CJPayLocalizedStr(@"多家银行优惠，");
    if (self.type == CJPayNotSufficientNewCardCommonViewTypeCompact) {
        if (hintInfo.voucherBankIcons.count >= 3) {
            CJPayMasReMaker(self.discountContentView, {
                make.top.centerX.equalTo(self);
            });
            CJPayMasReMaker(self.discountLabel, {
                make.top.equalTo(self.descLabel.mas_bottom).offset(2);
                make.centerX.equalTo(self);
                make.right.lessThanOrEqualTo(self);
                make.bottom.equalTo(self);
            });
            descStr = CJPayLocalizedStr(@"等多家银行优惠");
        } else {
            CJPayMasReMaker(self.discountLabel, {
                make.top.left.equalTo(self);
            });
            CJPayMasReMaker(self.discountLabel, {
                make.left.equalTo(self.descLabel.mas_right);
                make.centerY.equalTo(self.thirdImageView);
                make.right.bottom.equalTo(self);
            });
        }
    }
    
    self.descLabel.text = descStr;
    NSString *discountStr = CJString(hintInfo.recPayType.payTypeData.voucherMsgList.firstObject);
    self.discountLabel.text = discountStr;
    
    CJPayMasUpdate(self.discountContentView, {
        make.height.mas_equalTo(discountStr.length > 0 ? 20 : 0);
    })
}

- (void)p_setupUI {
    [self.discountContentView addSubview:self.firstImageView];
    [self.discountContentView addSubview:self.secondImageView];
    [self.discountContentView addSubview:self.thirdImageView];
    [self.discountContentView addSubview:self.descLabel];
    [self addSubview:self.discountContentView];
    [self addSubview:self.discountLabel];
    
    [self p_addCornerBackgroundViewToView:self.firstImageView];
    [self p_addCornerBackgroundViewToView:self.secondImageView];
    [self p_addCornerBackgroundViewToView:self.thirdImageView];
    
    CJPayMasMaker(self.firstImageView, {
        self.selfLeftBaseFirstImageViewLeftConstraint = make.left.equalTo(self.discountContentView);
        make.left.equalTo(self.discountContentView);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.secondImageView, {
        make.left.equalTo(self.firstImageView.mas_right).offset(-2);
        make.width.height.top.equalTo(self.firstImageView);
    });
    CJPayMasMaker(self.thirdImageView, {
        make.left.equalTo(self.secondImageView.mas_right).offset(-2);
        make.width.height.top.equalTo(self.secondImageView);
    })
    CJPayMasMaker(self.descLabel, {
        self.selfLeftBaseDiscountLeftConstraint = make.left.equalTo(self.discountContentView);
        make.left.equalTo(self.thirdImageView.mas_right).offset(4);
        make.centerY.equalTo(self.thirdImageView);
        make.right.lessThanOrEqualTo(self.discountContentView);
        make.top.bottom.equalTo(self.discountContentView);
    })
    CJPayMasMaker(self.discountContentView, {
        make.top.left.equalTo(self);
    });
    
    CJPayMasMaker(self.discountLabel, {
        make.left.equalTo(self.discountContentView.mas_right);
        make.centerY.equalTo(self.thirdImageView);
        make.right.lessThanOrEqualTo(self);
        make.bottom.equalTo(self);
    });
    
    [self.selfLeftBaseDiscountLeftConstraint deactivate];
}

- (UIImageView *)firstImageView {
    if (!_firstImageView) {
        _firstImageView = [UIImageView new];
        _firstImageView.backgroundColor = [UIColor whiteColor];
        _firstImageView.layer.cornerRadius = 8;
    }
    return _firstImageView;
}
    
- (UIImageView *)secondImageView {
    if (!_secondImageView) {
        _secondImageView = [UIImageView new];
        _secondImageView.backgroundColor = [UIColor whiteColor];
        _secondImageView.layer.cornerRadius = 8;
    }
    return _secondImageView;
}

- (UIImageView *)thirdImageView {
    if (!_thirdImageView) {
        _thirdImageView = [UIImageView new];
        _thirdImageView.backgroundColor = [UIColor whiteColor];
        _thirdImageView.layer.cornerRadius = 8;
    }
    return _thirdImageView;
}

- (void)p_addCornerBackgroundViewToView:(UIView *)currentView {
    UIView *bgView = [UIView new];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.layer.cornerRadius = 9;
    [self.discountContentView insertSubview:bgView belowSubview:currentView];
    
    CJPayMasMaker(bgView, {
        make.center.equalTo(currentView);
        make.top.left.equalTo(currentView).offset(-1);
        make.right.bottom.equalTo(currentView).offset(1);
    });
}

- (UIView *)discountContentView {
    if (!_discountContentView) {
        _discountContentView = [UIView new];
    }
    return _discountContentView;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.font = [UIFont cj_fontOfSize:14];
        _descLabel.textColor = [UIColor cj_161823ff];
    }
    return _descLabel;
}

- (UILabel *)discountLabel {
    if (!_discountLabel) {
        _discountLabel = [UILabel new];
        _discountLabel.font = [UIFont cj_boldFontOfSize:14];
        _discountLabel.textColor = [UIColor cj_ff7a38ff];
    }
    return _discountLabel;
}

@end
