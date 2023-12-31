//
//  CJPayDYRecommendPayAgainViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/3/23.
//

#import "CJPayDYRecommendPayAgainViewController.h"

#import "CJPayDYRecommendPayAgainView.h"
#import "CJPayUIMacro.h"
#import "CJPayHintInfo.h"
#import "CJPayStyleButton.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayDYRecommendPayAgainListViewController.h"
#import "CJPayBDMethodTableView.h"
#import "CJPayDYVerifyManager.h"
#import "CJPayBDCreateOrderRequest.h"
#import "CJPayLoadingButton.h"
#import "CJPayToast.h"

typedef NS_ENUM(NSUInteger, kCJPayAgainLoadingLocation) {
    kCJPayAgainLoadingLocationNull,
    kCJPayAgainLoadingLocationBottomButton,
    kCJPayAgainLoadingLocationChooseCardVCAddCard,
    kCJPayAgainLoadingLocationChooseCardVCCell,
};

@interface CJPayDYRecommendPayAgainViewController ()<CJPayDYRecommendPayAgainListDelegate>

@property (nonatomic, strong) CJPayDYRecommendPayAgainView *recommendView;
@property (nonatomic, assign) kCJPayAgainLoadingLocation loadingLocation;
@property (nonatomic, weak) CJPayDYRecommendPayAgainListViewController *chooseCardVC;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentShowConfig;
@property (nonatomic, strong) CJPayOrderConfirmResponse *confirmResponse;

@property (nonatomic, assign) BOOL isRefreshCreateResponseSuccess; //刷新下单接口是否成功

@end

@implementation CJPayDYRecommendPayAgainViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.animationType = HalfVCEntranceTypeNone;
        self.exitAnimationType = HalfVCEntranceTypeFromBottom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    
    self.confirmResponse = self.verifyManager.confirmResponse;
    [self.recommendView refreshWithHintInfo:self.confirmResponse.hintInfo];
    self.currentShowConfig = [self.confirmResponse.hintInfo.recPayType buildShowConfig].firstObject;

    if (self.verifyManager.isBindCardAndPay) {
        [self p_refreshCreateResponseWithCompletion:nil];
    }
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_imp" params:@{}];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_freshloadingLocation) name:CJPayBindCardSuccessPreCloseNotification object:nil];
}

- (void)back {
    if ([self.navigationController isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)self.navigationController;
        if ([navi.viewControllers containsObject:self]) {
            [navi setViewControllers:@[self] animated:NO];
            [super back];
        }
    } else {
        [super back];
    }
}

- (void)bindCardSuccessAndPayFailedWithData:(id)data {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if ([viewControllers containsObject:self]) {
        [self.navigationController popToViewController:self animated:NO];
    }
    NSString *toastMsg = CJPayNoNetworkMessage;
    if ([data isKindOfClass:CJPayOrderConfirmResponse.class])  {
        CJPayOrderConfirmResponse *res = (CJPayOrderConfirmResponse *)data;
        if (Check_ValidString(res.msg)) {
            toastMsg = res.msg;
        }
    }
    [CJToast toastText:toastMsg inWindow:self.cj_window];
    [self p_refreshCreateResponseWithCompletion:nil];
}

- (void)p_refreshCreateResponseWithCompletion:(void(^)(CJPayBDCreateOrderResponse * _Nonnull response))completion {
    @CJWeakify(self);
    [CJPayBDCreateOrderRequest startWithAppId:self.createResponse.merchant.appId merchantId:self.createResponse.merchant.merchantId bizParams:self.verifyManager.bizParams completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self);
        if ([response isSuccess]) {
            self.createResponse = response;
            self.isRefreshCreateResponseSuccess = YES;
        }
        CJ_CALL_BLOCK(completion,response);
    }];
}

- (void)p_freshloadingLocation {
    self.loadingLocation = kCJPayAgainLoadingLocationNull;
}

- (void)p_setupUI {
    self.title = CJPayLocalizedStr(@"支付失败");
    [self useCloseBackBtn];
    [self.contentView addSubview:self.recommendView];
    CJPayMasMaker(self.recommendView, {
        make.top.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-CJ_TabBarSafeBottomMargin);
    })
}

- (void)p_confirmButtonClicked {
    CJPayDefaultChannelShowConfig *showConfig = [self.confirmResponse.hintInfo.recPayType buildShowConfig].firstObject;
    if (showConfig.type == BDPayChannelTypeAddBankCard || [showConfig isNeedReSigning]) {
        self.loadingLocation = kCJPayAgainLoadingLocationBottomButton;
    }
    [self p_payWithChannelShowConfig:showConfig];
    [self p_trackerWithEventName:@"wallet_cashier_second_pay_page_click" params:@{
        @"button_name" : CJString(self.recommendView.confirmButtton.titleLabel.text)
    }];
}

