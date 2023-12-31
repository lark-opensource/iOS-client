//
//  CJPayBankCardDetailViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardDetailViewController.h"
#import "CJPayBankCardItemViewModel.h"
#import "CJPayCardDetailFreezeTipViewModel.h"
#import "CJPayCardDetailLimitViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayAlertSheetView.h"
#import "CJPayBizWebViewController.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPaySDKDefine.h"
#import "CJPayAlertSheetAction.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBizWebViewController+Biz.h"
#import "CJPayQueryUserBankCardRequest.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayAllBankCardListViewController.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayPopoverMenuSheet.h"
#import "UIButton+CJPay.h"
#import "CJPayBankCardHeaderSafeBannerViewModel.h"
#import "CJPayBankCardHeaderSafeBannerCellView.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayNavigationBarView.h"
#import "CJPayWebviewStyle.h"

@interface CJPayBankCardDetailViewController ()

@property (nonatomic, strong) CJPayAlertSheetView *menu;
@property (nonatomic, strong) CJPayPopoverMenuSheet *popoverMenu;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic,   copy) NSString *statusStr;
@property (nonatomic, assign) BOOL allowPopGesture;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, strong) UIView *qaAndUnBindContainverView;
@property (nonatomic, strong) CJPayButton *qaButton;
@property (nonatomic, strong) CJPayButton *unBindButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayBankCardHeaderSafeBannerCellView *safeBannerView;

@property (nonatomic, strong) CJPayBankCardModel *cardModel;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *smchId;
@property (nonatomic, assign) BOOL needShowUnbind;
@property (nonatomic, strong) CJPayMemAuthInfo *authInfo;
@property (nonatomic, copy) NSString *unbindUrl;

@end

@implementation CJPayBankCardDetailViewController

- (instancetype)initWithCardItemModel:(CJPayBankCardItemViewModel *)cardItemModel {
    self = [super init];
    if (self) {
        self.cardModel = cardItemModel.cardModel;
        self.merchantId = cardItemModel.merhcantId;
        self.appId = cardItemModel.appId;
        self.smchId = cardItemModel.smchId;
        self.needShowUnbind = cardItemModel.needShowUnbind;
        self.authInfo = cardItemModel.authInfo;
        self.unbindUrl = cardItemModel.unbindUrl;
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.view).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.width.equalTo(self.view);
            make.height.mas_equalTo(18);
        });
    }

    [self setupNavBar];

    self.allowPopGesture = YES;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    self.tableView.contentInset = UIEdgeInsetsMake((showInsuranceEntrance ? 12 : 0), 0, CJ_TabBarSafeBottomMargin, 0);
    CJPayBankCardItemViewModel *cardViewModel = [CJPayBankCardItemViewModel new];
    cardViewModel.cardModel = self.cardModel;
    cardViewModel.canJumpCardDetail = NO;
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:cardViewModel];
    if (![self.cardModel.status isEqualToString:@"available"]) {
        CJPayCardDetailFreezeTipViewModel *tipViewModel = [[CJPayCardDetailFreezeTipViewModel alloc] initWithViewController:self];
        tipViewModel.freezeReason = @"因风险控制原因，该卡暂不可用。你可以";
        [array addObject:tipViewModel];
    } else {
        if ((Check_ValidString(self.cardModel.perdayLimit) && ![self.cardModel.perdayLimit isEqualToString:@"-1"]) || (Check_ValidString(self.cardModel.perpayLimit) && ![self.cardModel.perpayLimit isEqualToString:@"-1"])) {
            CJPayCardDetailLimitViewModel *limitViewModel = [CJPayCardDetailLimitViewModel new];
            limitViewModel.perDayLimitStr = self.cardModel.perdayLimit;
            limitViewModel.perPayLimitStr = self.cardModel.perpayLimit;
            [array addObject:limitViewModel];
        }
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    dic[@(0)] = array;
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:dic];
    [self reloadTableViewData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_popBankCardDetailView) name:CJPayBizPreCloseCallbackNoti object:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (CJ_Pad && _popoverMenu && self.view.cj_width == [UIApplication btd_mainWindow].cj_width) {
        [self.popoverMenu dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (_popoverMenu) {
        [self.popoverMenu dismissViewControllerAnimated:NO completion:nil];
    }
    if (_menu) {
        [self.menu dismissWithCompletionBlock:nil];
    }
}

- (BOOL)cjAllowTransition {
    return self.allowPopGesture;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *bankCardName = [NSString stringWithFormat:@"%@", self.cardModel.bankName];
    [self p_trackerWithEventName:@"wallet_bcard_manage_detail_imp" params:@{@"bank_name" : CJString(bankCardName),
                                                                            @"bank_type" : [self p_getBankType]}];
}

#pragma mark - Getter

- (CJPayAlertSheetView *)menu {
    if (!_menu) {
        @CJWeakify(self)
        _menu = [[CJPayAlertSheetView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) isAlwaysShow:NO];
        [_menu addAction:[CJPayAlertSheetAction actionWithRegularTitle:CJPayLocalizedStr(@"取消") handler:nil]];
        [_menu addAction:[CJPayAlertSheetAction actionWithRegularTitle:CJPayLocalizedStr(@"解绑银行卡") handler:^(CJPayAlertSheetAction *action) {
            @CJStrongify(self)
            [self cancel];
            self.allowPopGesture = YES;
        }]];
        [_menu addAction:[CJPayAlertSheetAction actionWithRegularTitle:CJPayLocalizedStr(@"常见问题") handler:^(CJPayAlertSheetAction *action) {
            @CJStrongify(self)
            [self goToHelpVC];
            self.allowPopGesture = YES;
        }]];
        _menu.cancelBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_bcard_manage_detail_cannel" params:@{}];
            self.allowPopGesture = YES;
        };
    }
    return _menu;
}

