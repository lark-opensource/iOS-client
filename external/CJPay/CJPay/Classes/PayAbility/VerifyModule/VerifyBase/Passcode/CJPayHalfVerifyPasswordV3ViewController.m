//
//  CJPayHalfVerifyPasswordV3ViewController.m
//  Pods
//
//  Created by xutianxi on 2023/03/01.
//

#import "CJPayHalfVerifyPasswordV3ViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayChoosedPayMethodView.h"
#import "CJPayDeductDetailView.h"
#import "CJPaySafeInputView.h"
#import "CJPayStyleButton.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayErrorInfoActionView.h"
#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPaySafeKeyboard.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPaySignPayChoosePayMethodManager.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayPasswordContentViewV3.h"
#import "CJPayToast.h"
#import "CJPayQueryPayTypeResponse.h"
#import "CJPayIntegratedChannelModel.h"
#import "CJPayOutDisplayInfoModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayKVContext.h"
/*
 UI稿：https://www.figma.com/file/z2SR6Duw4ZmxFnlHnurzqn/%E6%8A%96%E9%9F%B3%E6%94%AF%E4%BB%98-O%E9%A1%B9%E7%9B%AE?type=design&node-id=105-5306&t=Rq6SJ4HJ4bTOa3Tg-0
 */

@interface CJPayHalfVerifyPasswordV3ViewController () <CJPayChooseDyPayMethodDelegate, CJPaySignPayChoosePayMethodDelegate, CJPayBaseLoadingProtocol>

// subviews
@property (nonatomic, strong) CJPayButton *otherVerifyButton;
@property (nonatomic, strong) UILabel *merchantNameLabel;
@property (nonatomic, strong) UIImageView *titleBGImageView;
@property (nonatomic, strong) UIScrollView *contentScrollView;

@property (nonatomic, assign) BOOL nonFirstAppear;
@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayChooseDyPayMethodManager *chooseDyPayMethodManager;
@property (nonatomic, strong) CJPaySignPayChoosePayMethodManager *signPayChoosePayMethodManager;
@property (nonatomic, assign) BOOL isPasswordVerifyStyle; // 页面验证方式是否展示为验密，1：验密、0：生物验证、新卡支付
@property (nonatomic, assign) BOOL isFixedContainerHeight; //动态布局时，是否强制设定半屏高度（自撑开高度超出边界Case）

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *combinedPayBankCard;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *combinedPayBalance;

@property (nonatomic, assign) BOOL isPasswordOfLastVerifyStyle; //用户新卡切换成老卡时，判断是否要切换面板样式（老卡 - 组合支付切新卡 - 变矮 - 切老卡 - 是否需要切回高样式）

@end

@implementation CJPayHalfVerifyPasswordV3ViewController

#pragma mark - life cycle

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.isPasswordVerifyStyle = YES;
        self.isPasswordOfLastVerifyStyle = YES;
    }
    
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.view.hidden = NO;
    self.navigationController.view.backgroundColor = [UIColor cj_maskColor];
    // 转场需清除密码输入
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        [self p_clearPasswordInput];
    }
    
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.response.deskConfig isFastEnterBindCard] && self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard) {
        self.view.hidden = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
    }
    
    self.nonFirstAppear = NO;
    if (self.isSimpleVerifyStyle) {
        self.title = [self p_pageTitleStr];
    }
    
    self.viewModel.displayConfigs = [self p_defaultDisplayConfigs]; //创建displayConfigs，供页面展示支付信息
    self.viewModel.passwordFixedTips = [self p_pageTitleStr];
    //    [self.viewModel reset];
    if (self.viewModel.response.topRightBtnInfo ||
        self.viewModel.isFromOpenBioPayVerify ||
        self.viewModel.isStillShowingTopRightBioVerifyButton) {
        [self p_setupOtherVerifyBtn];
    }
    
    [self p_setupUI];
    self.passwordContentView.inputPasswordTitle.text = [self p_pageTitleStr];
    
    // 进入初始化样式
    if (![self.viewModel isSuggestCardStyle]) {
        [self switchToPasswordVerifyStyle:[self p_isPassVerifyStyle]];
        if (self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard) {
            [self p_updateConfirmButtonTitle];
        }
        self.isPasswordOfLastVerifyStyle = [self.passwordContentView isPasswordVerifyStyle];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess:) name:CJPayBindCardSuccessNotification object:nil];
    // 截屏监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_screenShotDetected) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    // 录屏监听
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_screenCaptureDetected:) name:UIScreenCapturedDidChangeNotification object:nil];
    }
    
    // 进入后台监听, 清除密码输入
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_clearPasswordInput) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    NSString *showVerifyType = [[NSString alloc] init];
    if(!self.otherVerifyButton.isHidden) {
        showVerifyType = CJString(self.otherVerifyButton.titleLabel.text);
    }
    
    NSString *cashierType = @""; // O项目埋点-收银台类型
    if ([self p_isSkipPwd]) {
        cashierType = @"onesteppswd";
    } else if ([self.viewModel isSuggestCardStyle]) {
        cashierType = @"new_user";
    } else if ([self.passwordContentView isPasswordVerifyStyle]) {
        cashierType = @"check_pass";
    } else {
        if (self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard) {
            cashierType = @"bind_card";
        } else if ([self.viewModel isNeedResignCard]) {
            cashierType = @"add_sign";
        } else if ([self p_isFacePayment] || [self p_isFingerprintPayment]) {
            cashierType = @"check_biology";
        }
    }
    [self.viewModel trackWithEventName:@"wallet_cashier_imp" params:@{
        @"fingerprint_type" : [self.response.preBioGuideInfo.bioType isEqualToString:@"FINGER"] ? @"指纹" : @"面容",
        @"is_fingerprint_default" : CJString([self.viewModel isFingerprintDefault]),
        @"activity_label" : CJString([self.viewModel trackActivityLabel]),
        @"guide_type" : CJString([self.viewModel getBioGuideType]),
        @"enable_string" : CJString([self.viewModel getBioGuideTypeStr]),
        @"tips_label" : CJString(self.viewModel.downgradePasswordTips),
        @"show_verify_type" : CJString(showVerifyType),
        @"is_awards_show" : @"1",
        @"awards_info" : CJString(self.response.payInfo.guideVoucherLabel),
        @"cashier_imptype" : CJString(cashierType)
    }];
    
    [self.containerView setNeedsLayout];
    [self.containerView layoutIfNeeded];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showKeyBoardView];
    
    if (!self.nonFirstAppear) {
        NSString *showVerifyType = [[NSString alloc] init];
        if(!self.otherVerifyButton.isHidden) {
            showVerifyType = CJString(self.otherVerifyButton.titleLabel.text);
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
        }];
        
        if (Check_ValidString(self.viewModel.response.payInfo.verifyDesc)) {
            [CJToast toastText:CJString(self.viewModel.response.payInfo.verifyDesc) inWindow:self.cj_window];
        }
        if ([self p_isVerifyBioWhenPaswordViewAppear]) {
            // 签约并支付唤起O项目，如果能使用生物验证，需先拉起高半屏验密页再立刻启动系统生物验证，此时无需拉起键盘
            if (self.viewModel.isDynamicLayout) {
                [self retractKeyBoardView];
                [self p_clickedOtherVerifyButton];
            } else {
                // 非动态化场景在viewDidLoad方法内会调一次switchToPasswordVerifyStyle来拉起生物验证，因此无需在此处唤起生物验证
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{  //解决新转场不调用runEntranceAnimation导致首次进入密码页无法自动拉起键盘问题
                [self showKeyBoardView];
            });
        }
    }
    
    if (!self.nonFirstAppear && self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard && [self.response.deskConfig isFastEnterBindCard]) {
        // 主动发起进入绑卡
        CJ_CALL_BLOCK(self.inputCompleteBlock, @"");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[CJPayToast sharedToast] toastText:@"当前无可用银行卡，请先完成绑卡，再支付" inWindow:self.cj_window];
        });
    }
    
    self.nonFirstAppear = YES;
    [self p_updateOtherVerifyButtonStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [CJKeyboard resignFirstResponder:self.passwordContentView.inputPasswordView];
}

