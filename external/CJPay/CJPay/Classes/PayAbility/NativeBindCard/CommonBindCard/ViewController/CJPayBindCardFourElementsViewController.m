//
//  CJPayBindCardFourElementsViewController.m
//  CJPay
//
//  Created by 徐天喜 on 2022/08/05
//

#import "CJPayBindCardFourElementsViewController.h"
#import "CJPayBindCardChooseView.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayBindCardChooseIDTypeViewController.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayCustomTextField.h"
#import "CJPayBindCardValidateManager.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayStyleButton.h"
#import "CJPayTracker.h"
#import "CJPayAlertUtil.h"
#import "CJPayPassPortAlertView.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPaySafeUtil.h"
#import "CJPayNormalIDTextFieldConfigration.h"
#import "CJPayHKIDTextFieldConfigration.h"
#import "CJPayTWIDTextFieldConfigration.h"
#import "CJPayPDIDTextFieldConfigration.h"
#import "CJPayHKRPTextFieldConfigration.h"
#import "CJPayTWRPTextFieldConfigration.h"
#import "CJPayWebViewUtil.h"
#import "CJPayMemCardBinResponse.h"
#import "CJPayBindCardScrollView.h"
#import "CJPayBindCardAuthPhoneTipsView.h"
#import "CJPayAuthPhoneRequest.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAccountInsuranceTipView.h"
#import <TTReachability/TTReachability.h>
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardTopHeaderView.h"
#import "CJPayBindCardManager.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayIDCardProfileOCRViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPayBindCardRetainInfo.h"

@implementation CJPayBindCardFourElementsModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"bizAuthInfoModel" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"bankMobileNoMask" : CJPayBindCardShareDataKeyBankMobileNoMask,
        @"firstStepVCTimestamp" : CJPayBindCardShareDataKeyFirstStepVCTimestamp,
        @"cardInfoModel" : CJPayBindCardPageParamsKeyInfoModel,
        @"memCardBinResponse" : CJPayBindCardPageParamsKeyMemCardBinResponse,
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle,
        @"displayIcon" : CJPayBindCardShareDataKeyDisplayIcon,
        @"displayDesc" : CJPayBindCardShareDataKeyDisplayDesc,
        @"isFromCardOCR" : CJPayBindCardPageParamsKeyIsFromCardOCR,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"cachedInfoModel" : CJPayBindCardShareDataKeyCachedIdentityInfoModel,
        @"retainInfo" : CJPayBindCardShareDataKeyRetainInfo
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBindCardFourElementsViewController () <CJPayCustomTextFieldContainerDelegate, CJPayBindCardChooseIDTypeDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, CJPayTrackerProtocol, CJPayBindCardPageProtocol>

#pragma mark - View
@property (nonatomic, strong) CJPayBindCardScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayBindCardTopHeaderView *headerView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *centerContentView;
@property (nonatomic, strong) CJPayBindCardChooseView *bankCardView;
@property (nonatomic, strong) CJPayBindCardChooseView *identityView;
@property (nonatomic, strong) CJPayBindCardChooseView *nationalityView;
@property (nonatomic, strong) CJPayCustomTextFieldContainer *nameContainer;
@property (nonatomic, strong) CJPayCustomTextFieldContainer *identityContainer;
@property (nonatomic, strong) CJPayButton *ocrButton;
@property (nonatomic, strong) CJPayCustomTextFieldContainer *phoneContainer;
@property (nonatomic, strong) CJPayBindCardAuthPhoneTipsView *authPhoneTipsView;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) UILabel *scrollServiceLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) UIView *containerMaskView;

#pragma mark - model
@property (nonatomic, strong) CJPayBindCardFourElementsModel *viewModel;
@property (nonatomic, strong) CJPaySendSMSResponse *latestSMSResponse;

#pragma mark - data
@property (nonatomic, copy) NSArray *scrollContentViews;

// H5国籍选择页url
@property (nonatomic, copy) NSString *nationalitySelectionURL;
// 国籍code
@property (nonatomic, copy) NSString *nationalityCode;
@property (nonatomic, copy) NSString *nationalityDesc;
@property (nonatomic, strong) CJPayCustomTextFieldConfigration *idTextFieldConfigration;
@property (nonatomic, assign) NSUInteger lastInputContentHash;
// 银行预留手机号（被加密）
@property (nonatomic, copy) NSString *authPhoneNumber;

#pragma mark - MASConstraints
// 更新国籍页约束
@property (nonatomic, strong) MASConstraint *nationalityViewConstraint;

#pragma mark - flag
@property (nonatomic, assign) CJPayBindCardChooseIDType selectedIDType;
//是否手动关闭了获取手机号提示框，PV内如果手动关闭则不再提示
@property (nonatomic, assign) BOOL isCloseAuthPhoneTips;
// 手机号是否处于反显状态
@property (nonatomic, assign) BOOL isPhoneNumReverseDisplay;
// 短信参数是否使用银行预留加密手机号
@property (nonatomic, assign) BOOL isUseAuthPhoneNumber;

// tracker 相关
@property (nonatomic, assign) BOOL hasTrackNameInput;
@property (nonatomic, assign) BOOL hasTrackIDInput;
@property (nonatomic, assign) BOOL hasTrackPhoneInput;
// 是否展示过四要素授权浮窗
@property (nonatomic, assign) BOOL hasShownAuthTipsView;

@property (nonatomic, weak) CJPayHalfSignCardVerifySMSViewController *verifySMSVC;

@property (nonatomic, assign) double enterTimestamp;

@end

@implementation CJPayBindCardFourElementsViewController

+ (Class)associatedModelClass {
    return [CJPayBindCardFourElementsModel class];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        self.viewModel = [[CJPayBindCardFourElementsModel alloc] initWithDictionary:dict error:nil];
        self.selectedIDType = CJPayBindCardChooseIDTypeNormal;
        self.lastInputContentHash = 0;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - vc life cycle & override

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupCardInfo];
    [self p_updateIDTypeInfo];
    [self p_setupProtocolView];
    [self p_registerForKeyboardNotifications];
    [self p_showCachedIdentityInfo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0];
    self.enterTimestamp = [dt timeIntervalSince1970]*1000;
    
    // track
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    NSMutableArray *phoneTypes = [NSMutableArray array];
    if (Check_ValidString(self.viewModel.userInfo.mobile)) {
        [phoneTypes addObject:@"支付账户手机号"];
    }
    if (Check_ValidString(self.viewModel.userInfo.uidMobileMask)) {
        [phoneTypes addObject:@"App手机号"];
    }
    [params addEntriesFromDictionary:@{
        @"phone_type" : [phoneTypes componentsJoinedByString:@","],
    }];
    [self trackWithEventName:@"wallet_addbcard_page_imp" params:[params copy]];
}

- (void)back {
    [self trackWithEventName:@"wallet_page_back_click"
                      params:@{@"page_name": @"wallet_addbcard_page"}];
    [self p_cacheIdentityInfo];
    [super back];
}

- (BOOL)p_isNeedSaveUserInfo {
    return [self.viewModel.retainInfo.isNeedSaveUserInfo isEqualToString:@"Y"];
}

- (void)p_cacheIdentityInfo {
    if ([self p_isNameInvalid] ||
        !Check_ValidString([self.idTextFieldConfigration userInputContent]) ||
        ![self p_isIDCardNumValid] ||
        ![self p_isNeedSaveUserInfo]) {
        return;
    }
    CJPayBindCardCachedIdentityInfoModel *model = self.viewModel.cachedInfoModel ?: [CJPayBindCardCachedIdentityInfoModel new];
    model.name = self.nameContainer.textField.text;
    model.identity = self.identityContainer.textField.text;
    model.selectedIDType = self.selectedIDType;
    if (model.selectedIDType == CJPayBindCardChooseIDTypePD) {
        model.nationalityCode = self.nationalityCode;
        model.nationalityDesc = self.nationalityDesc;
    }
    if (!self.viewModel.cachedInfoModel) { //首次缓存时记录时间
        model.cachedBeginTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    }
    
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
        CJPayBindCardShareDataKeyCachedIdentityInfoModel: [model toDictionary] ?: @{}
    } completion:nil];
}