- (CJPayPopoverMenuSheet *)popoverMenu {
    if (!_popoverMenu) {
        _popoverMenu = [[CJPayPopoverMenuSheet alloc] init];
        @CJWeakify(self)
        CJPayPopoverMenuModel *qaModel = [CJPayPopoverMenuModel actionWithTitle:CJPayLocalizedStr(@"常见问题") titleTextAlignment:NSTextAlignmentCenter block:^(CJPayPopoverMenuSheet * _Nonnull tableVc, NSInteger buttonIndex) {
            @CJStrongify(self)
            [self goToHelpVC];
        }];
        CJPayPopoverMenuModel *menuModel = [CJPayPopoverMenuModel actionWithTitle:CJPayLocalizedStr(@"解绑银行卡") titleTextAlignment:NSTextAlignmentCenter block:^(CJPayPopoverMenuSheet * _Nonnull tableVc, NSInteger buttonIndex) {
            @CJStrongify(self)
            [self cancel];
        }];
        [_popoverMenu addButtonWithModel:qaModel];
        [_popoverMenu addButtonWithModel:menuModel];
        [_popoverMenu setTitleFont:[UIFont cj_fontOfSize:14]];
        [_popoverMenu setCornerRadius:12];
        [_popoverMenu setCellHeight:50];
        [_popoverMenu setWidth:102];
    }
    return _popoverMenu;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [[UIButton alloc] init];
        [_moreButton cj_setImageName:self.cjLocalTheme.navigationBarMoreImageName forState:UIControlStateNormal];
    }
    return _moreButton;
}

- (UIView *)qaAndUnBindContainverView {
    if (!_qaAndUnBindContainverView) {
        _qaAndUnBindContainverView = [UIView new];
    }
    return _qaAndUnBindContainverView;
}

- (CJPayButton *)qaButton {
    if (!_qaButton) {
        _qaButton = [[CJPayButton alloc] init];
        [_qaButton setTitleColor:self.cjLocalTheme.faqTextColor forState:UIControlStateNormal];
        _qaButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        _qaButton.cjEventInterval = 1;
        [_qaButton setTitle:CJPayLocalizedStr(@"常见问题") forState:UIControlStateNormal];
        [_qaButton addTarget:self action:@selector(goToHelpVC) forControlEvents:UIControlEventTouchUpInside];
    }
    return _qaButton;
}

- (UIView *)sepLine {
    if (!_sepLine) {
        _sepLine = [[UIView alloc] init];
        _sepLine.backgroundColor = self.cjLocalTheme.separatorColor;
    }
    return _sepLine;
}

