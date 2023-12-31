//
//  CJPayHalfVerifyPasswordV2ViewController.m
//  Pods
//
//  Created by 徐天喜 on 2022/11/19.
//

#import "CJPayHalfVerifyPasswordV2ViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayChoosedPayMethodView.h"
#import "CJPayChoosedPayMethodViewV3.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleButton.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayPasswordContentViewV2.h"
#import "CJPayPasswordContentViewV3.h"

#import "CJPayToast.h"
#import "CJPayChooseDyPayMethodGroupModel.h"

@interface CJPayHalfVerifyPasswordV2ViewController () <CJPayChooseDyPayMethodDelegate>

// subviews
@property (nonatomic, strong) CJPayButton *otherVerifyButton;

@property (nonatomic, assign) BOOL nonFirstAppear;
@property (nonatomic, assign) BOOL isFixedContainerHeight; //动态布局时，是否强制设定半屏高度（自撑开高度超出边界Case）
@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayChooseDyPayMethodManager *chooseDyPayMethodManager;
@property (nonatomic, copy) NSArray<CJPayChooseDyPayMethodGroupModel *> *groupModel;

@end

@implementation CJPayHalfVerifyPasswordV2ViewController

#pragma mark - life cycle

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }
    
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // 转场需清除密码输入
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        [self p_clearPasswordInput];
    }
    
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nonFirstAppear = NO;
    self.title = [self p_pageTitleStr];
    self.viewModel.passwordViewHeight = [self containerHeight]; //赋值passwordViewHeight，否则免密引导协议页面高度不正确
    self.viewModel.displayConfigs = [self p_defaultDisplayConfigs]; //创建displayConfigs，供页面展示支付信息
    //    [self.viewModel reset];
    if (self.viewModel.response.topRightBtnInfo ||
        self.viewModel.isFromOpenBioPayVerify ||
        self.viewModel.isStillShowingTopRightBioVerifyButton) {
        [self p_setupOtherVerifyBtn];
    }
    
    [self p_setupUI];
    @CJWeakify(self)
    [self.chooseDyPayMethodManager getPayMethodListSlient:YES completion:^(NSArray<CJPayChooseDyPayMethodGroupModel *> * _Nonnull groupModel) {
        @CJStrongify(self)
        self.groupModel = groupModel;
        [self p_updateDefaultConfig:groupModel];
        if (groupModel && groupModel.count > 0) {
            self.isChoosePayTypeDataReady = YES;
        }
    }]; //静默请求一次选卡页数据
    // 截屏监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_screenShotDetected) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    // 录屏监听
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_screenCaptureDetected:) name:UIScreenCapturedDidChangeNotification object:nil];
    }
    
    // 进入后台监听, 清除密码输入
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_clearPasswordInput) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self getPasswordContentView] showKeyBoardView];
    
    if (!self.nonFirstAppear) {
        NSString *showVerifyType = [[NSString alloc] init];
        if(!self.otherVerifyButton.isHidden) {
            showVerifyType = CJString(self.otherVerifyButton.titleLabel.text);
            if(showVerifyType.length) {
                [self.viewModel trackWithEventName:@"wallet_password_verify_page_alivecheck_imp" params:@{
                    @"button_position":@"0",
                    @"is_awards_show" : @"1",
                    @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel)
                }];
            }
        }
        
        [self.viewModel trackWithEventName:@"wallet_password_verify_page_imp" params:@{
            @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
            @"is_fingerprint_default" : CJString([self.viewModel isFingerprintDefault]),
            @"activity_label" : CJString([self.viewModel trackActivityLabel]),
            @"guide_type" : CJString([self.viewModel getBioGuideType]),
            @"enable_string" : CJString([self.viewModel getBioGuideTypeStr]),
            @"tips_label" : CJString(self.viewModel.downgradePasswordTips),
            @"show_verify_type" : CJString(showVerifyType),
            @"is_awards_show" : @"1",
            @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
            @"biology_verify_source" : [self p_downgradeReason]
        }];
        
        // 展示验证降级toast提示
        if (Check_ValidString(self.viewModel.downgradePasswordTips) && !self.viewModel.isDynamicLayout) {
            [CJToast toastText:CJString(self.viewModel.downgradePasswordTips) inWindow:self.cj_window];
        }
    }
    self.nonFirstAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self getPasswordContentView] retractKeyBoardView];
}

