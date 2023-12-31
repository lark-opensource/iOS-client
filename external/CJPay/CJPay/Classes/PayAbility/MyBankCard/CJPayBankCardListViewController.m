//
//  CJPayBankCardListViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardListViewController.h"
#import "CJPayBankCardItemViewModel.h"
#import "CJPayBankCardAddViewModel.h"
#import "CJPayBankCardEmptyAddViewModel.h"
#import "CJPayBankCardNoCardTipViewModel.h"
#import "CJPayBankCardFooterViewModel.h"
#import "CJPayBankCardActivityHeaderViewModel.h"
#import "CJPayBankCardActivityItemViewModel.h"
#import "CJPayBizWebViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPayTracker.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayQueryUserBankCardRequest.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBaseRequest.h"
#import "CJPayMemBankSupportListRequest.h"
#import "CJPayMemBankActivityRequest.h"
#import "CJPayMemBankActivityResponse.h"
#import "CJPayQuickBindCardViewModel.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayButton.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayExceptionViewController.h"
#import "CJPayMyBankCardListView.h"
#import "CJPayMyBankCardListViewModel.h"
#import "CJPayAllBankCardListViewController.h"
#import "CJPayBankActivityInfoModel.h"
#import "CJPayRequestParam.h"
#import "CJPayBankCardActivityItemCell.h"
#import <ByteDanceKit/UIScrollView+BTDAdditions.h>
#import "CJPayAccountInsuranceTipView.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayWebViewUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPayBindCardTitleInfoModel.h"
#import <TTReachability/TTReachability.h>
#import "CJPayBankCardHeaderSafeBannerViewModel.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayQuickBindCardManager.h"
#import "CJPayAlertUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayQueryUnionPaySignStatusRequest.h"
#import "CJPayQueryUnionPaySignStatusResponse.h"
#import "CJPaySyncUnionViewModel.h"
#import "CJPayBankCardListUtil.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayUIMacro.h"
#import "CJPayUnionBindCardPlugin.h"

@interface CJPayBankCardListViewController ()

#pragma mark - data
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSArray *cardModels;
@property (nonatomic, copy) NSString *bankCardListStr;
@property (nonatomic, copy) NSString *quickBindCardListStr;
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;
@property (nonatomic, assign) NSInteger checkStatus;
@property (nonatomic, assign) NSInteger countDown;
@property (nonatomic, strong) CJPaySyncUnionViewModel *syncUnionViewModel;

// lynx绑卡链接
@property (nonatomic, copy) NSString *bindCardUrl;

#pragma mark - model
@property (nonatomic, strong) BDPayQueryUserBankCardResponse *userBankCardResponse;
@property (nonatomic, strong) CJPayMemBankSupportListResponse *bankSupportListResponse;
@property (nonatomic, strong) CJPayMemBankActivityResponse *bankActivityResponse;

#pragma mark - flag
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isWalletBcardManageImpTracked;
@property (nonatomic, assign) BOOL isFromCancelBind;
@property (nonatomic, assign) BOOL isLoadBindCardList;
@property (nonatomic, assign) BOOL needShowUnionPay;
@property (nonatomic, assign) BOOL lastShowUnionPayStatus;
@property (nonatomic, assign) BOOL syncUnionPayABTest;
@property (nonatomic, assign) BOOL cancelRefresh;

@property (nonatomic, assign) CJPayIndependentBindCardType independentBindCardType;
@property (nonatomic, strong) CJPayAllBankCardListViewController *allBankListVC;

@end

@implementation CJPayBankCardListViewController

+ (instancetype)openWithAppId:(NSString *)appId merchantId:(NSString *)merhcantId userId:(NSString *)userId extraParams:(NSDictionary *)extraParams {
    CJPayBankCardListViewController *bankCardVC = [[CJPayBankCardListViewController alloc] initWithAppId:appId merchantId:merhcantId userId:userId];
    NSString *inheritTheme = [extraParams cj_stringValueForKey:@"inherit_theme"];
    if (Check_ValidString(inheritTheme)) {
        bankCardVC.cjInheritTheme = [CJPayThemeModeManager themeModeFromString:inheritTheme];
    }
    [bankCardVC presentWithNavigationControllerFrom:merhcantId.cjpay_referViewController
                                            useMask:NO
                                         completion:nil];
    return bankCardVC;
}

- (instancetype)initWithAppId:(NSString *)appId
                   merchantId:(NSString *)merchantId
                       userId:(NSString *)userId {
    self = [super init];
    if (self) {
        self.appId = appId;
        self.merchantId = merchantId;
        self.userId = userId;
        self.isFirstAppear = YES;
        self.isFromCancelBind = NO;
        
        [CJPayBankCardListUtil shared].appId = appId;
        [CJPayBankCardListUtil shared].merchantId = merchantId;
        [CJPayBankCardListUtil shared].userId = userId;
        [CJPayBankCardListUtil shared].vc = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syncUnionPayABTest = [[CJPayABTest getABTestValWithKey:CJPayABUnionCard] isEqualToString:@"1"];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    // Do any additional setup after loading the view.
    [self.navigationBar setTitle:CJPayLocalizedStr(@"我的银行卡")];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(cancelBindSuccess) name:CJPayCancelBindCardNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess) name:CJPayBindCardSuccessPreCloseNotification object:nil];
        
    self.tableView.contentInset = UIEdgeInsetsMake(8, 0, 0, 0);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.independentBindCardType = [[CJPayBankCardListUtil shared] indepentdentBindCardType];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.cancelRefresh) {
        self.cancelRefresh = NO;
        return;
    }
    
    [self refreshBankCardList];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.isFirstAppear = NO;
}