- (void)p_showCachedIdentityInfo {
    if (![self p_isNeedSaveUserInfo]) {
        return;
    }
    NSTimeInterval currentTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    CJPayBindCardCachedIdentityInfoModel *model = self.viewModel.cachedInfoModel;
    if (!model) { //无缓存
        return;
    }
    
    NSInteger cacheDuration = [CJPaySettingsManager shared].currentSettings.bindCardUISettings.userInputCacheDuration;
    if (currentTime - self.viewModel.cachedInfoModel.cachedBeginTime > cacheDuration) { //超时，不反显并清空缓存
        [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
            CJPayBindCardShareDataKeyCachedIdentityInfoModel: @{}
        } completion:nil];
        return;
    }
    
    [self didSelectIDType:model.selectedIDType];
    if (model.selectedIDType == CJPayBindCardChooseIDTypePD) { // 护照需要更新国家/地区
        self.nationalityCode = model.nationalityCode;
        self.nationalityDesc = model.nationalityDesc;
        [self.nationalityView updateWithMainStr:CJPayLocalizedStr(@"国家/地区") subStr:CJString(self.nationalityDesc)];
    }
    [self.nameContainer preFillText:CJString(model.name)];
    [self.identityContainer preFillText:CJString(model.identity)];
}

#pragma mark - setup UI

- (void)p_setupUI {
    // set background color
    self.view.backgroundColor = [UIColor cj_colorWithHexString:@"F5F5F5"];
    self.navigationBar.backgroundColor = [UIColor cj_colorWithHexString:@"F5F5F5"];
    [self p_setupBackgroundImageView];

    // add subviews
    [self.view addSubview:self.scrollView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEditMode)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEditMode)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    [self.view addGestureRecognizer:panGesture];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.headerView];
        
    [self.scrollContentView addSubview:self.centerContentView];
    self.centerContentView.backgroundColor = [UIColor whiteColor];
    
    self.scrollContentViews = @[self.bankCardView, self.identityView, self.nationalityView, self.nameContainer, self.identityContainer, self.phoneContainer];
        
    [self.identityView cj_viewAddTarget:self action:@selector(p_chooseIDType) forControlEvents:UIControlEventTouchUpInside];
    [self.nationalityView cj_viewAddTarget:self action:@selector(p_chooseNationality) forControlEvents:UIControlEventTouchUpInside];

    
    for (int i = 0; i<self.scrollContentViews.count; i++) {
        [self.centerContentView addSubview:self.scrollContentViews[i]];
    }
    
    [self.nameContainer addSubview:self.ocrButton];
    [self p_setOCRButtonHidden:NO];
    [self.centerContentView addSubview:self.authPhoneTipsView];
    [self.centerContentView addSubview:self.containerMaskView];
    [self.centerContentView addSubview:self.protocolView];
    [self.centerContentView addSubview:self.nextStepButton];
    [self.scrollContentView addSubview:self.scrollServiceLabel];
    [self.scrollContentView addSubview:self.safeGuardTipView];
    
    [self.centerContentView bringSubviewToFront:self.authPhoneTipsView];
    [self.centerContentView bringSubviewToFront:self.containerMaskView];
    
    [self p_makeConstraints];
}

- (void)p_makeConstraints {

    CJPayMasMaker(self.scrollView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.view);
        make.height.greaterThanOrEqualTo(self.scrollView);
    });
    
    CJPayMasMaker(self.headerView, {
        make.top.equalTo(self.scrollContentView).offset(12);
        make.centerX.equalTo(self.scrollContentView);
        make.left.equalTo(self.scrollContentView);
        make.right.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.centerContentView, {
        make.top.equalTo(self.headerView.mas_bottom);
        make.centerX.equalTo(self.scrollContentView);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    });
    
    CJPayMasMaker(self.bankCardView, {
        make.top.equalTo(self.centerContentView);
        make.left.equalTo(self.centerContentView).offset(16);
        make.right.equalTo(self.centerContentView).offset(-16);
        make.height.mas_equalTo(60);
    });
    
    CJPayMasMaker(self.identityView, {
        make.top.equalTo(self.bankCardView.mas_bottom);
        make.left.equalTo(self.centerContentView).offset(16);
        make.right.equalTo(self.centerContentView).offset(-16);
        make.height.mas_equalTo(60);
    });
    
    CJPayMasMaker(self.nationalityView, {
        make.top.equalTo(self.identityView.mas_bottom);
        make.left.equalTo(self.centerContentView).offset(16);
        make.right.equalTo(self.centerContentView).offset(-16);
        self.nationalityViewConstraint = make.height.mas_equalTo(0);
    });
    
    CJPayMasReMaker(self.nameContainer, {
        if (self.selectedIDType == CJPayBindCardChooseIDTypePD) {
            make.top.equalTo(self.nationalityView.mas_bottom);
        } else {
            make.top.equalTo(self.identityView.mas_bottom);
        }
        make.left.right.equalTo(self.centerContentView);
        make.height.mas_equalTo(60);
    });
    
    CJPayMasMaker(self.ocrButton, {
        make.top.equalTo(self.nameContainer).offset(18);
        make.right.equalTo(self.centerContentView).offset(-16);
        make.width.height.mas_offset(24);
    })
    
    CJPayMasMaker(self.identityContainer, {
        make.top.equalTo(self.nameContainer.mas_bottom);
        make.left.right.equalTo(self.nameContainer);
        make.height.mas_equalTo(60);
    });
    
    CJPayMasMaker(self.phoneContainer, {
        make.top.equalTo(self.identityContainer.mas_bottom);
        make.left.right.equalTo(self.identityContainer);
        make.height.mas_equalTo(60);
    });
    
    CJPayMasMaker(self.authPhoneTipsView, {
        make.top.equalTo(self.phoneContainer.mas_bottom).offset(1);
        make.left.equalTo(self.scrollContentView).offset(24);
        make.right.equalTo(self.scrollContentView).offset(-24);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.phoneContainer.mas_bottom).offset(34);
        make.left.equalTo(self.centerContentView).offset(16);
    });
    
    CJPayMasMaker(self.nextStepButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(12);
        make.left.equalTo(self.centerContentView).offset(16);
        make.right.equalTo(self.centerContentView).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.bottom.lessThanOrEqualTo(self.centerContentView).offset(-22);
    });
    
    CJPayMasMaker(self.scrollServiceLabel, {
        make.left.right.equalTo(self.nextStepButton);
        make.top.greaterThanOrEqualTo(self.nextStepButton.mas_bottom).offset(16);
        make.bottom.equalTo(self.scrollContentView).offset(-16-CJ_TabBarSafeBottomMargin);
        make.top.greaterThanOrEqualTo(self.nextStepButton.mas_bottom).offset(16);
        make.height.mas_equalTo(18);
    });
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        CJPayMasMaker(self.safeGuardTipView, {
            make.left.right.equalTo(self.scrollContentView);
            make.center.equalTo(self.scrollServiceLabel);
            make.height.mas_equalTo(18);
        });
        self.scrollServiceLabel.hidden = YES;
    }
}