#pragma mark - public method

// 更新验密页错误文案
- (void)updateErrorText:(NSString *)text {
    [[self getPasswordContentView] updateErrorText:text];
    [[self getPasswordContentView] showKeyBoardView];
}

- (void)reset {
    if ([self p_isShowBioVerify] && ![self p_isBioPayAvailable]) {
        self.otherVerifyButton.hidden = YES;//隐藏面容支付
    } else {
        self.otherVerifyButton.hidden = NO;
    }
    [[self getPasswordContentView] clearPasswordInput];
}

- (void)showKeyBoardView {
    [[self getPasswordContentView] showKeyBoardView];
}

- (void)retractKeyBoardView {
    [[self getPasswordContentView] retractKeyBoardView];
}

// 设置验密页右上角验证方式和文案
- (void)updateOtherVerifyType:(CJPayPasswordSwitchOtherVerifyType)verifyType btnText:(NSString *)text {
    [self.otherVerifyButton setTitle:text forState:UIControlStateNormal];
    self.otherVerifyType = verifyType;
}

- (void)showPasswordVerifyKeyboard {
    [self showKeyBoardView];
}

- (void)changePayMethodWithPayType:(CJPayChannelType)payType bankCardId:(NSString *)bankCardId {
    if ([self.viewModel.defaultConfig.bankCardId isEqualToString:bankCardId]) {
        return;
    }
    __block CJPayDefaultChannelShowConfig *defaultShowConfig;
    __block BOOL stopFlag = NO;
    [self.groupModel enumerateObjectsUsingBlock:^(CJPayChooseDyPayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.methodList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self p_matchPayMethod:payType bankCardId:bankCardId channelConfig:obj]) {
                defaultShowConfig = obj;
                defaultShowConfig.isSelected = YES;
                *stop = YES;
                stopFlag = YES;
            }
        }];
        *stop = stopFlag;
    }];
    
    if (!stopFlag) {
        CJPayLogInfo(@"没匹配到支付方式");
        return;
    }
    
    self.viewModel.defaultConfig.isSelected = NO;
    self.chooseDyPayMethodManager.curSelectConfig.isSelected = NO;
    self.viewModel.defaultConfig = defaultShowConfig;
    self.chooseDyPayMethodManager.curSelectConfig = defaultShowConfig;
    [self.chooseDyPayMethodManager didSelectPayMethod:defaultShowConfig loadingView:nil];
    [self.chooseDyPayMethodManager refreshPayMethodSelectStatus:defaultShowConfig];
    
    if (self.viewModel.isDynamicLayout) {
        [self p_showChoosePayMethodViewWithPayType:payType];
        return;
    }
    if (payType == BDPayChannelTypeBankCard) {
        self.viewModel.hideChoosedPayMethodView = NO;
        self.passwordContentView.choosedPayMethodView.hidden = NO;
        self.passwordContentView.choosedPayMethodView.alpha = 0;
    }
        
    [UIView animateWithDuration:0.3 animations:^{
        CJPayMasReMaker(self.containerView, {
            make.left.right.bottom.equalTo(self.view);
            make.height.mas_equalTo([self containerHeight]);
        });
        
        [self.passwordContentView updateForChoosedPayMethod:self.viewModel.hideChoosedPayMethodView];
        self.passwordContentView.choosedPayMethodView.alpha = self.viewModel.hideChoosedPayMethodView ? 0 : 1;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

// 动态布局验密页更新choosedPayMethodView的显隐状态
- (void)p_showChoosePayMethodViewWithPayType:(CJPayChannelType)payType {
    if (payType == BDPayChannelTypeBankCard) {
        self.viewModel.hideChoosedPayMethodView = NO;
        self.commonPasswordContentView.choosedPayMethodView.alpha = 0;
    }
    [self.commonPasswordContentView updateChoosedPayMethodViewHiddenStatus:NO];
    [UIView animateWithDuration:0.3 animations:^{
        self.commonPasswordContentView.choosedPayMethodView.alpha = 1;
        [self.view layoutIfNeeded];
    }];
}

//过渡期间，动态化布局使用commonPasswordContentView，常规布局使用passwordContentView
- (UIView<CJPayPasswordViewProtocol> *)getPasswordContentView {
    if (self.viewModel.isDynamicLayout) {
        return self.commonPasswordContentView;
    } else {
        return self.passwordContentView;
    }
}
#pragma mark - private method

- (BOOL)p_matchPayMethod:(CJPayChannelType)payType bankCardId:(NSString *)bankCardId channelConfig:(CJPayDefaultChannelShowConfig *)config {
    return (payType == BDPayChannelTypeBankCard && [config.bankCardId isEqualToString:bankCardId])
            || (payType == BDPayChannelTypeCreditPay && config.type == BDPayChannelTypeCreditPay);
}

- (void)p_setupUI {
    // 验密页动态布局（自适应高度）
    if (self.viewModel.isDynamicLayout) {
        [self p_setupUIForDynamicLayout];
        return;
    }
        
    [self.contentView addSubview:self.passwordContentView];
    CJPayMasMaker(self.passwordContentView, {
        make.top.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-[self.passwordContentView.inputPasswordView getFixKeyBoardHeight]);
    });
    if (CJ_Pad) {
        self.navigationBar.titleLabel.hidden = YES;
    }
}

// passwordContentView动态布局，containerView的布局高度依赖于passwordContentView
- (void)p_setupUIForDynamicLayout {
    
    [self p_containerViewLayoutDynamically];
    CJPayMasReMaker(self.topView, {
        make.left.top.right.equalTo(self.view);
        make.bottom.equalTo(self.containerView.mas_top).priorityLow();
    });
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

// 验密页动态布局
- (void)p_containerViewLayoutDynamically {

    self.isFixedContainerHeight = NO;
    [self.contentView addSubview:self.commonPasswordContentView];
    
    CJPayMasReMaker(self.containerView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.navigationBar);
    });
        
    CJPayMasReMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.containerView);
        make.top.equalTo(self.navigationBar.mas_bottom);
    });
    
    CJPayMasReMaker(self.commonPasswordContentView, {
        make.left.right.top.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-[self p_getPasswordContentViewBottomMargin]);
    });
}

