//
//  CJPayPayAgainHalfViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainHalfViewController.h"

#import "CJPayPayAgainHalfView.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayPayAgainChoosePayMethodViewController.h"
#import "CJPayPayAgainViewModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayIntegratedChannelModel.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPayMerchantInfo.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayRetainUtil.h"
#import "CJPayKVContext.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayQueryPayTypeRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayCreditPayUtil.h"
#import "CJPayPayAgainCombinationPaymentViewController.h"
#import "CJPayPayAgainChoosePayMethodViewController.h"
#import "CJPayToast.h"

@interface CJPayPayAgainHalfViewController () <CJPayPayAgainChoosePayMethodDelegate, CJPayPayAgainCombineChoosePayMethodDelegate>

@property (nonatomic, strong) CJPayPayAgainHalfView *notSufficientView;
@property (nonatomic, strong) CJPayPayAgainViewModel *viewModel;
@property (nonatomic, strong) CJPayPayAgainCombinationPaymentViewController *ecommerceCombineViewController;
@property (nonatomic, weak) CJPayPayAgainChoosePayMethodViewController *chooseVC;
@property (nonatomic, copy) NSAttributedString *buttonTitle;

@end

@implementation CJPayPayAgainHalfViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeNone;
        self.exitAnimationType = HalfVCEntranceTypeFromBottom;
        self.isSuperPay = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.isSuperPay) {
        [self.viewModel fetchNotSufficientCardListResponseWithCompletion:nil];
        self.hintInfo = self.confirmResponse.hintInfo;//非极速付取trade_confirm，极速付由外部传入
    }
    [self p_setupUI];
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_imp" params:@{}];
}

- (void)back {
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click" params:@{@"button_name" : @"关闭"}];
    [self p_back:YES];
}

- (void)p_back:(BOOL)showRetain {
    if (self.dismissCompletionBlock) {
        @CJWeakify(self)
        if (showRetain && [self shouldShowRetainVC]) {
            // 展示了挽留弹窗，就以挽留弹窗的事件进行页面的关闭。
        } else {
            [super closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.dismissCompletionBlock, self.viewModel.defaultShowConfig);
            }];
        }
    } else {
        if (showRetain && [self shouldShowRetainVC]) {
            // 展示了挽留弹窗，就以挽留弹窗的事件进行页面的关闭。
        } else {
            [super back];
        }
    }
}

- (BOOL)shouldShowRetainVC {
    CJPayRetainUtilModel *retainUtilModel = [CJPayRetainUtilModel new];
    CJPayBDRetainInfoModel *retainInfo = self.hintInfo.retainInfo;
    retainUtilModel.intergratedTradeNo = [self.createOrderResponse.tradeInfo.tradeNo stringByAppendingString:@"0"];
    retainUtilModel.retainInfo = retainInfo;
    retainUtilModel.positionType = CJPayRetainVerifyPage;
    retainUtilModel.isBonusPath = YES;
    
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = ^{
        @CJStrongify(self);
        [self p_trackerWithEventName:@"wallet_cashier_second_pay_keep_pop_click" params:@{@"button_name" : retainInfo ? CJString(retainInfo.retainButtonText) : @"继续付款"}];
    };
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self);
        [self p_trackerWithEventName:@"wallet_cashier_second_pay_keep_pop_click" params:@{@"button_name" : retainInfo ? @"关闭" : @"放弃"}];
        if (self.dismissCompletionBlock) {
            [super closeWithAnimation:YES
                            comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.dismissCompletionBlock, self.viewModel.defaultShowConfig);
            }];
        } else {
            [super back];
        }
    };
    
    BOOL showRetainVC = [CJPayRetainUtil couldShowRetainVCWithSourceVC:self retainUtilModel:retainUtilModel];
    if (showRetainVC) {
        [self p_trackerWithEventName:@"wallet_cashier_second_pay_keep_pop_imp" params:@{}];
    }
    return showRetainVC;
}

- (void)p_setupUI {
    if (self.hintInfo.style == CJPayHintInfoStyleNewHalf) {
        self.title = [self p_getNavTitle];
        [self.navigationBar hideBottomLine];
    } else if (self.hintInfo.style == CJPayHintInfoStyleVoucherHalf || self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2 || self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV3) {
        self.title = @"";//优惠不可用时不展示上方标题
        [self.navigationBar hideBottomLine];
    } else {
        self.title = CJPayDYPayTitleMessage;//兜底
    }
    if (self.isSuperPay) {
        self.title = CJPayLocalizedStr(@"极速付款失败");
    }
    [self useCloseBackBtn];
    [self.contentView addSubview:self.notSufficientView];
    CJPayMasMaker(self.notSufficientView, {
        make.top.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-CJ_TabBarSafeBottomMargin);
    })
}

