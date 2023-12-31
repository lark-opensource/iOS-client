//
//  CJPayQuickBindCardTypeChooseViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/14.
//

#import "CJPayQuickBindCardTypeChooseViewController.h"

#import "CJPayQuickBindCardTypeChooseView.h"
#import "CJPayStyleButton.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayBizWebViewController.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayUserInfo.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayMemProtocolListRequest.h"
#import "CJPayMemProtocolListResponse.h"
#import "CJPayCookieUtil.h"
#import "CJPayBindCardFirstStepViewController.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayRequestParam.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayUIMacro.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayAuthVerifyViewController.h"
#import "CJPayWebViewUtil.h"
#import "CJPayVerifyItemBindCardRecogFace.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemberFaceVerifyInfoModel.h"
#import "CJPayFaceVerifyInfo.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayPasswordVerifyViewController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayNavigationController.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayCardManageModule.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardShareDataKeysDefine.h"
#import "CJPayQuickBindCardManager.h"
#import "CJPayQuickBindCardKeysDefine.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayOrderInfoView.h"
#import "CJPayBindCardTopHeaderView.h"
#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayBindCardRetainInfo.h"
#import "CJPayAlertUtil.h"
#import "CJPayKVContext.h"
#import "CJPayBindCardRetainUtil.h"

#define CJ_BACKGROUND_VIEW_WIDTH 375.0
#define CJ_BACKGROUND_VIEW_HEIGHT 380.0
#define CJ_BACKGROUND_LOGO_WIDTH 200
#define CJ_STANDARD_WIDTH 375.0

@implementation CJPayQuickBindCardTypeChooseViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"processInfo" : CJPayBindCardShareDataKeyProcessInfo,
        @"isQuickBindCard" : CJPayBindCardShareDataKeyIsQuickBindCard,
        @"jumpQuickBindCard" : CJPayBindCardShareDataKeyJumpQuickBindCard,
        @"quickBindCardModel" : CJPayBindCardShareDataKeyQuickBindCardModel,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"title" : CJPayBindCardShareDataKeyTitle,
        @"subTitle" : CJPayBindCardShareDataKeySubTitle,
        @"orderAmount": CJPayBindCardShareDataKeyOrderAmount,
        @"frontIndependentBindCardSource" : CJPayBindCardShareDataKeyFrontIndependentBindCardSource,
        @"bindCardInfo" : CJPayBindCardShareDataKeyBindCardInfo,
        @"trackerParams" : CJPayBindCardShareDataKeyTrackerParams,
        @"displayIcon" : CJPayBindCardShareDataKeyDisplayIcon,
        @"displayDesc" : CJPayBindCardShareDataKeyDisplayDesc,
        @"orderInfo" : CJPayBindCardShareDataKeyOrderInfo,
        @"iconURL" : CJPayBindCardShareDataKeyIconURL,
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"isSilentAuthorize" : CJPayQuickBindCardPageParamsKeyIsSilentAuthorize,
        @"retainInfo" : CJPayBindCardShareDataKeyRetainInfo,
        @"startTimestamp" : CJPayBindCardShareDataKeyStartTimestamp
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

@end

@interface CJPayQuickBindCardTypeChooseViewController ()<CJPayTrackerProtocol>

@property (nonatomic, strong) CJPayQuickBindCardTypeChooseViewModel *viewModel;

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) CJPayOrderInfoView *orderInfoView;
@property (nonatomic, strong) CJPayBindCardTopHeaderView *topHeaderView;
@property (nonatomic, strong) CJPayBindCardTopHeaderViewModel *topHeaderViewModel;
@property (nonatomic, strong) CJPayQuickBindCardTypeChooseView *cardTypeChooseView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayButton *changeOtherBankCardButton;
@property (nonatomic, strong) UIImageView *arrowImageView;