#pragma mark - public method

// 更新验密页错误文案
- (void)updateErrorText:(NSString *)text {
    if (self.viewModel.isDynamicLayout) {
        [self.passwordContentView updateErrorText:text];
    } else {
        self.passwordContentView.errorInfoActionView.hidden = !Check_ValidString(text);
        self.passwordContentView.errorInfoActionView.errorLabel.text = CJString(text);        
    }
    [self showKeyBoardView];
}

- (void)reset {    
    self.passwordContentView.guideView.confirmButton.enabled = NO;
    [self.passwordContentView.inputPasswordView clearInput];
}

- (void)showLoadingStatus:(BOOL)isLoading {
    if (isLoading) {
        self.title = @"";
        [self retractKeyBoardView];
        self.otherVerifyButton.hidden = YES;
    } else {
        if (self.isSimpleVerifyStyle) {
            self.title = [self p_pageTitleStr];
        }
        [self p_updateOtherVerifyButtonStatus];
        [self showKeyBoardView];
    }
}

- (void)showKeyBoardView {
    if ([self.passwordContentView isPasswordVerifyStyle]) {
        [CJKeyboard becomeFirstResponder:self.passwordContentView.inputPasswordView];
    } else {
        [CJKeyboard resignFirstResponder:self.passwordContentView.inputPasswordView]; // TODO: 是否可以删掉
    }
}

- (void)retractKeyBoardView {
    [CJKeyboard resignFirstResponder:self.passwordContentView.inputPasswordView];
}


// 设置验密页右上角验证方式和文案
- (void)updateOtherVerifyType:(CJPayPasswordSwitchOtherVerifyType)verifyType btnText:(NSString *)text {
    [self.otherVerifyButton setTitle:text forState:UIControlStateNormal];
    self.otherVerifyType = verifyType;
}

- (void)updateChoosedPayMethodWhenBindCardPay {
    // 绑卡并支付，绑卡成功，支付失败，刷新逻辑
    BOOL isSuggestStyle = [self.viewModel isSuggestCardStyle];
    
    [self.verifyManager useLatestResponse];
    self.response = self.verifyManager.response;
    self.viewModel.response = self.verifyManager.response;
    self.chooseDyPayMethodManager.response = self.viewModel.response;
    self.signPayChoosePayMethodManager.response = self.viewModel.response;
    
    self.viewModel.defaultConfig = [self.verifyManager.response.payTypeInfo getDefaultDyPayConfig];
    
    if (isSuggestStyle && !self.viewModel.isDynamicLayout) {
        self.isPasswordVerifyStyle = YES;
        CJPayMasReMaker(self.containerView, {
            make.left.right.bottom.equalTo(self.view);
            make.height.mas_equalTo([self containerHeight]);
        });
        
        CJPayMasReMaker(self.navigationBar, {
            make.left.right.top.equalTo(self.containerView);
            make.height.mas_equalTo(50);
        });
        CJPayMasReMaker(self.topView, {
            make.left.top.right.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-[self containerHeight]);
        });
        CJPayMasReMaker(self.contentView, {
            make.left.right.bottom.equalTo(self.containerView);
            make.height.equalTo(self.containerView).offset(-50);
        });
        [self.passwordContentView removeFromSuperview];
        _passwordContentView = nil;
        
        BOOL hideMerchantNameLabel = self.viewModel.hideMerchantNameLabel;
        [self.contentView addSubview:self.passwordContentView];
        CJPayMasReMaker(self.passwordContentView, {
            make.top.equalTo(hideMerchantNameLabel?self.contentView: self.merchantNameLabel.mas_bottom);
            make.left.right.equalTo(self.contentView);
            if (self.passwordContentView.isPasswordVerifyStyle) {
                make.bottom.equalTo(self.contentView).offset(-[self.passwordContentView.inputPasswordView getFixKeyBoardHeight]);
            } else {
                make.bottom.equalTo(self.contentView).offset(-46 + (CJ_IPhoneX ? 34 : 0));
            }
        });
        
        [self.containerView setNeedsLayout];
        [self.containerView layoutIfNeeded];
    }
    
    [self.passwordContentView refreshDynamicViewContent];
    @CJWeakify(self)
    if (self.viewModel.defaultConfig.type == BDPayChannelTypeAddBankCard) {
        [self switchToPasswordVerifyStyle:NO showPasswordVerifyKeyboard:NO completion:^{
            @CJStrongify(self)
            // 进入选卡页
            if (!isSuggestStyle) { // 这里绑卡结果是cancel的时候会走到这里的逻辑，所以需要判断是否是新客，新客的话不会重新进入绑卡页。
                [self gotoChooseCardList];
            }
        }];
        [self p_updateConfirmButtonTitle];
    } else {
        [self switchToPasswordVerifyStyle:![self p_isFacePayment] && ![self p_isFingerprintPayment] showPasswordVerifyKeyboard:NO completion:^{
            @CJStrongify(self)
            // 进入选卡页
            [self gotoChooseCardList];
        }];
    }
    
    if (self.viewModel.defaultConfig) {
        [self.passwordContentView updatePayConfigContent:@[self.viewModel.defaultConfig]];
    }
    self.isPasswordOfLastVerifyStyle = [self.passwordContentView isPasswordVerifyStyle];
    [self p_updateOtherVerifyButtonStatus];
}

#pragma mark - private method