- (void)appDidEnterForground {
    if ([[UIViewController cj_foundTopViewControllerFrom:self] isKindOfClass:[self class]]) {
        [[CJPayQuickBindCardManager shared] queryOneKeySignStateAppDidEnterForground];
    }
}

- (void)p_scrollToTop {
    CGPoint off = self.tableView.contentOffset;
    off.y = 0 - self.tableView.contentInset.top;
    [self.tableView setContentOffset:off animated:YES];
}

- (void)p_bindCardSuccess {
    [self.navigationController popToViewController:self animated:YES];
    if (CJ_Pad) { // ipad端绑卡成功后不走viewWillAppear
        [self refreshBankCardList];
    }
}

- (void)p_bindCardSuccessToast {
    [CJToast toastText:CJPayLocalizedStr(@"绑卡成功") duration:0.5 inWindow:self.cj_window];
}

- (void)cancelBindSuccess {
    self.isFromCancelBind = YES;
}

- (void)reloadCurrentView
{
    [self refreshBankCardList];
}

- (BOOL)cjAllowTransition {
    return YES;
}

- (void)dealloc
{
    [CJPayPerformanceMonitor trackAPIEndWithAPIScene:CJPayPerformanceAPISceneBankCardList extra:@{}];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CJPayMyBankCardListViewModel *)p_myBankCardListViewModel {
    CJPayMyBankCardListViewModel *myBankCardListViewModel = [CJPayMyBankCardListViewModel new];
    myBankCardListViewModel.bankCardListViewModels = [self p_normalBankCardListViewModelsWithIsAllCardList:NO];
    @CJWeakify(self)
    myBankCardListViewModel.safeBannerDidClickBlock = ^{
        @CJStrongify(self)
        static NSString * const url = @"sslocal://cjpay/webview?url=https%3a%2f%2fcashier.ulpay.com%2fusercenter%2finsurance&canvas_mode=1&status_bar_text_style=dark";
        [self p_gotoBankActivityPageWithUrl:CJString(url)];
        
        [self p_trackerWithEventName:@"wallet_addbcard_insurance_title_click" params:@{
            @"insurance_title" : @"保障中",
            @"page_name" : @"wallet_bcard_manage_page_havecard"
        }];
    };
    
    myBankCardListViewModel.allBankCardListBlock = ^{
        @CJStrongify(self)
        self.allBankListVC.authInfo = self.userBankCardResponse.userInfo;// 这个要早于viewModel的设置
        self.allBankListVC.passParams = @{//这个要早于viewModel的设置
            @"app_id": CJString(self.appId),
            @"merchant_id": CJString(self.merchantId),
            @"is_chaselight": @"1",
            @"needidentity": self.userBankCardResponse.isAuthed ? @"0" : @"1",
            @"haspass": self.userBankCardResponse.isSetPWD ? @"1" : @"0",
            @"show_onestep": self.isLoadBindCardList ? @"1" : @"0",
            @"source" : @"wallet_bcard_manage",
            @"insurance_title" : @"抖音支付全程保障资金与信息安全",
            @"page_name" : @"wallet_bcard_manage_all_page",
            @"extra_query" : [@{@"insurance_source" : @"wallet_bcard_manage_all_page"} cj_toStr]
        };
        self.allBankListVC.viewModels = [self p_normalBankCardListViewModelsWithIsAllCardList:YES];
        [self p_trackerWithEventName:@"wallet_bcard_manage_all_click" params:@{@"card_num": @(self.userBankCardResponse.cardList.count)}];

        [self.navigationController pushViewController:self.allBankListVC animated:YES];
        
        NSDictionary *params = [@{
            @"insurance_title" : @"抖音支付全程保障资金与信息安全",
            @"page_name" : @"wallet_bcard_manage_all_page"
        } mutableCopy];
        [self p_trackerWithEventName:@"wallet_addbcard_insurance_title_imp"
                              params:params];
    };
    
    return myBankCardListViewModel;
}

- (CJPayBankCardHeaderSafeBannerViewModel *)p_bankCardEmptyAddSafeBannerViewModel {
    CJPayBankCardHeaderSafeBannerViewModel *emptyAddSafeBannerViewModel = [CJPayBankCardHeaderSafeBannerViewModel new];
    emptyAddSafeBannerViewModel.passParams = @{
        @"app_id": CJString(self.appId),
        @"merchant_id": CJString(self.merchantId),
        @"is_chaselight": @"1",
        @"needidentity": self.userBankCardResponse.isAuthed ? @"0" : @"1",
        @"haspass": self.userBankCardResponse.isSetPWD ? @"1" : @"0",
        @"show_onestep": self.isLoadBindCardList ? @"1" : @"0",
        @"source" : @"wallet_bcard_manage",
        @"insurance_title" : @"添加银行卡，享百万资金安全保障",
        @"page_name" : @"wallet_bcard_manage_page_nocard",
        @"extra_query" : [@{@"insurance_source" : @"wallet_bcard_manage_page_nocard"} cj_toStr]
    };
    return emptyAddSafeBannerViewModel;
}