- (void)p_setupCardInfo {
    NSString *cardTailStr = @"";
    if (self.viewModel.cardInfoModel.cardNumStr.length >= 4) {
        cardTailStr = [self.viewModel.cardInfoModel.cardNumStr substringFromIndex:self.viewModel.cardInfoModel.cardNumStr.length - 4];
    }
    
    NSString *cardTypeName = CJPayLocalizedStr(@"储蓄卡");
    if ([self.viewModel.cardInfoModel.cardType.uppercaseString isEqualToString:@"CREDIT"]) {
        cardTypeName = CJPayLocalizedStr(@"信用卡");
    }
    
    CJPayBindCardTopHeaderViewModel *model = [CJPayBindCardTopHeaderViewModel new];
    model.title = self.viewModel.firstStepMainTitle;
    model.displayIcon = self.viewModel.displayIcon;
    model.displayDesc = self.viewModel.displayDesc;
    CJPayBindCardVoucherInfo *voucherInfo = [[CJPayBindCardVoucherInfo alloc] initWithDictionary:[self.viewModel.cardInfoModel.voucherInfoDict cj_dictionaryValueForKey:CJString(self.viewModel.cardInfoModel.cardType)] error:nil];
    model.voucherMsg = CJString(voucherInfo.voucherMsg);
    model.orderAmount = self.viewModel.orderAmount;

    [self.headerView updateWithModel:model];
    NSString *cardTotalName = [NSString stringWithFormat:@"%@%@(%@)", self.viewModel.cardInfoModel.bankName, cardTypeName, cardTailStr];
    [self.bankCardView updateWithMainStr:CJPayLocalizedStr(@"卡类型") subStr:cardTotalName];
}

- (void)p_updateIDTypeInfo {
    NSString *idTypeName = [CJPayBindCardChooseIDTypeModel getIDTypeStr:self.selectedIDType];
    [self.identityView updateWithMainStr:CJPayLocalizedStr(@"证件类型") subStr:idTypeName];
    
    [self p_showNationalitySelection:self.selectedIDType == CJPayBindCardChooseIDTypePD];
    
    [self.idTextFieldConfigration bindTextFieldContainer:self.identityContainer];
}

- (void)p_setupProtocolView {
    if (self.viewModel.memCardBinResponse.agreements.count == 0) {
        CJPayMasUpdate(self.protocolView, {
            make.height.mas_equalTo(0);
        });
    } else {
        CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
        commonModel.guideDesc = CJString(self.viewModel.memCardBinResponse.guideMessage);
        commonModel.groupNameDic = self.viewModel.memCardBinResponse.protocolGroupNames;
        commonModel.agreements = self.viewModel.memCardBinResponse.agreements;
        commonModel.protocolCheckBoxStr = self.viewModel.memCardBinResponse.protocolCheckBox;
        commonModel.supportRiskControl = YES;
        [self.protocolView updateWithCommonModel:commonModel];
    }
}

- (void)p_registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(p_keyboardWasChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)p_showNationalitySelection:(BOOL)isShow {
    self.nationalityView.hidden = !isShow;
    self.nationalityViewConstraint.offset = isShow ? 60 : 0;
}

- (void)p_setupBackgroundImageView {
    [self.view addSubview:self.backgroundImageView];
    if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
        [self.backgroundImageView cj_setImage:@"cj_bindcard_logo_icon"];
    }
    CJPayMasMaker(self.backgroundImageView, {
        make.top.right.equalTo(self.view);
        make.width.height.mas_equalTo(self.view.cj_width * 200 /
                                      375.0);
    });
}

#pragma mark - private func

- (void)p_handleWebViewCloseCallback:(id)back {
    if ([back isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)back;
        NSString *service = [dic cj_stringValueForKey:@"service"];
        NSUInteger code = [dic cj_intValueForKey:@"code"];
        // 验证服务 : select_nationality
        // code = 0 成功， 1 失败
        if ([service isEqualToString:@"select_nationality"] && code == 0) {
            NSDictionary *data = [CJPayCommonUtil jsonStringToDictionary:back[@"data"]];
            self.nationalityCode = data[@"code"];
            self.nationalityDesc = [data btd_stringValueForKey:@"label"];
            [self.nationalityView updateWithMainStr:CJPayLocalizedStr(@"国家/地区") subStr:CJString(self.nationalityDesc)];
        }
    }
}

- (void)p_nativeAlertViewWithTitle:(NSString *)title {
    if (!Check_ValidString(title)) {
        return;
    }
    
    [CJPayAlertUtil customSingleAlertWithTitle:CJString(title)
                                 content:nil
                              buttonDesc:CJPayLocalizedStr(@"我知道了")
                             actionBlock:^{} useVC:self];
}

- (void)p_endEditMode {
    [self.view endEditing:YES];
}

- (BOOL)p_isNextStepButtonEnable {
    // 姓名
    if (self.nameContainer.textField.userInputContent.length < 2 || [self p_isNameInvalid]) {
        return NO;
    }
    
    // 证件号码
    if (![self p_isIDCardNumValid]) {
        return NO;
    }
    
    // 手机号
    if (![self p_isPhoneNumValid] && !self.isPhoneNumReverseDisplay) {
        return NO;
    }
    
    return YES;
}

- (NSString *)p_getIDTypeStr {
    switch (self.selectedIDType) {
        case CJPayBindCardChooseIDTypeNormal:
            return @"ID_CARD";
        case CJPayBindCardChooseIDTypeHK:
            return @"HKMPASS";
        case CJPayBindCardChooseIDTypeTW:
            return @"TAIWANPASS";
        case CJPayBindCardChooseIDTypePD:
            return @"PASSPORT";
        default:
            return @"ID_CARD";
    }
}

- (BOOL)p_isIDCardNumValid {
    return [self.idTextFieldConfigration contentISValid];
}

- (BOOL)p_isPhoneNumValid {
    NSString *text = self.phoneContainer.textField.userInputContent;
    return text.length == 11;
}

- (BOOL)p_isNameInvalid {
    NSString *nameStr = self.nameContainer.textField.userInputContent;
    
    return ![CJPayBindCardValidateManager isNameValid:nameStr] || [self p_isContainSpecialCharacterInIDCardName];
}

- (BOOL)p_isContainSpecialCharacterInIDCardName {
    BOOL isContainSpecialCharacterInName = NO;
    if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
        // 只有身份证证件时才判断姓名是否包含特殊字符
        NSString *nameStr = self.nameContainer.textField.userInputContent;
        isContainSpecialCharacterInName = [CJPayBindCardValidateManager isContainSpecialCharacterInString:nameStr];
    }
    
    return isContainSpecialCharacterInName;
}

- (BOOL)p_isSupportAuthPhoneNumber {
    return Check_ValidString(self.viewModel.userInfo.uidMobileMask) && !Check_ValidString(self.viewModel.userInfo.mobile);
}

- (BOOL)p_shouldShowAuthTipsWithInputStr:(NSString *)inputStr mobileStr:(NSString *)mobileStr {
    if (!Check_ValidString(mobileStr)) {
        return NO;
    }
    
    if (!Check_ValidString(inputStr)) {
        return YES;
    }
    
    return [mobileStr hasPrefix:inputStr];
}

- (void)p_updateTextFeildHeight {
    CJPayMasReMaker(self.nameContainer, {
        if (self.selectedIDType == CJPayBindCardChooseIDTypePD) {
            make.top.equalTo(self.nationalityView.mas_bottom);
        } else {
            make.top.equalTo(self.identityView.mas_bottom);
        }
        make.left.right.equalTo(self.centerContentView);
        make.height.mas_equalTo([self.nameContainer hasTipsText] ? 66 : 60);
    });
    
    CJPayMasUpdate(self.identityContainer, {
        make.height.mas_equalTo([self.identityContainer hasTipsText] ? 66 : 60);
    });
    
    CJPayMasUpdate(self.phoneContainer, {
        make.height.mas_equalTo([self.phoneContainer hasTipsText] ? 66 : 60);
    });
}

- (void)p_fillCardNumber:(CJPayCardOCRResultModel *)resultModel {
    
    [self.nameContainer clearText];
    [self.identityContainer clearText];
    
    [self.nameContainer textFieldBeginEditAnimation];
    [self.identityContainer textFieldBeginEditAnimation];
    
    self.nameContainer.textField.text = CJString(resultModel.idName);
    [self.nameContainer updateTips:@""];

    CJPayCustomTextField *identityTextField = self.identityContainer.textField;
    [identityTextField textField:identityTextField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:CJString(resultModel.idCode)];
    [self textFieldContentChange:CJString(resultModel.idCode) textContainer:self.identityContainer];

    self.viewModel.isFromCardOCR = YES;

    if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
        [self p_setOCRButtonHidden:NO];
    }
    
    self.nextStepButton.enabled = [self p_isNextStepButtonEnable];
}

