//
//  CJPayQuickBindCardTypeChooseItemView.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import "CJPayQuickBindCardTypeChooseItemView.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleCheckMark.h"


@interface CJPayQuickBindCardTypeChooseItemView()

@property (nonatomic, strong) CJPayStyleCheckMark *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *voucherLabel;
@property (nonatomic, strong) UILabel *inputHintLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UILabel *disableLabel;

@property (nonatomic, strong) MASConstraint *voucherRightToIconConstraint;
@property (nonatomic, strong) MASConstraint *voucherRightToInputHintConstraint;

@end

@implementation CJPayQuickBindCardTypeChooseItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)showInputHintLabel:(BOOL)isShow {
    if (isShow) {
        [self.voucherRightToInputHintConstraint activate];
        [self.voucherRightToIconConstraint deactivate];
    } else {
        [self.voucherRightToInputHintConstraint deactivate];
        [self.voucherRightToIconConstraint activate];
    }
    
    self.inputHintLabel.text = CJPayLocalizedStr(@"输入卡号绑卡");
    self.inputHintLabel.hidden = !isShow;
    self.arrowImageView.hidden = !isShow;
}

- (void)updateTitle:(NSString *)title withColor:(UIColor *)color {
    [self updateTitle:title];
    self.titleLabel.textColor = color;
}

- (void)updateTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)updateVoucherStr:(NSString *)voucherStr {
    self.voucherLabel.text = voucherStr;
    self.voucherLabel.hidden = !Check_ValidString(voucherStr);
}

- (void)setSelected:(BOOL)selected {
    if (!self.enable) {
        return;
    }
    
    _selected = selected;
    
    [self.iconImageView setSelected:selected];
    
    if (selected) {
        self.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.05];
        [self cj_showBorder:[UIColor cj_fe2c55WithAlpha:0.5] borderWidth:1];
    } else {
        self.backgroundColor = [UIColor clearColor];
        [self cj_showBorder:[UIColor cj_161823WithAlpha:0.12] borderWidth:0.5];
    }
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    self.iconImageView.hidden = !enable;
}

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.voucherLabel];
    [self addSubview:self.iconImageView];
    
    self.titleLabel.textColor = [UIColor cj_222222ff];
    self.layer.cornerRadius = 5;
    
    [self.voucherLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [self cj_showBorder:[UIColor cj_161823WithAlpha:0.12] borderWidth:0.5];
    
    [self addSubview:self.arrowImageView];
    [self addSubview:self.inputHintLabel];
    
    self.titleLabel.font = [UIFont cj_boldFontOfSize:16];
    [self.iconImageView cj_showCornerRadius:8];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(@16);
        make.top.equalTo(self).offset(14);
        make.bottom.lessThanOrEqualTo(self).offset(-14);
    });
    
    CJPayMasMaker(self.voucherLabel, {
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.top.equalTo(self).offset(14);
        make.bottom.equalTo(self).offset(-14);
        self.voucherRightToInputHintConstraint = make.right.lessThanOrEqualTo(self.inputHintLabel.mas_left).offset(-12);
        self.voucherRightToIconConstraint = make.right.lessThanOrEqualTo(self.iconImageView.mas_left).offset(-12);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.right.equalTo(@-16);
        make.width.height.equalTo(@16);
        make.centerY.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(@-12);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.inputHintLabel, {
        make.right.equalTo(self.arrowImageView.mas_left).offset(-2);
        make.centerY.equalTo(self);
    });
    
    [self.voucherRightToInputHintConstraint activate];
    [self.voucherRightToIconConstraint deactivate];
}

- (CJPayStyleCheckMark *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [CJPayStyleCheckMark new];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
    }
    return _titleLabel;
}

- (UILabel *)voucherLabel {
    if (!_voucherLabel) {
        _voucherLabel = [UILabel new];
        _voucherLabel.textColor = [UIColor cj_fe2c55ff];
        _voucherLabel.font = [UIFont cj_fontOfSize:12];
        _voucherLabel.numberOfLines = 0;
    }
    return _voucherLabel;
}

- (UILabel *)inputHintLabel {
    if (!_inputHintLabel) {
        _inputHintLabel = [UILabel new];
        _inputHintLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _inputHintLabel.font = [UIFont cj_fontOfSize:12];
        _inputHintLabel.hidden = YES;
    }
    return _inputHintLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_quick_bindcard_arrow_light_icon"];
        _arrowImageView.hidden = YES;
    }
    return _arrowImageView;
}

@end