- (void)p_setupUI {
    // 验密页动态布局（自适应高度）
    if (self.viewModel.isDynamicLayout) {
        [self p_setupUIForDynamicLayout];
        return;
    }
    
    BOOL hideMerchantNameLabel = self.viewModel.hideMerchantNameLabel;
    if (!hideMerchantNameLabel) {
        [self.contentView addSubview:self.merchantNameLabel];
        CJPayMasMaker(self.merchantNameLabel, {
            make.top.left.right.equalTo(self.contentView);
            make.height.mas_equalTo(21);
        });
    }
    
    if ([self.viewModel isSuggestCardStyle]) {
        CJPayMasReMaker(self.containerView, {
            make.left.right.bottom.equalTo(self.view);
            make.top.equalTo(self.navigationBar);
        });
        
        CJPayMasReMaker(self.topView, {
            make.left.top.right.equalTo(self.view);
            make.bottom.equalTo(self.containerView.mas_top).priorityLow();
        });
        
        CJPayMasReMaker(self.contentView, {
            make.left.right.bottom.equalTo(self.containerView);
            make.top.equalTo(self.navigationBar.mas_bottom);
        });
        self.isPasswordVerifyStyle = NO;
        [self.passwordContentView usePasswordVerifyStyle:NO];
    }
    
    [self.contentView addSubview:self.passwordContentView];
    CJPayMasMaker(self.passwordContentView, {
        make.top.equalTo(hideMerchantNameLabel?self.contentView: self.merchantNameLabel.mas_bottom);
        make.left.right.equalTo(self.contentView);
        if ([self.viewModel isSuggestCardStyle]) {
            make.bottom.equalTo(self.contentView).offset(CJ_IPhoneX ? -34 : 0);
        } else if (self.passwordContentView.isPasswordVerifyStyle) {
            make.bottom.equalTo(self.contentView).offset(-[self.passwordContentView.inputPasswordView getFixKeyBoardHeight]);
        } else {
            make.bottom.equalTo(self.contentView).offset(-46 + (CJ_IPhoneX ? 34 : 0));
        }
    });
    
    if (Check_ValidString(self.viewModel.response.payTypeInfo.homePagePictureUrl)) {
        [self.contentView addSubview:self.titleBGImageView];
        [self.contentView bringSubviewToFront:self.merchantNameLabel];
        [self.containerView bringSubviewToFront:self.navigationBar];
        
        CJPayMasMaker(self.titleBGImageView, {
            make.top.equalTo(self.navigationBar.mas_top);
            make.left.right.equalTo(self.navigationBar);
            make.height.mas_equalTo(80);
        });
    }
    
    if (CJ_Pad) {
        self.navigationBar.titleLabel.hidden = YES;
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

// 验密页动态布局
- (void)p_setupUIForDynamicLayout {
    
    // UI组件自适应高度
    [self p_containerViewLayoutDynamically];
    CJPayMasReMaker(self.topView, {
        make.left.top.right.equalTo(self.view);
        make.bottom.equalTo(self.containerView.mas_top).priorityLow();
    });
    
    if (Check_ValidString(self.viewModel.response.payTypeInfo.homePagePictureUrl)) {

        [self.containerView insertSubview:self.titleBGImageView atIndex:0];
        
        CJPayMasMaker(self.titleBGImageView, {
            make.top.equalTo(self.containerView);
            make.left.right.equalTo(self.containerView);
            make.height.mas_equalTo(80);
        });
        self.navigationBar.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    [self p_updateConfirmButtonTitle];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    if (self.containerView.cj_height > 0) {
        // O项目场景下，半屏页面入场时的背景动画
        CGFloat startHeight = self.containerView.cj_height > 200 ? self.containerView.cj_height - 200 : 0;
        [self p_sendNotificationWithContainerHeight:startHeight needAnimate:NO];
        
        CGFloat endHeight = self.containerView.cj_height;
        [self p_sendNotificationWithContainerHeight:endHeight needAnimate:YES];
    }
}

// passwordContentView动态布局，containerView的布局高度依赖于passwordContentView
- (void)p_containerViewLayoutDynamically {
    self.isFixedContainerHeight = NO;
    
//    [self.contentScrollView removeFromSuperview];
//    [self.contentScrollView cj_removeAllSubViews];
//    self.contentScrollView.hidden = YES;
    
    [self.contentView addSubview:self.passwordContentView];
    
    CJPayMasReMaker(self.containerView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.navigationBar);
    });
        
    CJPayMasReMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.containerView);
        make.top.equalTo(self.navigationBar.mas_bottom);
    });
    
    CJPayMasReMaker(self.passwordContentView, {
        make.left.right.top.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-[self p_getPasswordContentViewBottomMargin]);
    });
}

// passwordContentView动态布局，但containerView整体静态布局（固定高度）
- (void)p_containerViewLayoutFixedHeight:(CGFloat)fixContainerHeight
                       dynamicViewScroll:(BOOL)needScroll {
    // 产品逻辑修改，顶到最上面的时候不需要整个页面可滑动。
    self.isFixedContainerHeight = YES;

    // 强制containerView固定高度展示
    CJPayMasReMaker(self.containerView, {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(fixContainerHeight);
    });
    
    CJPayMasReMaker(self.contentView, {
        make.left.right.bottom.equalTo(self.containerView);
        make.height.equalTo(self.containerView).offset(-50);
    });
    
    // 自撑开高度过高时，passwordContentView需要可滑动
//    if (needScroll) {
//        self.contentScrollView.hidden = NO;
//        [self.contentView addSubview:self.contentScrollView];
//        [self.contentScrollView addSubview:self.passwordContentView];
//
//        CGFloat scrollHeight = fixContainerHeight - [self p_getPasswordContentViewBottomMargin] - 50;
//        CJPayMasReMaker(self.contentScrollView, {
//            make.top.left.right.equalTo(self.contentView);
//            make.height.mas_equalTo(scrollHeight);
//        });
//
//        CJPayMasReMaker(self.passwordContentView, {
//            make.edges.equalTo(self.contentScrollView);
//            make.width.equalTo(self.contentView);
//        });
//    } else {
//        // 自撑开高度过低时，passwordContentView距上布局
//        [self.contentScrollView removeFromSuperview];
//        [self.contentScrollView cj_removeAllSubViews];
//        self.contentScrollView.hidden = YES;
//
//        [self.contentView addSubview:self.passwordContentView];
//        CJPayMasReMaker(self.passwordContentView, {
//            make.left.right.top.equalTo(self.contentView);
//        });
//    }
    // ⬇️
    // 自撑开高度过高时，deductDetailView需要可滑动,其他的暂时不支持可滑动
    
    if (needScroll) {
        [self.passwordContentView.deductDetailView layoutIfNeeded]; // layout 一下 获取deductDetailView的高度
        CGFloat scrollHeight = [self.passwordContentView.deductDetailView cj_height] - ([self.containerView cj_height] - fixContainerHeight);
        [self.passwordContentView deductDetailViewNeedScroll:YES deductDetailHeight:scrollHeight];
    } else {
        [self.passwordContentView deductDetailViewNeedScroll:NO deductDetailHeight:self.passwordContentView.deductDetailView.frame.size.height];
    }
    [self.contentView addSubview:self.passwordContentView];
    CJPayMasReMaker(self.passwordContentView, {
        make.left.right.top.equalTo(self.contentView);
    });
}