// passwordContentView动态布局，但containerView整体静态布局（固定高度）
- (void)p_containerViewLayoutFixedHeight:(CGFloat)fixContainerHeight {
    
    self.isFixedContainerHeight = YES;

    CJPayMasReMaker(self.containerView, {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(fixContainerHeight);
    });
    
    CJPayMasReMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.containerView);
        make.height.equalTo(self.containerView).offset(-50);
    });
    // 自撑开高度过低时，passwordContentView距上布局
    [self.contentView addSubview:self.commonPasswordContentView];
    CJPayMasReMaker(self.commonPasswordContentView, {
        make.left.right.top.equalTo(self.contentView);
    });
    
}

- (void)p_comfirmButtonClickWithContent:(NSString *)passwordStr {
    if (passwordStr.length != 6) {
        return;
    }
    self.viewModel.confirmBtnClickTimes = self.viewModel.confirmBtnClickTimes + 1;
    [self.viewModel trackPageClickWithButtonName:@"1"];
    CJ_CALL_BLOCK(self.inputCompleteBlock, passwordStr);
    [[self getPasswordContentView] retractKeyBoardView];
    [self reset];
}

// 完成输入
- (void)p_completeInputWithContent:(NSString *)passwordStr {
    [self.viewModel trackWithEventName:@"wallet_password_verify_page_input"
                      params:@{
        @"time": @(self.viewModel.passwordInputCompleteTimes),
        @"activity_label" : CJString([self.viewModel trackActivityLabel]),
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self.viewModel isFingerprintDefault]),
        @"guide_type" : CJString([self.viewModel getBioGuideType]),
        @"enable_string" : CJString([self.viewModel getBioGuideTypeStr]),
        @"tips_label" : CJString(self.viewModel.downgradePasswordTips),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel)
    }];
    
    if (!self.inputCompleteBlock) {
        return;
    }
    
    if ([self.viewModel isShowComfirmButton]) { //有确认按钮
        return;
    }
    
    CJ_CALL_BLOCK(self.inputCompleteBlock, passwordStr);
    [[self getPasswordContentView] retractKeyBoardView];
    [self reset];
}