- (void)p_setOCRButtonHidden:(BOOL)hidden {
    self.ocrButton.hidden = hidden;
    if (![CJPaySettingsManager shared].currentSettings.bindCardUISettings.isShowIDProfileCard) {
        self.ocrButton.hidden = YES;
    }
}

#pragma mark - network request

- (void)p_sendSMS {
    @CJStartLoading(self.nextStepButton)
    @CJWeakify(self)
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:[self p_buildULBDPaySendSMSBaseParam]
                                       bizParam:[self p_buildULSMSBizParam]
                                     completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStopLoading(self.nextStepButton)
        
        [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                         metric:@{@"timestamp" : [NSString stringWithFormat:@"%.01f", [[NSDate date] timeIntervalSince1970] - self.viewModel.firstStepVCTimestamp]}
                       category:@{@"userType" : @"unAuth", @"stage" : @"smsSend"}
                          extra:@{}];
        
        NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
        [params addEntriesFromDictionary:@{
            @"loading_time" : [NSString stringWithFormat:@"%f", response.responseDuration]
        }];
        [self trackWithEventName:@"wallet_bcard_yaosu_check_time" params:[params copy]];
        
        if (error) {
            [self showNoNetworkToast];
            return;
        }
        
        [self trackWithEventName:@"wallet_businesstopay_auth_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"url" : @"bytepay.member_product.send_sign_sms",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg),
            @"auth_type" : @"four_elements"
        }];
        
        if (self.viewModel.isFromCardOCR) {
            [self trackWithEventName:@"wallet_addbcard_orc_accuracy_result_2" params:@{
                @"result" : [response isSuccess] ? @"1" : @"0"
            }];
        }
        
        if ([response isSuccess]) {
            [self p_verifySMS:response];
        } else if ([response.code isEqualToString:@"MP020308"]) {
            // 与银行预留手机号不符
            [self p_showCardWarningAlertWithResponse:response];
        } else if (response.buttonInfo) {
            CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
            @CJWeakify(self)
            
            actionModel.logoutBizRealNameAction = ^{
                // 去注销宿主端实名能力降级处理，只展示提示文案
                @CJStrongify(self)
                [self trackWithEventName:@"wallet_businesstopay_auth_fail_click"
                                  params:@{@"auth_type" : @"four_elements"}];
            };
            
            actionModel.alertPresentAction = ^{
                @CJStrongify(self)
                [self trackWithEventName:@"wallet_businesstopay_auth_fail_imp"
                                  params:@{@"auth_type" : @"four_elements"}];
            };
            
            actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
                [CJToast toastText:errorText inWindow:self.cj_window];
            };
            
            response.buttonInfo.trackCase = @"3.3";
            response.buttonInfo.code = response.code;
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self
                                                            errorMsg:response.msg
                                                         withActions:actionModel
                                                           withAppID:self.viewModel.appId
                                                          merchantID:self.viewModel.merchantId];
            return;
        } else {
            // 单button alert
            [self p_showSingleButtonAlertWithResponse:response];
        }
    }];
}

// 构造三方支付发短信请求参数
- (NSDictionary *)p_buildULSMSBizParam {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:self.viewModel.signOrderNo forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:self.viewModel.specialMerchantId forKey:@"smch_id"];
    //后续需加密处理
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:self.viewModel.cardInfoModel.cardNumStr] forKey:@"card_no"];
    NSString *phoneStr = self.isUseAuthPhoneNumber ? CJString(self.authPhoneNumber) : [self.phoneContainer.textField.userInputContent cj_noSpace];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:phoneStr] forKey:@"mobile"];
    
    NSString *name = self.nameContainer.textField.userInputContent;
    NSString *idCardNumStr = self.identityContainer.textField.userInputContent;
    [encParams cj_setObject:[CJPaySafeUtil encryptField:name] forKey:@"name"];
    [encParams cj_setObject:[self p_getIDTypeStr] forKey:@"identity_type"];
    if (self.selectedIDType == CJPayBindCardChooseIDTypePD) {
        [encParams cj_setObject:self.nationalityCode forKey:@"country"];
    }
    [encParams cj_setObject:[CJPaySafeUtil encryptField:idCardNumStr] forKey:@"identity_code"];
    
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    
    return bizContentParams;
}

- (void)p_verifySMS:(CJPaySendSMSResponse *)response {
    [self.view endEditing:YES];
    self.latestSMSResponse = response;
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfVerifySMS params:nil completion:nil];
    if (![vc isKindOfClass:CJPayHalfSignCardVerifySMSViewController.class]) {
        return;
    }
    CJPayHalfSignCardVerifySMSViewController *verifySMSVC = (CJPayHalfSignCardVerifySMSViewController *)vc;
    verifySMSVC.ulBaseReqquestParam = [self p_buildULBDPaySendSMSBaseParam];
    verifySMSVC.sendSMSResponse = response;
    verifySMSVC.sendSMSBizParam = [self p_buildULSMSBizParam];
    verifySMSVC.bankCardInfo = self.viewModel.cardInfoModel;
    verifySMSVC.externTimer = self.smsTimer;
    if (!CJ_Pad){
        [verifySMSVC useCloseBackBtn];
    }
    NSMutableString *mutablePhoneStr = [self.phoneContainer.textField.userInputContent mutableCopy];
    NSString *noSpacePhoneStr = [mutablePhoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableString *phoneNoMaskStr = [[NSMutableString alloc] initWithString:CJString(noSpacePhoneStr)];
    
    if (phoneNoMaskStr.length == 11) {
        [phoneNoMaskStr replaceCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    }
    CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
    helpModel.cardNoMask = self.viewModel.cardInfoModel.cardNumStr;
    helpModel.frontBankCodeName = self.viewModel.cardInfoModel.bankName;
    helpModel.phoneNum = phoneNoMaskStr;
    
    verifySMSVC.helpModel = helpModel;
    verifySMSVC.animationType = HalfVCEntranceTypeFromBottom;
    [verifySMSVC showMask:YES];
    self.verifySMSVC = verifySMSVC;
}

- (void)p_showCardWarningAlertWithResponse:(CJPaySendSMSResponse *)response {
    CJPayErrorButtonInfo *buttonInfo = response.buttonInfo;
    if (!Check_ValidString(buttonInfo.page_desc) ||
        !Check_ValidString(buttonInfo.button_desc)) {
        [CJToast toastText:response.msg ?: CJPayLocalizedStr(@"与银行预留手机号码不一致") inWindow:self.cj_window];
        return;
    }
    
    @CJWeakify(self)
    void(^actionBlock)(void) = ^() {
        @CJStrongify(self)
        [self.phoneContainer.textField becomeFirstResponder];
        [self.phoneContainer updateTips:CJString(buttonInfo.page_desc)];
                        
        NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
        
        [self trackWithEventName:@"wallet_addbcard_page_error_click" params:[params copy]];
    };
    
    [CJPayAlertUtil customSingleAlertWithTitle:CJString(buttonInfo.page_desc)
                                       content:[NSString stringWithFormat:@"(%@)", CJString(response.code)]
                                    buttonDesc:CJString(buttonInfo.button_desc)
                                   actionBlock:actionBlock
                                         useVC:self];
    
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    [params addEntriesFromDictionary:@{
        @"errorcode" : CJString(response.code),
        @"errordesc" : CJString(response.msg)
    }];
    
    [self trackWithEventName:@"wallet_addbcard_page_error_imp" params:[params copy]];
}

- (void)p_showSingleButtonAlertWithResponse:(CJPaySendSMSResponse *)response {
    if(!Check_ValidString(response.msg)) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
        return;
    }
    
    @CJWeakify(self)
    void(^actionBlock)(void) = ^() {
        @CJStrongify(self)
        NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
        [self trackWithEventName:@"wallet_addbcard_page_error_click" params:[params copy]];
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJPayAlertUtil customSingleAlertWithTitle:CJString(response.msg)
                                           content:[NSString stringWithFormat:@"(%@)", CJString(response.code)]
                                        buttonDesc:CJPayLocalizedStr(@"知道了")
                                       actionBlock:actionBlock
                                             useVC:self];
    });
    
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    [params addEntriesFromDictionary:@{
        @"errorcode" : CJString(response.code),
        @"errordesc" : CJString(response.msg)
    }];
    [self trackWithEventName:@"wallet_addbcard_page_error_imp" params:[params copy]];
}