// commonPasswordContentView的frame变化处理
- (void)p_dynamicViewFrameChange:(CGRect)newFrame {
    if (!self.viewModel.isDynamicLayout) {
        return;
    }
    
    CGFloat currentContainerHeight = newFrame.size.height + 50 + [self p_getPasswordContentViewBottomMargin];
    BOOL needLayout = NO;
    if (self.passwordContentView.status == CJPayPasswordContentViewStatusPassword) {
        if (currentContainerHeight < CJ_HALF_SCREEN_HEIGHT_LOW) {
            // 如果自适应高度低于470，则强制将半屏高度设置为470
            [self p_containerViewLayoutFixedHeight:CJ_HALF_SCREEN_HEIGHT_LOW dynamicViewScroll:NO];
            needLayout = YES;
            
        } else if (currentContainerHeight >= CJ_SCREEN_HEIGHT - CJ_STATUSBAR_HEIGHT) {
            // 如果自适应高度超出可显示区域，则强制将半屏高度设为屏幕高度，且passwordContantView可滑动
            //                                  ⬇️
            // 如果自适应高度超出可显示区域，则强制将半屏高度设为屏幕高度，且如果有deductDetailView 则 其可滑动
            [self p_containerViewLayoutFixedHeight:CJ_SCREEN_HEIGHT - CJ_STATUSBAR_HEIGHT dynamicViewScroll:YES];
            needLayout = YES;
            
        } else if (self.isFixedContainerHeight) {
            // 如果当前为固定高度 且 新的自适应布局高度不满足边界Case，则半屏containerView改为自适应高度布局
            [self p_containerViewLayoutDynamically];
            needLayout = YES;
        }
    }
    if (needLayout) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}

// commonPasswordContentView与contentView的底部约束间距
- (CGFloat)p_getPasswordContentViewBottomMargin {
    return self.passwordContentView.status == CJPayPasswordContentViewStatusPassword ? [self.passwordContentView.inputPasswordView getFixKeyBoardHeight] + 24 : CJ_NewTabBarSafeBottomMargin;
}

- (void)p_comfirmButtonClickWithContent:(NSString *)passwordStr {
    self.viewModel.confirmBtnClickTimes = self.viewModel.confirmBtnClickTimes + 1;
    [self.viewModel trackPageClickWithButtonName:CJString(self.passwordContentView.confirmButton.titleLabel.text) params:@{@"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
    CJ_CALL_BLOCK(self.inputCompleteBlock, passwordStr);
    [CJKeyboard resignFirstResponder:self.passwordContentView.inputPasswordView];
    [self reset];
}

//  收到绑卡成功通知后的处理
- (void)p_bindCardSuccess:(NSNotification *)notification  {
    if (![notification.object isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSDictionary *dic = (NSDictionary *)notification.object;
    NSInteger isCancelPay = [dic cj_integerValueForKey:@"is_cancel_pay"];
    // 绑卡成功没有继续支付，点击取消后刷新下单
    if (isCancelPay == 1) {
        // 绑卡成功通知发出后绑卡相关页面还未关闭，延迟处理
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.verifyManager sendEventTOVC:CJPayHomeVCEventBindCardSuccessPayFail obj:nil];
            [self.verifyManager exitBindCardStatus];
        });
    }
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
    [CJKeyboard resignFirstResponder:self.passwordContentView.inputPasswordView];
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
    [self p_updateOtherVerifyButtonStatus];
    [self p_resetOtherVerifyBtnText];
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
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
        return;
    }
    if ([self p_isPasswordStatus]) {
        [CJToast toastText:CJPayLocalizedStr(@"监测到截屏，请注意密码安全") inWindow:self.cj_window];
    }
}

- (void)p_screenCaptureDetected:(NSNotification *)notification {
    if (![notification isKindOfClass:NSNotification.class]) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
        return;
    }

    if (@available(iOS 11.0, *)) {
        UIScreen *screen = [notification object];
        if ([screen isKindOfClass:UIScreen.class] && [screen isCaptured] && [self p_isPasswordStatus]) {
            [CJToast toastText:CJPayLocalizedStr(@"监测到录屏，请注意密码安全") inWindow:self.cj_window];
        }
    }
    
}

- (BOOL)p_isPasswordStatus {
    if (self.viewModel.isDynamicLayout) {
        return self.passwordContentView.status == CJPayPasswordContentViewStatusPassword;
    } else {
        return [self.passwordContentView isPasswordVerifyStyle];
    }
}

