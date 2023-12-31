//
//  CJPayAuthVerifyViewController.m
//  Pods
//
//  Created by xiuyuanLee on 2020/10/12.
//

#import "CJPayAuthVerifyViewController.h"

#import "CJPayStyleButton.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayAlertUtil.h"
#import "CJPayNormalIDTextFieldConfigration.h"
#import "CJPayBindCardValidateManager.h"
#import "CJPayQuickPayUserAgreement.h"
#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBindCardManager.h"
#import "CJPayMemVerifyBizOrderRequest.h"
#import "CJPayMemVerifyBizOrderResponse.h"
#import "CJPayMemProtocolListResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayToast.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayUserInfo.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayBizAuthViewController.h"
#import "CJPayBindCardScrollView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardTopHeaderView.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayAuthAgreementContentModel.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayQuickBindCardKeysDefine.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayIDCardProfileOCRViewController.h"
#import "CJPaySettingsManager.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayBindCardRetainInfo.h"
#import "CJPayUnionBindCardPlugin.h"
#import "CJPayNavigationController.h"
#import "CJPayNativeBindCardPlugin.h"

#define CJ_BACKGROUND_LOGO_WIDTH 200
#define CJ_STANDARD_WIDTH 375.0

@implementation BDPayAuthVerifyModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"processInfo" : CJPayBindCardShareDataKeyProcessInfo,
        @"isBizAuthVCShown" : CJPayBindCardShareDataKeyIsBizAuthVCShown,
        @"jumpQuickBindCard" : CJPayBindCardShareDataKeyJumpQuickBindCard,
        @"bindCardInfo" : CJPayBindCardShareDataKeyBindCardInfo,
        @"memCreatOrderResponse" : CJPayBindCardShareDataKeyMemCreatOrderResponse,
        @"bizAuthInfo" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"quickBindCardModel" : CJPayBindCardShareDataKeyQuickBindCardModel,
        @"isQuickBindCard" : CJPayBindCardShareDataKeyIsQuickBindCard,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"title" : CJPayBindCardShareDataKeyTitle,
        @"subTitle" : CJPayBindCardShareDataKeySubTitle,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"displayIcon" : CJPayBindCardShareDataKeyDisplayIcon,
        @"displayDesc" : CJPayBindCardShareDataKeyDisplayDesc,
        @"frontIndependentBindCardSource" : CJPayBindCardShareDataKeyFrontIndependentBindCardSource,
        @"trackerParams" : CJPayBindCardShareDataKeyTrackerParams,
        @"selectedCardType" : CJPayQuickBindCardPageParamsKeySelectedCardType,
        @"isNeedCreateOrder": CJPayQuickBindCardPageParamsKeyIsNeedCreateSignOrder,
        @"selectedCardTypeVoucher" : CJPayBindCardPageParamsKeySelectedCardTypeVoucher,
        @"unionCommonModel" :CJPayBindCardShareDataKeyUnionBindCardCommonModel,
        @"bindUnionCardType" : CJPayBindCardShareDataKeyBindUnionCardType,
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

@interface CJPayAuthVerifyViewController () <CJPayCustomTextFieldContainerDelegate, UIGestureRecognizerDelegate, CJPayBindCardPageProtocol, CJPayTrackerProtocol>

#pragma mark - view
@property (nonatomic, strong) CJPayBindCardScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) UIView *whiteGroundView;
@property (nonatomic, strong) UIImageView *authImageView;
@property (nonatomic, strong) UILabel *authTitle;
@property (nonatomic, strong) UILabel *authVerifyTipsLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayBindCardTopHeaderView *headerView;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) CJPayButton *ocrButton;

// 输入框遮罩，拦截第一次“nameContainer + identityContainer”的点击事件
@property (nonatomic, strong) UIView *containerMaskView;
// 姓名输入
@property (nonatomic, strong) CJPayCustomTextFieldContainer *nameContainer;
// 证件号输入
@property (nonatomic, strong) CJPayCustomTextFieldContainer *identityContainer;
@property (nonatomic, strong) CJPayCustomTextFieldConfigration *idTextFieldConfigration;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) UILabel *doNotHaveIDCardLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) UIView *emptyView;
@property (nonatomic, strong) UIView *curFoucsView;
@property (nonatomic, assign) NSTimeInterval startPollingTime;

#pragma mark - data
@property (nonatomic, strong) void(^completionBlock)(BOOL);
@property (nonatomic, strong) BDPayAuthVerifyModel *viewModel;

@property (nonatomic, strong) CJPayCreateOneKeySignOrderResponse *oneKeyCreateOrderResponse;

@property (nonatomic, assign) BOOL isCardOCR;
@property (nonatomic, strong) CJPayCardOCRResultModel *latestOCRModel;
@property (nonatomic, assign) NSTimeInterval oneKeyBeginTimeInterval; //点击授权按钮|点击确认按钮时间
@property (nonatomic, assign) double enterTimestamp;

@end

@implementation CJPayAuthVerifyViewController

+ (Class)associatedModelClass {
    return [BDPayAuthVerifyModel class];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        self.viewModel = [[BDPayAuthVerifyModel alloc] initWithDictionary:dict error:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupAuthVerifyTips];
    [self p_updateProtocolView];
    
    if ([self p_isBizAuthHalfPage]) {
        [self p_showBizAuthViewController];
    } else{
        BOOL isHadShowCachedInfo = [self p_showCachedIdentityInfo];
        if (!isHadShowCachedInfo) {
            [self.nameContainer.textField becomeFirstResponder];
        }
    }
    
    // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [self p_trackWithEventName:@"wallet_two_elements_identified_page_imp" params:@{
        @"twoelements_verify_status" : CJString(self.viewModel.userInfo.authStatus)
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0];
    self.enterTimestamp = [dt timeIntervalSince1970]*1000;
}