// 验密页标题
- (NSString *)p_pageTitleStr {
    if (self.viewModel.isFromOpenBioPayVerify) {
        return CJPayLocalizedStr(@"输入密码并开通");
    }
    return CJPayLocalizedStr(@"输入支付密码");
}

// 右上角”其他支付方式按钮“布局
- (void)p_setupOtherVerifyBtn {
    [self.navigationBar addSubview:self.otherVerifyButton];
    
    CJPayMasMaker(self.otherVerifyButton, {
        make.right.equalTo(self.navigationBar).offset(-16);
        make.centerY.equalTo(self.navigationBar);
        make.height.mas_equalTo(20);
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right).offset(5);
    });
    
    if ([self p_isShowBioVerify] && ![self p_isBioPayAvailable]) {
        self.otherVerifyButton.hidden = YES;//隐藏面容支付
    } else {
        self.otherVerifyButton.hidden = NO;
    }
}

//检查指纹/面容是否可用
- (BOOL)p_isBioPayAvailable {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioPayAvailableWithResponse:self.viewModel.response];
}

- (BOOL)p_isShowBioVerify {//面容支付
    return [self.viewModel.response.topRightBtnInfo.action isEqualToString:@"bio_verify"];
}

- (void)p_screenShotDetected {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordV2ViewController.class]) {
        return;
    }
    
    [CJToast toastText:CJPayLocalizedStr(@"监测到截屏，请注意密码安全") inWindow:self.cj_window];
}

- (void)p_screenCaptureDetected:(NSNotification *)notification {
    if (![notification isKindOfClass:NSNotification.class]) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordV2ViewController.class]) {
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        UIScreen *screen = [notification object];
        if ([screen isKindOfClass:UIScreen.class] && [screen isCaptured]) {
            [CJToast toastText:CJPayLocalizedStr(@"监测到录屏，请注意密码安全") inWindow:self.cj_window];
        }
    }
    
}

- (void)p_clearPasswordInput {
    [[self getPasswordContentView] clearPasswordInput];
}

// 根据subPayTypeDisplayInfoList构造初始验密页支付方式信息
- (NSArray<CJPayDefaultChannelShowConfig *> *)p_defaultDisplayConfigs {
    NSArray<CJPaySubPayTypeDisplayInfo *> *displayInfo = self.viewModel.response.payInfo.subPayTypeDisplayInfoList;
    if (!Check_ValidArray(displayInfo)) {
        return @[self.viewModel.defaultConfig];
    }
    if (displayInfo.count == 1) { // 非组合支付
        CJPaySubPayTypeDisplayInfo *defaultInfo = [displayInfo cj_objectAtIndex:0];
        CJPayDefaultChannelShowConfig *config = [defaultInfo buildShowConfig];
        return @[config];
    } else if (displayInfo.count == 2) { // 组合支付
        NSMutableArray<CJPayDefaultChannelShowConfig *> *configs = [NSMutableArray new];
        [displayInfo enumerateObjectsUsingBlock:^(CJPaySubPayTypeDisplayInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CJPayDefaultChannelShowConfig *config = [obj buildShowConfig];
            [configs btd_addObject:config];
        }];
        return [configs copy];
    } else {
        return @[self.viewModel.defaultConfig];
    }
}

- (void)p_updateDefaultConfig:(NSArray<CJPayChooseDyPayMethodGroupModel *> *)groupModel {
    __block BOOL stopFlag = NO;
    [groupModel enumerateObjectsUsingBlock:^(CJPayChooseDyPayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.methodList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isSelected) {
                self.viewModel.defaultConfig = obj;
                *stop = YES;
                stopFlag = YES;
            }
        }];
        *stop = stopFlag;
    }];
}

// commonPasswordContentView与contentView的底部约束间距
- (CGFloat)p_getPasswordContentViewBottomMargin {
    return [self.commonPasswordContentView.inputPasswordView getFixKeyBoardHeight] + 24;
}