@property (nonatomic, strong) CJPayCommonProtocolModel *creditProtocolModel;
@property (nonatomic, strong) CJPayCommonProtocolModel *debitProtocolModel;
@property (nonatomic, strong) CJPayCreateOneKeySignOrderResponse *oneKeyCreateOrderResponse;

@property (nonatomic, assign) BOOL isShowAddOtherCard;
@property (nonatomic, assign) BOOL hasFetchedProtocol;

@end

@implementation CJPayQuickBindCardTypeChooseViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_fetchProtocolList];
    [self p_tracker];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForground) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_reload) name:CJPayBindCardSetPwdShowNotification object:nil];
}

- (void)p_reload {
    self.viewModel.retainInfo.isHadShowRetain = YES;
}

- (void)p_tracker {
    [[CJPayBindCardManager sharedInstance] setEntryName:@"1"];
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:[self.viewModel.quickBindCardModel activityInfoWithCardType:self.viewModel.quickBindCardModel.cardType] forKey:@"campaign_info"];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.rankType forKey:@"rank_type"];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.bankRank forKey:@"bank_rank"];
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_page_imp" params:[trackerParams copy]];
}

- (void)back
{
    [self p_trackerWithEventName:@"wallet_page_back_click"
                          params:@{@"page_name": @"wallet_addbcard_onestepbind_banktype_page"}];
    __block BOOL shouldReturn = NO;
    @CJWeakify(self)
    
    [self.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if ([obj isKindOfClass:[CJPayBindCardBaseViewController class]]) {
            [self.navigationController popToViewController:obj animated:YES];
            *stop = YES;
            shouldReturn = YES;
        }
    }];
    if (shouldReturn) {
        return;
    }
    
    if ([self p_needRetain]) {
        [self p_showRetainVC];
        return;
    }
    
    [self p_closeBindProcess];
}

- (BOOL)p_needRetain {
    if (!self.viewModel.retainInfo) {
        return NO;
    }
    return !([self.viewModel.retainInfo.controlFrequencyStr isEqualToString:@"1"] || self.viewModel.retainInfo.isHadShowRetain);
}

- (void)p_closeBindProcess {
    if (![[CJPayBindCardManager sharedInstance] cancelBindCard]) {
        [super back];
    }
}

- (void)p_showRetainVC {
    
    @CJWeakify(self)
    void(^cancelBlock)(void) = ^() {
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @CJStrongify(self)
            [self p_closeBindProcess];
        });
    };
    
    CJPayBindCardRetainInfo *retainInfo = self.viewModel.retainInfo;
    retainInfo.cancelBlock = [cancelBlock copy];
    @CJWeakify(retainInfo)
    void(^continueBlock)(void) = ^() {
        @CJStrongify(self)
        @CJStrongify(retainInfo)
        [self p_changeOtherBank];
        return;
    };
    retainInfo.continueBlock = [continueBlock copy];
    retainInfo.appId = self.viewModel.appId;
    retainInfo.merchantId = self.viewModel.merchantId;
    retainInfo.cardType = [self.cardTypeChooseView currentSelectedCardType];
    retainInfo.trackDelegate = self;
    
    [CJPayBindCardRetainUtil showRetainWithModel:retainInfo fromVC:self];
    
    //记录已经展示过挽留弹框
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
        CJPayBindCardShareDataKeyIsHadShowRetain: @(YES)
    } completion:nil];
    self.viewModel.retainInfo.isHadShowRetain = YES;
}

- (void)appDidEnterForground {
    // 查询用户是否已经完成了绑卡
    if (Check_ValidString(self.oneKeyCreateOrderResponse.memberBizOrderNo) &&
        [[UIViewController cj_foundTopViewControllerFrom:self] isKindOfClass:[self class]] &&
        [self p_shouldOpenApp]) {
        [[CJPayQuickBindCardManager shared] queryOneKeySignState];
    }
}