- (void)p_otherButtonClicked {
    if (self.verifyManager.isBindCardAndPay && !self.isRefreshCreateResponseSuccess) {
        @CJWeakify(self);
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        [self p_refreshCreateResponseWithCompletion:^(CJPayBDCreateOrderResponse * _Nonnull response) {
            @CJStrongify(self);
            [[CJPayLoadingManager defaultService] stopLoading];
            if ([response isSuccess]) {
                [self p_gotoPayAgainListVC];
            } else {
                [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            }
        }];
    } else {
        [self p_gotoPayAgainListVC];
    }
}

- (void)p_gotoPayAgainListVC {
    CJPayDYRecommendPayAgainListViewController *listVC = [CJPayDYRecommendPayAgainListViewController new];
    listVC.createResponse = self.createResponse;
    listVC.delegate = self;
    listVC.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
    listVC.outerRecommendShowConfig = [self.confirmResponse.hintInfo.recPayType buildShowConfig].firstObject;
    self.chooseCardVC = listVC;
    [self.navigationController pushViewController:listVC animated:YES];
}

- (void)p_payWithChannelShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    self.currentShowConfig = showConfig;
    if ([self.delegate respondsToSelector:@selector(payWithChannel:)]) {
        [self.delegate payWithChannel:showConfig];
    } else {
        CJPayLogAssert(NO, @"未实现推荐二次支付代理方法！！");
    }
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(trackWithEventName:params:)]) {
        return;
    }
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.currentShowConfig toActivityInfoTracker];
    if (activityInfo.count > 0 ) {
        [activityInfos btd_addObject:activityInfo];
    }
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    [mutableParams cj_setObject:CJString(self.confirmResponse.code) forKey:@"error_code"];
    [mutableParams cj_setObject:CJString(self.confirmResponse.msg) forKey:@"error_message"];
    [mutableParams cj_setObject:activityInfos forKey:@"activity_info"];
    [mutableParams cj_setObject:[self p_recMethod] forKey:@"rec_method"];
    [mutableParams cj_setObject:[self.createResponse.userInfo.pwdCheckWay isEqualToString:@"3"] ? @"1" : @"0" forKey:@"pswd_pay_type"];
    [mutableParams addEntriesFromDictionary:params];

    [self.delegate trackWithEventName:eventName params:[mutableParams copy]];
}

- (NSString *)p_recMethod {
    switch (self.currentShowConfig.type) {
        case BDPayChannelTypeAddBankCard:
            return @"addcard";
        case BDPayChannelTypeBalance:
            return @"balance";
        case BDPayChannelTypeBankCard:
            return @"quickpay";
        case BDPayChannelTypeCreditPay:
            return @"creditpay";
        default:
            return @"";
    }
}

#pragma mark - CJPayDYRecommendPayAgainListDelegate
- (void)didClickPayMethod:(CJPayDefaultChannelShowConfig *)payChannel {
    self.loadingLocation = kCJPayAgainLoadingLocationChooseCardVCCell;
    [self p_payWithChannelShowConfig:payChannel];
}

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self p_trackerWithEventName:eventName params:params];
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] || [vc isKindOfClass:CJPayDYRecommendPayAgainListViewController.class]) {
        switch (self.loadingLocation) {
            case kCJPayAgainLoadingLocationChooseCardVCAddCard:
                [self.chooseCardVC.payMethodView startLoadingAnimationOnAddBankCardCell];
                break;
            case kCJPayAgainLoadingLocationChooseCardVCCell:
                [self.chooseCardVC.payMethodView startLoading];
                break;
            case kCJPayAgainLoadingLocationBottomButton:
                @CJStartLoading(self.recommendView.confirmButtton)
                break;
            case kCJPayAgainLoadingLocationNull:
            default:
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
                break;
        }
    } else if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    }
}

- (void)stopLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] || [vc isKindOfClass:CJPayDYRecommendPayAgainListViewController.class]) {
        switch (self.loadingLocation) {
            case kCJPayAgainLoadingLocationChooseCardVCAddCard:
                [self.chooseCardVC.payMethodView stopLoadingAnimationOnAddBankCardCell];
                break;
            case kCJPayAgainLoadingLocationChooseCardVCCell:
                [self.chooseCardVC.payMethodView stopLoading];
                break;
            case kCJPayAgainLoadingLocationBottomButton:
                @CJStopLoading(self.recommendView.confirmButtton)
                break;
            case kCJPayAgainLoadingLocationNull:
            default:
                [[CJPayLoadingManager defaultService] stopLoading];
                break;
        }
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

#pragma mark - Lazy Views

- (CJPayDYRecommendPayAgainView *)recommendView {
    if (!_recommendView) {
        _recommendView = [CJPayDYRecommendPayAgainView new];
        @CJWeakify(self);
        [_recommendView.confirmButtton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_confirmButtonClicked];
        } forControlEvents:UIControlEventTouchUpInside];
         
        [_recommendView.otherPayButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_otherButtonClicked];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _recommendView;
}

@end