- (NSString *)p_getNavTitle {
    CJPayChannelType channelType = self.verifyManager.defaultConfig.type;
    return channelType == BDPayChannelTypeCreditPay ? @"付款失败" : @"支付失败";
}

- (void)p_gotoCardList {
    
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click"
                          params:@{@"button_name" : CJString(self.notSufficientView.otherPayMethodButton.titleLabel.text)}];
    
    if (self.isSuperPay) {
        [self p_back:NO];
        return;
    }
    
    @CJWeakify(self);
    void(^gotoCardListBlock)(void) = ^(void) {
        @CJStrongify(self);
        CJPayPayAgainChoosePayMethodViewController *chooseVC = [[CJPayPayAgainChoosePayMethodViewController alloc] initWithEcommerceViewModel:self.viewModel];
        chooseVC.delegate = self;
        chooseVC.isSkipPwd = [self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"3"];
        chooseVC.showStyle = [self p_getStyleFromCashierTag];
        self.chooseVC = chooseVC;
        [self.verifyManager.homePageVC push:chooseVC animated:YES];
    };
    
    if (!self.viewModel.cardListModel) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        @CJWeakify(self);
        [self.viewModel fetchNotSufficientCardListResponseWithCompletion:^(BOOL isSuccess) {
            @CJStrongify(self);
            [[CJPayLoadingManager defaultService] stopLoading];
            if (!isSuccess) {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
                return;
            }
            CJ_CALL_BLOCK(gotoCardListBlock);
        }];
        return;
    }
    
    CJ_CALL_BLOCK(gotoCardListBlock);
}

- (void)p_confirmButtonClicked {
    
    
    if (self.isSuperPay) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(payWithContext:loadingView:)]) {
            [self.delegate payWithContext:self.viewModel.payContext loadingView:self.notSufficientView.confirmPayBtn];
        }
        [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click"
                              params:@{@"button_name" : CJString(self.notSufficientView.confirmPayBtn.titleLabel.text)}];
        return;
    }
    @CJStartLoading(self)
    @CJWeakify(self);
    self.viewModel.installment = self.notSufficientView.creditInstallment;
    self.viewModel.currentShowConfig = self.viewModel.defaultShowConfig;
    [self.viewModel fetchNotSufficientTradeCreateResponseWithCompletion:^(BOOL isSuccess) {
        [CJPayKVContext kv_setValue:@"second_pay" forKey:@"CJPayPayAgainTeaSource"];
        @CJStrongify(self);
        @CJStopLoading(self)
        if (!isSuccess) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(payWithContext:loadingView:)]) {
            [self.delegate payWithContext:self.viewModel.payContext loadingView:self.notSufficientView.confirmPayBtn];
        }
        [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click"
                              params:@{@"button_name" : CJString(self.notSufficientView.confirmPayBtn.titleLabel.text)}];
    }];
}


- (void)useCloseBackBtn {
    [super useCloseBackBtn];
    self.navigationBar.backBtn.accessibilityLabel = @"关闭";
}