- (void)p_setupUI
{
    [self.view addSubview:self.cardTypeChooseView];

    [self p_setupForNewStyle];
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.view).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
            make.centerX.width.equalTo(self.view);
        });
    }
    

    [self.cardTypeChooseView reloadWithQuickBindCardModel:self.viewModel.quickBindCardModel];
}

- (void)p_setupForNewStyle {
    self.navigationBar.backgroundColor = [UIColor cj_colorWithHexString:@"#F5F5F5"];
    self.view.backgroundColor = [UIColor cj_colorWithHexString:@"#F5F5F5"];
    
    if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
        [self.view addSubview:self.backgroundImageView];
        [self.backgroundImageView cj_setImage:@"cj_bindcard_logo_icon"];
        CJPayMasMaker(self.backgroundImageView, {
            make.top.right.equalTo(self.view);
            make.width.height.mas_equalTo(self.view.cj_width * CJ_BACKGROUND_LOGO_WIDTH / CJ_STANDARD_WIDTH);
        });
    }
    
    [self.view addSubview:self.topHeaderView];
    
    if ([self.viewModel.jumpQuickBindCard isEqualToString:@"1"]) { //电商进入头部带上订单提交成功
        [self.view addSubview:self.orderInfoView];
        [self.orderInfoView updateWithText:self.viewModel.orderInfo iconURL:self.viewModel.iconURL];
        CJPayMasMaker(self.orderInfoView, {
            make.centerX.equalTo(self.navigationBar);
            make.centerY.equalTo(self.navigationBar.backBtn);
        })
        
        if (self.viewModel.startTimestamp > 100000) {
            // 过滤无效的时间戳数据
            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
            NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
            long duration = currentTimestamp - self.viewModel.startTimestamp;
            [CJTracker event:@"wallet_bindcard_perf_track_event" params:@{
                @"duration" : @(duration),
                @"type": @"card_type_choose"
            }];
        }
        
    }
    
    self.topHeaderViewModel.displayIcon = self.viewModel.displayIcon;
    self.topHeaderViewModel.displayDesc = self.viewModel.displayDesc;
    self.topHeaderViewModel.orderAmount = self.viewModel.orderAmount;

    if (self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay) {
        self.topHeaderViewModel.title = CJPayLocalizedStr(@"添加银行卡支付");
    } else {
        self.topHeaderViewModel.title = CJPayLocalizedStr(@"添加银行卡");
    }
    self.topHeaderViewModel.preTitle = @"";
    [self.topHeaderView updateWithModel:self.topHeaderViewModel];
    
    CJPayMasMaker(self.topHeaderView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.centerX.equalTo(self.view);
        make.left.right.equalTo(self.view);
    })
    
    CJPayMasMaker(self.cardTypeChooseView, {
        make.top.equalTo(self.topHeaderView.mas_bottom);
        make.left.right.equalTo(self.view);
    });
    
    if (self.isShowAddOtherCard) {
        [self.view addSubview:self.changeOtherBankCardButton];
        [self.view addSubview:self.arrowImageView];
        CJPayMasMaker(self.changeOtherBankCardButton, {
            make.top.equalTo(self.cardTypeChooseView);
            make.right.equalTo(self.cardTypeChooseView).offset(-44);
            make.height.equalTo(@52);
            make.width.equalTo(@48);
        });
        CJPayMasMaker(self.arrowImageView, {
            make.centerY.equalTo(self.changeOtherBankCardButton);
            make.right.equalTo(self).offset(-32);
            make.height.width.equalTo(@12);
        });
    
        
        // 显示了更换其他银行卡后之后流程都不显示
        self.viewModel.jumpQuickBindCard = @"0";
        [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyJumpQuickBindCard: @"0"} completion:^(NSArray * _Nonnull modifyedKeysArray) {}];
    }
}