- (void)back
{
    [self p_cacheIdentityInfo];
    __block BOOL shouldReturn = NO;
    @CJWeakify(self)
    [self.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if ([obj isKindOfClass:NSClassFromString(@"CJPayBindCardBaseViewController")] || [obj isKindOfClass:NSClassFromString(@"CJPayQuickBindCardTypeChooseViewController")]) {
            [self.navigationController popToViewController:obj animated:YES];
            *stop = YES;
            shouldReturn = YES;
        }
    }];
    if (shouldReturn) {
        return;
    }
    
    if (![[CJPayBindCardManager sharedInstance] cancelBindCard]) {
        [super back];
    }
}

- (void)p_cacheIdentityInfo {
    if (![self p_isNameValid] || ![self p_isIdentityValid] || ![self.idTextFieldConfigration contentISValid]|| ![self p_isNeedSaveUserInfo]) {
        return;
    }
    CJPayBindCardCachedIdentityInfoModel *model = self.viewModel.cachedInfoModel ?: [CJPayBindCardCachedIdentityInfoModel new];
    model.name = self.nameContainer.textField.text;
    model.identity = self.identityContainer.textField.text;
    model.selectedIDType = CJPayBindCardChooseIDTypeNormal;
    if (!self.viewModel.cachedInfoModel) { //首次缓存时记录时间
        model.cachedBeginTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    }
    
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
        CJPayBindCardShareDataKeyCachedIdentityInfoModel: [model toDictionary] ?: @{}
    } completion:nil];
}

- (BOOL)p_isNeedSaveUserInfo {
    return [self.viewModel.retainInfo.isNeedSaveUserInfo isEqualToString:@"Y"];
}

- (BOOL)p_showCachedIdentityInfo {
    if (![self p_isNeedSaveUserInfo]) {
        return NO;
    }
    NSTimeInterval currentTime = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970];
    CJPayBindCardCachedIdentityInfoModel *model = self.viewModel.cachedInfoModel;
    if (!model) { //无缓存
        return NO;
    }
    
    NSInteger cacheDuration = [CJPaySettingsManager shared].currentSettings.bindCardUISettings.userInputCacheDuration;
    if (currentTime - self.viewModel.cachedInfoModel.cachedBeginTime > cacheDuration) { //超时，不反显并清空缓存
        [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{
            CJPayBindCardShareDataKeyCachedIdentityInfoModel: @{}
        } completion:nil];
        return NO;
    }
    
    if (model.selectedIDType != CJPayBindCardChooseIDTypeNormal) { //非身份证类型不反显
        return NO;
    }
    [self.nameContainer preFillText:CJString(model.name)];
    [self.identityContainer preFillText:CJString(model.identity)];
    self.nextStepButton.enabled = YES;
    return YES;
}

#pragma mark - Private Methods
- (void)p_setupUI {    
    [self.view addSubview:self.scrollView];
    
    UITapGestureRecognizer *endEditGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEditMode)];
    endEditGesture.delegate = self;
    endEditGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:endEditGesture];
    
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.protocolView];
    [self.scrollContentView addSubview:self.nextStepButton];
    [self.scrollContentView addSubview:self.emptyView];
    
    CJPayMasMaker(self.scrollView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
        make.width.equalTo(self.view);
    });
    
    [self.scrollContentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        make.height.mas_greaterThanOrEqualTo(self.scrollView);
    }];
        
    [self p_setupSafetyUI];
    
    self.emptyView.backgroundColor = self.view.backgroundColor;
    CJPayMasMaker(self.emptyView, {
        make.left.right.equalTo(self.scrollContentView);
        make.top.equalTo(self.nextStepButton.mas_bottom).offset(20);
        make.height.equalTo(@20);
    })
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.scrollContentView addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.centerX.equalTo(self.scrollContentView);
            make.top.greaterThanOrEqualTo(self.emptyView.mas_bottom);
            make.bottom.equalTo(self.scrollContentView).offset(-16-CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
        });
    }
    
    [self.idTextFieldConfigration bindTextFieldContainer:self.identityContainer];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)p_updateEmptyViewHeight:(CGFloat)height {
    CJPayMasUpdate(self.emptyView, {
        make.height.equalTo(@(height));
    });
    [self.scrollView setNeedsLayout];
    [self.scrollView layoutIfNeeded];
}

- (void)p_updateEmptyViewForRoll {
    
    //12-距离键盘的最小距离，（-42 - CJ_TabBarSafeBottomMargin - 16）安全险高度及其距离底部距离
    CGFloat emptyViewHeight = [self.identityContainer getKeyBoardHeight] + 12 - 42 - CJ_TabBarSafeBottomMargin - 16;
    [self p_updateEmptyViewHeight:emptyViewHeight];
    CGFloat contentOffsetY = self.scrollView.contentOffset.y > 0 ? : 0;
    self.scrollView.contentOffset = CGPointMake(0, self.scrollContentView.cj_height - self.scrollView.cj_height - contentOffsetY);
}