- (CJPayBaseListViewModel *)p_bankCardEmptyAddViewModel {
    CJPayBankCardEmptyAddViewModel *emptyAddViewModel = [CJPayBankCardEmptyAddViewModel new];
    emptyAddViewModel.userInfo = self.userBankCardResponse.userInfo;
    emptyAddViewModel.merchantId = self.merchantId;
    emptyAddViewModel.appId = self.appId;
    emptyAddViewModel.authActionUrl = self.userBankCardResponse.authActionUrl;
    emptyAddViewModel.noPwdBindCardDisplayDesc = self.bankSupportListResponse.noPwdBindCardDisplayDesc;
    NSMutableDictionary *dic = [[self buildTrackDic] mutableCopy];
    [dic cj_setObject:self.bankCardListStr forKey:@"bank_list"];
    [dic cj_setObject:self.quickBindCardListStr forKey:@"onestep_bank_list"];
    emptyAddViewModel.trackDic = dic;
    @CJWeakify(self)
    @CJWeakify(emptyAddViewModel);
    emptyAddViewModel.didClickBlock = ^{
        @CJStrongify(self)
        @CJStrongify(emptyAddViewModel);
        [self p_bindCardWithViewModel:emptyAddViewModel];
    };
    return emptyAddViewModel;
}

- (NSArray<CJPayBaseListViewModel *> *)p_eitherBindCardOrBankActivityViewModelArray {
    return self.isLoadBindCardList ? [self p_bindCardViewModelArray] : [self p_bankActivityViewModelArray];
}

- (NSArray<CJPayBaseListViewModel *> *)p_bindCardViewModelArray
{
    //绑卡列表展现时曝实验
    NSMutableArray *viewModels = [NSMutableArray array];
    if (self.bankSupportListResponse.oneKeyBanks.count == 0) {
        return [viewModels copy];
    }
    CJPayQuickBindCardHeaderViewModel *headerViewModel = [[CJPayQuickBindCardHeaderViewModel alloc] initWithViewController:self];
    headerViewModel.isAdaptTheme = YES;
    headerViewModel.title = self.bankSupportListResponse.title;
    headerViewModel.subTitle = self.bankSupportListResponse.subTitle;
    [viewModels btd_addObject:headerViewModel];
    
    NSArray<CJPayQuickBindCardModel *> *bankList = self.bankSupportListResponse.oneKeyBanks;
    if (!Check_ValidArray(bankList)) {
        bankList = self.bankSupportListResponse.oneKeyBanks;
        headerViewModel.title = self.bankSupportListResponse.title;
        headerViewModel.subTitle = self.bankSupportListResponse.subTitle;
    }
    @CJWeakify(self)
    @CJWeakify(viewModels)
    [bankList enumerateObjectsUsingBlock:^(CJPayQuickBindCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        @CJStrongify(viewModels)
        CJPayQuickBindCardViewModel *bindCardViewModel = [CJPayQuickBindCardViewModel new];
        bindCardViewModel.viewStyle = CJPayBindCardStyleCardCenter;
        bindCardViewModel.bindCardModel = obj;
        bindCardViewModel.isBottomRounded = idx == bankList.count - 1; //最后一个加圆角
        [viewModels btd_addObject:bindCardViewModel];
        @CJWeakify(bindCardViewModel);
        bindCardViewModel.didSelectedBlock = ^(CJPayQuickBindCardModel * _Nonnull bindCardModel) {
            @CJStrongify(self)
            @CJStrongify(bindCardViewModel);
            CJ_DelayEnableView(self.view);
            [[CJPayBankCardListUtil shared] createNormalOrderWithViewModel:bindCardViewModel];
            [self p_trackerWithEventName:@"wallet_bcard_manage_onestepbind_click" params:@{@"bank_name": obj.bankName}];
        };
    }];
    return [viewModels copy];
}

