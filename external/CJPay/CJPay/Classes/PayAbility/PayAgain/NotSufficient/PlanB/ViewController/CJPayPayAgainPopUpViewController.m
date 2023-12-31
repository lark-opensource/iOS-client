//
//  CJPayPayAgainPopUpViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainPopUpViewController.h"

#import "CJPayPayAgainPopUpView.h"
#import "CJPayStyleButton.h"
#import "CJPaySDKMacro.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayPayAgainChoosePayMethodViewController.h"
#import "CJPayPayAgainViewModel.h"
#import "CJPayLoadingManager.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayToast.h"

@interface CJPayPayAgainPopUpViewController () <CJPayPayAgainChoosePayMethodDelegate>

@property (nonatomic, strong) CJPayPayAgainPopUpView *notSufficientView;
@property (nonatomic, strong) CJPayPayAgainViewModel *viewModel;

@end

@implementation CJPayPayAgainPopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self.viewModel fetchNotSufficientCardListResponseWithCompletion:nil];
    self.containerView.layer.cornerRadius = 12;
    
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_imp" params:@{}];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.verifyManager.loadingDelegate = self;
    self.view.hidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.verifyManager.loadingDelegate = self.verifyManager.homePageVC;
    self.view.hidden = YES;
}

- (void)p_setupUI {
    [self.containerView addSubview:self.notSufficientView];
    
    CJPayMasReMaker(self.containerView, {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(280);
    });
    
    CJPayMasMaker(self.notSufficientView, {
        make.edges.equalTo(self.containerView);
    });
    
    [self.notSufficientView refreshWithHintInfo:self.confirmResponse.hintInfo];
}

- (void)p_close {
    @CJWeakify(self);
    [self dismissSelfWithCompletionBlock:^{
        @CJStrongify(self);
        if (self.dismissCompletionBlock) {
            self.dismissCompletionBlock(self.viewModel.defaultShowConfig);
        } else {
            CJ_CALL_BLOCK(self.closeActionCompletionBlock, YES);
        }
    }];
}

- (void)p_gotoCardList {
    
    @CJWeakify(self);
    void(^gotoCardListBlock)(void) = ^(void) {
        @CJStrongify(self);
        CJPayPayAgainChoosePayMethodViewController *chooseVC = [[CJPayPayAgainChoosePayMethodViewController alloc] initWithEcommerceViewModel:self.viewModel];
        chooseVC.delegate = self;
        chooseVC.isSkipPwd = [self.createResponse.userInfo.pwdCheckWay isEqualToString:@"3"];
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

- (void)p_otherButtonClicked {
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click"
                          params:@{@"button_name" : CJString(self.notSufficientView.otherPayMethodButton.titleLabel.text)}];
    CJPayChannelType currentPayChannel = self.confirmResponse.hintInfo.recPayType.channelType;
    if (currentPayChannel == BDPayChannelTypeAddBankCard) {
        [self p_close];
    } else {
        [self p_gotoCardList];
    }
}

- (void)p_confirmButtonClicked {
    @CJStartLoading(self)
    @CJWeakify(self);
    [self.viewModel fetchNotSufficientTradeCreateResponseWithCompletion:^(BOOL isSuccess) {
        @CJStrongify(self);
        @CJStopLoading(self)
        self.viewModel.currentShowConfig= self.viewModel.defaultShowConfig;
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
        case BDPayChannelTypeIncomePay:
            return @"Pre_Pay_Income";
        case BDPayChannelTypeCombinePay:
            return @"Pre_Pay_Combine";
        default:
            return @"";
    }
}

// 弹框页面埋点
- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *dict = [params mutableCopy];
    [dict addEntriesFromDictionary:[self.viewModel trackerParams]];
    [dict cj_setObject:[self.createResponse.userInfo.pwdCheckWay isEqualToString:@"3"] ? @"1" : @"0" forKey:@"pswd_pay_type"];
    [dict cj_setObject:[self p_getRecMethodString] forKey:@"rec_method"];

    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:CJString(eventName) params:[dict copy]];
}

// 卡列表埋点
- (void)p_trackerMethodListEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *dict = [params mutableCopy];
    [dict addEntriesFromDictionary:[self.viewModel trackerParams]];
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:CJString(eventName) params:[dict copy]];
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    if (self.verifyManager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd && self.viewModel.currentShowConfig.type != BDPayChannelTypeAddBankCard) {
        [self.notSufficientView.confirmPayBtn cj_setBtnTitle:@"免密支付中..."];
        [self.notSufficientView.confirmPayBtn startLeftLoading];
    }
    else {
        @CJStartLoading(self.notSufficientView.confirmPayBtn)
    }
}

- (void)stopLoading {
    if (self.verifyManager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd && self.viewModel.currentShowConfig.type != BDPayChannelTypeAddBankCard) {
        [self.notSufficientView.confirmPayBtn cj_setBtnTitle:self.confirmResponse.hintInfo.buttonText];
        [self.notSufficientView.confirmPayBtn stopLeftLoading];
    }
    else {
        @CJStopLoading(self.notSufficientView.confirmPayBtn)
    }
}

#pragma mark - CJPayPayAgainChoosePayMethodDelegate
- (void)didClickMethodCell:(UITableViewCell *)cell channelBizModel:(CJPayChannelBizModel *)bizModel {
    if ([cell isKindOfClass:[CJPayBytePayMethodCell class]]) {
        self.viewModel.currentShowConfig = bizModel.channelConfig;
        @CJStartLoading(((CJPayBytePayMethodCell *)cell))
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

- (void)p_didSelectTracker {
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.viewModel.currentShowConfig toActivityInfoTracker];
    if (activityInfo.count > 0 ) {
        [activityInfos addObject:activityInfo];
    }
    
    CJPayChannelType type = self.viewModel.currentShowConfig.type;
    
    [self p_trackerMethodListEventName:@"wallet_cashier_confirm_click" params:@{
        @"activity_info" : activityInfos
    }];
    
    if (type == BDPayChannelTypeAddBankCard) {
        [self p_trackerMethodListEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"activity_info" : activityInfos,
            @"from": @"second_pay_bing_card",
            @"addcard_info": CJString(self.viewModel.currentShowConfig.title)
        }];
    }
}

- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self p_trackerMethodListEventName:eventName params:params];
}

#pragma mark - Getter
- (CJPayPayAgainPopUpView *)notSufficientView {
    if (!_notSufficientView) {
        _notSufficientView = [CJPayPayAgainPopUpView new];
        @CJWeakify(self);
        [_notSufficientView.closeBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_close];
            [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click"
                                  params:@{@"button_name" : @"取消"}];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [_notSufficientView.confirmPayBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_confirmButtonClicked];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [_notSufficientView.otherPayMethodButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_otherButtonClicked];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _notSufficientView;
}

- (CJPayPayAgainViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[CJPayPayAgainViewModel alloc] initWithConfirmResponse:self.confirmResponse createRespons:self.createResponse];
        _viewModel.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
        _viewModel.extParams = self.extParams;
    }
    return _viewModel;
}

@end