- (void)p_setupSafetyUI {
    [self.view insertSubview:self.backgroundView belowSubview:self.scrollContentView];
    self.view.backgroundColor = [UIColor cj_f8f8f8ff];
    self.navigationBar.backgroundColor = [UIColor cj_f8f8f8ff];
    [self.scrollContentView addSubview:self.headerView];
    [self.scrollContentView addSubview:self.whiteGroundView];
    [self.scrollContentView addSubview:self.tipsLabel];
    [self.scrollContentView addSubview:self.nameContainer];
    [self.nameContainer addSubview:self.ocrButton];
    [self p_setOCRButtonHidden:NO];
    [self.scrollContentView addSubview:self.identityContainer];
    [self.scrollContentView addSubview:self.protocolView];
    [self.scrollContentView addSubview:self.nextStepButton];
    [self p_refreshHeaderTitle];
    
    CJPayMasMaker(self.backgroundView, {
        make.top.right.equalTo(self.view);
        make.width.height.mas_equalTo(self.view.cj_width * CJ_BACKGROUND_LOGO_WIDTH / CJ_STANDARD_WIDTH);
    })
    
    CJPayMasMaker(self.headerView, {
        make.top.left.right.equalTo(self.scrollContentView);
        make.centerX.equalTo(self.scrollContentView);
    })
    
    CJPayMasMaker(self.whiteGroundView, {
        make.top.equalTo(self.headerView.mas_bottom);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
    })
    
    CJPayMasMaker(self.tipsLabel, {
        make.top.equalTo(self.whiteGroundView).offset(12);
        make.left.equalTo(self.whiteGroundView).offset(16);
        make.height.mas_equalTo(24);
    })
    
    CJPayMasMaker(self.nameContainer, {
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(12);
        make.left.equalTo(self.whiteGroundView);
        make.right.equalTo(self.whiteGroundView);
        make.height.mas_equalTo(60);
    })
    
    CJPayMasMaker(self.ocrButton, {
        make.top.equalTo(self.nameContainer).offset(18);
        make.right.equalTo(self.whiteGroundView).offset(-16);
        make.width.height.mas_offset(24);
    })

    CJPayMasMaker(self.identityContainer, {
        make.top.equalTo(self.nameContainer.mas_bottom);
        make.left.equalTo(self.whiteGroundView);
        make.right.equalTo(self.whiteGroundView);
        make.height.mas_equalTo(60);
    })
    
    CJPayMasMaker(self.protocolView, {
        make.top.mas_equalTo(self.identityContainer.mas_bottom).offset(36);
        make.left.equalTo(self.whiteGroundView).offset(16);
        make.right.equalTo(self.whiteGroundView).offset(-16);
    })
    
    CJPayMasMaker(self.nextStepButton, {
        make.top.mas_equalTo(self.protocolView.mas_bottom).offset(12);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        make.left.equalTo(self.whiteGroundView).offset(16);
        make.right.equalTo(self.whiteGroundView).offset(-16);
        make.bottom.equalTo(self.whiteGroundView.mas_bottom).offset(-24);
    })
    
}

- (void)p_setupAuthVerifyTips {    
    NSString *headStr = [NSString stringWithFormat:CJPayLocalizedStr(@"实名认证后可进行%@快速绑卡"), CJString(self.viewModel.quickBindCardModel.bankName)];
    NSString *tailStr = [NSString stringWithFormat:@"%@", CJPayLocalizedStr(@"，请使用本人信息完成认证")];
    
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13]};
    NSDictionary *weakAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:13],
                                     NSForegroundColorAttributeName : [UIColor cj_999999ff]};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:CJString(headStr) attributes:mainAttributes];
    [attributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:CJString(tailStr) attributes:weakAttributes]];
    
    self.authVerifyTipsLabel.attributedText = attributedString;
}

- (void)p_refreshHeaderTitle {
    CJPayBindCardTopHeaderViewModel *model = [CJPayBindCardTopHeaderViewModel new];
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        model.preTitle = CJPayLocalizedStr(@"同步");
        model.title = CJPayLocalizedStr(@"云闪付银行卡");
        model.bankIcon = self.viewModel.quickBindCardModel.iconUrl;
        if (!Check_ValidString(model.bankIcon)) {
            model.bankIcon = self.viewModel.unionCommonModel.unionIconUrl;
        }
        model.displayDesc = self.viewModel.unionCommonModel.unionPaySignInfo.displayDesc;
        model.displayIcon = self.viewModel.unionCommonModel.unionPaySignInfo.displayIcon;
        model.voucherMsg = self.viewModel.selectedCardTypeVoucher;
        [self.headerView updateWithModel:model];
        return;
    }
    
    model.preTitle = @"";
    model.orderAmount = self.viewModel.orderAmount;

    model.bankIcon = self.viewModel.quickBindCardModel.iconUrl;
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign) {
        model.title = CJPayLocalizedStr(@"云闪付银行卡");
    } else if (self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay) {
        model.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.quickBindCardModel.bankName, @"卡支付"];
    } else {
        model.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.quickBindCardModel.bankName, @"卡"];
    }
    model.displayDesc = self.viewModel.displayDesc;
    model.displayIcon = self.viewModel.displayIcon;
    model.voucherMsg = self.viewModel.selectedCardTypeVoucher;
        
    model.displayDesc = self.viewModel.displayDesc;
    model.displayIcon = self.viewModel.displayIcon;
    model.voucherMsg = self.viewModel.selectedCardTypeVoucher;
    [self.headerView updateWithModel:model];
    
}

- (NSAttributedString *)p_generateAttributedStringWith:(NSString *)content
                                           textColor:(UIColor *)color
                                                font:(UIFont *)font {
    // 飞书通用文案展示规则 https://bytedance.feishu.cn/docs/doccnjhauFqvGLXX45UuUWAiqdd
    NSString *divChar = @"$";
    NSArray<NSString *> *separateStringArr = [content componentsSeparatedByString:divChar];
    NSInteger divCharCount = [separateStringArr count] - 0;
    
    NSDictionary *mainAttributes = @{NSFontAttributeName : font};
    NSDictionary *weakAttributes = @{NSFontAttributeName : font,
                                     NSForegroundColorAttributeName : color};
    
    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    
    __block NSInteger mainAttributesCount = divCharCount / 2;
    
    [separateStringArr enumerateObjectsUsingBlock:^(NSString * _Nonnull strObj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 深色文案
        if (idx % 2 != 0 && mainAttributesCount > 0) {
            [attributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:CJString(strObj) attributes:mainAttributes]];
            mainAttributesCount--;
        } else if (idx % 2 == 0) {
            // 浅色文案
            [attributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:CJString(strObj) attributes:weakAttributes]];
        }
    }];
    
    return [attributedString copy];
}

- (void)p_updateProtocolView {
    [CJPayProtocolViewManager fetchProtocolListWithParams:[self p_buildBDPayProtocolListQueryParam] completion:^(NSError * _Nonnull error, CJPayMemProtocolListResponse * _Nonnull response) {
        if (![response isSuccess]) {
            return;
        }
        CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
        commonModel.guideDesc = Check_ValidString(response.guideMessage) ? response.guideMessage : CJPayLocalizedStr(@"阅读并同意");
        commonModel.groupNameDic = response.protocolGroupNames;
        commonModel.agreements = response.agreements;
        commonModel.protocolCheckBoxStr = response.protocolCheckBox;
        commonModel.supportRiskControl = YES;
        self.viewModel.bizAuthInfo.protocolCheckBox = response.protocolCheckBox;
        [self.protocolView updateWithCommonModel:commonModel];
    }];
}