- (NSArray<CJPayBaseListViewModel *> *)p_bankActivityViewModelArray {
    NSMutableArray *viewModels = [NSMutableArray array];
    
    if (self.bankActivityResponse.bankActivityInfoArray.count == 0) {
        return [viewModels copy];
    }
    
    CJPayBankCardActivityHeaderViewModel *headerViewModel = [CJPayBankCardActivityHeaderViewModel new];
    headerViewModel.mainTitle = self.bankActivityResponse.mainTitle;
    headerViewModel.ifShowSubTitle = self.bankActivityResponse.ifShowSubTitle;
    headerViewModel.subTitle = self.bankActivityResponse.subTitle;
    [viewModels addObject:headerViewModel];
    
    NSArray<CJPayBankActivityInfoModel *> *bankActivityInfoArray = self.bankActivityResponse.bankActivityInfoArray;
    for (NSInteger idx = 0; idx < [bankActivityInfoArray count]; idx+=2) {
        CJPayBankCardActivityItemViewModel *itemViewModel = [CJPayBankCardActivityItemViewModel new];
        [viewModels addObject:itemViewModel];
        itemViewModel.activityInfoModelArray = [bankActivityInfoArray cj_subarrayWithRange:NSMakeRange(idx, 2)];
        @CJWeakify(self)
        itemViewModel.buttonClickBlock = ^(CJPayBankActivityInfoModel * _Nonnull model) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.view);
            NSString *urlWithSafetyTestValue = [NSString stringWithFormat:@"%@&storage_keys=cj_initial", model.jumpUrl];
            [self p_lynxBindCardWithUrl:CJString(urlWithSafetyTestValue)];
            [self p_trackerWithEventName:@"wallet_bcard_manage_place_click" params:@{
                @"button_name": @"1",
                @"place_bank_name" : CJString(model.bankCardName)
            }];
        };
        itemViewModel.didSelectedBlock = ^(CJPayBankActivityInfoModel *model) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.view);
            NSMutableDictionary *passExts = [NSMutableDictionary new];
            [passExts cj_setObject:@"cj_initial" forKey:@"storage_keys"];
            NSString *passExtsStr = [[CJPayCommonUtil dictionaryToJson:passExts] cj_URLEncode];
            NSString *urlWithSafetyTestValue = [NSString stringWithFormat:@"%@&pass_exts=%@", model.activityPageUrl, passExtsStr];
            [self p_lynxBindCardWithUrl:CJString(urlWithSafetyTestValue)];
            
            [self p_trackerWithEventName:@"wallet_bcard_manage_place_click" params:@{
                @"button_name": @"0",
                @"place_bank_name" : CJString(model.bankCardName)
            }];
        };
    }
    
    [(CJPayBankCardActivityItemViewModel *)[viewModels lastObject] setIsLastBankActivityRowViewModel:YES];
    
    @CJWeakify(self)
    self.cellWillDisplayBlock = ^(CJPayBaseListCellView *cell, CJPayBaseListViewModel * _Nonnull viewModel) {
        @CJStrongify(self)
        if (![viewModel isKindOfClass:[CJPayBankCardActivityItemViewModel class]]) {
            return;
        }
        CJPayBankCardActivityItemViewModel *itemViewModel = (CJPayBankCardActivityItemViewModel *)viewModel;
        if (!itemViewModel.isBankCardActivityExposed && [cell isDisplayedInScreen]) {
            [itemViewModel.activityInfoModelArray enumerateObjectsUsingBlock:^(CJPayBankActivityInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.isEmptyResource) {
                    return;
                }
                [self p_trackerWithEventName:@"wallet_bcard_manage_place_imp" params:@{
                    @"place_bank_name" : CJString(obj.bankCardName)
                }];
            }];
            itemViewModel.isBankCardActivityExposed = YES;
        }
    };
    
    return [viewModels copy];
}

- (void)p_gotoBankActivityPageWithUrl:(NSString *)url {
    if (!Check_ValidString(url)) {
        return;
    }
    
    NSMutableDictionary *schemeDic = [[CJPayCommonUtil parseScheme:url] mutableCopy];
    
    NSDictionary *urlParamsDic = @{
        @"source" : @"wallet_bcard_manage",
        @"app_id" : CJString(self.appId),
        @"merchant_id" : CJString(self.merchantId),
        @"extra_query" : [@{@"insurance_source" : @"wallet_bcard_manage_page_havecard"} cj_toStr]
    };
    
    NSString *urlWithParams = [CJPayCommonUtil appendParamsToUrl:[schemeDic cj_stringValueForKey:@"url"] params:urlParamsDic];
    [schemeDic cj_setObject:[urlWithParams cj_URLEncode] forKey:@"url"];
    
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:[CJPayCommonUtil generateScheme:schemeDic] params:@{} closeCallBack:^(id  _Nonnull data) {
        if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary *)data;
            NSString *service = [dic cj_stringValueForKey:@"service"];
            if ([service isEqualToString:@"SDKBindNewCard"]) {
                // 绑卡成功进行toast弹窗
                [self p_bindCardSuccessToast];
                [self p_scrollToTop];
            }
        }
    }];
}

- (void)p_lynxBindCardWithUrl:(NSString *)url {
    if (!Check_ValidString(url)) {
        return;
    }
    NSMutableDictionary *param = [NSMutableDictionary new];
    NSMutableDictionary *sdkInfo = [NSMutableDictionary new];
    [sdkInfo cj_setObject:url forKey:@"schema"];
    [param cj_setObject:@(98) forKey:@"service"];
    [param cj_setObject:sdkInfo forKey:@"sdk_info"];
    
    @CJWeakify(self)
    CJPayAPICallBack *apiCallback = [[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse *response) {
        @CJStrongify(self)
        [self p_bindCardCallBackWithData:response.data];
    }];
    
    [CJ_OBJECT_WITH_PROTOCOL(CJPayUniversalPayDeskService) i_openUniversalPayDeskWithParams:param referVC:self withDelegate:apiCallback];
}

