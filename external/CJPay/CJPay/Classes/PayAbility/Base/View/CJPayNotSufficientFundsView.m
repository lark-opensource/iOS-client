//
//  CJPayNotSufficientFundsView.m
//  CJPay
//
//  Created by 王新华 on 2/12/20.
//

#import "CJPayNotSufficientFundsView.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayThemeStyleManager.h"


@interface CJPayNotSufficientFundsView()

@property (nonatomic, strong) CJPayStyleErrorLabel *contentLabel;
@property (nonatomic, strong) UIImageView *iconImgView;

@end

@implementation CJPayNotSufficientFundsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)updateTitle:(NSString *)title
{
    self.contentLabel.text = CJString(title);
}

- (void)setupUI {
    self.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.06];
    [self addSubview:self.contentLabel];
    [self addSubview:self.iconImgView];
    
    CJPayMasMaker(self.contentLabel, {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self);
        make.top.greaterThanOrEqualTo(self);
        make.bottom.lessThanOrEqualTo(self);
    });
    
    CJPayMasReMaker(self.iconImgView, {
        make.left.equalTo(self.contentLabel.mas_right).offset(4);
        make.centerY.equalTo(self.contentLabel);
        make.width.height.mas_equalTo(12);
    });
}

- (CJPayStyleErrorLabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [CJPayStyleErrorLabel new];
        _contentLabel.backgroundColor = [UIColor clearColor];
        _contentLabel.textColor = [CJPayThemeStyleManager shared].serverTheme.linkTextColor;
        _contentLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        _contentLabel.numberOfLines = 0;
        _contentLabel.text = CJPayLocalizedStr(@"银行卡可用余额不足，请选择下列方式完成付款");
    }
    return _contentLabel;
}

- (CGSize)calSize {
    CGSize size = [_contentLabel.text cj_sizeWithFont:_contentLabel.font maxSize:CGSizeMake(CJ_SCREEN_WIDTH - 32, 100)];
    return CGSizeMake(CJ_SCREEN_WIDTH, size.height + 20);
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [UIImageView new];
        [_iconImgView cj_setImage:@"cj_income_pay_about_red_icon"];
        _iconImgView.userInteractionEnabled = YES;
        [_iconImgView cj_viewAddTarget:self
                                action:@selector(p_tapIncomePayAboutImageView)
                      forControlEvents:UIControlEventTouchUpInside];
        _iconImgView.hidden = YES;
    }
    return _iconImgView;
}

- (void)p_tapIncomePayAboutImageView {
    CJ_CALL_BLOCK(self.iconClickBlock);
}

@end