- (NSString *)p_getRecMethodString {
    switch (self.viewModel.currentShowConfig.type) {
        case BDPayChannelTypeBalance:
            return @"Pre_Pay_Balance";
        case BDPayChannelTypeBankCard:
            return @"Pre_Pay_BankCard";
        case BDPayChannelTypeCreditPay:
            return @"Pre_Pay_Credit";
        case BDPayChannelTypeAddBankCard:
            return @"Pre_Pay_NewCard";
        case BDPayChannelTypeAfterUsePay:
            return @"Pre_Pay_PayAfterUse";
        case BDPayChannelTypeIncomePay:
            return @"Pre_Pay_Income";
        case BDPayChannelTypeCombinePay:
            return @"Pre_Pay_Combine";
        case BDPayChannelTypeFundPay:
            return @"Pre_Pay_FundPay";
        default:
            return @"";
    }
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    
    NSMutableDictionary *dict = [params mutableCopy];
    [dict addEntriesFromDictionary:[self.viewModel trackerParams]];
    if (self.isSuperPay) {
        [dict cj_setObject:@"2" forKey:@"pswd_pay_type"];//极速付
    } else if ([self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"3"]) {
        [dict cj_setObject:@"1" forKey:@"pswd_pay_type"];
    } else {
        [dict cj_setObject:@"0" forKey:@"pswd_pay_type"];
    }

    CJPayChannelType channelType = self.hintInfo.recPayType.channelType;
    if ((channelType == BDPayChannelTypeAddBankCard) ||
        ((channelType == BDPayChannelTypeCreditPay) && !self.hintInfo.recPayType.payTypeData.isCreditActivate)) {
        [dict cj_setObject:@"0" forKey:@"is_reserve_method"];
    } else {
        [dict cj_setObject:@"1" forKey:@"is_reserve_method"];
    }
    if (channelType == BDPayChannelTypeBankCard) {
        if ([self.hintInfo.recPayType.payTypeData.cardType isEqualToString:@"CREDIT"]) {
            [dict cj_setObject:@"信用卡" forKey:@"bank_type"];
        } else if ([self.hintInfo.recPayType.payTypeData.cardType isEqualToString:@"DEBIT"]) {
            [dict cj_setObject:@"储蓄卡" forKey:@"bank_type"];
        }
    } else if (channelType == BDPayChannelTypeAddBankCard) {
        [dict cj_setObject:self.hintInfo.recPayType.payTypeData.cardType forKey:@"newcard_type"];
    }
    
    if(self.hintInfo.style == CJPayHintInfoStyleVoucherHalf) {
        [dict cj_setObject:@"" forKey:@"rec_method"];
    } else {
        [dict cj_setObject:[self p_getRecMethodString] forKey:@"rec_method"];
    }
    
    if (self.isSuperPay) {
        [dict cj_setObject:@"superpay" forKey:@"second_pay_type"];
    }
    
    [dict addEntriesFromDictionary:[self p_getDiscountLabel]];
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:CJString(eventName) params:[dict copy]];
}

- (void)p_trackerMethodListEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *dict = [params mutableCopy];
    [dict addEntriesFromDictionary:[self.viewModel trackerParams]];
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:CJString(eventName) params:[dict copy]];
}

- (NSDictionary *)p_getDiscountLabel {
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    NSString *discountText = [self.notSufficientView getDiscount];
    if(!Check_ValidString(discountText)) {
        [params cj_setObject:@"0" forKey:@"is_discount"];
        [params cj_setObject:@"" forKey:@"activity_label"];
    } else {
        [params cj_setObject:@"1" forKey:@"is_discount"];
        [params cj_setObject:discountText forKey:@"activity_label"];
    }
    return params;
}

- (void)p_gotoCombinationPaymentType:(CJPayChannelBizModel *)bizModel {
    self.ecommerceCombineViewController = [[CJPayPayAgainCombinationPaymentViewController alloc] initWithViewModel:self.viewModel];
    self.ecommerceCombineViewController.type = bizModel.type;
    self.ecommerceCombineViewController.delegate = self;
    [self.navigationController pushViewController:self.ecommerceCombineViewController animated:YES];
}

#pragma mark - CJPayPayAgainChoosePayMethodDelegate
- (void)didClickMethodCell:(UITableViewCell *)cell channelBizModel:(CJPayChannelBizModel *)bizModel {
    if (bizModel.showCombinePay) {
        [self p_gotoCombinationPaymentType:bizModel];
        return ;
    }
    if ([cell isKindOfClass:[CJPayBytePayMethodCell class]]) {
        @CJStartLoading(((CJPayBytePayMethodCell *)cell))
        self.viewModel.currentShowConfig = bizModel.channelConfig;
        @CJWeakify(self);
        [self.viewModel fetchNotSufficientTradeCreateResponseWithCompletion:^(BOOL isSuccess) {
            @CJStrongify(self);
            @CJStopLoading(((CJPayBytePayMethodCell *)cell))
            if (!isSuccess) {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
                return;
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(payWithContext:loadingView:)]) {
                [self.delegate payWithContext:self.viewModel.payContext loadingView:cell];
            }
            
            [self p_didSelectTracker];
        }];
    }
}

- (void)didChangeCreditPayInstallment:(NSString *)installment {
    self.viewModel.installment = Check_ValidString(installment) ? installment : @"1";
}