- (void)p_clickedOtherVerifyButton {
    CJ_DelayEnableView(self.otherVerifyButton);
    if ([self.passwordContentView isPasswordVerifyStyle]) {
        [self.viewModel trackWithEventName:@"wallet_password_verify_page_click" params:@{@"button_name":CJString( self.otherVerifyButton.titleLabel.text), @"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
    } else {
        [self.viewModel trackWithEventName:@"wallet_o_project_fingerprint_verify_pay_confirm_click" params:@{@"button_name":CJString(self.otherVerifyButton.titleLabel.text), @"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
    }
    
    if (!(self.otherVerifyType == CJPayPasswordSwitchOtherVerifyTypeBio) || self.isSimpleVerifyStyle) {
        CJ_CALL_BLOCK(self.otherVerifyPayBlock, self.otherVerifyType);
    } else {        
        [self switchToPasswordVerifyStyle:![self.passwordContentView isPasswordVerifyStyle]];
        self.isPasswordOfLastVerifyStyle = [self.passwordContentView isPasswordVerifyStyle];
        if ([self.passwordContentView isPasswordVerifyStyle]) {
            // 密码页上报
            [self.viewModel trackWithEventName:@"wallet_o_project_fingerprint_verify_pay_page_imp" params:@{}];
        } else {
            // 生物页上报
            [self.viewModel trackWithEventName:@"wallet_password_verify_page_imp" params:@{}];
        }
    }
}

- (void)p_clearPasswordInput {
    [self.passwordContentView.inputPasswordView clearInput];
}

// 根据subPayTypeDisplayInfoList构造初始验密页支付方式信息
- (NSArray<CJPayDefaultChannelShowConfig *> *)p_defaultDisplayConfigs {
    CJPayDefaultChannelShowConfig *defaultConfig = [self.viewModel.response.payTypeInfo getDefaultDyPayConfig];
    return @[defaultConfig];
}

- (BOOL)p_isSkipPwd {
    if ([self.response.userInfo.pwdCheckWay isEqualToString:@"3"]) {
        return YES;
    }
    return NO;
}

- (BOOL)p_isFacePayment {
    if ([self.response.userInfo.pwdCheckWay isEqualToString:@"2"]) {
        return [self p_isBioPayAvailable];
    }
    
    return NO;
}

- (BOOL)p_isFingerprintPayment {
    if ([self.response.userInfo.pwdCheckWay isEqualToString:@"1"]) {
        return [self p_isBioPayAvailable];
    }
    
    return NO;
}

- (void)p_updateConfirmButtonTitle {
    NSString *confirmBtnTitle = @"";
    // 根据选中支付方式来更新确认按钮文案
    CJPayDefaultChannelShowConfig *showBankCardConfig = self.viewModel.defaultConfig;
    if (Check_ValidString(showBankCardConfig.tradeConfirmButtonText)) {
        confirmBtnTitle = CJString(showBankCardConfig.tradeConfirmButtonText);
    } else if ([showBankCardConfig isNeedReSigning]) {
        confirmBtnTitle = CJPayLocalizedStr(@"确认支付");
    } else {
        switch (showBankCardConfig.type) {
            case BDPayChannelTypeAddBankCard:
                confirmBtnTitle = CJPayLocalizedStr(@"添加银行卡并支付");
                break;
            case BDPayChannelTypeBankCard:
            case BDPayChannelTypeBalance:
            case BDPayChannelTypeIncomePay:
                confirmBtnTitle = CJPayLocalizedStr(@"确认支付");
                if (showBankCardConfig.type == BDPayChannelTypeAddBankCard) {
                    confirmBtnTitle = CJPayLocalizedStr(@"添加银行卡并支付");
                } else if ([self p_isFacePayment]) {
                    confirmBtnTitle = CJPayLocalizedStr(@"面容支付");
                } else if ([self p_isFingerprintPayment]) {
                    confirmBtnTitle = CJPayLocalizedStr(@"指纹支付");
                }
                break;
            case BDPayChannelTypeCreditPay:
                confirmBtnTitle = CJPayLocalizedStr(@"确认交易");
            default:
                break;
        }
    }
    
    [self.passwordContentView.confirmButton cj_setBtnTitle:confirmBtnTitle];
}

- (CJPayPasswordContentViewStatus)p_getPasswordViewOriginStatus {
    if ([self.viewModel isSuggestCardStyle]) {
        return CJPayPasswordContentViewStatusOnlyAddCard;
    }
    if (![self p_isPassVerifyStyle]) {
        if ([self p_isVerifyBioWhenPaswordViewAppear]) {
            return CJPayPasswordContentViewStatusPassword;
        }
        return CJPayPasswordContentViewStatusLowConfirm;
    } else {
        return CJPayPasswordContentViewStatusPassword;
    }
}

- (BOOL)p_isPassVerifyStyle {
    return self.viewModel.defaultConfig.type != BDPayChannelTypeAddBankCard &&
           ![self p_isFacePayment] &&
           ![self p_isFingerprintPayment] &&
           ![self.viewModel isNeedResignCard] &&
           ![self p_isSkipPwd];
}

- (BOOL)p_isVerifyBioWhenPaswordViewAppear {
    return self.isSimpleVerifyStyle && ([self p_isFacePayment] || [self p_isFingerprintPayment]);
}

- (void)gotoChooseCardList {
    CGFloat choosePageHeight = self.containerView.cj_height;
    CGFloat minChoosePageHeight = 580 + CJ_TabBarSafeBottomMargin; // 选卡页最小高度
    if (self.passwordContentView.status == CJPayPasswordContentViewStatusLowConfirm && choosePageHeight < minChoosePageHeight) {
        choosePageHeight = minChoosePageHeight;
    }
    self.chooseDyPayMethodManager.height = choosePageHeight; // 设置选卡页高度
    self.signPayChoosePayMethodManager.height = choosePageHeight;
    
    if (self.viewModel.defaultConfig.isCombinePay) {
        [self.chooseDyPayMethodManager setSelectedBalancePayMethod];
    }
    if ([self.viewModel.outDisplayInfoModel isDeductPayMode]) {
        [self.signPayChoosePayMethodManager gotoSignPayChooseDyPayMethod]; // 轮扣情况下走轮扣的选卡页
    } else {
        [self.chooseDyPayMethodManager gotoChooseDyPayMethod]; // 前往选卡页
    }
}

- (void)switchToPasswordVerifyStyle:(BOOL)isPasswordVerifyStyle {
    [self switchToPasswordVerifyStyle:isPasswordVerifyStyle showPasswordVerifyKeyboard:YES];
}

- (void)switchToPasswordVerifyStyle:(BOOL)isPasswordVerifyStyle showPasswordVerifyKeyboard:(BOOL)isShowPasswordVerifyKeyboard {
    
    [self switchToPasswordVerifyStyle:isPasswordVerifyStyle showPasswordVerifyKeyboard:isShowPasswordVerifyKeyboard completion:nil];
}

- (void)switchToPasswordVerifyStyle:(BOOL)isPasswordVerifyStyle showPasswordVerifyKeyboard:(BOOL)isShowPasswordVerifyKeyboard
                         completion:(nullable void(^)(void))completionBlock {
    
    // 动态布局时，高矮形态切换逻辑与常规布局不同
    if (self.viewModel.isDynamicLayout) {
        CJPayPasswordContentViewStatus switchStatus = isPasswordVerifyStyle ? CJPayPasswordContentViewStatusPassword : CJPayPasswordContentViewStatusLowConfirm;
        if ([self.viewModel isSuggestCardStyle]) {
            switchStatus = CJPayPasswordContentViewStatusOnlyAddCard;
        }
        [self p_switchPasswordViewStatus:switchStatus needShowKeyboard:isShowPasswordVerifyKeyboard completion:completionBlock];
        return;
    }
    
    if ([self.passwordContentView isPasswordVerifyStyle] == isPasswordVerifyStyle) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayVerifyPageDidChangedHeightNotification object:@([self containerHeight])];
        return;
    }
    
    if (self.isSimpleVerifyStyle) {
        [self retractKeyBoardView];
        [self p_clickedOtherVerifyButton];
        return;
    }
    
    [self.passwordContentView usePasswordVerifyStyle:isPasswordVerifyStyle];
    [self retractKeyBoardView];
    
    CGFloat currentTopOffset = self.containerView.frame.origin.y;
    self.isPasswordVerifyStyle = [self.passwordContentView isPasswordVerifyStyle];

    [self.view setNeedsUpdateConstraints];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayVerifyPageDidChangedHeightNotification object:@([self containerHeight])];
    
    @weakify(self);
    [UIView animateWithDuration:0.2 animations:^{
        @strongify(self);
        CJPayMasUpdate(self.containerView, {
            make.top.equalTo(self.view).offset([self.passwordContentView isPasswordVerifyStyle] ? currentTopOffset - [self animateHeight] : currentTopOffset + [self animateHeight]);
            make.bottom.equalTo(self.view).offset([self.passwordContentView isPasswordVerifyStyle] ? 0 : [self animateHeight]);
        });
        [self p_resetOtherVerifyBtnText];
        
        // 告知父类控件绘制，不添加注释的这两行的代码无法生效
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        @strongify(self);
        CJPayMasUpdate(self.containerView, {
            make.bottom.equalTo(self.view);
        });
        CJPayMasReMaker(self.passwordContentView, {
            make.top.equalTo(self.viewModel.hideMerchantNameLabel? self.contentView: self.merchantNameLabel.mas_bottom);
            make.left.right.equalTo(self.contentView);
            if (self.passwordContentView.isPasswordVerifyStyle) {
                make.bottom.equalTo(self.contentView).offset(-[self.passwordContentView.inputPasswordView getFixKeyBoardHeight]);
            } else {
                make.bottom.equalTo(self.contentView).offset(-46 + (CJ_IPhoneX ? 34 : 0));
            }
        });
        // 更新右上角文案
        [self p_updateConfirmButtonTitle];
        if (isShowPasswordVerifyKeyboard) {
            [self showKeyBoardView];
        }
        CJ_CALL_BLOCK(completionBlock);
    }];
}

// 动态布局时的高矮半屏形态切换
- (void)p_switchPasswordViewStatus:(CJPayPasswordContentViewStatus)status needShowKeyboard:(BOOL)showKeyboard
                        completion:(nullable void(^)(void))completionBlock {
    
    if (!self.nonFirstAppear) {
        return;
    }
    
    [self retractKeyBoardView];
    // 极简样式下不具备形态切换能力，点击右上角按钮直接调otherVerifyPayBlock
    if (self.isSimpleVerifyStyle) {
        [self p_clickedOtherVerifyButton];
        return;
    }
    // 在containerView底下插入填充视图，以避免做动画时因自适应高度变化而导致出现空缺
    UIView *switchBackgroundView = [UIView new];
    switchBackgroundView.backgroundColor = [self getHalfPageBGColor];
    [self.view insertSubview:switchBackgroundView belowSubview:self.containerView];
    CJPayMasMaker(switchBackgroundView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.contentView);
    });
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    if (self.isFixedContainerHeight) {
        [self p_containerViewLayoutDynamically];
    }
    // 自适应形态切换核心代码
    [self.passwordContentView switchPasswordViewStatus:status];
    CJPayMasUpdate(self.passwordContentView, {
        make.bottom.equalTo(self.contentView).offset(-[self p_getPasswordContentViewBottomMargin]);
    });
    
    @CJWeakify(self)
    [UIView animateWithDuration:0.2 animations:^{
        @CJStrongify(self)
        
        [self p_resetOtherVerifyBtnText];
        [self.view layoutIfNeeded]; //通过强制刷新来做视图动画
        [self p_sendNotificationWithContainerHeight:[self containerHeight] needAnimate:YES]; //发通知告知containerView的新frame
        
    } completion:^(BOOL finished) {
        @CJStrongify(self)
        [switchBackgroundView removeFromSuperview]; //移除背景填充视图
        [self p_updateConfirmButtonTitle]; // 更新确认按钮文案
        if (showKeyboard) {
            [self showKeyBoardView];
        }
        CJ_CALL_BLOCK(completionBlock);
    }];
}