- (CJPayButton *)unBindButton {
    if (!_unBindButton) {
        _unBindButton = [[CJPayButton alloc] init];
        [_unBindButton setTitleColor:self.cjLocalTheme.faqTextColor forState:UIControlStateNormal];
        _unBindButton.titleLabel.font = [UIFont cj_fontOfSize:13];
        _unBindButton.cjEventInterval = 1;
        [_unBindButton setTitle:CJPayLocalizedStr(@"解绑银行卡") forState:UIControlStateNormal];
        [_unBindButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _unBindButton;
}

- (CJPayBankCardHeaderSafeBannerCellView *)safeBannerView {
    if(!_safeBannerView) {
        _safeBannerView = [CJPayBankCardHeaderSafeBannerCellView new];
        _safeBannerView.viewModel.viewHeight = 32;
        [_safeBannerView updateSafeString:@"抖音支付全程保障资金与信息安全"];
        _safeBannerView.backgroundColor = self.cjLocalTheme.safeBannerBGColor;
        _safeBannerView.safeBannerViewModel.passParams = @{
            @"app_id": CJString(self.appId),
            @"merchant_id": CJString(self.merchantId),
            @"is_chaselight": @"1",
            @"needidentity": @"0",
            @"haspass": @"1",
            @"show_onestep": @"1",
            @"source" : @"wallet_bcard_manage",
            @"insurance_title" : @"抖音支付全程保障资金与信息安全",
            @"page_name" : @"wallet_bcard_manage_detail_page",
            @"extra_query" : [@{@"insurance_source" : @"wallet_bcard_manage_detail_page"} cj_toStr]
        };
    }
    return _safeBannerView;
}

#pragma mark - Private Method
- (void)setupNavBar {
    [self.navigationBar setTitle:CJPayLocalizedStr(@"我的银行卡")];
    if (self.needShowUnbind) {
        [self p_setupUI];
    } else {
        [self.navigationBar addSubview:self.moreButton];
        CJPayMasMaker(self.moreButton, {
            make.right.equalTo(self.navigationBar).offset(-16);
            make.centerY.equalTo(self.navigationBar.titleLabel);
            make.width.height.mas_equalTo(24);
        });
        [self.moreButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    }
    
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    if(showInsuranceEntrance){
        [self.view addSubview:self.safeBannerView];
        CJPayMasMaker(self.safeBannerView, {
            make.width.equalTo(self.view);
            make.top.equalTo(self.view).offset([self navigationHeight]);
        });
        CJPayMasReMaker(self.tableView, {
            make.centerX.width.bottom.equalTo(self.view);
            make.top.equalTo(self.view).offset([self navigationHeight]+[self.safeBannerView.viewModel getViewHeight]);
        });
    }
}

- (void)p_setupUI {
    [self.view addSubview:self.qaAndUnBindContainverView];
    [self.qaAndUnBindContainverView addSubview:self.qaButton];
    [self.qaAndUnBindContainverView addSubview:self.unBindButton];
    [self.qaAndUnBindContainverView addSubview:self.sepLine];
    CJPayMasMaker(self.qaButton, {
        make.top.bottom.left.equalTo(0);
    });
    CJPayMasMaker(self.sepLine, {
        make.left.equalTo(self.qaButton.mas_right).offset(16);
        make.height.mas_equalTo(14);
        make.width.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    CJPayMasMaker(self.unBindButton, {
        make.left.equalTo(self.sepLine.mas_right).offset(16);
        make.top.bottom.right.equalTo(0);
    });
    CJPayMasMaker(self.qaAndUnBindContainverView, {
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(14);
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-14);
        } else {
            make.bottom.equalTo(self.view).mas_offset(- 30 - CJ_TabBarSafeBottomMargin);
        }
    });
}

- (void)showMenu {
    if (CJ_Pad && self.view.cj_width != [UIApplication btd_mainWindow].cj_width) {
        [self presentViewController:self.popoverMenu animated:YES completion:nil];
        [self.popoverMenu showFromView:self.moreButton
                                atRect:self.moreButton.bounds
                        arrowDirection:UIPopoverArrowDirectionUp];
        
    } else {
        [self.menu showOnView:self.view];
        self.allowPopGesture = NO;
    }
    [self p_trackerWithEventName:@"wallet_bcard_manage_detail_more" params:@{}];
}

- (void)cancel {
    // 旧版本url兜底
    NSString *urlString = @"http://cashier.ulpay.com/usercenter/cards/unbind/cardBackBlock?merchant_id=%s&app_id=%s&service=unbind&bank_card_id=%s&source=%s&need_private_header=0";
    NSMutableString *cancelBindCardBaseURL = [NSMutableString stringWithString:urlString];
    NSMutableDictionary *queryParam = [self p_buildUnbindCardParams];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self
                                                  useNewNavi:YES
                                                       toUrl:cancelBindCardBaseURL
                                                      params:queryParam
                                           nativeStyleParams:@{}
                                               closeCallBack:^(id _Nonnull data) {
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary *)data;
            NSString *service = [dic cj_stringValueForKey:@"service"];
            NSUInteger code = [dic cj_intValueForKey:@"code" defaultValue: -1];
            if ([service isEqualToString:@"unbind"] && code == 0) {
                NSString *callBackStr = [dic cj_stringValueForKey:@"data"];
                NSUInteger showToast = 1;
                NSString *toastMsg = CJPayLocalizedStr(@"解绑成功");
                if (callBackStr) {
                    NSDictionary *callBackData = [CJPayCommonUtil jsonStringToDictionary:callBackStr];
                    if (callBackData && [callBackData isKindOfClass:NSDictionary.class]) {
                        showToast = [callBackData cj_intValueForKey:@"showToast"];
                        toastMsg = [callBackData cj_stringValueForKey:@"toastMsg"];
                    }
                }
                if (showToast == 1 && Check_ValidString(toastMsg)) {
                    [CJToast toastText:toastMsg duration:0.5 inWindow:self.cj_window];
                }
            }
        }
    }];
    [self p_trackerWithEventName:@"wallet_bcard_manage_detail_unbind" params:@{@"bank_type" : CJString([self p_getBankType]),
                                                                               @"bank_name" : CJString(self.cardModel.bankName)}];
}

