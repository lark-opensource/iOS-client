//
//  CJPaySignCardListViewController.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPaySignCardListViewController.h"

#import "CJPayBytePayMethodView.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPaySignQueryMemberPayListRequest.h"
#import "CJPaySignQueryMemberPayListResponse.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPaySettingsManager.h"

@interface CJPaySignCardListViewController ()<CJPayMethodTableViewDelegate>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) CJPayBytePayMethodView *payMethodView;
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *models;

@end

@implementation CJPaySignCardListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.models = [self p_getShouldShowConfigs];
    [self p_setupUI];
    [self p_updateMethodView];
    NSMutableArray *methodList = [NSMutableArray new];
    [self.models enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [methodList btd_addObject:[obj toSubPayMethodInfoTrackerDic]];
    }];
    [self p_trackEvent:@"wallet_orderqueue_setup_method_show"
                params:@{@"byte_sub_pay_list": methodList}];
}

- (void)back {
    [super back];
    [self p_trackEvent:@"wallet_orderqueue_setup_method_click" params:@{@"button_name": @"关闭"}];
    [self p_trackEvent:@"wallet_orderqueue_setup_method_close" params:@{}];
}

- (void)p_setupUI {
    [self.navigationBar setTitle:CJPayLocalizedStr(@"选择优先扣款方式")];
    [self useCloseBackBtn];
    [self.contentView addSubview:self.headerView];
    [self.headerView addSubview:self.tipsLabel];
    [self.contentView addSubview:self.payMethodView];
    
    CJPayMasMaker(self.headerView, {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.centerY.equalTo(self.headerView);
        make.left.equalTo(self.headerView).offset(16);
        make.right.equalTo(self.headerView).offset(-16);
        make.height.mas_equalTo(18);
    });
    
    CJPayMasMaker(self.payMethodView, {
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(24);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
    });
    
    self.payMethodView.delegate = self;
}

- (void)p_updateMethodView {
    NSMutableArray *array = [NSMutableArray array];
    for (CJPayDefaultChannelShowConfig *channelConfig in self.models) {
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.isConfirmed = [self.defaultShowConfig isEqual:channelConfig];
        model.isChooseMethodSubPage = YES;
        model.hasConfirmBtnWhenUnConfirm = YES;
        [array btd_addObject:model];
    }
    
    self.payMethodView.models = [array copy];;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)p_getShouldShowConfigs {
    NSArray *showConfigs = [self.listResponse memberPayListShowConfigs];
    NSMutableArray *sortedConfigs = [NSMutableArray array];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqual:self.defaultShowConfig]) {
            [sortedConfigs insertObject:obj atIndex:0];
        } else {
            [sortedConfigs addObject:obj];
        }
    }];
    return [sortedConfigs copy];;
}

- (void)p_refreshCardList {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    [CJPaySignQueryMemberPayListRequest startWithBizParams:self.requestParams completion:^(NSError * _Nonnull error, CJPaySignQueryMemberPayListResponse * _Nonnull response) {
        [[CJPayLoadingManager defaultService] stopLoading];
        if (error || ![response isSuccess]) {
            [CJToast toastText:Check_ValidString(response.msg) ? CJString(response.msg) : CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        self.listResponse = response;
        self.models = [self p_getShouldShowConfigs];
        [self p_updateMethodView];
    }];
}

- (void)p_trackEvent:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionary];
    [trackParams addEntriesFromDictionary:self.trackParams];
    [trackParams addEntriesFromDictionary:@{
        @"orderqueue_source" : self.isSignOnly ? @"wallet_withhold_merchant_project_page" : @"wallet_withhold_open_page",
        @"method": CJString(self.defaultShowConfig.title),
        @"cashier_style": self.isSignOnly ? @"2" : @"1"
    }];
    [trackParams addEntriesFromDictionary:params];
    [CJTracker event:eventName params:[trackParams copy]];
}

#pragma mark - CJPayMethodTableViewDelegate
- (void)didSelectAtIndex:(int)selectIndex {
    CJPayDefaultChannelShowConfig *selectModel = [self.models cj_objectAtIndex:selectIndex];
    
    if (!selectModel.enable) {
        return;
    }
    
    if (selectModel.type == BDPayChannelTypeAddBankCard) {
        [self p_bindCard];
        return;
    }
    
    self.defaultShowConfig = selectModel;
    [self p_updateMethodView];
    [self p_trackEvent:@"wallet_orderqueue_setup_method_click" params:@{@"button_name": CJString(self.defaultShowConfig.title)}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //延时0.25让用户看到切换后的选中态
        @CJWeakify(self);
        [self p_trackEvent:@"wallet_orderqueue_setup_method_close" params:@{}];
        [self closeWithAnimation:YES comletion:^(BOOL isSuccess) {
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.didClickMethodBlock, self.defaultShowConfig);
        }];
    });
}

- (void)p_bindCard {
    [self p_trackEvent:@"wallet_orderqueue_setup_addcard_click" params:@{}];
    CJPayBindCardSharedDataModel *commonModel = [self p_buildCommonModel];
    NSString *sourceStr = self.isSignOnly ? @"sign" : @"pay_and_sign";
    commonModel.frontIndependentBindCardSource = sourceStr;
    BOOL enableNativeBindCard = [CJPaySettingsManager shared].currentSettings.nativeBindCardConfig.enableNativeBindCard;
    if (!enableNativeBindCard || [[CJPayBindCardManager sharedInstance] isLynxReady]) {
        [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:commonModel];
        return;
    }
    
    NSDictionary *params = @{
        @"source" : sourceStr,
        @"app_id" : CJString(self.zgAppId),
        @"merchant_id" : CJString(self.zgMerchantId)};
    [self.payMethodView startLoading];
    [[CJPayBindCardManager sharedInstance] onlyBindCardWithCommonModel:commonModel params:params completion:nil stopLoadingBlock:^{
        [self.payMethodView stopLoading];
    }];
}

- (CJPayBindCardSharedDataModel *)p_buildCommonModel {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceSignPay;
    model.cardBindSource = CJPayCardBindSourceTypeFrontIndependent;
    model.appId = self.zgAppId;
    model.merchantId = self.zgMerchantId;
    model.referVC = self;
    model.cjpay_referViewController = self;
    @CJWeakify(self);
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        @CJStrongify(self)
        NSString *resultStr = cardResult.result == CJPayBindCardResultSuccess ? @"1" : @"0";
        [self p_trackEvent:@"wallet_orderqueue_setup_addcard_result" params:@{@"result": resultStr}];
        switch (cardResult.result) {
            case CJPayBindCardResultSuccess:
                [self p_refreshCardList];
                break;
            case CJPayBindCardResultFail:
            case CJPayBindCardResultCancel:
                CJPayLogInfo(@"绑卡失败 code: %ld", cardResult.result);
                break;
        }
    };
    return model;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [UIView new];
        _headerView.backgroundColor = [UIColor cj_f8f8f8ff];
    }
    return _headerView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:13];
        _tipsLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _tipsLabel.text = CJPayLocalizedStr(@"优先方式扣款失败时，将尝试按顺序从其他支付方式扣款");
    }
    return _tipsLabel;
}

- (CJPayBytePayMethodView *)payMethodView {
    if (!_payMethodView) {
        _payMethodView = [CJPayBytePayMethodView new];
        _payMethodView.isChooseMethodSubPage = YES;
    }
    return _payMethodView;
}


@end