- (NSDictionary *)p_trackerBankTypeParams
{
    NSString *bankTypeList = [self.viewModel.quickBindCardModel.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡";
    NSString *normalBankTypeList = [self.viewModel.quickBindCardModel.cardType isEqualToString:@"DEBIT"] ? @"信用卡" : @"储蓄卡";//支持跳转手动输入的银行卡类型
    if ([self.viewModel.quickBindCardModel.cardType isEqualToString:@"ALL"]) {
        bankTypeList = @"储蓄卡、信用卡";
        normalBankTypeList = @"";
    }
    
    NSString *isAliveCheckStr = self.oneKeyCreateOrderResponse.faceVerifyInfoModel.needLiveDetection ? @"1": @"0";
    
    return @{
        @"bank_name": CJString(self.viewModel.quickBindCardModel.bankName),
        @"bank_type": [[self.cardTypeChooseView currentSelectedCardType] isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡",
        @"bank_type_list": bankTypeList,
        @"is_alivecheck": CJString(isAliveCheckStr),
        @"activity_info": [self.viewModel.quickBindCardModel activityInfoWithCardType:[self.cardTypeChooseView currentSelectedCardType]] ?: @[],
        @"page_type": @"page",
        @"normal_bank_type": CJString(normalBankTypeList)
    };
}

- (void)p_confirmButtonTapped {
    @CJWeakify(self)
    [self.cardTypeChooseView.protocolView executeWhenProtocolSelected:^{
        @CJStrongify(self)
        [self p_startOneKeyBindCard];
    } notSeleted:^{
        @CJStrongify(self)
        if (self.cardTypeChooseView.protocolView.protocolModel.agreements.count) {
            CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.cardTypeChooseView.protocolView.protocolModel from:[self p_pageName]];
            popupProtocolVC.confirmBlock = ^{
                @CJStrongify(self)
                [self.cardTypeChooseView.protocolView setCheckBoxSelected:YES];
                [self p_startOneKeyBindCard];
            };
            [self.navigationController pushViewController:popupProtocolVC animated:YES];
        }
    } hasToast:NO];
}

- (void)p_startOneKeyBindCard {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
    
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.rankType forKey:@"rank_type"];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.bankRank forKey:@"bank_rank"];
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_page_agreement"
                          params:[trackerParams copy]];
    
    NSDictionary *dict = @{
        CJPayBindCardShareDataKeyQuickBindCardModel : [self.viewModel.quickBindCardModel toDictionary] ?: @{},
    };
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict
                                                         completion:^(NSArray * _Nonnull modifyedKeysArray) {}];
    
    if (![self p_isAuthorized]) {
        [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickAuthVerify
                                              params:@{
            CJPayQuickBindCardPageParamsKeyIsNeedCreateSignOrder : @(YES),
            CJPayQuickBindCardPageParamsKeySelectedCardType : [self.cardTypeChooseView currentSelectedCardType],
            CJPayBindCardPageParamsKeySelectedCardTypeVoucher : CJString([self.cardTypeChooseView currentSelectedCardVoucher])}
                                             completion:^(BOOL isOpenedSuccessed, NSString * _Nonnull errMsg) {}];
        return;
    }
    

    CJ_DelayEnableView(self.view);
    BDPayQuickBindCardSignOrderModel *signOrderModel = [[BDPayQuickBindCardSignOrderModel alloc] initWithDictionary:[self.viewModel toDictionary] error:nil];
    signOrderModel.selectedCardType = [self.cardTypeChooseView currentSelectedCardType];

    [[CJPayQuickBindCardManager shared] startOneKeySignOrderFromVC:self
                                                    signOrderModel:signOrderModel
                                                         extParams:@{@"start_one_key_time": @(currentTimestamp)}
                                         createSignOrderCompletion:^(CJPayCreateOneKeySignOrderResponse * _Nonnull response) {
                                                                        [self.cardTypeChooseView.confirmButton stopLoading];
                                                                        self.oneKeyCreateOrderResponse = response;
                                                                    }
                                                        completion:^(BOOL isFinished) {
                                                                        if (isFinished) {
                                                                            [[CJPayQuickBindCardManager shared] queryOneKeySignState];
                                                                    }
    }];
}