- (NSMutableDictionary *)p_buildUnbindCardParams{
    NSMutableDictionary *queryParam = [NSMutableDictionary dictionary];
    [queryParam cj_setObject:self.merchantId forKey:@"merchant_id"];
    [queryParam cj_setObject:self.appId forKey:@"app_id"];
    [queryParam cj_setObject:self.smchId forKey:@"smch_id"];
    [queryParam cj_setObject:self.cardModel.bankCardId forKey:@"bank_card_id"];
    [queryParam cj_setObject:@"sdk" forKey:@"source"];
    [queryParam cj_setObject:@"unbind" forKey:@"service"];
    [queryParam cj_setObject:@"0" forKey:@"need_private_header"];
    return [queryParam copy];
}

- (void)goToHelpVC {//常见问题按钮
    NSString *urlString = [NSString stringWithFormat:@"%@/usercenter/member/faq", [CJPayBaseRequest bdpayH5DeskServerHostString]];
    NSMutableString *qaBaseURL = [NSMutableString stringWithString:urlString];
    NSMutableDictionary *queryParam = [NSMutableDictionary dictionary];
    queryParam[@"merchant_id"] = self.merchantId;
    queryParam[@"app_id"] = self.appId;
    NSString *finalURL = [CJPayCommonUtil appendParamsToUrl:qaBaseURL params:queryParam];
    
    CJPayBizWebViewController *webvc = [[CJPayBizWebViewController alloc] initWithUrlString:finalURL];
    webvc.webviewStyle.titleText = CJPayLocalizedStr(@"常见问题");
    if (self.navigationController) {
        [self.navigationController pushViewController:webvc animated:YES];
    } else {
        [self presentViewController:webvc animated:YES completion:nil];
    }

    [self p_trackerWithEventName:@"wallet_bcard_manage_detail_comproblem" params:@{@"from" : @"详情页",
                                                                                   @"bank_name" : CJString(self.cardModel.bankName),
                                                                                   @"bank_type" :
                                                                                       CJString([self p_getBankType])}];
}

- (NSString *)p_getBankType {
    if ([self.cardModel.cardType isEqualToString:@"DEBIT"]) {
        return @"储蓄卡";
    } else if ([self.cardModel.cardType isEqualToString:@"CREDIT"]){
        return @"信用卡";
    }
    return @"";
}

- (void)handleWithEventName:(NSString *)eventName data:(id)data {
    if ([eventName isEqualToString:CJPayBankCardDetailCancelBindEvent]) {
        [self cancel];
    }
}

- (NSString *)statusStr {
    NSString *cardStatus = @"1";
    if (![self.cardModel.status isEqualToString:@"available"]) {
        cardStatus = @"0";
    }
    return cardStatus;
}

- (void)p_popBankCardDetailView {
    
    NSMutableArray *curVCs = [NSMutableArray array];
    
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[CJPayAllBankCardListViewController class]] && obj != self) { //把全部银行卡列表页和卡详情页删除
            [curVCs addObject:obj];
        }
    }];
    
    self.navigationController.viewControllers = [curVCs copy];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSMutableDictionary *baseParams = [@{
        @"app_id": CJString(self.appId),
        @"merchant_id": CJString(self.merchantId),
        @"is_chaselight": @"1",
        @"needidentity": @"0",
        @"haspass": @"1",
        @"show_onestep": @"1",
        @"smch_id" : CJString(self.smchId),
        @"card_status" : CJString(self.statusStr)
    } mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}


@end