// 发通知告知外部 containerView的当前高度
- (void)p_sendNotificationWithContainerHeight:(CGFloat)containerHeight
                                  needAnimate:(BOOL)animated {
    NSDictionary *params = @{@"need_animate": @(animated),
                             @"container_height": @(containerHeight)
                            };
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayVerifyPageDidChangedHeightNotification object:params];
}

// 重设otherVerifyBtn文案
- (void)p_resetOtherVerifyBtnText {
    NSString *btnStr = @"";
    if (self.otherVerifyType == CJPayPasswordSwitchOtherVerifyTypeBio) {
        if ([self.passwordContentView isPasswordVerifyStyle]) {
            btnStr = ([self.response.topRightBtnInfo.bioType isEqualToString:@"FACEID"] && [self p_isBioPayAvailable]) ? CJPayLocalizedStr(@"使用面容") : CJPayLocalizedStr(@"使用指纹");
        } else {
            btnStr = CJPayLocalizedStr(@"使用密码");
        }
    } else if (self.otherVerifyType == CJPayPasswordSwitchOtherVerifyTypeRecogFace) {
        btnStr = CJPayLocalizedStr(@"使用刷脸");
    }
    [self updateOtherVerifyType:self.otherVerifyType btnText:btnStr];
    [self p_updateOtherVerifyButtonStatus];
}

- (void)p_updateOtherVerifyButtonStatus {
    self.otherVerifyButton.hidden = [self p_isNeedHiddenOtherVerifyButton];
}

- (BOOL)p_isNeedHiddenOtherVerifyButton {
    if ([self.viewModel isSuggestCardStyle]) {
        return YES;
    }
    
    if ([self p_isShowBioVerify] && ![self p_isBioPayAvailable]) {
        return YES;
    }
    
    if ([self.viewModel isSuggestCardStyle]) {
        return YES;
    }
    
    CJPayDefaultChannelShowConfig *currentDefaultShowConfig = self.viewModel.defaultConfig;
    if ([currentDefaultShowConfig isNeedReSigning] || currentDefaultShowConfig.type == BDPayChannelTypeAddBankCard) {
        return YES;
    }
    
    return NO;
}

#pragma mark - override