- (void)p_nextButtonClick {
    if (![self p_isIDCardNumExtremeValidate]) {
        return;
    }
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeTwoElementsValidation];
    [self.view endEditing:YES];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    double currentTimestamp = [date timeIntervalSince1970] * 1000;

    [self p_trackWithEventName:@"wallet_rd_custom_scenes_time" params:@{
        @"scenes_name" : @"绑卡",
        @"sub_section" : @"完成二要素输入",
        @"time" : @(currentTimestamp - self.enterTimestamp)
    }];
    
    bool isUnionBindCard = self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign ||
    self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind;
    @CJWeakify(self)
    [self.protocolView executeWhenProtocolSelected:^{
        @CJStrongify(self)
        if ([[CJPayABTest getABTestValWithKey:CJPayABBindCardNotRealnameApi] isEqualToString:@"1"] && !isUnionBindCard) {
            [self p_bindCardNextStep];
        } else {
            [self p_authVerify];
        }
    } notSeleted:^{
        @CJStrongify(self)
        CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.protocolView.protocolModel from:@"二要素"];
        popupProtocolVC.confirmBlock = ^{
            @CJStrongify(self)
            
            [self.protocolView setCheckBoxSelected:YES];
            if ([[CJPayABTest getABTestValWithKey:CJPayABBindCardNotRealnameApi] isEqualToString:@"1"] && !isUnionBindCard) {
                [self p_bindCardNextStep];
            } else {
                [self p_authVerify];
            }
        };
        [self.navigationController pushViewController:popupProtocolVC animated:YES];
        return;
    } hasToast:NO];
}

- (NSMutableDictionary *)p_buildBDPayMemVerifyParamInHalfBizAuthView:(BOOL)isHalfBizAuthView {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.viewModel.appId forKey:@"app_id"];
    [bizParams cj_setObject:self.viewModel.merchantId forKey:@"merchant_id"];
    [bizParams cj_setObject:isHalfBizAuthView ? CJString(self.viewModel.memCreatOrderResponse.bizAuthInfoModel.idNameMask) : CJString(self.nameContainer.textField.userInputContent) forKey:@"name"];
    [bizParams cj_setObject:isHalfBizAuthView ? CJString(self.viewModel.memCreatOrderResponse.bizAuthInfoModel.idType) : @"ID_CARD" forKey:@"identity_type"];
    [bizParams cj_setObject:isHalfBizAuthView ? CJString(self.viewModel.memCreatOrderResponse.bizAuthInfoModel.idCodeMask) : CJString(self.identityContainer.textField.userInputContent) forKey:@"identity_code"];
    
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign ||
        self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        [bizParams cj_setObject:CJString(self.viewModel.unionCommonModel.unionPaySignInfo.identityVerifyOrderNo) forKey:@"member_biz_order_no"];
    } else {
        [bizParams cj_setObject:CJString(self.viewModel.memCreatOrderResponse.memberBizOrderNo) forKey:@"member_biz_order_no"];
    }
    
    return bizParams;
}

- (NSMutableDictionary *)p_buildBDPayProtocolListQueryParam {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.viewModel.appId forKey:@"app_id"];
    [bizParams cj_setObject:self.viewModel.merchantId forKey:@"merchant_id"];
    [bizParams cj_setObject:@"verify_identity_info" forKey:@"biz_order_type"];
    [bizParams cj_setObject:self.viewModel.selectedCardType forKey:@"card_type"];
    [bizParams cj_setObject:self.viewModel.quickBindCardModel.bankCode forKey:@"bank_code"];
    return bizParams;
}


- (void)p_showNoNetworkToast {
    [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
}

- (void)p_endEditMode {
    [self.view endEditing:YES];
}

- (BOOL)p_isIDCardNumExtremeValidate {
    if (![self p_isIdentityValid]) {
        @CJWeakify(self)
        [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"请输入正确的证件号码")
                                           content:@""
                                        buttonDesc:CJPayLocalizedStr(@"我知道了")
                                       actionBlock:^{
            @CJStrongify(self)
            [self.identityContainer updateTips:CJPayLocalizedStr(@"请输入正确的证件号码")];
            [self.identityContainer.textField becomeFirstResponder];
                    
        } useVC:self];

        return NO;
    }
    return YES;
}

// 判断是否需要展示半屏实名授权页
- (BOOL)p_isBizAuthHalfPage {
    CJPayBizAuthInfoModel *bizAuthInfoModel = self.viewModel.memCreatOrderResponse.bizAuthInfoModel;
    
    return bizAuthInfoModel.isNeedAuthorize && !self.viewModel.isBizAuthVCShown;
}