- (BOOL)p_isAuthorized {
    return [self.viewModel.userInfo hasValidAuthStatus] || self.viewModel.isCertification;
}

- (void)p_fetchProtocolList
{
    if (![self p_isAuthorized]) {
        //未实名时新卡类型页不展示协议
        [self.cardTypeChooseView updateUIWithoutProtocol];
        [self.cardTypeChooseView.confirmButton setTitle: CJPayLocalizedStr(@"下一步") forState:UIControlStateNormal];
        return;
    }
    NSString *cardType = [self.cardTypeChooseView currentSelectedCardType];
    
    if ([cardType isEqualToString:@"DEBIT"] && self.debitProtocolModel) {
        [self.cardTypeChooseView.protocolView updateWithCommonModel:self.debitProtocolModel];
        return;
    }
    
    if ([cardType isEqualToString:@"CREDIT"] && self.creditProtocolModel) {
        [self.cardTypeChooseView.protocolView updateWithCommonModel:self.creditProtocolModel];
        return;
    }
    
    if (self.hasFetchedProtocol) {
        return;
    }
    
    self.hasFetchedProtocol = YES;//避免在等待协议的过程中切换卡重复请求
    [self.cardTypeChooseView.confirmButton setEnabled:NO];
    
    @CJWeakify(self)
    dispatch_group_t group = dispatch_group_create();
    [self p_fetchProtocol:@"DEBIT" group:group];
    [self p_fetchProtocol:@"CREDIT" group:group];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        if ([[self.cardTypeChooseView currentSelectedCardType] isEqualToString:@"DEBIT"] && self.debitProtocolModel) {
            [self.cardTypeChooseView.protocolView updateWithCommonModel:self.debitProtocolModel];
        } else if (self.creditProtocolModel) {
            [self.cardTypeChooseView.protocolView updateWithCommonModel:self.creditProtocolModel];
        }
        
        [self.cardTypeChooseView.confirmButton setEnabled:YES];
    });
}

- (void)p_fetchProtocol:(NSString *)cardType group:(dispatch_group_t)group {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"app_id" : CJString(self.viewModel.appId),
        @"merchant_id" : CJString(self.viewModel.merchantId),
        @"biz_order_type" : @"one_key_sign",
        @"bank_code" : CJString(self.viewModel.quickBindCardModel.bankCode),
        @"card_type" : CJString(cardType),
        @"member_biz_order_no" : CJString(self.viewModel.signOrderNo),
    }];
    @CJWeakify(self)
    dispatch_group_enter(group);
    [CJPayProtocolViewManager fetchProtocolListWithParams:params completion:^(NSError * _Nonnull error, CJPayMemProtocolListResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([response isSuccess]) {
            if ([cardType isEqualToString:@"DEBIT"]) {
                self.debitProtocolModel = [CJPayCommonProtocolModel new];
                self.debitProtocolModel.guideDesc = response.guideMessage;
                self.debitProtocolModel.groupNameDic = response.protocolGroupNames;
                self.debitProtocolModel.agreements = response.agreements;
                self.debitProtocolModel.protocolCheckBoxStr = response.protocolCheckBox;
                self.debitProtocolModel.supportRiskControl = YES;
                self.debitProtocolModel.isSelected = [self.cardTypeChooseView.protocolView isCheckBoxSelected];
            } else {
                self.creditProtocolModel = [CJPayCommonProtocolModel new];
                self.creditProtocolModel.guideDesc = response.guideMessage;
                self.creditProtocolModel.groupNameDic = response.protocolGroupNames;
                self.creditProtocolModel.agreements = response.agreements;
                self.creditProtocolModel.protocolCheckBoxStr = response.protocolCheckBox;
                self.creditProtocolModel.supportRiskControl = YES;
                self.creditProtocolModel.isSelected = [self.cardTypeChooseView.protocolView isCheckBoxSelected];
            }
        }
        dispatch_group_leave(group);
    }];
}