- (void)back {
    [self.viewModel trackPageClickWithButtonName:@"关闭" params:@{@"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
    [super back];
}

- (void)closeWithAnimation:(BOOL)animated
                 comletion:(nullable AnimationCompletionBlock)completion {
    self.passwordContentView.inputPasswordView.allowBecomeFirstResponder = NO;
    [super closeWithAnimation:animated comletion:completion];
}

- (CGFloat)loadingShowheight {
    
    CGFloat loadingTopMargin = self.viewModel.isDynamicLayout? 146: 140;
    if (self.viewModel.hideMerchantNameLabel) {
        loadingTopMargin = loadingTopMargin - 21;
    }
    return [self containerHeight] - loadingTopMargin;
}

- (CGFloat)containerHeight {
    /**
     https://www.figma.com/file/z2SR6Duw4ZmxFnlHnurzqn/%E6%8A%96%E9%9F%B3%E6%94%AF%E4%BB%98-O%E9%A1%B9%E7%9B%AE?node-id=105%3A5306&t=mrzwAdpHkuahIO49-0
     基本高度 : 580
     有引导 :     616
     有引导 + button : 不存在这个场景
     */
//    BOOL needLowerHeight = self.viewModel.hideChoosedPayMethodView; //如果需要隐藏“支付方式切换UI组件”，则半屏验密页的高度需降低一挡
    if (self.containerView.cj_height > 0 && (self.viewModel.isDynamicLayout || [self.viewModel isSuggestCardStyle]))
        return self.containerView.cj_height;
    
    CGFloat baseHeight = 580;
    if ([self.viewModel isNeedShowGuide]) {
        if ([self.viewModel isShowComfirmButton]) {
            baseHeight = 700;
        } else {
            baseHeight = 616;
        }
    }
    
    if (!self.isPasswordVerifyStyle) {
        baseHeight = 380;
    }
    
    if (self.isSimpleVerifyStyle) {
        baseHeight = 449;
    }
    
    CGFloat additionalHeight = 0;
    if (CJ_IPhoneX) {
        additionalHeight = 34;
    }
    
    return baseHeight + additionalHeight;
}

#pragma mark - loading
- (void)startLoading {
    @CJStartLoading(self.passwordContentView.confirmButton)
}

- (void)stopLoading {
    @CJStopLoading(self.passwordContentView.confirmButton)
}

// 在生物验证样式和密码验证样式之间切换时，指定 containerView 的高度
- (CGFloat)animateHeight {
    if ([self.viewModel isNeedShowGuide]) {
        return 616 - 380;
    } else {
        return 580 - 380;
    }
}

#pragma mark - CJPayChooseDyPayMethodDelegate
- (void)changeCombinedBankPayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *_Nullable)view {
    if ([payContext.defaultConfig isNeedReSigning] && [self.changeMethodDelegate respondsToSelector:@selector(signPayWithPayContext:loadingView:)]) {
        [self.changeMethodDelegate signPayWithPayContext:payContext loadingView:view];
        return;
    }

    CJPayDefaultChannelShowConfig *config = payContext.defaultConfig;
    CJPayChannelType combineType = self.combinedPayBankCard.combineType;
    config.isCombinePay = YES;
    self.combinedPayBankCard.combineType = combineType;
    
    if (config.type != BDPayChannelTypeAddBankCard) {
        self.combinedPayBankCard = payContext.defaultConfig;
        self.viewModel.defaultConfig = self.combinedPayBankCard;
        [self.passwordContentView updatePayConfigContent:@[self.combinedPayBankCard, self.combinedPayBalance]];
        [self.view layoutIfNeeded];
    }
    
    [self.changeMethodDelegate changePayMethod:payContext loadingView:view];
}

// 更改选中的支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *_Nullable)view {
    CJPayDefaultChannelShowConfig *config = payContext.defaultConfig;
    
    if (config.type == BDPayChannelTypeBalance && self.viewModel.defaultConfig.isCombinePay) {
        // 已经是组合支付，再次选择组合支付，直接返回
        return;
    }
    
    __block BOOL needLayout = NO;
    
    config.isCombinePay = NO;
    config.combineType = CJPayChannelTypeNone;
    
    if ([config isNeedReSigning] && [self.changeMethodDelegate respondsToSelector:@selector(signPayWithPayContext:loadingView:)]) {
        [self.changeMethodDelegate signPayWithPayContext:payContext loadingView:view];
        return;
    }
    
    BOOL isDeductPay = [self.response.payTypeInfo.outDisplayInfo isDeductPayMode]; // 判断是否是O项目签约代扣流程
    
    BOOL notImmediatelyBindCardPay = NO;
    if (config.type == BDPayChannelTypeBankCard || config.type == BDPayChannelTypeCreditPay || config.type == BDPayChannelTypeBalance || config.type == BDPayChannelTypeIncomePay) {
        if ((config.type == BDPayChannelTypeBalance || config.type == BDPayChannelTypeIncomePay) && config.showCombinePay) {
            // 组合支付
            self.combinedPayBalance = config;
            self.combinedPayBankCard = [self.response.payTypeInfo getDefaultBankCardPayConfig];
            self.combinedPayBankCard.isCombinePay = YES;
            self.combinedPayBankCard.combineType = config.type;
            
            payContext.defaultConfig = self.combinedPayBankCard;
            
            [self.passwordContentView updatePayConfigContent:@[self.combinedPayBankCard, config]];
            if (self.combinedPayBankCard.type == BDPayChannelTypeAddBankCard) {
                notImmediatelyBindCardPay = YES; // 无卡默认选择新卡组合时，不马上主动发起
                [self switchToPasswordVerifyStyle:NO];
            } else {
                needLayout = YES;
            }
            [self p_updateContentConstraints:payContext needLayout:needLayout];
        } else {
            config.isCombinePay = NO;
            config.combineType = CJPayChannelTypeNone;
            if (isDeductPay) {
                // 轮扣样式的时候 要先设置优先扣款卡，再更新UI信息
                NSString *payMode = [CJPaySignPayChoosePayMethodManager getPayMode:config.type];
                [self p_setMemberFirstPayMethod:payMode bankCardId:config.bankCardId completion:^(BOOL isSuccess) {
                    if (isSuccess) {
                        if ([self p_updateContentView:config]) {
                            needLayout = YES;
                        }
                        [self p_updateContentConstraints:payContext needLayout:needLayout];
                        [self.changeMethodDelegate changePayMethod:payContext loadingView:view];
                    } else {
                        NSString *warningMsg = CJPayLocalizedStr(@"设置优先扣款卡失败");
                        [[CJPayToast sharedToast] toastText:warningMsg inWindow:self.cj_window];
                    }
                    [self showKeyBoardView]; // 这里回到验密页loading，导致viewDidAppear的时候拉不起键盘，所以手动在这里拉起一下
                }];
            } else {
                if ([self p_updateContentView:config]) {
                    needLayout = YES;
                }
                [self p_updateContentConstraints:payContext needLayout:needLayout];
            }
        }
    }
    if (!notImmediatelyBindCardPay && (!isDeductPay || payContext.defaultConfig.type == BDPayChannelTypeAddBankCard)) {
        [self.changeMethodDelegate changePayMethod:payContext loadingView:view];
    }
}

- (BOOL)p_updateContentView:(CJPayDefaultChannelShowConfig *)config {
    [self.passwordContentView updatePayConfigContent:@[config]];
    
    BOOL needLayout = NO;
    if (self.combinedPayBankCard.type == BDPayChannelTypeAddBankCard && self.combinedPayBankCard.isCombinePay) {
        [self switchToPasswordVerifyStyle:self.isPasswordOfLastVerifyStyle];
    } else {
        needLayout = YES;
    }
    
    self.combinedPayBankCard = nil;
    self.combinedPayBalance = nil;
    
    return needLayout;
}

- (void)p_updateContentConstraints:(CJPayFrontCashierContext *)payContext needLayout:(BOOL)needLayout {
    self.viewModel.defaultConfig = payContext.defaultConfig;
    [self p_updateConfirmButtonTitle];
    if (needLayout) {
        [self.view layoutIfNeeded];
        if (self.viewModel.isDynamicLayout) {
            // 更新支付方式信息后，验密页高度可能有变化，需通知背景UI同步修改
            [self p_sendNotificationWithContainerHeight:[self containerHeight] needAnimate:YES];
        }
    }
}

- (void)p_setMemberFirstPayMethod:(NSString *)payMode bankCardId:(NSString *)bankCardId completion:(void(^)(BOOL isSuccess))completion {
    NSDictionary *bizParams = @{
        @"pay_type_item" : @{
            @"pay_mode" : CJString(payMode),
            @"bank_card_id" : CJString(bankCardId),
        },
        @"app_id" : CJString(self.response.merchant.appId),
        @"merchant_id": CJString(self.response.merchant.merchantId),
    };
    [CJPaySignPayChoosePayMethodManager setMemberFirstPayMethod:bizParams needLoading:YES completion:^(BOOL isSuccess) {
        CJ_CALL_BLOCK(completion, isSuccess);
    }];
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

- (UIImageView *)titleBGImageView {
    if (!_titleBGImageView) {
        _titleBGImageView = [UIImageView new];
        _titleBGImageView.backgroundColor = [UIColor clearColor];
        if (Check_ValidString(self.viewModel.response.payTypeInfo.homePagePictureUrl)) {
            [_titleBGImageView cj_setImageWithURL:[NSURL URLWithString:self.viewModel.response.payTypeInfo.homePagePictureUrl]];
        }
    }
    return _titleBGImageView;
}

- (UILabel *)merchantNameLabel {
    if (!_merchantNameLabel) {
        _merchantNameLabel = [UILabel new];
        _merchantNameLabel.font = [UIFont cj_fontOfSize:15];
        _merchantNameLabel.textColor = [UIColor cj_161823ff];
        _merchantNameLabel.textAlignment = NSTextAlignmentCenter;
        _merchantNameLabel.text = CJString(self.response.merchant.merchantShortToCustomer);
    }
    return _merchantNameLabel;
}

- (CJPayButton *)otherVerifyButton {
    if (!_otherVerifyButton) {
        _otherVerifyButton = [CJPayButton new];
        _otherVerifyButton.hidden = YES;//懒加载的地方可能并没有addsubview
        _otherVerifyButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        NSString *btnStr = @"";
        CJPayPasswordSwitchOtherVerifyType verifyType;
        
        [_otherVerifyButton setTitleColor:[UIColor cj_colorWithHexString:@"#04498D"] forState:UIControlStateNormal];

        if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FACEID"] && [self p_isBioPayAvailable]) {
            btnStr = CJPayLocalizedStr(@"使用面容");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeBio;
        } else if ([self.response.topRightBtnInfo.bioType isEqualToString:@"FINGER"] && [self p_isBioPayAvailable]) {
            btnStr = CJPayLocalizedStr(@"使用指纹");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeBio;
        } else if (self.viewModel.isFromOpenBioPayVerify) {
            btnStr = CJPayLocalizedStr(@"使用刷脸");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeRecogFace;
        } else {
            btnStr = Check_ValidString(self.response.topRightBtnInfo.desc)?CJPayLocalizedStr(self.response.topRightBtnInfo.desc):CJPayLocalizedStr(@"使用刷脸");
            verifyType = CJPayPasswordSwitchOtherVerifyTypeRecogFace;
        }
        [self updateOtherVerifyType:verifyType btnText:btnStr];
        
        _otherVerifyButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _otherVerifyButton.titleLabel.minimumScaleFactor = 0.1;
        @CJWeakify(self)
        [_otherVerifyButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self);
            [self p_clickedOtherVerifyButton];
        }];
    }
    return _otherVerifyButton;
}