- (void)p_bindCardCallBackWithData:(NSDictionary *)callbackData {
    if (![callbackData isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSDictionary *data = [callbackData cj_dictionaryValueForKey:@"data"];
    if (![data isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSDictionary *msg = [data cj_dictionaryValueForKey:@"msg"];
    if (![msg isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSInteger code = [msg cj_integerValueForKey:@"code"];
    NSString *process = [msg cj_stringValueForKey:@"process"];
    if (code == 0 && [process isEqualToString:@"bind_card_open_account"]) {
        [self p_bindCardSuccessToast];
        [self p_scrollToTop];
    }
}

- (void)p_bindCardWithViewModel:(CJPayBaseListViewModel *)viewModel {
    if (self.independentBindCardType == CJPayIndependentBindCardTypeLynx) {
        CJPayJHInformationConfig *jhConfig = [[CJPayBindCardManager sharedInstance] getJHConfig];
        
        NSString *url = [CJPayCommonUtil appendParamsToUrl:self.bindCardUrl params:@{
            @"app_id": CJString(self.appId),
            @"merchant_id": CJString(self.merchantId),
            @"jh_merchant_id": CJString(jhConfig.jhMerchantId),
            @"jh_app_id": CJString(jhConfig.jhAppId),
            @"source": CJString(jhConfig.source),
            @"tea_source": CJString(jhConfig.teaSourceLynx)
        }];
        
        [self p_lynxBindCardWithUrl:url];
        return;
    }
    
    if (self.independentBindCardType == CJPayIndependentBindCardTypeNative) {
        //抖音全量链路
        [[CJPayBankCardListUtil shared] createPromotionOrderWithViewModel:viewModel];
    } else {
        [[CJPayBankCardListUtil shared] createNormalOrderWithViewModel:viewModel];
    }
}

- (NSArray *)p_normalBankCardListViewModelsWithIsAllCardList:(BOOL)isAllBankCardList {
    NSMutableArray *totalCardModels = [NSMutableArray arrayWithArray:self.userBankCardResponse.cardList];
    NSMutableString *mutableStr = [NSMutableString new];
    NSMutableArray *cardListViewModels = [NSMutableArray array];
    
    @CJWeakify(self)
    [totalCardModels enumerateObjectsUsingBlock:^(CJPayBankCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        CJPayBankCardItemViewModel *cardViewModel = [CJPayBankCardItemViewModel new];
        if (obj.needResign) {
            @CJWeakify(obj)
            obj.createNormalOrderAndSendSMSBlock = ^(void) {
                @CJStrongify(self)
                @CJStrongify(obj)
                [self p_trackerWithEventName:@"wallet_bcard_manage_clickdetail_signup"
                                      params:@{@"bank_name": CJString(obj.bankName),
                                               @"bank_type": [self p_getBankType:obj.cardType],
                                               @"page_scenes": obj.isSmallStyle ? @"my_cards" : @"all_cards"
                                             }];
                [[CJPayBindCardManager sharedInstance] createNormalOrderAndSendSMSWithModel:obj
                                                                                      appId:self.appId
                                                                                 merchantId:self.merchantId];
            };
        }
        cardViewModel.cardModel = obj;
        cardViewModel.merhcantId = self.merchantId;
        cardViewModel.appId = self.appId;
        cardViewModel.needShowUnbind = self.userBankCardResponse.needShowUnbind;
        cardViewModel.trackDic = [self buildTrackDic];
        cardViewModel.authInfo = self.userBankCardResponse.userInfo;
        cardViewModel.unbindUrl = self.userBankCardResponse.unbindUrl;
        NSString *fullBankName = [NSString stringWithFormat:@"%@%@", obj.bankName, [self p_getBankType:obj.cardType]];
        [mutableStr appendString:fullBankName];
        if (idx != totalCardModels.count - 1) {
            [mutableStr appendString:@","];
        }
        [cardListViewModels addObject:cardViewModel];
    }];
    
    self.bankCardListStr = mutableStr;
    
    CJPayBankCardAddViewModel *addCardViewModel = [CJPayBankCardAddViewModel new];
    addCardViewModel.noPwdBindCardDisplayDesc = self.bankSupportListResponse.noPwdBindCardDisplayDesc;
    addCardViewModel.userInfo = self.userBankCardResponse.userInfo;
    addCardViewModel.merchantId = self.merchantId;
    addCardViewModel.appId = self.appId;
    addCardViewModel.userId = self.userId;
    NSMutableDictionary *dic = [[self buildTrackDic] mutableCopy];
    [dic cj_setObject:self.bankCardListStr forKey:@"bank_list"];
    [dic cj_setObject:self.quickBindCardListStr forKey:@"onestep_bank_list"];
    [dic cj_setObject:isAllBankCardList ? @"all_cards" : @"my_cards" forKey:@"page_scenes"];
    [dic cj_setObject:@"wallet_bcard_manage" forKey:@"source"];
    
    addCardViewModel.trackDic = dic;
    @CJWeakify(addCardViewModel);
    addCardViewModel.didClickBlock = ^{
        @CJStrongify(self)
        @CJStrongify(addCardViewModel);
        [self p_bindCardWithViewModel:addCardViewModel];
    };
    
    [cardListViewModels addObject:addCardViewModel];
    return [cardListViewModels copy];
}

- (void)p_refresh
{
    NSMutableString *mutableStr = [NSMutableString new];
    [self.bankSupportListResponse.oneKeyBanks enumerateObjectsUsingBlock:^(CJPayQuickBindCardModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableStr appendString:CJString(obj.bankName)];
        if (idx != self.bankSupportListResponse.oneKeyBanks.count - 1) {
            [mutableStr appendString:@","];
        }
    }];
    self.quickBindCardListStr = mutableStr;
    
    BOOL hasNormalCards = self.userBankCardResponse.cardList && self.userBankCardResponse.cardList.count > 0;
    if (hasNormalCards) {
        // 有卡
        [self p_refreshWithCards];
    } else {
        // 无卡
        [self p_refreshWithEmptyCard];
    }
}

- (void)p_refreshWithCards {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    // 已绑定卡
    CJPayMyBankCardListViewModel *myBankCardListViewModel = [self p_myBankCardListViewModel];
    [mutableArray addObject:myBankCardListViewModel];
    
    if (self.needShowUnionPay) {
        [mutableArray btd_addObject:self.syncUnionViewModel];
    }
    
    // 绑卡 或者 绑卡营销位
    [mutableArray addObjectsFromArray:[self p_eitherBindCardOrBankActivityViewModelArray]];
    // 插入QAcell
    [mutableArray addObject:[self p_getQAViewModelHeightWith:mutableArray]];
    
    NSMutableArray *totalCardModels = [NSMutableArray arrayWithArray:self.userBankCardResponse.cardList];
    dic[@(0)] = [mutableArray copy];
    if ([self isCardsInfoChanged:self.cardModels newCards:totalCardModels] || self.isLoadBindCardList || [self p_isShowUnionPayStatusChanged]) {
        self.cardModels = totalCardModels;
        [self.dataSource.sectionsDataDic removeAllObjects];
        [self.dataSource.sectionsDataDic addEntriesFromDictionary:dic];
        [self reloadTableViewData];
    }
    if (!self.userBankCardResponse.isFromCache && !self.isWalletBcardManageImpTracked) {
        self.isWalletBcardManageImpTracked = YES;
        [self p_trackerWithEventName:@"wallet_bcard_manage_imp"
                              params:@{@"card_number" : @(totalCardModels.count),
                                       @"card_status" : totalCardModels.count > 0 ? @"1" : @"0",
                                       @"bank_list" : CJString(self.bankCardListStr),
                                       @"onestep_bank_list" : CJString(self.quickBindCardListStr),
                                       @"ysf_guide_show" : self.needShowUnionPay ? @"1" : @"0"
                              }];
    }
    NSDictionary *params = [@{
        @"insurance_title" : @"保障中",
        @"page_name" : @"wallet_bcard_manage_page_havecard"
    } mutableCopy];
    [self p_trackerWithEventName:@"wallet_addbcard_insurance_title_imp"
                          params:params];
}

- (BOOL)p_isShowUnionPayStatusChanged {
    if (self.needShowUnionPay != self.lastShowUnionPayStatus) {
        self.lastShowUnionPayStatus = self.needShowUnionPay;
        return YES;
    }
    return NO;
}

- (void)p_refreshWithEmptyCard {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    // 无卡
    self.cardModels = [NSArray new];
    // 添加头部提示语
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    if(showInsuranceEntrance){
        [mutableArray addObject:[self p_bankCardEmptyAddSafeBannerViewModel]];
        
        NSDictionary *params = [@{
            @"insurance_title" : @"添加银行卡，享百万资金安全保障",
            @"page_name" : @"wallet_bcard_manage_page_nocard"
        } mutableCopy];
        [self p_trackerWithEventName:@"wallet_addbcard_insurance_title_imp"
                              params:params];
    }
    // 添加卡
    [mutableArray addObject:[self p_bankCardEmptyAddViewModel]];
    
    if (self.needShowUnionPay) {
        [mutableArray btd_addObject:self.syncUnionViewModel];
    }
    
    [mutableArray addObjectsFromArray:[self p_eitherBindCardOrBankActivityViewModelArray]];
    // 提示语
    if (!self.userBankCardResponse.isAuthed && ![self.bankActivityResponse isSuccess]) {
        CJPayBankCardNoCardTipViewModel *emptyTipViewModel = [CJPayBankCardNoCardTipViewModel new];
        [mutableArray addObject:emptyTipViewModel];
    }
    // 插入QAcell
    [mutableArray addObject:[self p_getQAViewModelHeightWith:mutableArray]];
    
    dic[@(0)] = [mutableArray copy];
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:dic];
    [self reloadTableViewData];
    if (!self.userBankCardResponse.isFromCache && !self.isWalletBcardManageImpTracked) {
        self.isWalletBcardManageImpTracked = YES;
        [self p_trackerWithEventName:@"wallet_bcard_manage_imp"
                              params:@{@"card_number" : @(0),
                                       @"card_status" : @"0",
                                       @"bank_list" : @"",
                                       @"onestep_bank_list" : CJString(self.quickBindCardListStr),
                                       @"ysf_guide_show" : self.needShowUnionPay ? @"1" : @"0"
                              }];
    }
}

- (void)refreshBankCardList
{
    if (![self hasValidData]) {
        [self hideNoNetworkView];
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self];
    }
    if (self.isFromCancelBind) {
        self.isFromCancelBind = NO;
    }
    self.view.userInteractionEnabled = NO;
    @CJWeakify(self)
    CJPayQueryUserBankCardRequestModel *queryUserBankCardRequestModel = [CJPayQueryUserBankCardRequestModel new];
    queryUserBankCardRequestModel.isNeedQueryBankCardList = YES;
    queryUserBankCardRequestModel.isNeedQueryAuthInfo = YES;
    queryUserBankCardRequestModel.isNeedBindCardTopPageUrl = self.independentBindCardType == CJPayIndependentBindCardTypeLynx;
    queryUserBankCardRequestModel.source = @"wallet_bcard_manage";
    CJPayPassKitBizRequestModel *passKitBizRequestModel = [CJPayPassKitBizRequestModel new];
    passKitBizRequestModel.appID = self.appId;
    passKitBizRequestModel.merchantID = self.merchantId;
    passKitBizRequestModel.uid = self.userId;
    passKitBizRequestModel.sessionKey = self.userId;
    [CJPayQueryUserBankCardRequest startWithModel:queryUserBankCardRequestModel
                              bizRequestModel:passKitBizRequestModel
                                   completion:^(NSError * _Nullable error, BDPayQueryUserBankCardResponse * _Nonnull response) {
        @CJStrongify(self)
        if (!self) {
            return;
        }
        if ([response.code hasPrefix:@"GW4009"]) {
            [[CJPayBindCardManager sharedInstance] gotoThrottleViewController:YES
                                                                       source:@"查询卡列表"
                                                                        appId:self.appId
                                                                   merchantId:self.merchantId];
            return;
        }
        self.userBankCardResponse = response;
        [self hideNoNetworkView];
        [[CJPayLoadingManager defaultService] stopLoading];
        self.view.userInteractionEnabled = YES;
        if (![response isSuccess] && [response.code isEqualToString:@"CD0001"]) {
            [CJPayAlertUtil singleAlertWithTitle:CJPayLocalizedStr(@"当前未登录，请登录后重试") content:@"" buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:^{
                @CJStrongify(self)
                [self back];
            } useVC:self];
            return;
        }
        if ([response isSuccess]) {
            if (!self) {
                return;
            }
            self.bindCardUrl = response.bindTopPageUrl;
            
            if (self.isFirstAppear) {
                [self p_queryInGroup];
            } else {
                [self p_queryUnionPaySignStatus:^{
                    @CJStrongify(self)
                    [self p_refresh];
                }];
            }
        } else {
            if (![self hasValidData]) {
                [self showNoNetworkViewUseThemeStyle:YES];
            }
        }
    }];
}

- (void)p_queryInGroup {
    @CJWeakify(self)
    
    dispatch_group_t group = dispatch_group_create();
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self];

    [self p_queryBankActivityWithGroup:group];
    [self p_querySupportListBankWithGroup:group];
    [self p_queryUnionPaySignStatusWithGroup:group];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [CJPayPerformanceMonitor trackPageFinishRenderWithVC:self name:@"" extra: @{}];
        [[CJPayLoadingManager defaultService] stopLoading];
        [self p_refresh];
    });
}