// commonPasswordContentView的frame变化处理
- (void)p_dynamicViewFrameChange:(CGRect)newFrame {
    
    if (!self.viewModel.isDynamicLayout) {
        return;
    }
    
    BOOL needLayout = NO;
    CGFloat currentContainerHeight = newFrame.size.height + 50 + [self p_getPasswordContentViewBottomMargin];
    // 如果自适应高度低于470，则强制将半屏高度设置为470
    if (currentContainerHeight < CJ_HALF_SCREEN_HEIGHT_LOW) {
        [self p_containerViewLayoutFixedHeight:CJ_HALF_SCREEN_HEIGHT_LOW];
        needLayout = YES;
        
    } else if (self.isFixedContainerHeight) {
        // 如果当前为固定高度 且 新的自适应布局高度不满足边界Case，则半屏containerView改为自适应高度布局
        [self p_containerViewLayoutDynamically];
        needLayout = YES;
    }
    
    if (needLayout) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];        
    }
}

- (void)p_gotoChooseMethodPage {
    self.chooseDyPayMethodManager.height = [self containerHeight]; // 选卡页高度保持与验密页一致
    self.chooseDyPayMethodManager.curSelectConfig = self.viewModel.defaultConfig;
    self.chooseDyPayMethodManager.payMethodDisabledReasonMap = [[self getPayDisabledReasonMap] mutableCopy];
    [self.chooseDyPayMethodManager gotoChooseDyPayMethod]; // 前往选卡页
}

- (NSString *)p_downgradeReason {
    if (self.otherVerifyButton.hidden) {
        return @"";
    }
    
    NSString *downgradeReason = @"";
    NSString *topRightBtnText = self.otherVerifyButton.titleLabel.text;
    if ([topRightBtnText isEqualToString:CJPayLocalizedStr(@"面容支付")] || [topRightBtnText isEqualToString:CJPayLocalizedStr(@"指纹支付")]) {
        downgradeReason = CJString(self.response.topRightBtnInfo.downgradeReason);
    }
    
    if (Check_ValidString(self.bioDowngradeToPassscodeReason)) {
        downgradeReason = self.bioDowngradeToPassscodeReason;
    }
    
    return downgradeReason;
}

#pragma mark - override

- (void)back {
    [self.viewModel trackPageClickWithButtonName:@"0"];
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
    } else {
        [super back];
    }
}

- (void)closeWithAnimation:(BOOL)animated
                 comletion:(nullable AnimationCompletionBlock)completion {
    [[self getPasswordContentView] setPasswordInputAllow:NO];
    [super closeWithAnimation:animated comletion:completion];
}

- (CGFloat)containerHeight {
    if (self.viewModel.isDynamicLayout && self.containerView.cj_height > 0) {
        return self.containerView.cj_height;
    }
    return [self p_fixedContainerHeight];
}

- (CGFloat)p_fixedContainerHeight {
    /**
     https://www.figma.com/file/kqz01MfKIHaaSAxsBcHjj7/%E7%94%B5%E5%95%86%C2%B7%E6%8A%96%E9%9F%B3%E6%94%AF%E4%BB%98V2.0?node-id=2488%3A34430&t=m1ovAYDaKgCx2V6n-0
     基本高度 : 513
     有引导 :     546
     有引导 + button : 602
     */
    BOOL needLowerHeight = self.viewModel.hideChoosedPayMethodView; //如果需要隐藏“支付方式切换UI组件”，则半屏验密页的高度需降低一挡
    CGFloat baseHeight = 513;
    if ([self.viewModel isNeedShowGuide] && [self.viewModel isShowComfirmButton]) {
        baseHeight = needLowerHeight ? 546 : 602;
    } else if ([self.viewModel isNeedShowGuide]) {
        baseHeight = needLowerHeight ? 513 : 546;
    } else {
        // do nothing
    }
    return baseHeight + CJ_TabBarSafeBottomMargin;
}