- (CJPayPasswordContentViewV3 *)passwordContentView {
    if (!_passwordContentView) {
        _passwordContentView = [[CJPayPasswordContentViewV3 alloc] initWithViewModel:self.viewModel originStatus:[self p_getPasswordViewOriginStatus]];
        @CJWeakify(self)
        _passwordContentView.clickedPayMethodBlock = ^(NSString * _Nullable btnName) {
            @CJStrongify(self);
            [self.viewModel trackPageClickWithButtonName:@"切换支付方式" params:@{@"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
            [self gotoChooseCardList];
        };
        _passwordContentView.clickedCombinedPayBankPayMethodBlock = ^(NSString * _Nullable btnName) {
            @CJStrongify(self);
            [self.viewModel trackPageClickWithButtonName:@"组合支付更多组合方式" params:@{@"is_password_verify" : self.isPasswordVerifyStyle?@"1":@"0"}];
            [self.chooseDyPayMethodManager setSelectedPayMethod:self.viewModel.defaultConfig];
            self.chooseDyPayMethodManager.height = [self containerHeight] < 580 ? 580 : [self containerHeight];
            [self.chooseDyPayMethodManager gotoChooseDyPayMethodFromCombinedPay:YES]; // 前往选卡页
        };
        
        _passwordContentView.inputCompleteBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            [self p_completeInputWithContent:passwordStr];
        };
        _passwordContentView.confirmBtnClickBlock = ^(NSString * _Nonnull passwordStr) {
            @CJStrongify(self)
            if ([self.viewModel isSuggestCardStyle]) {
                CJPayDefaultChannelShowConfig *selectedConfig = [self.viewModel getSuggestChannelByIndex:self.selectedSuggestIndex];
                CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
                context.defaultConfig = selectedConfig;
                NSMutableDictionary *params = [NSMutableDictionary new];
                NSDictionary *bindCardInfo = @{
                    @"bank_code": CJString(selectedConfig.frontBankCode),
                    @"card_type": CJString(selectedConfig.cardType),
                    @"card_add_ext": CJString(selectedConfig.cardAddExt),
                    @"business_scene": CJString([selectedConfig bindCardBusinessScene])
                };
                [params cj_setObject:bindCardInfo forKey:@"bind_card_info"];
                context.extParams = params;
                [self changePayMethod:context loadingView:nil];
            } else {
                [self p_comfirmButtonClickWithContent:passwordStr];
            }
        };
        _passwordContentView.clickedGuideCheckboxBlock = ^(BOOL isSelected) {
            @CJStrongify(self)
            self.viewModel.isGuideSelected = isSelected;
            NSString *guideStatus = isSelected ? @"勾选" : @"取消";
            NSString *guideTrackStr = [NSString stringWithFormat:@"%@%@", guideStatus, CJString([self.viewModel getBioGuideTypeStr])];
            [self.viewModel trackPageClickWithButtonName:guideTrackStr];
        };
        _passwordContentView.clickProtocolViewBlock = ^{
            @CJStrongify(self)
            [self.viewModel trackPageClickWithButtonName:@"查看协议"];
        };
        _passwordContentView.didClickedMoreBankBlock = ^{
            @CJStrongify(self)
            [self p_comfirmButtonClickWithContent:@""];
        };
        _passwordContentView.didSelectedNewSuggestBankBlock = ^(int index) {
            @CJStrongify(self)
            self.selectedSuggestIndex = index;
            [self.passwordContentView updateDeductViewWhenNewCustomer:[self.viewModel getSuggestChannelByIndex:self.selectedSuggestIndex]];
        };
        _passwordContentView.dynamicViewFrameChangeBlock = ^(CGRect newFrame) {
            @CJStrongify(self)
            [self p_dynamicViewFrameChange:newFrame];
        };
        _passwordContentView.forgetPasswordBtnBlock = ^(NSString * _Nonnull btnText) {
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
    }
    return _passwordContentView;
}

- (UIScrollView *)contentScrollView {
    if (!_contentScrollView) {
        _contentScrollView = [UIScrollView new];
        _contentScrollView.backgroundColor = UIColor.clearColor;
        _contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentScrollView.showsVerticalScrollIndicator = NO;
        _contentScrollView.clipsToBounds = YES;
        _contentScrollView.bounces = NO;
        if (@available(iOS 11.0, *)) {
            [_contentScrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _contentScrollView;
}

- (CJPayChooseDyPayMethodManager *)chooseDyPayMethodManager {
    if (!_chooseDyPayMethodManager) {
        _chooseDyPayMethodManager = [[CJPayChooseDyPayMethodManager alloc] initWithOrderResponse:self.response];
        _chooseDyPayMethodManager.delegate = self;
        _chooseDyPayMethodManager.curSelectConfig = self.viewModel.defaultConfig;
        _chooseDyPayMethodManager.payMethodDisabledReasonMap = [[self getPayDisabledReasonMap] mutableCopy];
        _chooseDyPayMethodManager.closeChoosePageAfterChangeMethod = YES;
        _chooseDyPayMethodManager.isNotCloseChooseVCWhenBindCardSuccess = [[CJPayABTest getABTestValWithKey:CJPayABIsDouPayProcess exposure:NO] isEqualToString:@"1"]; //命中标准化流程，切卡页绑卡成功不关闭自身
    }
    return _chooseDyPayMethodManager;
}

- (CJPaySignPayChoosePayMethodManager *)signPayChoosePayMethodManager {
    if (!_signPayChoosePayMethodManager) {
        _signPayChoosePayMethodManager = [[CJPaySignPayChoosePayMethodManager alloc] initWithOrderResponse:self.response];
        _signPayChoosePayMethodManager.delegate = self;
        _signPayChoosePayMethodManager.closeChoosePageAfterChangeMethod = YES;
    }
    return _signPayChoosePayMethodManager;
}

@end