- (NSArray<CJPayMemAgreementModel *> *)p_authTipsAgreementsWithGroup:(NSString *)group {
    NSMutableArray *agreements = [NSMutableArray array];
    [self.viewModel.bizAuthInfoModel.agreements enumerateObjectsUsingBlock:^(CJPayMemAgreementModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.group isEqualToString:group]) {
            [agreements btd_addObject:obj];
        }
    }];
    return agreements;
}

// 展示/隐藏手机号授权浮窗
- (void)p_updateAuthPhoneTipsView {
    if ([self p_shouldShowAuthTipsWithInputStr:self.phoneContainer.textField.text
                                     mobileStr:self.viewModel.userInfo.uidMobileMask] &&
        [self p_isSupportAuthPhoneNumber] &&
        [self.phoneContainer.textField isFirstResponder] &&
        !self.isCloseAuthPhoneTips) {
        if (self.authPhoneTipsView.alpha < 0.1) {  // 透明度小于0.1，认为不显示的情况才做动画和展示
            [UIView animateWithDuration:0.1 animations:^{
                self.authPhoneTipsView.alpha = 1;
            }];
            
            [self trackWithEventName:@"wallet_addbcard_page_phoneauth_imp" params:[self p_bankTrackerParamsWithCertType]];
        }
        
    } else {
        if (self.authPhoneTipsView.alpha > 0.1) { // 大于0.1 认为当前正在显示
            [UIView animateWithDuration:0.1 animations:^{
                self.authPhoneTipsView.alpha = 0;
            }];
        }
    }
}

- (void)p_fetchAuthPhoneNumber {
    NSDictionary *params = @{
        @"app_id": CJString(self.viewModel.appId),
        @"merchant_id": CJString(self.viewModel.merchantId),
        @"need_encrypt" : @YES
    };
    
    [CJPayAuthPhoneRequest startWithParams:params completion:^(NSError * _Nullable error, CJPayAuthPhoneResponse * _Nonnull response) {
        
        NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
        [params addEntriesFromDictionary:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
        [self trackWithEventName:@"wallet_addbcard_page_phoneauth_result" params:[params copy]];
        
        if (![response isSuccess]) {
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        
        [self p_reverseDisplayMaskedPhoneNumber:self.viewModel.userInfo.uidMobileMask];
        self.isUseAuthPhoneNumber = YES;
        self.authPhoneNumber = CJString(response.mobile);
        
        [self p_updateAuthPhoneTipsView];
    }];
}

- (void)p_reverseDisplayMaskedPhoneNumber:(NSString *)phoneNumer {
    NSMutableString *phoneNumMaskStr = [NSMutableString stringWithString:CJString(phoneNumer)];
    if (phoneNumMaskStr.length == 11) {
        [phoneNumMaskStr insertString:@" " atIndex:3];
        [phoneNumMaskStr insertString:@" " atIndex:8];
    }
    [self.phoneContainer preFillText:CJString(phoneNumMaskStr)];
    
    self.isPhoneNumReverseDisplay = YES;
    self.phoneContainer.textField.supportSeparate = NO;
    self.nextStepButton.enabled = [self p_isNextStepButtonEnable];
}

- (NSDictionary *)p_buildULBDPaySendSMSBaseParam {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams cj_setObject:self.viewModel.merchantId forKey:@"merchant_id"];
    [baseParams cj_setObject:self.viewModel.appId forKey:@"app_id"];
    return baseParams;
}

#pragma mark click event

- (void)p_chooseIDType {
    [self.view endEditing:YES];
    
    [self trackWithEventName:@"wallet_addbcard_page_cardtype_click" params:[self p_bankTrackerParams]];
    CJPayBindCardChooseIDTypeViewController *chooseTypeVC = [CJPayBindCardChooseIDTypeViewController new];
    chooseTypeVC.selectedType = self.selectedIDType;
    chooseTypeVC.animationType = HalfVCEntranceTypeFromBottom;
    [chooseTypeVC useCloseBackBtn];
    chooseTypeVC.delegate = self;
    [chooseTypeVC showMask:YES];
    [self.navigationController pushViewController:chooseTypeVC animated:YES];
    [self trackWithEventName:@"wallet_addbcard_page_cardtype_page_imp" params:[self p_bankTrackerParams]];
}

- (void)p_chooseNationality {
    [self.view endEditing:YES];
    
    // H5国籍选择请求页面参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:self.viewModel.merchantId forKey:@"merchant_id"];
    [params cj_setObject:self.viewModel.appId forKey:@"app_id"];
    [params cj_setObject:self.viewModel.specialMerchantId forKey:@"smch_id"];
    [params cj_setObject:@"sdk" forKey:@"source"];
    [params cj_setObject:@"select_nationality" forKey:@"service"];
    
    NSMutableDictionary *nativeStyleParams = [NSMutableDictionary dictionary];
    [nativeStyleParams cj_setObject:CJPayLocalizedStr(@"选择国家和地区") forKey:@"title"];
    [nativeStyleParams cj_setObject:@"1" forKey:@"has_title"];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self useNewNavi:CJ_Pad toUrl:self.nationalitySelectionURL params:params nativeStyleParams:@{} closeCallBack:^(id  _Nonnull data) {
            // 处理webView返回的数据
            [self p_handleWebViewCloseCallback:data];
    }];
}

- (void)p_keyboardWasChange:(NSNotification*)aNotification {
    if (self.verifySMSVC) {
        return;
    }
    
    CGRect keyboardEndRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat scrollDelta = self.nextStepButton.cj_bottom - (keyboardEndRect.origin.y) + self.navigationBar.cj_height + 120;
    if ( scrollDelta > 0) {
        [self.scrollView setContentOffset:CGPointMake(0,  scrollDelta)];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0,  0)];
    }
}

- (void)p_ocrButtonClick {

    [self trackWithEventName:@"wallet_addbcard_first_page_orc_idcard_click" params:@{
        @"ocr_source" : @"四要素"
    }];

    [self p_endEditMode];
    
    CJPayIDCardProfileOCRViewController *cardOCRVC = [CJPayIDCardProfileOCRViewController new];
    cardOCRVC.appId = self.viewModel.appId;
    cardOCRVC.merchantId = self.viewModel.merchantId;
    cardOCRVC.minLength = 13;
    cardOCRVC.maxLength = 23;
    cardOCRVC.trackDelegate = self;
    cardOCRVC.fromPage = @"四要素";
    
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_newFourElements_ocr_idcard_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_newFourElements_ocr_idcard_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_newFourElements_ocr_idcard_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_newFourElements_ocr_idcard_avcapturesession_stop_running";
    
    @CJWeakify(self)
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                [self p_fillCardNumber:resultModel];
                break;
            case CJPayCardOCRResultUserCancel: // 用户取消识别
            case CJPayCardOCRResultUserManualInput: // 用户手动输入
                self.viewModel.isFromCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoCameraAuthority: //BPEA降级导致无法获取相机权限
                [CJToast toastText:@"没有相机权限" inWindow:self.cj_window];
                self.viewModel.isFromCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoJumpSettingAuthority: //BPEA降级导致无法跳转系统设置开启相机权限
                [CJToast toastText:@"没有跳转系统设置权限" inWindow:self.cj_window];
                self.viewModel.isFromCardOCR = NO;
                break;
            default:
                break;
        }
    };
    [self.navigationController pushViewController:cardOCRVC animated:YES];
}