- (void)p_queryUnionPaySignStatus:(void(^)(void))completion {
    self.needShowUnionPay = NO;
    [CJPayBankCardListUtil shared].isSyncUnionCard = NO;
    @CJWeakify(self)
    NSDictionary *params = @{@"app_id" : self.appId,
                             @"merchant_id" : self.merchantId,
                             @"need_query_show_union_pay" : @(self.syncUnionPayABTest)};

    [CJPayQueryUnionPaySignStatusRequest startRequestWithParams:params
                                                     completion:^(NSError * _Nullable error, CJPayQueryUnionPaySignStatusResponse * _Nonnull signResponse) {
        @CJStrongify(self)
        if ([signResponse isSuccess] && signResponse.needShowUnionPay) {
            self.needShowUnionPay = YES;
            [CJPayBankCardListUtil shared].isSyncUnionCard = YES;
            self.syncUnionViewModel.bindCardDouyinIconUrl = signResponse.bindCardDouyinIconUrl;
            self.syncUnionViewModel.bindCardUnionIconUrl = signResponse.bindCardUnionIconUrl;
        }
        
        CJ_CALL_BLOCK(completion);
    }];
}

- (void)p_queryUnionPaySignStatusWithGroup:(dispatch_group_t)group {
    @CJWeakify(self)
    dispatch_group_enter(group);
    [self p_queryUnionPaySignStatus:^{
        @CJStrongify(self)
        dispatch_group_leave(group);
    }];
}

