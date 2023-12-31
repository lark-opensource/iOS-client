//
//  CJPayBytePayHomeContentView.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/13.
//

#import "CJPayBytePayHomeContentView.h"

#import "CJPayBytePayMethodView.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayLineUtil.h"
#import "CJPayMarketingMsgView.h"

@interface CJPayBytePayHomeContentView()

@property (nonatomic, strong) CJPayBytePayMethodView *payMethodTableView;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView; //金额区
@property (nonatomic, strong) UILabel *orderDetailLabel; //订单信息

@property (nonatomic, assign) BOOL showAmountWithVoucher; //金额区是否需要展示营销
#pragma mark - constraint
@property (nonatomic, strong) MASConstraint *amountViewTopConstraint; //金额区顶部约束
@property (nonatomic, strong) MASConstraint *orderDetailLabelTopConstraint; //orderDetailLabel顶部约束

@end

@implementation CJPayBytePayHomeContentView

- (void)setupUI {
    [super setupUI];
    [self addSubview:self.payMethodTableView];
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.orderDetailLabel];
    
    CJPayMasMaker(self.marketingMsgView, {
        self.amountViewTopConstraint = make.top.equalTo(self).offset(-4);
        make.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.orderDetailLabel, {
        self.orderDetailLabelTopConstraint = make.top.equalTo(self.marketingMsgView.mas_bottom);
        make.centerX.equalTo(self);
        make.left.right.equalTo(self.confirmPayBtn);
    });
    
    CJPayMasMaker(self.payMethodTableView, {
        make.top.equalTo(self.orderDetailLabel.mas_bottom).offset(32);
        make.left.right.equalTo(self);
        make.bottom.equalTo(self.confirmPayBtn.mas_top).offset(-3);
    });
    self.clipsToBounds = NO;
}

// 更新金额区金额信息和营销文案
- (void)refreshPriceViewWithAmount:(NSString *)amount voucher:(NSString *)voucher {

    [_marketingMsgView updateWithPayAmount:CJString(amount) voucherMsg:CJString(voucher)];
    [self p_updateHomeContentViewWithAmountVoucher:Check_ValidString(voucher)];
}

// 根据是否有营销文案来更新布局
- (void)p_updateHomeContentViewWithAmountVoucher:(BOOL)needShowAmountVoucher {
    if (_showAmountWithVoucher == needShowAmountVoucher) {
        return;
    }
    _showAmountWithVoucher = needShowAmountVoucher;
    self.amountViewTopConstraint.offset = needShowAmountVoucher ? -6 : -4;
    self.orderDetailLabelTopConstraint.offset = needShowAmountVoucher ? 5 : 0;

}

- (void)setTableViewDelegate:(id<CJPayMethodTableViewDelegate>)tableViewDelegate
{
    [super setTableViewDelegate:tableViewDelegate];
    self.payMethodTableView.delegate = tableViewDelegate;
}

- (void)refreshDataWithModels:(NSArray *)models {
    self.payMethodTableView.models = models;
}

- (void)startLoading
{
    @CJStartLoading(self.payMethodTableView)
}

- (void)stopLoading
{
    @CJStopLoading(self.payMethodTableView)
}

- (CJPayBytePayMethodView *)payMethodTableView {
    
    if (!_payMethodTableView) {
        _payMethodTableView = [CJPayBytePayMethodView new];
        _payMethodTableView.backgroundColor = [UIColor whiteColor];
    }
    return _payMethodTableView;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleNormal isShowVoucherMsg:NO];
        UIColor *priceColor = [self.response.deskConfig.theme amountColor];
        [_marketingMsgView updatePriceColor:priceColor];
        NSString *amountStr = [NSString stringWithFormat:@"%.2f", [self.response totalAmountWithDiscount] / (double)100];
        [_marketingMsgView updateWithPayAmount:CJString(amountStr) voucherMsg:@""];
    }
    return _marketingMsgView;
}

- (UILabel *)orderDetailLabel {
    if (!_orderDetailLabel) {
        _orderDetailLabel = [UILabel new];
        _orderDetailLabel.font = [UIFont cj_fontOfSize:12];
        _orderDetailLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _orderDetailLabel.text = CJString(self.response.tradeInfo.tradeName);
        _orderDetailLabel.textAlignment = NSTextAlignmentCenter;
        [CJPayLineUtil addBottomLineToView:_orderDetailLabel marginLeft:0 marginRight:0 marginBottom:-21];
    }
    return _orderDetailLabel;
}
@end