- (void)p_nextButtonClick {
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    double currentTimestamp = [date timeIntervalSince1970] * 1000;
    [self trackWithEventName:@"wallet_rd_custom_scenes_time" params:@{
        @"scenes_name" : @"绑卡",
        @"sub_section" : @"完成四要素输入",
        @"time" : @(currentTimestamp - self.enterTimestamp)
    }];
    
    @CJWeakify(self)
    [self.protocolView executeWhenProtocolSelected:^{
        @CJStrongify(self)
        [self p_startBindCard];
    } notSeleted:^{
        @CJStrongify(self)
        [self.view endEditing:YES];
        CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.protocolView.protocolModel from:@"四要素"];
        popupProtocolVC.confirmBlock = ^{
            @CJStrongify(self)
            [self.protocolView setCheckBoxSelected:YES];
            [self p_startBindCard];
        };
        [self.navigationController pushViewController:popupProtocolVC animated:YES];
    } hasToast:NO];
}

- (void)p_startBindCard {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskSignSMSCheckRequest];
    [self p_endEditMode];
    
    NSString *card = CJString(self.viewModel.cardInfoModel.cardNumStr);
    NSString *name = CJString(self.nameContainer.textField.userInputContent);
    NSString *identityType = [self p_getIDTypeStr];
    NSString *identityCode = CJString(self.identityContainer.textField.userInputContent);
    NSString *phone = CJString([self.phoneContainer.textField.userInputContent cj_noSpace]);
    
    NSUInteger curInputContentHash = [[NSString stringWithFormat:@"%@%@%@%@%@", card, name, identityType, identityCode, phone] hash];
    
    if (self.smsTimer.curCount <= 0 ||
        self.lastInputContentHash != curInputContentHash ||
        !self.latestSMSResponse) {
        self.lastInputContentHash = curInputContentHash;
        [self.smsTimer reset];
        [self p_sendSMS];
    } else {
        [self p_verifySMS:self.latestSMSResponse];
    }
    
    [self trackWithEventName:@"wallet_addbcard_page_next_click" params:[self p_bankTrackerParams]];
}

- (void)p_clickContainerMaskview {
    [self.containerMaskView removeFromSuperview];
}


#pragma mark CJPayCustomTextFieldContainerDelegate

- (void)textFieldBeginEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.nameContainer &&
        textContainer.textField.userInputContent.length > 0) {
        [self p_setOCRButtonHidden:YES];
    }
    
    [self p_updateAuthPhoneTipsView];
    if (CJ_Pad) {
        [self p_updateTextFeildHeight];
        return;
    }
}

- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    [self p_updateAuthPhoneTipsView];

    if (textContainer == self.identityContainer ||
        textContainer == self.phoneContainer ||
        textContainer == self.nameContainer) {
        
        // 实时校验证件号码，如果合法或者为空就将错误提示消除
        if (textContainer == self.identityContainer) {
            [self.identityContainer updateTips:@""];
            if ((self.selectedIDType == CJPayBindCardChooseIDTypeHK || self.selectedIDType == CJPayBindCardChooseIDTypePD) && !textContainer.textField.markedTextRange) {
                self.identityContainer.textField.text = self.identityContainer.textField.text.uppercaseString;
            } else if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
                if ([self.idTextFieldConfigration userInputContent].length == 18) {
                    [self.idTextFieldConfigration contentISValid];
                }
            }
        }
        
        // 实时校验手机号码，如果合法或者为空就将错误提示消除
        if (textContainer == self.phoneContainer) {
            if (self.isPhoneNumReverseDisplay) {
                self.phoneContainer.textField.text = @"";
                self.isPhoneNumReverseDisplay = NO;
                self.phoneContainer.textField.supportSeparate = YES;
            }
            [self.phoneContainer updateTips:@""];
        }
        
        if (textContainer == self.nameContainer) {
            [self.nameContainer updateTips:@""];
            if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
                [self p_setOCRButtonHidden:!(textContainer.textField.userInputContent.length == 0)];
            }
        }
    }
    
    self.nextStepButton.enabled = [self p_isNextStepButtonEnable];
    [self p_updateTextFeildHeight];

    // track
    if (textContainer == self.nameContainer && !self.hasTrackNameInput) {
        self.hasTrackNameInput = YES;
        
        NSMutableDictionary *params = [@{@"input_type" : @"userName"} mutableCopy];
        [params addEntriesFromDictionary:[self p_bankTrackerParamsWithCertType]];
        [self trackWithEventName:@"wallet_addbcard_page_input" params:[params copy]];
    }
    
    if (textContainer == self.identityContainer && !self.hasTrackIDInput) {
        self.hasTrackIDInput = YES;
        
        NSMutableDictionary *params = [@{@"input_type" : @"idCard"} mutableCopy];
        [params addEntriesFromDictionary:[self p_bankTrackerParamsWithCertType]];
        
        [self trackWithEventName:@"wallet_addbcard_page_input" params:[params copy]];
    }
    
    if (textContainer == self.phoneContainer && !self.hasTrackPhoneInput) {
        self.hasTrackPhoneInput = YES;
        
        NSMutableDictionary *params = [@{@"input_type" : @"mobile"} mutableCopy];
        [params addEntriesFromDictionary:[self p_bankTrackerParamsWithCertType]];
        
        [self trackWithEventName:@"wallet_addbcard_page_input" params:[params copy]];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.nameContainer.textField == textField) {
        // 姓名输入框不能粘贴非法的字符
        if (string.length > 1) {
            if (![CJPayBindCardValidateManager isNameValid:string]) {
                [CJToast toastText:CJPayLocalizedStr(@"粘贴内容不合法") inWindow:self.cj_window];
                return NO;
            }
            [self p_setOCRButtonHidden:YES];
        }
    }
    
    if (self.identityContainer.textField == textField) {
        return [self.idTextFieldConfigration textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    
    return YES;
}

- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer {
    
    NSString *monitorStage = [NSString new];
    
    if (self.nameContainer == textContainer) {
        monitorStage = @"nameInput";
    } else if (self.identityContainer == textContainer) {
        monitorStage = @"identityNumInput";
    } else if (self.phoneContainer == textContainer) {
        monitorStage = @"phoneNumInput";
    }
    
    [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                     metric:@{@"timestamp" : [NSString stringWithFormat:@"%.01f", [[NSDate date] timeIntervalSince1970] - self.viewModel.firstStepVCTimestamp]}
                   category:@{@"userType" : @"unAuth", @"stage" : CJString(monitorStage)}
                      extra:@{}];
    
    // 失焦时校验证件号码 如果有内容并且内容不合法就提示错误信息
    if (textContainer == self.identityContainer) {
        
        @CJWeakify(self)
        self.idTextFieldConfigration.textFieldEndEditCompletionBlock = ^(BOOL isLegal) {
            @CJStrongify(self)
            BOOL hasInput = self.idTextFieldConfigration.userInputContent.length > 0;
            if (hasInput) {
                NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
                [params addEntriesFromDictionary:@{
                    @"input_type" : @"idCard",
                    @"is_legal" : isLegal ? @"1" : @"0"
                }];
                [self trackWithEventName:@"wallet_addbcard_page_input_inform_verif_info" params:[params copy]];
                
                NSMutableDictionary *trackParams = [NSMutableDictionary new];
                [trackParams cj_setObject:isLegal ? @"1" : @"0" forKey:@"result"];
                if ( !isLegal && Check_ValidString(self.idTextFieldConfigration.errorMsg)) {
                    [trackParams cj_setObject:self.idTextFieldConfigration.errorMsg forKey:@"error_type"];
                }
            }
        };
        
        [self.idTextFieldConfigration textFieldEndEdit];
    }
    
    // 失焦时校验手机号码 非返显手机号状态下如果有内容并且内容不合法就提示错误信息
    if (textContainer == self.phoneContainer) {
        [self p_updateAuthPhoneTipsView];
        BOOL isLegal = YES;
        if (!self.isPhoneNumReverseDisplay && ![self p_isPhoneNumValid] && ![self.phoneContainer.textField.userInputContent isEqualToString:@""]) {
            [self.phoneContainer updateTips:CJPayLocalizedStr(@"请输入正确的手机号码")];
            isLegal = NO;
        }
        BOOL hasInput = self.phoneContainer.textField.userInputContent.length > 0;
        if (hasInput) {
            
            NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
            [params addEntriesFromDictionary:@{
                @"input_type" : @"mobile",
                @"is_legal" : isLegal ? @"1" : @"0"
            }];
            [self trackWithEventName:@"wallet_addbcard_page_input_inform_verif_info" params:[params copy]];
        }
    }
    
    if (textContainer == self.nameContainer) {
        BOOL isLegal = YES;
        NSString *errorType = @"";
        
        if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
            [self p_setOCRButtonHidden:NO];

        }
        if (self.nameContainer.textField.userInputContent.length == 1) {
            [self.nameContainer updateTips:CJPayLocalizedStr(@"姓名输入不完整，请检查")];
            errorType = @"姓名不完整";
            isLegal = NO;
        } else if ([self p_isContainSpecialCharacterInIDCardName]){
            [self.nameContainer updateTips:CJPayLocalizedStr(@"姓名含有特殊字符，请检查")];
        }
        
        if ([self p_isNameInvalid] && self.nameContainer.textField.userInputContent.length > 0) {
            errorType = @"姓名含有特殊字符";
            isLegal = NO;
        }
        
        BOOL hasInput = self.nameContainer.textField.userInputContent.length > 0;
        if (hasInput) {
            NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
            [params addEntriesFromDictionary:@{
                @"input_type" : @"userName",
                @"is_legal" : isLegal ? @"1" : @"0"
            }];
            
            [self trackWithEventName:@"wallet_addbcard_page_input_inform_verif_info" params:[params copy]];
        }
    }
    
    [self p_updateTextFeildHeight];
}