- (void)p_queryBankActivityWithGroup:(dispatch_group_t)group {
    @CJWeakify(self)
    dispatch_group_enter(group);
    
    [CJPayMemBankActivityRequest startWithBizParams:[self p_buildMemBankActivityBizParams] completion:^(NSError * _Nonnull error, CJPayMemBankActivityResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([response isSuccess]) {
            self.bankActivityResponse = response;
        }
        self.isLoadBindCardList = ([response.bankActivityInfoArray count] == 0);
        dispatch_group_leave(group);
    }];
}

- (void)p_querySupportListBankWithGroup:(dispatch_group_t)group {
    @CJWeakify(self)
    dispatch_group_enter(group);
    [CJPayMemBankSupportListRequest startWithAppId:self.appId
                                        merchantId:self.merchantId
                                 specialMerchantId:self.merchantId
                                       signOrderNo:@""
                                        completion:^(NSError * _Nullable error, CJPayMemBankSupportListResponse * _Nonnull response) {
        @CJStrongify(self)
        if ([response isSuccess]) {
            self.bankSupportListResponse = response;
            self.displayIcon = response.bindCardTitleModel.displayIcon;
            self.displayDesc = response.bindCardTitleModel.displayDesc;
            [CJPayBankCardListUtil shared].displayIcon = response.bindCardTitleModel.displayIcon;
            [CJPayBankCardListUtil shared].displayDesc = response.bindCardTitleModel.displayDesc;
        } else {
            [CJToast toastText:CJString(response.msg) ?: CJPayNoNetworkMessage inWindow:self.cj_window];
        }
        dispatch_group_leave(group);
    }];
}

