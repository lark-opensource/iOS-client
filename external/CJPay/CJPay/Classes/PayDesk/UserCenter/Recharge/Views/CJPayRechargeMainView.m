//
//  BDPayRechargeMainView.m
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import "CJPayRechargeMainView.h"
#import "CJPayRechargeInputAmountView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"
#import "UIView+CJTheme.h"

@interface CJPayRechargeMainView()

@property (nonatomic, strong) CJPayChooseMethodView *methodView;
@property (nonatomic, strong) CJPayRechargeInputAmountView *amountView;

@end

@implementation CJPayRechargeMainView

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
    self.methodView.comeFromSceneType = CJPayComeFromSceneTypeBalanceRecharge;
    self.methodView.selectConfig = selectConfig;
    [self.methodView updateWithDefaultDiscount:self.defaultDiscount];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)showLimitLabel:(BOOL)isShow {
    [self.amountView showLimitLabel:isShow];
}

#pragma mark: get Methods
- (CJPayChooseMethodView *)methodView {
    if (!_methodView) {
        _methodView = [CJPayChooseMethodView new];
        _methodView.backgroundColor = [UIColor clearColor];
        _methodView.comeFromSceneType = CJPayComeFromSceneTypeBalanceRecharge;
        @CJWeakify(self)
        _methodView.clickBlock = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.chooseCardBlock);
        };
    }
    return _methodView;
}

- (CJPayRechargeInputAmountView *)amountView {
    if (!_amountView) {
        _amountView = [CJPayRechargeInputAmountView new];
        _amountView.layer.cornerRadius = 8;
    }
    return _amountView;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        _amountView.backgroundColor = localTheme.rechargeMainViewBackgroundColor;
    }
}

- (void)setupViews {
    [self addSubview:self.methodView];
    [self addSubview:self.amountView];

    CJPayMasMaker(self.methodView, {
        make.left.top.right.equalTo(self);
    });
    
    CJPayMasMaker(self.amountView, {
        make.top.equalTo(self.methodView.mas_bottom);
        make.left.right.bottom.equalTo(self);
    });
}

@end