- (NSString *)p_pageName {
    if (self.viewModel.isSilentAuthorize) {
        return @"实名静默授权卡类型选择";
    } else {
        return @"卡类型选择";
    }
}

- (BOOL)p_shouldOpenApp
{
    NSString *aid = [CJPayRequestParam gAppInfoConfig].appId;
    if (![aid isEqualToString:@"1128"]) {
        return NO;
    }
    
    NSString *bankCode = self.viewModel.quickBindCardModel.bankCode;
    return ([bankCode isEqualToString:@"CMB"] && [[self.cardTypeChooseView currentSelectedCardType] isEqualToString:@"DEBIT"]);
}

- (void)p_changeOtherBank {
        
    [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                             params:@{CJPayBindCardPageParamsKeyIsFromQuickBindCard : @(YES)
                                                    }
                                         completion:^(BOOL isOpenedSuccessed, NSString * _Nonnull errMsg) {
            
        }];
    
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:[self.viewModel.quickBindCardModel activityInfoWithCardType:self.viewModel.quickBindCardModel.cardType] forKey:@"campaign_info"];
    [trackerParams cj_setObject:@"2" forKey:@"page_from"];
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_return_banklist_click" params:trackerParams];
}

- (void)updateViewData:(CJPayQuickBindCardModel *)model {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:@"银行卡切换中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[CJPayLoadingManager defaultService] stopLoading];
    });
    
    self.viewModel.quickBindCardModel = model;
    self.topHeaderViewModel.bankIcon = self.viewModel.quickBindCardModel.iconUrl;
    if (self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay) {
        self.topHeaderViewModel.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.quickBindCardModel.bankName, @"卡支付"];
    } else {
        self.topHeaderViewModel.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.quickBindCardModel.bankName, @"卡"];
    }
    
    [self.topHeaderView updateWithModel:self.topHeaderViewModel];

    [self p_fetchProtocolList];
    [self.cardTypeChooseView reloadWithQuickBindCardModel:self.viewModel.quickBindCardModel];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (void)p_trackerBankTypePageClick {
    NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.rankType forKey:@"rank_type"];
    [trackerParams cj_setObject:self.viewModel.quickBindCardModel.bankRank forKey:@"bank_rank"];

    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_page_click" params:[trackerParams copy]];
}

#pragma mark - Lazy View