#pragma mark - CJPayPayAgainCombineChoosePayMethodDelegate
- (void)didClickCombineMethodCell:(UITableViewCell *)cell channelBizModel:(CJPayChannelBizModel *)bizModel {
    @CJStartLoading(((CJPayBytePayMethodCell *)cell))
    self.viewModel.currentShowConfig = bizModel.channelConfig;
    @CJWeakify(self);
    [self.viewModel fetchCombinationPaymentResponseWithCompletion:^(BOOL isSuccess) {
        @CJStrongify(self);
        @CJStopLoading(((CJPayBytePayMethodCell *)cell))
        if (!isSuccess) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(payWithContext:loadingView:)]) {
            [self.delegate payWithContext:self.viewModel.payContext loadingView:cell];
        }
        
        [self p_didSelectTracker];
    }];
    
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    if (self.verifyManager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd && self.viewModel.currentShowConfig.type != BDPayChannelTypeAddBankCard) {
        if (self.hintInfo.style == CJPayHintInfoStyleVoucherHalfV2 || self.notSufficientView.showStyle == CJPaySecondPayRecSimpleStyle ) {//使用富文本设置的btn，有时不能被普通文本覆盖
            self.buttonTitle = self.notSufficientView.confirmPayBtn.currentAttributedTitle;
            [self.notSufficientView.confirmPayBtn cj_setBtnAttributeTitle:self.notSufficientView.skipPwdTitle];
        } else {
            [self.notSufficientView.confirmPayBtn cj_setBtnTitle:CJPayLocalizedStr(@"免密支付中...")];
        }
        [self.notSufficientView.confirmPayBtn startLeftLoading];
    }
    else {
        @CJStartLoading(self.notSufficientView.confirmPayBtn)
    }
}

- (void)stopLoading {
    if (self.verifyManager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd && self.viewModel.currentShowConfig.type != BDPayChannelTypeAddBankCard) {
        if (self.buttonTitle) {
            [self.notSufficientView.confirmPayBtn cj_setBtnAttributeTitle:self.buttonTitle];
        } else {
            [self.notSufficientView.confirmPayBtn cj_setBtnTitle:self.hintInfo.buttonText];
        }
        [self.notSufficientView.confirmPayBtn stopLeftLoading];
    }
    else {
        @CJStopLoading(self.notSufficientView.confirmPayBtn)
    }
}

- (void)p_didSelectTracker {
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.viewModel.currentShowConfig toActivityInfoTracker];
    if (self.viewModel.currentShowConfig.isCombinePay) {
        activityInfo = [self.viewModel.currentShowConfig toCombinePayActivityInfoTracker];
    }
    if (activityInfo.count > 0 ) {
        [activityInfos addObject:activityInfo];
    }
    
    CJPayChannelType type = self.viewModel.currentShowConfig.type;
    
    [self p_trackerMethodListEventName:@"wallet_cashier_confirm_click" params:@{
        @"activity_info" : activityInfos,
        @"addcard_info": CJString(self.viewModel.currentShowConfig.title)
    }];
    
    if (type == BDPayChannelTypeAddBankCard) {
        [self p_trackerMethodListEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"activity_info" : activityInfos,
            @"from": @"second_pay_bing_card",
            @"addcard_info": CJString(self.viewModel.currentShowConfig.title)
        }];
    }
}

- (CJPaySecondPayShowStyle)p_getStyleFromCashierTag {//获取实验值
    NSArray<NSString *> *cashierTag = self.confirmResponse.cashierTag;
    if(Check_ValidArray(cashierTag)) {
        if([cashierTag containsObject:@"pay_again_rec_simple"]){
            return CJPaySecondPayRecSimpleStyle;
        }
    }
    if (self.isSuperPay) {
        return CJPaySecondPayRecSimpleStyle;
    }
    return CJPaySecondPayNoneStyle;
}

- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self p_trackerMethodListEventName:eventName params:params];
}

#pragma mark - Getter
- (CJPayPayAgainHalfView *)notSufficientView {
    if (!_notSufficientView) {
        _notSufficientView = [CJPayPayAgainHalfView new];
        _notSufficientView.showStyle = [self p_getStyleFromCashierTag];
        _notSufficientView.isSuperPay = self.isSuperPay;
        @CJWeakify(self);
        [_notSufficientView.confirmPayBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_confirmButtonClicked];
        } forControlEvents:UIControlEventTouchUpInside];
         
        [_notSufficientView.otherPayMethodButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_gotoCardList];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [_notSufficientView refreshWithNotSufficientHintInfo:self.hintInfo];
    }
    return _notSufficientView;
}

- (CJPayPayAgainViewModel *)viewModel {
    if (!_viewModel) {
        if (self.isSuperPay) {
            _viewModel = [[CJPayPayAgainViewModel alloc] initWithHintInfo:self.hintInfo];
        } else {
            _viewModel = [[CJPayPayAgainViewModel alloc] initWithConfirmResponse:self.confirmResponse createRespons:self.createOrderResponse];
        }
        _viewModel.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
        _viewModel.extParams = self.extParams;
    }
    return _viewModel;
}

@end