- (void)p_showBizAuthViewController {
    self.viewModel.isBizAuthVCShown = YES;
    NSDictionary *dict = @{CJPayBindCardShareDataKeyIsBizAuthVCShown: @(YES)}; // 标记为已经展示过半屏授权弹窗
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:nil];
    UIViewController *halfBizAuthVC;
    if(self.viewModel.bizAuthInfo.protocolCheckBox) {
        halfBizAuthVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfBizAuth params:@{
            CJPayBindCardPageParamsKeyIsProtocolCheckBox:self.viewModel.bizAuthInfo.protocolCheckBox,
        } completion:nil];
    } else {
        halfBizAuthVC = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfBizAuth params:nil completion:nil];
    }
    CJPayBizAuthViewController *bizAuthVC;
    if ([halfBizAuthVC isKindOfClass:CJPayBizAuthViewController.class]) {
        bizAuthVC = (CJPayBizAuthViewController *)halfBizAuthVC;
    }
    if (bizAuthVC == nil) {
        CJPayLogAssert(NO, @"创建授权弹框页面失败.");
        return;
    }
    bizAuthVC.from = @"two_elements";
    @CJWeakify(self)
    bizAuthVC.noAuthCompletionBlock = ^(CJPayBizAuthCompletionType type) {
        @CJStrongify(self)
        [self.nameContainer.textField becomeFirstResponder];
    };
    
    @CJWeakify(bizAuthVC)
    bizAuthVC.authVerifiedBlock = ^{
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        self.oneKeyBeginTimeInterval = [date timeIntervalSince1970] * 1000;
        
        @CJStrongify(bizAuthVC)
        @CJStartLoading(bizAuthVC)
        
        [CJPayMemVerifyBizOrderRequest startWithBizParams:[self p_buildBDPayMemVerifyParamInHalfBizAuthView:YES] completion:^(NSError * _Nonnull error, CJPayMemVerifyBizOrderResponse * _Nonnull response) {
            
            @CJStrongify(bizAuthVC)
            @CJStopLoading(bizAuthVC)
            
            if (error || !response) {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
                return;
            }
            
            [self p_trackWithEventName:@"wallet_businesstopay_auth_result" params:@{
                @"result" : [response isSuccess] ? @"1" : @"0",
                @"url" : @"bytepay.member_product.verify_identity_info",
                @"error_code" : CJString(response.code),
                @"error_message" : CJString(response.msg),
                @"auth_type" : @"two_elements"
            }];
            
            if (![response isSuccess]) {
                if (response.buttonInfo) {
                    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
                    response.buttonInfo.code = response.code;
                    [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                      fromVC:self errorMsg:response.msg
                                                                 withActions:actionModel
                                                                   withAppID:self.viewModel.appId
                                                                  merchantID:self.viewModel.merchantId];
                    return;
                } else if ([response.code isEqualToString:@"MP010032"]) {
                    // 外籍证件刷新单号进入老用户绑卡
                                        
                    self.viewModel.userInfo.mName = CJString(self.viewModel.memCreatOrderResponse.bizAuthInfoModel.idNameMask);
                    NSDictionary *dict = @{CJPayBindCardShareDataKeySignOrderNo: CJString(response.signOrderNo),
                                           CJPayBindCardShareDataKeyUserInfo: [self.viewModel.userInfo toDictionary] ?: @{},
                                           CJPayBindCardShareDataKeyIsCertification: @(YES)
                    };
                    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:^(NSArray * _Nonnull modifyedKeysArray) {
                                    
                    }];
                    
                    [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep params:nil completion:nil];
                } else {
                    [CJToast toastText:CJString(response.msg) ?: CJPayNoNetworkMessage inWindow:self.cj_window];
                }
                return;
            }

            // 只有身份证用户会鉴权通过
            [bizAuthVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                
                if (self.viewModel.unionCommonModel) {
                    self.viewModel.userInfo.mName = CJString(self.viewModel.memCreatOrderResponse.bizAuthInfoModel.idNameMask);
                    NSMutableDictionary *dict = [@{
                        CJPayBindCardShareDataKeyUserInfo: [self.viewModel.userInfo toDictionary],
                        CJPayBindCardShareDataKeyIsCertification: @(YES)
                    } mutableCopy];
                    
                    if ([response.additionalVerifyType isEqualToString:@"live_detection"] && response.faceVerifyInfoModel) {

                        self.viewModel.unionCommonModel.unionPaySignInfo.additionalVerifyType = response.additionalVerifyType;
                        self.viewModel.unionCommonModel.unionPaySignInfo.faceVerifyInfoModel = response.faceVerifyInfoModel;
                        [dict cj_setObject:[self.viewModel.unionCommonModel toDictionary] ?: @{} forKey:CJPayBindCardShareDataKeyUnionBindCardCommonModel];
                        
                    }
                    
                    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:[dict copy] completion:^(NSArray * _Nonnull modifyedKeysArray) {
                                    
                    }];
                    
                    if(CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
                        [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) authAdditionalVerifyType:response.additionalVerifyType loadingStart:^{
                            @CJStrongify(bizAuthVC)
                            @CJStartLoading(bizAuthVC);
                        } loadingStopBlock:^{
                            @CJStrongify(bizAuthVC)
                            @CJStopLoading(bizAuthVC);
                        }];
                    }
                    else {
                        [CJToast toastText:@"不支持云闪付绑卡" inWindow:self.cj_window];
                    }
                    
                } else if (![self.viewModel.jumpQuickBindCard isEqualToString:@"1"]) {
                // 只有身份证会鉴权通过
                    [self p_bindCardNextStep];
                }
            }];
            return;
            
        }];
    };
}

- (void)p_gotoBindCard {
    CJ_DelayEnableView(self.view);
    [self p_trackWithEventName:@"wallet_two_elements_identified_page_next_click"
                        params:@{@"button_name" : @"0"}];
    
    [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeCommonQuickFrontFirstStep
                                          params:@{CJPayBindCardPageParamsKeyIsQuickBindCardListHidden : @(YES),
                                                   CJPayBindCardPageParamsKeyIsFromQuickBindCard: @(YES)}
                                      completion:nil];
}