- (CJPayQuickBindCardTypeChooseView *)cardTypeChooseView
{
    if (!_cardTypeChooseView) {
        _cardTypeChooseView = [[CJPayQuickBindCardTypeChooseView alloc] init];
        @CJWeakify(self)
        _cardTypeChooseView.confirmButtonClickBlock = ^{
            @CJStrongify(self)
            [self p_confirmButtonTapped];
        };
        _cardTypeChooseView.didSelectedCardTypeBlock = ^{
            @CJStrongify(self)
            [self p_fetchProtocolList];
            [self p_trackerBankTypePageClick];
        };
        _cardTypeChooseView.inputCardClickBlock = ^(NSString * _Nonnull voucherStr, NSString * _Nonnull cardType) {
            @CJStrongify(self)
            NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
            [trackerParams cj_setObject:self.viewModel.quickBindCardModel.rankType forKey:@"rank_type"];
            [trackerParams cj_setObject:self.viewModel.quickBindCardModel.bankRank forKey:@"bank_rank"];

            [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_return_cardid_click" params:[trackerParams copy]];

            // 防暴击
            CJ_DelayEnableView(self.cardTypeChooseView);
            
            UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                                  params:@{CJPayBindCardPageParamsKeyIsQuickBindCardListHidden : @(YES),
                                                           CJPayBindCardPageParamsKeyIsFromQuickBindCard : @(YES),
                                                           CJPayBindCardPageParamsKeyIsShowKeyboard : @(YES),
                                                           CJPayBindCardPageParamsKeySelectedBankIcon : self.viewModel.quickBindCardModel.iconUrl,
                                                           CJPayBindCardPageParamsKeySelectedBankName : self.viewModel.quickBindCardModel.bankName,
                                                           CJPayBindCardPageParamsKeySelectedCardTypeVoucher : CJString(voucherStr),
                                                           CJPayBindCardPageParamsKeySelectedBankType : CJString(cardType)
                                                         }
                                              completion:^(BOOL isOpenedSuccessed, NSString * _Nonnull errMsg) {
                
            }];
            if ([vc isKindOfClass:CJPayBindCardFirstStepViewController.class]) {
                CJPayBindCardFirstStepViewController *bindCardVC = (CJPayBindCardFirstStepViewController *)vc;
                bindCardVC.forceShowTopSafe = YES;
            }
        };
        
        _cardTypeChooseView.didSelectedAddOtherCardBlock = ^{
            @CJStrongify(self);
            self.viewModel.jumpQuickBindCard = @"0";
            NSDictionary *dict = @{
                CJPayBindCardShareDataKeyJumpQuickBindCard: @"0",
            };
            [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:^(NSArray * _Nonnull modifyedKeysArray) {
                
            }];
            
            [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                                     params:@{CJPayBindCardPageParamsKeyIsFromQuickBindCard : @(YES)
                                                            }
                                                 completion:^(BOOL isOpenedSuccessed, NSString * _Nonnull errMsg) {
                
            }];
            
            NSMutableDictionary *trackerParams = [[self p_trackerBankTypeParams] mutableCopy];
            [trackerParams cj_setObject:[self.viewModel.quickBindCardModel activityInfoWithCardType:self.viewModel.quickBindCardModel.cardType] forKey:@"campaign_info"];
            [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_page_other_click" params:trackerParams];
        };
    }
    return _cardTypeChooseView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
    }
    return _backgroundImageView;
}

- (CJPayOrderInfoView *)orderInfoView {
    if (!_orderInfoView) {
        _orderInfoView = [CJPayOrderInfoView new];
    }
    return _orderInfoView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (CJPayBindCardTopHeaderView *)topHeaderView {
    if (!_topHeaderView) {
        _topHeaderView = [CJPayBindCardTopHeaderView new];
    }
    return _topHeaderView;
}

- (CJPayButton *)changeOtherBankCardButton {
    if (!_changeOtherBankCardButton) {
        _changeOtherBankCardButton = [CJPayButton new];
        [_changeOtherBankCardButton cj_setBtnTitle:CJPayLocalizedStr(@"更换银行")];
        [_changeOtherBankCardButton cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.6]];
        _changeOtherBankCardButton.titleLabel.font = [UIFont cj_fontOfSize:12];
        [_changeOtherBankCardButton addTarget:self action:@selector(p_changeOtherBank) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeOtherBankCardButton;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_combine_pay_arrow_denoise_icon"];
    }
    return _arrowImageView;
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayQuickBindCardTypeChooseViewModel alloc] initWithDictionary:dict error:&error];
        if (error) {
            CJPayLogAssert(NO, @"创建 CJPayQuickBindCardTypeChooseViewModel 失败.");
        }
        
        if ([self.viewModel.jumpQuickBindCard isEqualToString:@"1"]) {
            self.isShowAddOtherCard = YES;
        }
    }
}

- (CJPayBindCardTopHeaderViewModel *)topHeaderViewModel {
    if (!_topHeaderViewModel) {
        _topHeaderViewModel = [CJPayBindCardTopHeaderViewModel new];
    }
    return _topHeaderViewModel;
}

+ (Class)associatedModelClass {
    return [CJPayQuickBindCardTypeChooseViewModel class];
}

#pragma mark - CJPayTrackerProtocol
- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self p_trackerWithEventName:event params:params];
}

@end
