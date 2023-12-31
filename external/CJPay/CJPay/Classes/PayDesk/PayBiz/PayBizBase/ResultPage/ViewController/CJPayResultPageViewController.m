//
//  CJPayResultPageViewController.m
//  CJPay-Pay
//
//  Created by wangxinhua on 2020/9/18.
//

#import "CJPayResultPageViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayManager.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayKVContext.h"
#import "CJPayIntegratedResultPageView.h"

@interface CJPayResultPageViewController ()<CJPayIntegratedResultPageViewDelegate>

@property (nonatomic, strong) CJPayIntegratedResultPageView *resultView;

@end

@implementation CJPayResultPageViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        // 入场无动画，出场设置动画
        self.animationType = HalfVCEntranceTypeNone;
        self.exitAnimationType = HalfVCEntranceTypeFromBottom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setNavTitle];
    [self useCloseBackBtn];
    [self p_setupUI];
    [self p_showResult];
    [self p_trackWhenViewDidLoad];
}

#pragma mark - Private Method

- (void)p_setupUI {
    [self.contentView addSubview:self.resultView];
    CJPayMasMaker(self.resultView, {
        make.top.equalTo(self.stateView.mas_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    });
}

- (void)p_setNavTitle {
    NSString *cashierTitle = [CJPayBrandPromoteABTestManager shared].model.cashierTitle;
    NSString *quickPayCashierTitle = [CJPayBrandPromoteABTestManager shared].model.oneKeyQuickCashierTitle;
    if ([self.resultResponse.tradeInfo.ptCode isEqualToString:@"wx"] || [self.resultResponse.tradeInfo.ptCode isEqualToString:EN_zfb]) {
        CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
        [self setTitle:nameModel.payName ?: CJPayLocalizedStr(@"支付结果")];
    } else if (self.isOneKeyQuickPay) {
        if (Check_ValidString(quickPayCashierTitle)) {
            [self setTitle:quickPayCashierTitle];
        } else {
            CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
            [self setTitle:nameModel.payName ?: CJPayLocalizedStr(@"极速支付")];
        }
    } else {
        if (Check_ValidString(cashierTitle)) {
            [self setTitle:cashierTitle];
        } else {
            CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
            [self setTitle:nameModel.payName ?: CJPayLocalizedStr(@"支付")];
        }
    }
}

- (void)p_trackWhenViewDidLoad {
    
    NSString *result = @"处理中";
    if (!self.resultResponse) { // 网络异常
        result = @"失败";
    } else if (![self.resultResponse isSuccess]) {
        result = @"处理中";
    } else {
        switch (self.resultResponse.tradeInfo.tradeStatus) {
            case CJPayOrderStatusTimeout:
                result = @"超时";
                break;
            case CJPayOrderStatusSuccess:
                result = @"成功";
                break;
            case CJPayOrderStatusProcess:
                result = @"处理中";
                break;
            case CJPayOrderStatusFail:
                result = @"失败";
                break;
            default:
                result = @"处理中";
                break;
        }
    }
    
    NSString *finishImpEventName = self.isOneKeyQuickPay ? @"wallet_cashier_fastpay_finish_page_imp": @"wallet_cashier_pay_finish_page_imp";
    if (self.isOneKeyQuickPay) {
        [self p_trackWithEventName:finishImpEventName params:@{
            @"result" : CJString(result),
            @"method" : CJString([self.resultResponse.tradeInfo.bdpayResultResponse payTypeDescText]),
            @"amount" : @(self.resultResponse.tradeInfo.amount),
            @"real_amount" : @(self.resultResponse.tradeInfo.bdpayResultResponse.tradeInfo.payAmount),
            @"reduce_amount" : @(self.resultResponse.tradeInfo.bdpayResultResponse.tradeInfo.reduceAmount),
        }];
    } else {
        [self p_trackWithEventName:finishImpEventName params:@{
            @"result" : CJString(result),
        }];
    }
}

- (void)p_showResult {
    CJPayStateType stateType = CJPayStateTypeWaiting;
    if (!self.resultResponse) { // 网络异常
        stateType = CJPayStateTypeNetException;
    } else if (![self.resultResponse isSuccess]) {
        stateType = CJPayStateTypeWaiting;
    } else {
        switch (self.resultResponse.tradeInfo.tradeStatus) {
            case CJPayOrderStatusTimeout:
                stateType = CJPayStateTypeTimeOut; break;
            case CJPayOrderStatusSuccess:
                stateType = CJPayStateTypeSuccess;
                [self p_setSuccessState];
                [self p_resultPageType];
                break;
            case CJPayOrderStatusProcess:
                break;
            case CJPayOrderStatusFail:
                stateType = CJPayStateTypeFailure; break;
            default:
                break;
        }
    }
    self.stateView.isPaymentForOuterApp = self.isPaymentForOuterApp;
    [self showState:stateType];
    [self closeActionAfterTime:(int)[self closeAfterTime]];
    // 聚合支付结束
}

- (void)p_resultPageType {
    if (self.isPaymentForOuterApp) {
        self.resultView.resultPageType = CJPayIntegratedResultPageTypeOuterPay;
    }
}

- (void)p_setSuccessState {
    NSString *pagePayAmount = @(self.resultResponse.tradeInfo.amount).stringValue;
    if (self.resultResponse.tradeInfo.bdpayResultResponse != nil && self.isOneKeyQuickPay) {
        pagePayAmount = @(self.resultResponse.tradeInfo.bdpayResultResponse.tradeInfo.payAmount).stringValue;
    }
    CJPayStateShowModel *showModel = [CJPayStateShowModel new];
    showModel.titleAttributedStr = [CJPayStateView updateTitleWithContent:CJPayLocalizedStr(@"支付成功") amount:pagePayAmount];
    showModel.iconName = [[CJPayBrandPromoteABTestManager shared] isHitTest] ? @"cj_new_finish_gif" : @"cj_finish_gif";
    showModel.iconBackgroundColor = [UIColor clearColor];
    [self.stateView updateShowConfigsWithType:CJPayStateTypeSuccess model:showModel];
}

- (NSInteger)closeAfterTime {
    if (self.orderResponse) {
        return [self.orderResponse closeAfterTime];
    } else {
        return self.resultResponse.remainTime;
    }
}

- (void)closeActionAfterTime:(int)time {
    if (time < 0) { // 小于0的话，不关闭结果页，让用户手动关闭
        return;
    }
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        [self.navigationController popToViewController:self animated:NO];
        [self back];
    });
}