- (void)p_authVerify {
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    self.oneKeyBeginTimeInterval = [date timeIntervalSince1970] * 1000;
    
    @CJStartLoading(self.nextStepButton)
    CJ_DelayEnableView(self.view);
    @CJWeakify(self)
    [CJPayMemVerifyBizOrderRequest startWithBizParams:[self p_buildBDPayMemVerifyParamInHalfBizAuthView:NO] completion:^(NSError * _Nonnull error, CJPayMemVerifyBizOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStopLoading(self.nextStepButton)
        
        [self p_trackWithEventName:@"wallet_two_elements_identified_page_next_click" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg),
            @"button_name" : @"1",
            @"auth_type" : @"two_elements"
        }];
        [self p_trackWithEventName:@"wallet_businesstopay_auth_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg),
            @"auth_type" : @"two_elements"
        }];
        if (error) {
            [self p_showNoNetworkToast];
            return;
        }
        
        if (![response isSuccess]) {
            if (response.buttonInfo) {
                CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];

                actionModel.logoutBizRealNameAction = ^{
                    // 去注销宿主端实名能力降级处理，只展示提示文案
                    @CJStrongify(self)
                    [self p_trackWithEventName:@"wallet_businesstopay_auth_fail_click"
                                        params:@{@"auth_type" : @"two_elements"}];
                    [self p_trackWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:[self p_trackerBankTypeParams:response]];
                };
                
                actionModel.closeAlertAction = ^{
                    @CJStrongify(self)
                    [self p_trackWithEventName:@"wallet_addbcard_onestepbind_error_pop_click" params:[self p_trackerBankTypeParams:response]];
                };
                
                actionModel.alertPresentAction = ^{
                    @CJStrongify(self)
                    [self p_trackWithEventName:@"wallet_businesstopay_auth_fail_imp"
                                        params:@{@"auth_type" : @"two_elements"}];
                    [self p_trackWithEventName:@"wallet_addbcard_onestepbind_error_pop_imp" params:[self p_trackerBankTypeParams:response]];
                };
                response.buttonInfo.trackCase = @"3.1";
                response.buttonInfo.code = response.code;
                [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                  fromVC:self
                                                                errorMsg:response.msg
                                                             withActions:actionModel
                                                               withAppID:self.viewModel.appId
                                                              merchantID:self.viewModel.merchantId];
                return;
            } else {
                [CJToast toastText:response.msg inWindow:self.cj_window];
                return;
            }
            return;
        }
        
        if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign ||
            self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
            @CJWeakify(self)
            if(CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin)) {
                [CJ_OBJECT_WITH_PROTOCOL(CJPayUnionBindCardPlugin) authAdditionalVerifyType:response.additionalVerifyType loadingStart:^{
                    @CJStrongify(self)
                    @CJStartLoading(self.nextStepButton);
                } loadingStopBlock:^{
                    @CJStrongify(self)
                    @CJStopLoading(self.nextStepButton);
                }];
            }
            else {
                [CJToast toastText:@"不支持云闪付绑卡" inWindow:self.cj_window];
            }
        } else {
            [self p_bindCardNextStep];
        }
    }];
}

- (void)p_bindCardNextStep {
    @CJWeakify(self)
    if (!self.viewModel.isNeedCreateOrder) {
        [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeQuickChooseCard params:nil completion:nil];
    } else {
        if (!CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            CJPayLogAssert(NO, @"没有接入native绑卡");
            return;
        }
        NSDictionary *params = @{@"start_one_key_time": @(self.oneKeyBeginTimeInterval),
                                 @"identity_code":CJString(self.identityContainer.textField.userInputContent),
                                 @"name":CJString(self.nameContainer.textField.userInputContent)};
        [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) startOneKeySignOrderFromVC:self
                                                                        signOrderModel:[self.viewModel toDictionary]
                                                                             extParams:params
                                                             createSignOrderCompletion:^(CJPayCreateOneKeySignOrderResponse * _Nonnull response) {
                                                                                @CJStrongify(self)
                                                                                self.oneKeyCreateOrderResponse = response;
                                                                            }
                                                                            completion:^(BOOL isFinished) {
                                                                                if (isFinished) {
                                                                                    [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) queryOneKeySignState];
                                                                                }}];
    }
}

- (BOOL)p_isNameValid {
    NSString *nameStr = self.nameContainer.textField.userInputContent;
    return [CJPayBindCardValidateManager isNameValid:nameStr] && ![self p_isContainSpecialCharacterInIDCardName];
}

- (BOOL)p_isIdentityValid {
    return [CJPayBindCardValidateManager isNormalIDCardNumExtremeValid:self.identityContainer.textField.userInputContent];
}

- (BOOL)p_isContainSpecialCharacterInIDCardName {
    BOOL isContainSpecialCharacterInName = NO;
    // 只有身份证证件时才判断姓名是否包含特殊字符
    NSString *nameStr = self.nameContainer.textField.userInputContent;
    if (nameStr.length) {
        isContainSpecialCharacterInName = [CJPayBindCardValidateManager isContainSpecialCharacterInString:nameStr];
    }
    
    return isContainSpecialCharacterInName;
}

- (BOOL)p_shouldOpenApp
{
    NSString *aid = [CJPayRequestParam gAppInfoConfig].appId;
    if (![aid isEqualToString:@"1128"]) {
        return NO;
    }
    
    NSString *bankCode = self.viewModel.quickBindCardModel.bankCode;
    return ([bankCode isEqualToString:@"CMB"] && [self.viewModel.selectedCardType isEqualToString:@"DEBIT"]);
}

- (void)p_updateTextFeildHeight {
    CJPayMasUpdate(self.nameContainer, {
        make.height.mas_equalTo([self.nameContainer hasTipsText] ? 66 : 60);
    });
    
    CJPayMasUpdate(self.identityContainer, {
        make.height.mas_equalTo([self.identityContainer hasTipsText] ? 66 : 60);
    });
}

- (void)p_ocrButtonClick {
    [self p_trackWithEventName:@"wallet_addbcard_first_page_orc_idcard_click" params:@{
        @"ocr_source" : @"二要素"
    }];
    
    CJPayIDCardProfileOCRViewController *cardOCRVC = [CJPayIDCardProfileOCRViewController new];
    cardOCRVC.appId = self.viewModel.appId;
    cardOCRVC.merchantId = self.viewModel.merchantId;
    cardOCRVC.minLength = 13;
    cardOCRVC.maxLength = 23;
    cardOCRVC.trackDelegate = self;
    cardOCRVC.fromPage = @"二要素";
    
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_newTwoElements_ocr_idcard_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_newTwoElements_ocr_idcard_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_newTwoElements_ocr_idcard_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_newTwoElements_ocr_idcard_avcapturesession_stop_running";
    
    @CJWeakify(self)
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        self.latestOCRModel = resultModel;
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                [self p_fillCardNumber:resultModel];
                break;
            case CJPayCardOCRResultUserCancel: // 用户取消识别
            case CJPayCardOCRResultUserManualInput: // 用户手动输入
                self.isCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoCameraAuthority: //BPEA降级导致无法获取相机权限
                [CJToast toastText:@"没有相机权限" inWindow:self.cj_window];
                self.isCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoJumpSettingAuthority: //BPEA降级导致无法跳转系统设置开启相机权限
                [CJToast toastText:@"没有跳转系统设置权限" inWindow:self.cj_window];
                self.isCardOCR = NO;
                break;
            default:
                break;
        }
    };
    [self.navigationController pushViewController:cardOCRVC animated:YES];
}