- (void)textFieldWillClear:(CJPayCustomTextFieldContainer *)textContainer {
    self.nextStepButton.enabled = NO;
    if (self.phoneContainer == textContainer) {
        if (self.isPhoneNumReverseDisplay) {
            self.isPhoneNumReverseDisplay = NO;
            self.phoneContainer.textField.supportSeparate = YES;
        }
    }
}

- (void)textFieldDidClear:(CJPayCustomTextFieldContainer *)textContainer {
    [textContainer updateTips:@""];
    if (textContainer == self.phoneContainer) {
        [self p_updateAuthPhoneTipsView];
    }
    [self p_updateTextFeildHeight];
    if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
        [self p_setOCRButtonHidden:NO];
    }
}

#pragma mark CJPayBindCardChooseIDTypeDelegate
- (void)didSelectIDType:(CJPayBindCardChooseIDType)idType {
    // 切换证件类型以后，清空证件号输入框，清空错误提示，将按钮置为不可用
    if (idType != self.selectedIDType) {
        [self.identityContainer updateTips:@""];
        [self.identityContainer clearText];
        self.nextStepButton.enabled = NO;
        
        // 如果在展示授权浮窗前切换了证件类型，则以后不会展示授权浮窗
        if (self.containerMaskView.superview == self.scrollContentView) {
            [self.containerMaskView removeFromSuperview];
            self.hasShownAuthTipsView = YES;
        }
    }

    if (idType == CJPayBindCardChooseIDTypeHK) {
        self.nameContainer.infoContentStr = CJPayLocalizedStr(@"请输入银行卡的开户名称，如，Zhang San、张三");
    } else if (idType == CJPayBindCardChooseIDTypeTW) {
        self.nameContainer.infoContentStr = CJPayLocalizedStr(@"请输入银行卡的开户名称，如，Zhang San、张三");
    } else {
        self.nameContainer.infoContentStr = @"";
    }
    
    self.selectedIDType = idType;
    
    if (self.selectedIDType == CJPayBindCardChooseIDTypeNormal) {
        [self p_setOCRButtonHidden:NO];
    } else {
        [self p_setOCRButtonHidden:YES];
    }
    
    [self p_updateIDTypeInfo];
    [self trackWithEventName:@"wallet_addbcard_page_cardtype_page_click" params:[self p_bankTrackerParamsWithCertType]];
    [self p_updateTextFeildHeight];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 设置指定子视图不接受VC的手势事件
    if ([touch.view isDescendantOfView:self.protocolView]) {
        return NO;
    }

    return YES;
}

#pragma mark - getter & setter

- (CJPayBindCardScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[CJPayBindCardScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.bounces  = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
        _scrollContentView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _scrollContentView;
}

- (UIView *)centerContentView {
    if (!_centerContentView) {
        _centerContentView = [[UIView alloc] init];
        _centerContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _centerContentView.layer.cornerRadius = 8;
    }
    return _centerContentView;
}

- (CJPayBindCardTopHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [CJPayBindCardTopHeaderView new];
    }
    return _headerView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
    }
    return _backgroundImageView;
}

- (CJPayBindCardChooseView *)bankCardView {
    if (!_bankCardView) {
        _bankCardView = [[CJPayBindCardChooseView alloc] init];
        _bankCardView.translatesAutoresizingMaskIntoConstraints = NO;
        _bankCardView.isClickStyle = NO;
    }
    return _bankCardView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

- (CJPayBindCardChooseView *)identityView {
    if (!_identityView) {
        _identityView = [[CJPayBindCardChooseView alloc] init];
        _identityView.translatesAutoresizingMaskIntoConstraints = NO;
        _identityView.isClickStyle = YES;
        _identityView.rightImageView.hidden = NO;
    }
    return _identityView;
}

- (CJPayBindCardChooseView *)nationalityView {
    if (!_nationalityView) {
        _nationalityView = [[CJPayBindCardChooseView alloc] init];
        _nationalityView.translatesAutoresizingMaskIntoConstraints = NO;
        _nationalityView.isClickStyle = YES;
        _nationalityView.rightImageView.hidden = NO;
        [_nationalityView updateWithMainStr:CJPayLocalizedStr(@"国家/地区") subStr:CJPayLocalizedStr(@"请选择国家/地区")];
    }
    return _nationalityView;
}

- (CJPayCustomTextFieldContainer *)nameContainer {
    if (!_nameContainer) {
        _nameContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypeName style:CJPayCustomTextFieldContainerStyleWhiteAndBottomTips];
        _nameContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _nameContainer.keyBoardType = CJPayKeyBoardTypeSystomDefault;
        _nameContainer.delegate = self;
        _nameContainer.placeHolderText = CJPayLocalizedStr(@"输入持卡人姓名");
        @CJWeakify(self)
        _nameContainer.infoClickBlock = ^{
            @CJStrongify(self)
            [self p_endEditMode];
            NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
            [params addEntriesFromDictionary:@{@"type" : @"姓名"}];
            [self trackWithEventName:@"wallet_addbcard_page_info_check" params:[params copy]];
            [self p_nativeAlertViewWithTitle:self.nameContainer.infoContentStr];
        };
    }
    return _nameContainer;
}

