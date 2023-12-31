//
//  BDPayWithDrawMainView.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawMainView.h"
#import "CJPayWithDrawInputAmountView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleTimerButton.h"
#import "CJPayChooseMethodView.h"
#import "UIView+CJTheme.h"

@interface CJPayWithDrawMainView()

@property (nonatomic, strong) CJPayChooseMethodView *methodView;
@property (nonatomic, strong) CJPayWithDrawInputAmountView *amountView;

@end

@implementation CJPayWithDrawMainView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setSelectConfig:(CJPayDefaultChannelShowConfig *)selectConfig {
    _selectConfig = selectConfig;
    self.methodView.comeFromSceneType = CJPayComeFromSceneTypeBalanceWithdraw;
    self.methodView.selectConfig = selectConfig;
    [self.methodView updateWithDefaultDiscount:self.defaultDiscount];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse {
    _orderResponse = orderResponse;
}


#pragma mark: get Methods
- (CJPayChooseMethodView *)methodView {
    if (!_methodView) {
        _methodView = [CJPayChooseMethodView new];
        _methodView.backgroundColor = [UIColor clearColor];
        _methodView.comeFromSceneType = CJPayComeFromSceneTypeBalanceWithdraw;
        @CJWeakify(self)
        _methodView.clickBlock = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.chooseCardBlock);
        };
    }
    return _methodView;
}

- (CJPayWithDrawInputAmountView *)amountView {
    if (!_amountView) {
        _amountView = [CJPayWithDrawInputAmountView new];
        _amountView.layer.cornerRadius = 5;
        _amountView.backgroundColor = [UIColor whiteColor];
    }
    return _amountView;
}

- (void)setupViews {
    [self addSubview:self.methodView];
    [self addSubview:self.amountView];
    
    CJPayMasMaker(self.methodView, {
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.top.equalTo(self);
        make.height.greaterThanOrEqualTo(@(64));
    });
    
    CJPayMasMaker(self.amountView, {
        make.top.equalTo(self.methodView.mas_bottom);
        make.left.mas_equalTo(12);
        make.right.mas_equalTo(-12);
        make.height.mas_equalTo(176);
        make.bottom.equalTo(self);
    });
}

- (void)adapterTheme {
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    self.amountView.backgroundColor = localTheme.rechargeMainViewBackgroundColor;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.amountView.backgroundColor = localTheme.rechargeMainViewBackgroundColor;
    }
}

@end