#pragma mark - lazy views

- (CJPayIntegratedResultPageView *)resultView {
    if (!_resultView) {
        _resultView = [[CJPayIntegratedResultPageView alloc] initWithCJResponse:self.resultResponse];
        _resultView.delegate = self;
    }
    return _resultView;
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:self.commonTrackerParams];
    [mutableDic addEntriesFromDictionary:params];
    [CJTracker event:eventName params:mutableDic];
}

- (void)stateButtonClick:(NSString *)buttonName {
    [self back];
}

- (void)back {
    [super back];
    if (self.isOneKeyQuickPay) {
        NSString *finishClickEventName = @"wallet_cashier_fastpay_finish_page_icon_click";
        [self p_trackWithEventName:finishClickEventName
                            params:@{@"icon_name" : @"返回",
                                     @"method" : CJString([self.resultResponse.tradeInfo.bdpayResultResponse payTypeDescText]),
                                     @"amount" : @(self.resultResponse.tradeInfo.amount),
                                     @"real_amount" : @(self.resultResponse.tradeInfo.bdpayResultResponse.tradeInfo.payAmount),
                                     @"reduce_amount" : @(self.resultResponse.tradeInfo.bdpayResultResponse.tradeInfo.reduceAmount),
                            }];
    }
}

@end