#pragma mark - CJPayChooseDyPayMethodDelegate
// 更改选中的支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *_Nullable)view {
    CJPayDefaultChannelShowConfig *config = payContext.defaultConfig;
    
    if ([config isNeedReSigning] && [self.changeMethodDelegate respondsToSelector:@selector(signPayWithPayContext:loadingView:)]) {
        [self.changeMethodDelegate signPayWithPayContext:payContext loadingView:view];
        return;
    }
    
    if ([self p_isNeedUpdateShowConfigWithSelectedShowConfig:config]) {
        self.viewModel.defaultConfig = config;
        [[self getPasswordContentView] updatePayConfigContent:@[config]];
        [self.view layoutIfNeeded];
    }
    [self.changeMethodDelegate changePayMethod:payContext loadingView:view];
}

- (BOOL)p_isNeedUpdateShowConfigWithSelectedShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    if ([showConfig isNeedReSigning]) {
        return NO;
    }
    if (showConfig.type == BDPayChannelTypeAddBankCard) {
        return NO;
    }
    return YES;
}

// 展示选卡页
- (void)pushChoosePayMethodVC:(UIViewController *)vc animated:(BOOL)animated {
    [self.verifyManager.homePageVC push:vc animated:animated];
}

- (void)trackEvent:(NSString *)event params:(NSDictionary *)params {
    [self.viewModel trackWithEventName:event params:params];
}

- (NSDictionary *)payContextExtParams {
    if ([self.changeMethodDelegate respondsToSelector:@selector(payContextExtParams)]) {
        return [self.changeMethodDelegate payContextExtParams];
    }
    return [NSDictionary new];
}

- (NSDictionary *)getPayDisabledReasonMap {
    if ([self.changeMethodDelegate respondsToSelector:@selector(getPayDisabledReasonMap)]) {
        return [self.changeMethodDelegate getPayDisabledReasonMap];
    }
    return [NSDictionary new];
}
#pragma mark - lazy views

- (CJPayButton *)otherVerifyButton {
    if (!_otherVerifyButton) {
        _otherVerifyButton = [CJPayButton new];
        _otherVerifyButton.hidden = YES;//懒加载的地方可能并没有addsubview
        _otherVerifyButton.titleLabel.font = [UIFont cj_fontOfSize:15];
        NSString *btnStr = @"";
        CJPayPasswordSwitchOtherVerifyType verifyType;
        
        [_otherVerifyButton setTitleColor:[UIColor cj_colorWithHexString:@"#04498D"] forState:UIControlStateNormal];
        if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FACEID"]) {
            btnStr = CJPayLocalizedStr(@"面容支付");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeBio;
        } else if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FINGER"]) {
            btnStr = CJPayLocalizedStr(@"指纹支付");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeBio;
        } else if (self.viewModel.isFromOpenBioPayVerify) {
            btnStr = CJPayLocalizedStr(@"刷脸验证");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeRecogFace;
        } else {
            btnStr = CJPayLocalizedStr(self.response.topRightBtnInfo.desc);
            verifyType = CJPayPasswordSwitchOtherVerifyTypeRecogFace;
        }
        [self updateOtherVerifyType:verifyType btnText:btnStr];
        
        _otherVerifyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _otherVerifyButton.titleLabel.minimumScaleFactor = 0.1;
        @CJWeakify(self)
        [_otherVerifyButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_DelayEnableView(self.otherVerifyButton);
            [self.viewModel trackWithEventName:@"wallet_password_verify_page_right_click"
                                        params:@{@"button_name":self.otherVerifyButton.titleLabel.text,
                                                 @"biology_verify_source":[self p_downgradeReason]}];
            CJ_CALL_BLOCK(self.otherVerifyPayBlock, self.otherVerifyType);
        }];
    }
    return _otherVerifyButton;
}