- (void)p_setOCRButtonHidden:(BOOL)hidden {
    self.ocrButton.hidden = hidden;
    if (![CJPaySettingsManager shared].currentSettings.bindCardUISettings.isShowIDProfileCard) {
        self.ocrButton.hidden = YES;
    }
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
    
    self.isCardOCR = YES;
    [self p_setOCRButtonHidden:NO];
    
    self.nextStepButton.enabled = [self.idTextFieldConfigration contentISValid] && self.nameContainer.textField.userInputContent.length >= 2 && [self p_isNameValid];
}



#pragma mark - 一键绑卡查询订单
- (void)appDidEnterForground {
    // 查询用户是否已经完成了绑卡
    if (Check_ValidString(self.oneKeyCreateOrderResponse.memberBizOrderNo) &&
        [[UIViewController cj_foundTopViewControllerFrom:self] isKindOfClass:[self class]] &&
        [self p_shouldOpenApp]) {
        if(CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin)) {
            [CJ_OBJECT_WITH_PROTOCOL(CJPayNativeBindCardPlugin) queryOneKeySignState];
        } else {
            CJPayLogAssert(NO, @"没有接入native绑卡");
        }
    }
}

#pragma mark - CJPayCustomTextFieldContainerDelegate
- (void)textFieldBeginEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.nameContainer && textContainer.textField.userInputContent.length > 0) {
        [self p_setOCRButtonHidden:YES];
    }
    if (textContainer == self.identityContainer) {
        [textContainer updateTips:@""];
    }
    [self p_updateTextFeildHeight];
    [self p_updateEmptyViewForRoll];
    self.curFoucsView = textContainer;
}

- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    self.nextStepButton.enabled = [self.idTextFieldConfigration contentISValid] && self.nameContainer.textField.userInputContent.length >= 2 && [self p_isNameValid];
    
    if (textContainer == self.identityContainer) {
        [self.identityContainer updateTips:@""];
        if ([self.idTextFieldConfigration userInputContent].length == 18) {
            [self.idTextFieldConfigration contentISValid];
        }
    } else if (textContainer == self.nameContainer) {
        [self.nameContainer updateTips:@""];
        [self p_setOCRButtonHidden:!(textContainer.textField.userInputContent.length == 0)];
    }
    [self p_updateTextFeildHeight];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.nameContainer.textField == textField) {
        // 姓名输入框不能粘贴非法字符
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
    
    [self p_updateTextFeildHeight];
    return YES;
}

- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer {
    // 失焦时校验手机号码
    if (textContainer == self.identityContainer) {
        
        @CJWeakify(self)
        self.idTextFieldConfigration.textFieldEndEditCompletionBlock = ^(BOOL isLegal) {
            @CJStrongify(self)
            BOOL hasInput = self.idTextFieldConfigration.userInputContent.length > 0;
            if (hasInput) {
                NSMutableDictionary *trackParams = [NSMutableDictionary new];
                [trackParams cj_setObject:isLegal ? @"1" : @"0" forKey:@"result"];
                [trackParams cj_setObject:@"居民身份证" forKey:@"type"];
                if (Check_ValidString(self.idTextFieldConfigration.errorMsg)) {
                    [trackParams cj_setObject:self.idTextFieldConfigration.errorMsg forKey:@"error_type"];
                }
                
                [self p_trackWithEventName:@"wallet_two_elements_identified_page_idnumber_input" params:trackParams];
            }
        };
        
        [self.idTextFieldConfigration textFieldEndEdit];
    } else if (textContainer == self.nameContainer) {
        NSString *errorType = @"";
        [self p_setOCRButtonHidden:NO];
        if (self.nameContainer.textField.userInputContent.length < 2 &&
            ![self.nameContainer.textField.userInputContent isEqualToString:@""]) {
                [self.nameContainer updateTips:CJPayLocalizedStr(@"姓名输入不完整，请检查")];
                errorType = @"姓名不完整";
        }
        
        if ([self p_isContainSpecialCharacterInIDCardName]) {
            [self.nameContainer updateTips:CJPayLocalizedStr(@"姓名含有特殊字符，请检查")];
            errorType = @"姓名含有特殊字符";
        }
        
        if ([self p_isNameValid]) {
            [self p_trackWithEventName:@"wallet_two_elements_identified_page_name_input" params:@{@"result" : @"1"}];
        } else {
            [self p_trackWithEventName:@"wallet_two_elements_identified_page_name_input" params:@{@"result" : @"0", @"error_type" : CJString(errorType)}];
        }
    }
    [self p_updateTextFeildHeight];
}

- (void)textFieldDidClear:(CJPayCustomTextFieldContainer *)textContainer {
    self.nextStepButton.enabled = NO;
    [textContainer updateTips:@""];
    [self p_updateTextFeildHeight];
    [self p_setOCRButtonHidden:NO];
}

#pragma mark - Getter
- (CJPayBindCardScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[CJPayBindCardScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bounces = YES;
    }
    return _scrollView;
}

- (CJPayBindCardTopHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [CJPayBindCardTopHeaderView new];
    }
    return _headerView;
}

- (UIView *)whiteGroundView {
    if (!_whiteGroundView) {
        _whiteGroundView = [UIView new];
        _whiteGroundView.backgroundColor = [UIColor whiteColor];
        _whiteGroundView.layer.cornerRadius = 8;
    }
    return _whiteGroundView;
}

- (UIImageView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [UIImageView new];
        if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
            [_backgroundView cj_setImage:@"cj_bindcard_logo_icon"];
        }
    }
    return _backgroundView;
}
    
- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
    }
    return _scrollContentView;
}

