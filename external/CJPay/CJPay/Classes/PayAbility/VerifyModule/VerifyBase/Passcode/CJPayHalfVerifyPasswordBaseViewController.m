//
//  CJPayHalfVerifyPasswordBaseViewController.m
//  Pods
//
//  Created by chenbocheng on 2022/4/12.
//

#import "CJPayHalfVerifyPasswordBaseViewController.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayProtocolManager.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayVerifyItem.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayToast.h"
#import "CJPayLoadingManager.h"

@interface CJPayHalfVerifyPasswordBaseViewController ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, assign) BOOL nonFirstAppear;
@property (nonatomic, strong) CJPayButton *topRightButton;

@end

@implementation CJPayHalfVerifyPasswordBaseViewController

#pragma mark - life cycle

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    CJPayLogAssert(NO, @"请覆写此方法");
    return nil;
}

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType viewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    CJPayLogAssert(NO, @"请覆写此方法");
    return nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // 转场需清除密码输入
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        [self p_clearPasswordInput];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nonFirstAppear = NO;
    self.title = [self p_pageTitleStr];
    [self.viewModel reset];
    if (self.viewModel.response.topRightBtnInfo || self.viewModel.isFromOpenBioPayVerify || self.viewModel.isStillShowingTopRightBioVerifyButton) {
        [self p_setupOtherVerifyBtn];
    }
    
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

- (void)p_screenShotDetected {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordBaseViewController.class]) {
        return;
    }
    
    [CJToast toastText:CJPayLocalizedStr(@"监测到截屏，请注意密码安全") inWindow:self.cj_window];
}

- (void)p_screenCaptureDetected:(NSNotification *)notification {
    if (![notification isKindOfClass:NSNotification.class]) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self];
    if (![topVC isKindOfClass:CJPayHalfVerifyPasswordBaseViewController.class]) {
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
    [self.viewModel.inputPasswordView clearInput];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CJKeyboard becomeFirstResponder:self.viewModel.inputPasswordView];
    
    if (!self.nonFirstAppear) {
        [self.viewModel pageFirstAppear];
        if (self.viewModel.response.payInfo.verifyDescType == 4) {
            [CJToast toastText:CJString(self.viewModel.response.payInfo.verifyDesc) inWindow:self.cj_window];
        }
    }
    self.nonFirstAppear = YES;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.viewModel.inputPasswordView resignFirstResponder];
}

- (void)closeWithAnimation:(BOOL)animated
                comletion:(nullable AnimationCompletionBlock)completion {
    self.viewModel.inputPasswordView.allowBecomeFirstResponder = NO;
    [super closeWithAnimation:animated comletion:completion];
}

#pragma mark - private method

- (NSString *)p_pageTitleStr {
    if (self.viewModel.isFromOpenBioPayVerify) {
        return CJPayLocalizedStr(@"输入密码并开通");
    }
    return Check_ValidString([CJPayBrandPromoteABTestManager shared].model.halfInputPasswordTitle) ? CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.halfInputPasswordTitle) : CJPayLocalizedStr(@"输入支付密码");
}

// 右上角文案展示
- (void)p_setupOtherVerifyBtn {
    [self.navigationBar addSubview:self.viewModel.otherVerifyButton];
        
    CJPayMasMaker(self.viewModel.otherVerifyButton, {
        make.right.equalTo(self.navigationBar).offset(-16);
        make.centerY.equalTo(self.navigationBar);
        make.height.mas_equalTo(20);
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right).offset(5);
    });
    
    if ([self p_isShowBioVerify] && ![self p_isBioPayAvailable]) {
        self.viewModel.otherVerifyButton.hidden = YES;//隐藏面容支付
    } else {
        self.viewModel.otherVerifyButton.hidden = NO;
    }
}

//检查指纹/面容是否可用
- (BOOL)p_isBioPayAvailable {
    return [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBioPayAvailableWithResponse:self.viewModel.response];
}

- (BOOL)p_isShowBioVerify {//面容支付
    return [self.viewModel.response.topRightBtnInfo.action isEqualToString:@"bio_verify"];
}

#pragma mark - override

- (void)back{
    [self.viewModel trackPageClickWithButtonName:@"0"];
    [self.viewModel.inputPasswordView resignFirstResponder];
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
    } else {
        [super back];
    }
}

- (BOOL)resignFirstResponder {
    [self.viewModel.inputPasswordView resignFirstResponder];
    return [super resignFirstResponder];
}

@end