- (CJPayCustomTextFieldContainer *)identityContainer {
    if (!_identityContainer) {
        _identityContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypeIdentity style:CJPayCustomTextFieldContainerStyleWhiteAndBottomTips];
        _identityContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _identityContainer.keyBoardType = CJPayKeyBoardTypeCustomXEnable;
        _identityContainer.delegate = self;
        _identityContainer.placeHolderText = CJPayLocalizedStr(@"输入持卡人证件号");
        @CJWeakify(self)
        _identityContainer.infoClickBlock = ^{
            @CJStrongify(self)
            NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
            [params addEntriesFromDictionary:@{@"type" : @"证件号码"}];
            [self trackWithEventName:@"wallet_addbcard_page_info_check" params:[params copy]];
            
            [self p_endEditMode];
            if (Check_ValidString(self.identityContainer.infoContentStr)) {
                if (self.selectedIDType == CJPayBindCardChooseIDTypePD) {
                    CJPayPassPortAlertView *alertView = [CJPayPassPortAlertView alertControllerWithTitle:CJString(self.identityContainer.infoContentStr) withActionTitle:CJPayLocalizedStr(@"知道了")];
                    
                    [self.view addSubview:alertView];
                    CJPayMasMaker(alertView, {
                        make.edges.mas_equalTo(self.view);
                    });
                } else {
                    [self p_nativeAlertViewWithTitle:self.identityContainer.infoContentStr];
                }
            }
        };
    }
    return _identityContainer;
}

- (CJPayCustomTextFieldConfigration *)idTextFieldConfigration {
    switch (self.selectedIDType) {
        case CJPayBindCardChooseIDTypeHK:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayHKIDTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayHKIDTextFieldConfigration new];
            }
            break;
        case CJPayBindCardChooseIDTypeTW:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayTWIDTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayTWIDTextFieldConfigration new];
            }
            break;
        case CJPayBindCardChooseIDTypePD:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayPDIDTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayPDIDTextFieldConfigration new];
            }
            break;
        case CJPayBindCardChooseIDTypeNormal:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayNormalIDTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayNormalIDTextFieldConfigration new];
            }
            break;
        case CJPayBindCardChooseIDTYpeHKRP:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayHKRPTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayHKRPTextFieldConfigration new];
            }
            break;
        case CJPayBindCardChooseIDTYpeTWRP:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayTWRPTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayTWRPTextFieldConfigration new];
            }
            break;
        default:
            if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayCustomTextFieldConfigration.class]) {
                _idTextFieldConfigration = [CJPayCustomTextFieldConfigration new];
            }
            break;
    }
    return _idTextFieldConfigration;
}


- (CJPayButton *)ocrButton {
    if (!_ocrButton) {
        _ocrButton = [CJPayButton new];
        [_ocrButton cj_setBtnImageWithName:@"cj_ocr_scan_camera_icon"];
        [_ocrButton addTarget:self action:@selector(p_ocrButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _ocrButton.alpha = 0.75;
    }
    return _ocrButton;
}

- (CJPayCustomTextFieldContainer *)phoneContainer {
    if (!_phoneContainer) {
        _phoneContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypePhone style:CJPayCustomTextFieldContainerStyleWhiteAndBottomTips];
        _phoneContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _phoneContainer.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
        _phoneContainer.delegate = self;
        _phoneContainer.placeHolderText = CJPayLocalizedStr(@"输入银行预留手机号");
    }
    return _phoneContainer;
}

- (CJPayBindCardAuthPhoneTipsView *)authPhoneTipsView
{
    if (!_authPhoneTipsView) {
        _authPhoneTipsView = [CJPayBindCardAuthPhoneTipsView new];
        [_authPhoneTipsView updatePhoneNumber:self.viewModel.userInfo.uidMobileMask];
        _authPhoneTipsView.alpha = 0;
        @CJWeakify(self)
        _authPhoneTipsView.clickAuthButtonBlock = ^{
            @CJStrongify(self)
            [self trackWithEventName:@"wallet_addbcard_page_phoneauth_click" params:[self p_bankTrackerParamsWithCertType]];
            
            [self p_fetchAuthPhoneNumber];
        };
        _authPhoneTipsView.clickCloseButtonBlock = ^{
            @CJStrongify(self)
            
            [self trackWithEventName:@"wallet_addbcard_page_phoneauth_close" params:nil];
            
            self.isCloseAuthPhoneTips = YES;
            [self p_updateAuthPhoneTipsView];
        };
    }
    return _authPhoneTipsView;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
        _protocolView.translatesAutoresizingMaskIntoConstraints = NO;
        _protocolView.clipsToBounds = YES;
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            NSString *nameList = [NSString new];
            if ([[agreements valueForKey:@"name"] isKindOfClass:[NSArray class]]) {
                nameList = [((NSArray *)[agreements valueForKey:@"name"]) componentsJoinedByString:@","];
            }
            [self trackWithEventName:@"wallet_agreement_click" params:@{
                @"agreement_type" : CJString(nameList)
            }];
        };
    }
    return _protocolView;
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        _nextStepButton = [[CJPayStyleButton alloc] init];
        [_nextStepButton setTitleColor:[UIColor cj_colorWithHexString:@"ffffff"] forState:UIControlStateNormal];
        [_nextStepButton setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
        _nextStepButton.layer.cornerRadius = 5;
        _nextStepButton.layer.masksToBounds = YES;
        _nextStepButton.cjEventInterval = 2;
        _nextStepButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_nextStepButton addTarget:self action:@selector(p_nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _nextStepButton.enabled = NO;
    }
    return _nextStepButton;
}

// 遮罩，负责拦截输入框第一次点击事件
- (UIView *)containerMaskView {
    if (!_containerMaskView) {
        _containerMaskView = [UIView new];
        _containerMaskView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *maskTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_clickContainerMaskview)];
        [_containerMaskView addGestureRecognizer:maskTapGesture];
    }
    return _containerMaskView;
}

- (void)setIsPhoneNumReverseDisplay:(BOOL)isPhoneNumReverseDisplay {
    _isPhoneNumReverseDisplay = isPhoneNumReverseDisplay;
    if (!isPhoneNumReverseDisplay) {
        self.isUseAuthPhoneNumber = NO;
    }
}

- (UILabel *)scrollServiceLabel {
    if (!_scrollServiceLabel) {
        _scrollServiceLabel = [[UILabel alloc] init];
        _scrollServiceLabel.font = [UIFont cj_fontOfSize:12];
        _scrollServiceLabel.textColor = [UIColor cj_cacacaff];
        _scrollServiceLabel.textAlignment = NSTextAlignmentCenter;
        _scrollServiceLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
        _scrollServiceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _scrollServiceLabel;
}

- (NSString *)nationalitySelectionURL {
    if (!_nationalitySelectionURL) {
        _nationalitySelectionURL = [NSString stringWithFormat:@"%@/cardbind/options/nationality", [CJPayBaseRequest bdpayH5DeskServerHostString]];
    }
    return _nationalitySelectionURL;
}

#pragma mark -  track & CJPayTrackerProtocol

- (void)trackWithEventName:(NSString *)eventName
                    params:(nullable NSDictionary *)params {
    NSDictionary *baseDic = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] initWithDictionary:baseDic];
    if (params) {
        [paramsDic addEntriesFromDictionary:params];
    }
    
    [CJTracker event:eventName params:paramsDic];
}

- (NSDictionary *)p_bankTrackerParamsWithCertType {
    NSString *selectedType = [CJPayBindCardChooseIDTypeModel getIDTypeStr:self.selectedIDType];
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    [params addEntriesFromDictionary:@{@"type" : CJString(selectedType)}];
    
    return [params copy];
}

- (NSDictionary *)p_bankTrackerParams {
    NSMutableDictionary *cardTypeNameDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"DEBIT" : @"储蓄卡",
        @"CREDIT" : @"信用卡"
    }];
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.viewModel.memCardBinResponse toActivityInfoTracker];
    if (activityInfo.count > 0 ) {
        [activityInfos addObject:activityInfo];
    }
    
    return @{
        @"bank_name" : CJString(self.viewModel.cardInfoModel.bankName),
        @"bank_type" : CJString([cardTypeNameDic cj_stringValueForKey:CJString(self.viewModel.cardInfoModel.cardType)]),
        @"activity_info" : activityInfos
    };
}

- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self trackWithEventName:event params:params];
}

@end