- (UIImageView *)authImageView {
    if (!_authImageView) {
        _authImageView = [UIImageView new];
        [_authImageView cj_setImage:@"cj_authverify_icon"];
    }
    return _authImageView;
}

- (UILabel *)authTitle {
    if (!_authTitle) {
        _authTitle = [UILabel new];
        _authTitle.text = CJPayLocalizedStr(@"支付实名认证");
        _authTitle.font = [UIFont cj_boldFontOfSize:20];
        _authTitle.textColor = [UIColor cj_222222ff];
        _authTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _authTitle;
}

- (UILabel *)authVerifyTipsLabel {
    if (!_authVerifyTipsLabel) {
        _authVerifyTipsLabel = [UILabel new];
        _authVerifyTipsLabel.numberOfLines = 0; // 显示多行
    }
    return _authVerifyTipsLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.text = CJPayLocalizedStr(@"首次绑卡需完善个人信息");
        _tipsLabel.font = [UIFont cj_boldFontOfSize:14];
        _tipsLabel.textColor = [UIColor cj_161823ff];
    }
    return _tipsLabel;
}

- (CJPayCustomTextFieldContainer *)nameContainer {
    if (!_nameContainer) {
        _nameContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypeName style:CJPayCustomTextFieldContainerStyleWhiteAndBottomTips];
        _nameContainer.keyBoardType = CJPayKeyBoardTypeSystomDefault;
        _nameContainer.delegate = self;
        _nameContainer.placeHolderText = CJPayLocalizedStr(@"输入持卡人姓名");
    }
    return _nameContainer;
}

- (CJPayCustomTextFieldContainer *)identityContainer {
    if (!_identityContainer) {
        _identityContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypeIdentity style:CJPayCustomTextFieldContainerStyleWhiteAndBottomTips];
        _identityContainer.keyBoardType = CJPayKeyBoardTypeCustomXEnable;
        _identityContainer.delegate = self;
        _identityContainer.customInputTitle = CJPayLocalizedStr(@"身份证号");
        _identityContainer.placeHolderText = CJPayLocalizedStr(@"输入持卡人身份证号");
    }
    return _identityContainer;
}

- (CJPayCustomTextFieldConfigration *)idTextFieldConfigration {
    if (!_idTextFieldConfigration || ![_idTextFieldConfigration isKindOfClass:CJPayNormalIDTextFieldConfigration.class]) {
        _idTextFieldConfigration = [CJPayNormalIDTextFieldConfigration new];
    }
    
    return _idTextFieldConfigration;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)            
            NSString *nameList = @"";
            if ([[agreements valueForKey:@"name"] isKindOfClass:[NSArray class]]) {
                nameList = [((NSArray *)[agreements valueForKey:@"name"]) componentsJoinedByString:@","];
            }
            [self p_trackWithEventName:@"wallet_two_elements_identified_page_agreement_click" params:@{
                @"type" : CJString(nameList)
            }];
        };
    }
    return _protocolView;
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        _nextStepButton = [[CJPayStyleButton alloc] init];
        [_nextStepButton setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
        [_nextStepButton setTitleColor:[UIColor cj_colorWithHexString:@"ffffff"] forState:UIControlStateNormal];
        _nextStepButton.layer.cornerRadius = 5;
        _nextStepButton.layer.masksToBounds = YES;
        _nextStepButton.cjEventInterval = 2;
        [_nextStepButton addTarget:self action:@selector(p_nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _nextStepButton.enabled = NO;
    }
    return _nextStepButton;
}

- (UILabel *)doNotHaveIDCardLabel {
    if (!_doNotHaveIDCardLabel) {
        _doNotHaveIDCardLabel = [UILabel new];
        _doNotHaveIDCardLabel.font = [UIFont cj_fontOfSize:12];
        _doNotHaveIDCardLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _doNotHaveIDCardLabel.text = CJPayLocalizedStr(@"没有身份证？添加银行卡认证");
        
        [_doNotHaveIDCardLabel cj_viewAddTarget:self
                                         action:@selector(p_gotoBindCard)
                               forControlEvents:UIControlEventTouchUpInside];
        _doNotHaveIDCardLabel.userInteractionEnabled = YES;
    }
    return _doNotHaveIDCardLabel;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
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

- (UIView *)emptyView {
    if (!_emptyView) {
        _emptyView = [UIView new];
    }
    return _emptyView;
}

#pragma mark - tracker
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];

    [baseParams addEntriesFromDictionary:params];
    [baseParams addEntriesFromDictionary:@{@"type" : @"居民身份证"}];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

#pragma mark - CJPayTrackerProtocol
- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self p_trackWithEventName:event params:params];
}

- (NSDictionary *)p_trackerBankTypeParams:(CJPayMemVerifyBizOrderResponse *)response {
    NSString *bankTypeList = [self.viewModel.quickBindCardModel.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡";
    if ([self.viewModel.quickBindCardModel.cardType isEqualToString:@"ALL"]) {
        bankTypeList = @"储蓄卡、信用卡";
    }
    NSString *isAliveCheckStr = self.oneKeyCreateOrderResponse.faceVerifyInfoModel.needLiveDetection ? @"1": @"0";
    
    return @{
        @"error_code": CJString(response.code),
        @"error_message": CJString(response.buttonInfo.page_desc),
        @"rank_type": CJString(self.viewModel.quickBindCardModel.rankType),
        @"bank_rank": CJString(self.viewModel.quickBindCardModel.bankRank),
        @"bank_name": CJString(self.viewModel.quickBindCardModel.bankName),
        @"bank_type": CJString(self.viewModel.selectedCardType),
        @"bank_type_list": bankTypeList,
        @"is_alivecheck": CJString(isAliveCheckStr),
        @"activity_info": [self.viewModel.quickBindCardModel activityInfoWithCardType:self.viewModel.selectedCardType] ?: @[],
        @"page_type": @"page"
    };
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 设置指定子View是否接受来自VC的手势事件
    
    if ([touch.view isDescendantOfView:self.nameContainer] || [touch.view isDescendantOfView:self.identityContainer]) {
        return NO;
    }
    
    return YES;
}

@end
