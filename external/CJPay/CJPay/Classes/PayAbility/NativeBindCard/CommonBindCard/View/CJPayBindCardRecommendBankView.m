//
//  CJPayBindCardRecommendBankView.m
//  CJPay-CJPayDemoTools-Example
//
//  Created by chenbocheng on 2022/6/8.
//

#import "CJPayBindCardRecommendBankView.h"
#import "CJPayUIMacro.h"
#import "CJPayQuickBindCardModel.h"

@interface CJPayBindCardRecommendBankView()

@property (nonatomic, strong) UILabel *supportLabel;
@property (nonatomic, strong) UIImageView *firstBankIcon;
@property (nonatomic, strong) UILabel *firstBankLabel;
@property (nonatomic, strong) UIImageView *secondBankIcon;
@property (nonatomic, strong) UILabel *secondBankLabel;
@property (nonatomic, strong) UILabel *bankTipsLabel;

@property (nonatomic, strong) MASConstraint *secondIconLeftAlignConstraint;
@property (nonatomic, strong) MASConstraint *tipsLabelLeftAlignFirstBankConstraint;
@property (nonatomic, strong) MASConstraint *tipsLabelLeftAlignSecondBankConstraint;

@end

@implementation CJPayBindCardRecommendBankView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public method

- (BOOL)isTipsShow {
    return Check_ValidString(self.firstBankLabel.text);
}

- (void)updateContent:(NSArray<CJPayQuickBindCardModel *> *)recommendBanks {
    self.firstBankLabel.text = [recommendBanks btd_objectAtIndex:0].bankName;
    [self.firstBankIcon cj_setImageWithURL:[NSURL cj_URLWithString:[recommendBanks btd_objectAtIndex:0].iconUrl]];
    if (recommendBanks.count > 1) {
        self.secondBankLabel.text = [recommendBanks btd_objectAtIndex:1].bankName;
        [self.secondBankIcon cj_setImageWithURL:[NSURL cj_URLWithString:[recommendBanks btd_objectAtIndex:1].iconUrl]];
        [self.secondIconLeftAlignConstraint activate];
        [self.tipsLabelLeftAlignFirstBankConstraint deactivate];
        [self.tipsLabelLeftAlignSecondBankConstraint activate];
    }
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.supportLabel];
    [self addSubview:self.firstBankIcon];
    [self addSubview:self.firstBankLabel];
    [self addSubview:self.secondBankIcon];
    [self addSubview:self.secondBankLabel];
    [self addSubview:self.bankTipsLabel];
    
    CJPayMasMaker(self.supportLabel, {
        make.left.top.bottom.equalTo(self);
    });
    [self.supportLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.firstBankIcon, {
        make.left.equalTo(self.supportLabel.mas_right).offset(4);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(16, 16)));
    });
    
    CJPayMasMaker(self.firstBankLabel, {
        make.left.equalTo(self.firstBankIcon.mas_right).offset(2);
        make.width.greaterThanOrEqualTo(@(36 * [UIFont cjpayFontScale])).priorityHigh();
        make.centerY.equalTo(self);
    });
    
    CJPayMasMaker(self.secondBankIcon, {
        self.secondIconLeftAlignConstraint = make.left.equalTo(self.firstBankLabel.mas_right).offset(4);
        make.centerY.equalTo(self);
        make.size.equalTo(@(CGSizeMake(16, 16)));
    });
    [self.secondIconLeftAlignConstraint deactivate];
    
    CJPayMasMaker(self.secondBankLabel, {
        make.left.equalTo(self.secondBankIcon.mas_right).offset(2);
        make.width.greaterThanOrEqualTo(@(36 * [UIFont cjpayFontScale])).priorityHigh();
        make.centerY.equalTo(self);
    });
    [self.secondBankLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.bankTipsLabel, {
        self.tipsLabelLeftAlignFirstBankConstraint = make.left.equalTo(self.firstBankLabel.mas_right).offset(4);
        self.tipsLabelLeftAlignSecondBankConstraint = make.left.equalTo(self.secondBankLabel.mas_right).offset(4);
        make.centerY.equalTo(self);
        make.right.lessThanOrEqualTo(self);
    });
    [self.bankTipsLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.tipsLabelLeftAlignFirstBankConstraint activate];
    [self.tipsLabelLeftAlignSecondBankConstraint deactivate];
}

#pragma mark - lazy views

- (UILabel *)supportLabel {
    if (!_supportLabel) {
        _supportLabel = [UILabel new];
        _supportLabel.font = [UIFont cj_fontOfSize:12];
        _supportLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _supportLabel.text = CJPayLocalizedStr(@"支持");
    }
    return _supportLabel;
}

- (UIImageView *)firstBankIcon {
    if (!_firstBankIcon) {
        _firstBankIcon = [UIImageView new];
    }
    return _firstBankIcon;
}

- (UILabel *)firstBankLabel {
    if (!_firstBankLabel) {
        _firstBankLabel = [UILabel new];
        _firstBankLabel.font = [UIFont cj_fontOfSize:12];
        _firstBankLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _firstBankLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _firstBankLabel;
}

- (UIImageView *)secondBankIcon {
    if (!_secondBankIcon) {
        _secondBankIcon = [UIImageView new];
    }
    return _secondBankIcon;
}

- (UILabel *)secondBankLabel {
    if (!_secondBankLabel) {
        _secondBankLabel = [UILabel new];
        _secondBankLabel.font = [UIFont cj_fontOfSize:12];
        _secondBankLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _secondBankLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _secondBankLabel;
}

- (UILabel *)bankTipsLabel {
    if (!_bankTipsLabel) {
        _bankTipsLabel = [UILabel new];
        _bankTipsLabel.font = [UIFont cj_fontOfSize:12];
        _bankTipsLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _bankTipsLabel.text = CJPayLocalizedStr(@"等200+银行");
    }
    return _bankTipsLabel;
}

@end
