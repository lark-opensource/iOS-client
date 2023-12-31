//
//  CJPayMethodCellTagView.m
//  CJPay
//
//  Created by wangxiaohong on 2020/7/7.
//

#import "CJPayMethodCellTagView.h"

#import "CJPayUIMacro.h"
#import "CJPayDeskTheme.h"
#import "CJPayCurrentTheme.h"
#import "UIView+CJPay.h"

@interface CJPayMethodCellTagView()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation CJPayMethodCellTagView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{   
    [self addSubview:self.titleLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(1);
        make.bottom.equalTo(self).offset(-1);
        make.left.equalTo(self).offset(3);
        make.right.equalTo(self).offset(-3);
        make.centerY.equalTo(self);
    });
    
    [self cj_showCornerRadius:2];

    self.backgroundColor = [UIColor clearColor];
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.5].CGColor;
}

- (void)updateTitle:(NSString *)title
{
    self.hidden = !Check_ValidString(title);
    self.titleLabel.text = title;
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    if (!borderColor) {
        return;
    }
    self.layer.borderColor = borderColor.CGColor;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    if (!textColor) {
        return;
    }
    self.titleLabel.textColor = textColor;
}

#pragma mark - Getter
- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:10];
        _titleLabel.textColor = [UIColor cj_fe2c55ff];
    }
    return _titleLabel;
}

@end
