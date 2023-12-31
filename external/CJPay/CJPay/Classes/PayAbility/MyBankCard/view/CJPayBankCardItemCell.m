//
//  CJPayBankCardItemCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardItemCell.h"
#import "CJPayBankCardView.h"
#import "CJPayUIMacro.h"
#import "CJPayBankCardItemViewModel.h"
#import <TTReachability/TTReachability.h>
#import "CJPaySDKDefine.h"
#import "CJPayToast.h"
#import "CJPayMyBankCardPlugin.h"

@implementation CJPayBankCardItemCell

- (void)setupUI {
    [super setupUI];

    [self.containerView addSubview:self.shadowView];
    [self.containerView addSubview:self.cardView];
    
    CJPayMasMaker(self.cardView, {
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.top.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-12);
    });
    CJPayMasMaker(self.shadowView, {
        make.edges.equalTo(self.cardView);
    });
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(p_SMSSignSuccess:) name:CJPayCardsManageSMSSignSuccessNotification object:nil];
}

- (void)p_SMSSignSuccess:(NSNotification*)notification {
    NSString *cardID = [notification object];
    if ([self.viewModel isKindOfClass:CJPayBankCardItemViewModel.class]) {
        CJPayBankCardItemViewModel *cardViewModel = (CJPayBankCardItemViewModel *)self.viewModel;
        if ([cardViewModel.cardModel.bankCardId isEqualToString:cardID]) {
            cardViewModel.cardModel.needResign = NO;
            self.viewModel = cardViewModel;
            [self.cardView hideSendSMSLabel];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    CJPayBankCardItemViewModel *cardViewModel = (CJPayBankCardItemViewModel *)viewModel;
    if (cardViewModel) {
        cardViewModel.cardModel.isSmallStyle = cardViewModel.isSmallStyle;
        [self.cardView updateCardView:cardViewModel.cardModel];
    }
}

- (void)didSelect {
    CJ_DelayEnableView(self);
    //无网不能跳转银行卡详情页
    TTReachability *reachAbility = [TTReachability reachabilityForInternetConnection];
    if (reachAbility.currentReachabilityStatus == NotReachable) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:self.window];
        return;
    }
    
    CJPayBankCardItemViewModel *cardViewModel = (CJPayBankCardItemViewModel *)self.viewModel;
    if (cardViewModel && cardViewModel.canJumpCardDetail) {
        if(!CJ_OBJECT_WITH_PROTOCOL(CJPayMyBankCardPlugin)) {
            CJPayLogAssert(NO, @"未实现CJPayMyBankCardPlugin的对应方法");
            return;
        }
        CJPayFullPageBaseViewController *cardDetailVC = [CJ_OBJECT_WITH_PROTOCOL(CJPayMyBankCardPlugin) openDetailWithCardItemModel:cardViewModel];
        UINavigationController *navigationVC = [self cj_responseViewController].navigationController;
        if (navigationVC) {
            [navigationVC pushViewController:cardDetailVC animated:YES];
        } else {
            [[self cj_responseViewController] presentViewController:cardDetailVC animated:YES completion:nil];
        }
        CJPayBankCardModel *cardModel = cardViewModel.cardModel;
        NSMutableDictionary *mutableDic = [cardViewModel.trackDic mutableCopy];
        [mutableDic addEntriesFromDictionary:@{@"merchant_id" : CJString(cardViewModel.merhcantId),
                                               @"app_id" : CJString(cardViewModel.appId),
                                               @"bank_name" : CJString(cardModel.bankName),
                                               @"bank_type" : CJString([self p_getBankType:cardModel.cardType]),
                                               @"page_scenes" : cardViewModel.isSmallStyle ? @"my_cards" : @"all_cards"}];
        [CJTracker event:@"wallet_bcard_manage_clickdetail" params:mutableDic];
        
        NSMutableDictionary *mutableDicForInsurance = [cardViewModel.trackDic mutableCopy];
        [mutableDicForInsurance addEntriesFromDictionary:@{@"merchant_id" : CJString(cardViewModel.merhcantId),
                                                           @"app_id" : CJString(cardViewModel.appId),
                                                           @"source" : @"wallet_bcard_manage",
                                                           @"insurance_title" : @"抖音支付全程保障资金与信息安全",
                                                           @"page_name" : @"wallet_bcard_manage_detail_page"}];
        [CJTracker event:@"wallet_addbcard_insurance_title_imp" params:mutableDicForInsurance];
    }
   
}

- (NSString *)p_getBankType:(NSString *)cardType {
    if ([cardType isEqualToString:@"DEBIT"]) {
        return @"储蓄卡";
    } else if ([cardType isEqualToString:@"CREDIT"]){
        return @"信用卡";
    }
    return @"";
}

- (CJPayBankCardView *)cardView {
    if (!_cardView) {
        _cardView = [CJPayBankCardView new];
        _cardView.layer.cornerRadius = 4;
        _cardView.layer.masksToBounds = YES;
    }
    return _cardView;
}

- (UIView *)shadowView {
    if (!_shadowView) {
        _shadowView = [UIView new];
        _shadowView.clipsToBounds = NO;
        _shadowView.layer.masksToBounds = NO;
    }
    return _shadowView;
}

@end
