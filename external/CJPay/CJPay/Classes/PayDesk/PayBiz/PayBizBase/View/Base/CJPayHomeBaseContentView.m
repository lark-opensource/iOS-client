//
//  CJPayHomeBaseContentView.m
//  CJPay
//
//  Created by 尚怀军 on 2020/3/24.
//

#import "CJPayHomeBaseContentView.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayLineUtil.h"

@interface CJPayHomeBaseContentView()

@property (nonatomic, strong) UIView *lineView;

@end

@implementation CJPayHomeBaseContentView

- (instancetype)initWithFrame:(CGRect)frame
          createOrderResponse:(CJPayCreateOrderResponse *)createOrderResponse {
    self = [super initWithFrame:frame];
    if (self) {
        _response = createOrderResponse;
        [self setupUI];
    }
    return self;
}

-(void)setupUI {
    [self addSubview:self.payAmountLabel];
    [self addSubview:self.payAmountDiscountLabel];
    [self.payAmountDiscountLabel addSubview:self.lineView];
    [self addSubview:self.unitLabel];
    [self addSubview:self.tradeNameLabel];
    [self addSubview:self.confirmPayBtn];
    
    CJPayMasMaker(self.lineView, {
        make.left.right.equalTo(self.payAmountDiscountLabel);
        make.centerY.equalTo(self.payAmountDiscountLabel);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        if (CJ_Pad) {
            make.bottom.equalTo(self).offset(-16);
        } else {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(CJ_IPhoneX ? 0 : -8);
            } else {
                make.bottom.equalTo(self).offset(-8);
            }
        }
    });
}

- (CJPayStyleButton *)confirmPayBtn {
    if (!_confirmPayBtn) {
        _confirmPayBtn = [[CJPayStyleButton alloc] init];
        _confirmPayBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmPayBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        CJPayDeskTheme *theme = self.response.deskConfig.theme;
        if (theme) {
            [_confirmPayBtn cj_showCornerRadius:[theme confirmButtonShape]];
        } else {
            [_confirmPayBtn cj_showCornerRadius:4];
        }
        NSString *titleContent = self.response.deskConfig.confirmBtnDesc ?: CJPayLocalizedStr(@"确认支付");
        [_confirmPayBtn setTitle:titleContent forState:UIControlStateNormal];
        [_confirmPayBtn addTarget:self action:@selector(p_onConfirmPayAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmPayBtn;
}

- (UILabel *)unitLabel
{
    if (!_unitLabel) {
        _unitLabel = [UILabel new];
        _unitLabel.text = @"￥";
        _unitLabel.font = [UIFont cj_boldByteNumberFontOfSize:22];
    }
    return _unitLabel;
}

- (CJPayCounterLabel *)payAmountLabel {
    if (!_payAmountLabel) {
        _payAmountLabel = [CJPayCounterLabel new];
        _payAmountLabel.textAlignment = NSTextAlignmentLeft;
        _payAmountLabel.font = [UIFont cj_boldByteNumberFontOfSize:42];
        _payAmountLabel.text = @(_response.tradeInfo.amount).stringValue;
    }
    return _payAmountLabel;
}

- (UILabel *)payAmountDiscountLabel
{
    if (!_payAmountDiscountLabel) {
        _payAmountDiscountLabel = [UILabel new];
        _payAmountDiscountLabel.font = [UIFont cj_fontOfSize:14];
        _payAmountDiscountLabel.textColor = [UIColor cj_999999ff];
        _payAmountDiscountLabel.hidden = YES;
    }
    return _payAmountDiscountLabel;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = [UIColor cj_999999ff];
    }
    return _lineView;
}

- (UILabel *)tradeNameLabel {
    if (!_tradeNameLabel) {
        _tradeNameLabel = [UILabel new];
        _tradeNameLabel.cj_centerY = 88;
        _tradeNameLabel.font = [UIFont cj_fontOfSize:12];
        _tradeNameLabel.textAlignment = NSTextAlignmentCenter;
        _tradeNameLabel.textColor = [UIColor cj_999999ff];
    }
    return _tradeNameLabel;
}

- (void)p_onConfirmPayAction {
    // 确认按钮的点击抛到外层
    if (self.delegate && [self.delegate respondsToSelector:@selector(confirmButtonClick)]) {
        [self.delegate confirmButtonClick];
    }
}

-(void)refreshDataWithModels:(NSArray *)models {
    // 子类实现
}

- (void)updateAmount:(NSInteger)toAmount from:(NSInteger)fromAmount
{
    CJPayDeskTheme *currentTheme = self.response.deskConfig.theme;
    self.unitLabel.textColor = [currentTheme amountColor];
    self.payAmountLabel.textColor = [currentTheme amountColor];
    CGFloat fromFloatNubmer = fromAmount / 100.0;
    CGFloat toFloatNumber = toAmount / 100.0;
    [self.payAmountLabel cj_fromNumber:fromFloatNubmer toNumber:toFloatNumber duration:0.5 format:^NSString * _Nullable(CGFloat currentNumber) {
        return [NSString stringWithFormat:@"%.2f",currentNumber];
    }];
}

- (void)startLoading
{
    //子类实现
}

- (void)stopLoading
{
    //子类实现
}



@end