- (CJPayPasswordContentViewV2 *)passwordContentView {
    if (!_passwordContentView) {
        _passwordContentView = [[CJPayPasswordContentViewV2 alloc] initWithViewModel:self.viewModel];
        @CJWeakify(self)
        _passwordContentView.clickedPayMethodBlock = ^(NSString * _Nullable btnName) {
            @CJStrongify(self);
            [self.viewModel trackPageClickWithButtonName:@"5"];
            [self p_gotoChooseMethodPage];
        };
        _passwordContentView.forgetPasswordBtnBlock = ^{
            @CJStrongify(self)
            [self.viewModel trackWithEventName:@"wallet_password_verify_page_forget_click" params:@{
                @"button_name": CJString(self.passwordContentView.forgetPasswordBtn.titleLabel.text),
                @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
                @"is_fingerprint_default" : CJString([self.viewModel isFingerprintDefault]),
                @"activity_label" : CJString([self.viewModel trackActivityLabel]),
                @"guide_type" : CJString([self.viewModel getBioGuideType]),
                @"time" : @(self.viewModel.passwordInputCompleteTimes),
                @"is_awards_show" : @"1",
                @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
            }];
            
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock);
        };
        _passwordContentView.inputCompleteBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            [self p_completeInputWithContent:passwordStr];
        };
        _passwordContentView.confirmBtnClickBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            [self p_comfirmButtonClickWithContent:passwordStr];
        };
    }
    return _passwordContentView;
}

- (CJPayPasswordContentViewV3 *)commonPasswordContentView {
    if (!_commonPasswordContentView) {
        _commonPasswordContentView = [[CJPayPasswordContentViewV3 alloc] initWithViewModel:self.viewModel originStatus:CJPayPasswordContentViewStatusPassword];
        @CJWeakify(self)
        _commonPasswordContentView.clickedPayMethodBlock = ^(NSString * _Nullable btnName) {
            @CJStrongify(self);
            [self.viewModel trackPageClickWithButtonName:@"5"];
            [self p_gotoChooseMethodPage];
        };
        _commonPasswordContentView.clickedCombinedPayBankPayMethodBlock = ^(NSString * _Nullable btnName) {
            //暂不支持组合支付场景下的支付方式切换
        };
        _commonPasswordContentView.inputCompleteBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            [self p_completeInputWithContent:passwordStr];
        };
        _commonPasswordContentView.confirmBtnClickBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            [self p_comfirmButtonClickWithContent:passwordStr];
        };
        _commonPasswordContentView.clickedGuideCheckboxBlock = ^(BOOL isSelected) {
            @CJStrongify(self)
            self.viewModel.isGuideSelected = isSelected;
            [self.viewModel trackPageClickWithButtonName:isSelected ? @"2" : @"3"];
        };
        _commonPasswordContentView.clickProtocolViewBlock = ^{
            @CJStrongify(self)
            [self.viewModel trackPageClickWithButtonName:@"4"];
        };
        _commonPasswordContentView.forgetPasswordBtnBlock = ^(NSString * _Nonnull btnText) {
            @CJStrongify(self)
            [self.viewModel trackWithEventName:@"wallet_password_verify_page_forget_click" params:@{
                @"button_name": CJString(btnText),
                @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
                @"is_fingerprint_default" : CJString([self.viewModel isFingerprintDefault]),
                @"activity_label" : CJString([self.viewModel trackActivityLabel]),
                @"guide_type" : CJString([self.viewModel getBioGuideType]),
                @"time" : @(self.viewModel.passwordInputCompleteTimes),
                @"is_awards_show" : @"1",
                @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
            }];
            
            CJ_CALL_BLOCK(self.forgetPasswordBtnBlock);
        };
        _commonPasswordContentView.dynamicViewFrameChangeBlock = ^(CGRect newFrame) {
            @CJStrongify(self)
            [self p_dynamicViewFrameChange:newFrame];
        };
    }
    return _commonPasswordContentView;
}

- (CJPayChooseDyPayMethodManager *)chooseDyPayMethodManager {
    if (!_chooseDyPayMethodManager) {
        _chooseDyPayMethodManager = [[CJPayChooseDyPayMethodManager alloc] initWithOrderResponse:self.response];
        _chooseDyPayMethodManager.delegate = self;
        _chooseDyPayMethodManager.curSelectConfig = self.viewModel.defaultConfig;
        _chooseDyPayMethodManager.payMethodDisabledReasonMap = [[self getPayDisabledReasonMap] mutableCopy];
        _chooseDyPayMethodManager.closeChoosePageAfterChangeMethod = YES;
    }
    return _chooseDyPayMethodManager;
}


@end