- (NSDictionary *)p_buildMemBankActivityBizParams {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:CJString(self.appId) forKey:@"app_id"];
    [bizParams cj_setObject:CJString(self.merchantId) forKey:@"merchant_id"];
    [bizParams cj_setObject:CJString([CJPayRequestParam gAppInfoConfig].appId) forKey:@"aid"];
    [bizParams cj_setObject:self.userId forKey:@"uid"];
    NSString *did = @"";
    if ([CJPayRequestParam gAppInfoConfig].deviceIDBlock) {
        did = [CJPayRequestParam gAppInfoConfig].deviceIDBlock();
    }
    [bizParams cj_setObject:did forKey:@"did"];
    [bizParams cj_setObject:[CJPayRequestParam appVersion] forKey:@"app_version"];
    [bizParams cj_setObject:@"PP202101041000251153438201" forKey:@"title_place_no"];
    [bizParams cj_setObject:@"PP202204181000251153438205" forKey:@"bankcard_place_no"];
    return [bizParams copy];
}

// 比较卡列表的数据有没有发生变化
- (BOOL)isCardsInfoChanged:(NSArray *)oldCards
                  newCards:(NSArray *)newCards {
    if (!oldCards || !newCards) {
        return YES;
    }

    if (oldCards.count != newCards.count) {
        return YES;
    }

    for (int i = 0; i < oldCards.count; i++) {
        NSString *oldCardInfoStr = [[oldCards objectAtIndex:i] toJSONString];
        NSString *newCardInfoStr = [[newCards objectAtIndex:i] toJSONString];
        BOOL isTwoCardsSame = oldCardInfoStr && newCardInfoStr && [oldCardInfoStr isEqualToString:newCardInfoStr];
        if (!isTwoCardsSame) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)p_getBankType:(NSString *)cardType {
    if ([cardType isEqualToString:@"DEBIT"]) {
        return @"储蓄卡";
    } else if ([cardType isEqualToString:@"CREDIT"]){
        return @"信用卡";
    }
    return @"";
}

- (BOOL)hasValidData {
    return self.dataSource.sectionsDataDic.count > 0;
}

- (NSDictionary *)buildTrackDic {
    NSDictionary *dic = @{@"is_chaselight": @"1",
                          @"needidentity": self.userBankCardResponse.isAuthed ? @"0" : @"1",
                          @"haspass": self.userBankCardResponse.isSetPWD ? @"1" : @"0",
                          @"show_onestep": self.isLoadBindCardList ? @"1" : @"0"};
    return dic;
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSMutableDictionary *baseParams = [@{
        @"app_id": CJString(self.appId),
        @"merchant_id": CJString(self.merchantId),
        @"is_chaselight": @"1",
        @"needidentity": self.userBankCardResponse.isAuthed ? @"0" : @"1",
        @"haspass": self.userBankCardResponse.isSetPWD ? @"1" : @"0",
        @"show_onestep": self.isLoadBindCardList ? @"1" : @"0",
        @"source" : @"wallet_bcard_manage",
    } mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (CJPayBankCardFooterViewModel *)p_getQAViewModelHeightWith:(NSArray<CJPayBaseListViewModel *> *)dataSource {
    CJPayBankCardFooterViewModel *qaViewModel = [CJPayBankCardFooterViewModel new];
    qaViewModel.merchantId = self.merchantId;
    qaViewModel.appId = self.appId;
    qaViewModel.showQAView = YES;
    
    __block CGFloat listContentHeight = 0;
    [dataSource enumerateObjectsUsingBlock:^(CJPayBaseListViewModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        listContentHeight += [model getViewHeight];
    }];
    
    CGFloat maxListContentHeight = self.tableView.cj_height - CJ_TabBarSafeBottomMargin - 8;
    CGFloat qaMinHeight = 54;
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        qaMinHeight = qaMinHeight + 32;
        qaViewModel.showGurdTipView = YES;
    }
    if (maxListContentHeight - listContentHeight > qaMinHeight) {
        self.tableView.bounces = NO;
        qaMinHeight = maxListContentHeight - listContentHeight;
    } else {
        self.tableView.bounces = YES;
    }
    qaViewModel.cellHeight = qaMinHeight;
    qaViewModel.bottomMarginHeight = CJ_TabBarSafeBottomMargin;
    qaViewModel.bottomMarginColor = UIColor.clearColor;
    return qaViewModel;
}

- (CJPaySyncUnionViewModel *)syncUnionViewModel {
    if (!_syncUnionViewModel) {
        _syncUnionViewModel = [CJPaySyncUnionViewModel new];
        @CJWeakify(self)
        self.syncUnionViewModel.didClickBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_bcard_manage_ysf_guide_click" params:@{}];
            if(!CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
                CJPayLogAssert(NO, @"没有接入云闪付绑卡");
                return;
            }
            NSDictionary *params = @{@"app_id":CJString(self.appId),
                                     @"merchant_id":CJString(self.merchantId)};
            [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) createPromotionOrder:params];
        };
    }
    return _syncUnionViewModel;
}

- (CJPayAllBankCardListViewController *)allBankListVC {
    if (!_allBankListVC) {
        _allBankListVC = [CJPayAllBankCardListViewController new];
    }
    return _allBankListVC;
}

@end
