//
//  CJPayPassCodeSetBaseViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/1/7.
//

#import "CJPayPassCodeSetBaseViewController.h"

#import "CJPayFixKeyboardView.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPaySafeKeyboard.h"
#import "CJPaySafeInputView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKDefine.h"
#import "CJPayStyleButton.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPaySafeUtil.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPayPasswordSecondStepViewController.h"
#import "CJPaySettingPasswordRequest.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayProcessInfo.h"
#import "CJPayAlertUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayBindCardManager.h"

@implementation CJPayPassCodeSetBaseViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"retainInfo" : CJPayBindCardShareDataKeyRetainInfo,
        @"isHadShowRetain" : CJPayBindCardShareDataKeyIsHadShowRetain
    }];
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    return dict;
}

@end

@implementation CJPayPasswordSetModel

@end

@interface CJPayPassCodeSetBaseViewController () <CJPaySafeInputViewDelegate>
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) CJPayPasswordView *passwordView; // 密码输入新样式
@property (nonatomic, strong) CJPayFixKeyboardView *keyboardView;
@property (nonatomic, strong) UIView *keyboardSnapshotView;

@end

@implementation CJPayPassCodeSetBaseViewController

+ (nonnull Class<CJPayBindCardPageModelProtocol>)associatedModelClass {
    return [CJPayPassCodeSetBaseViewModel class];
}

- (void)createAssociatedModelWithParams:(nonnull NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayPassCodeSetBaseViewModel alloc] initWithDictionary:dict error:&error];
        if (error) {
            CJPayLogAssert(NO, @"创建 CJPayPassCodeSetBaseViewModel 失败.");
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self useCloseBackBtn];
    [self p_setupUI];
    
    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = CJ_Pad;
    } else {
        // Fallback on earlier versions
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    UIViewController *navLastChildVC = self.navigationController.viewControllers.lastObject;
    if (navLastChildVC != self && [navLastChildVC isKindOfClass:CJPayPassCodeSetBaseViewController.class]) {
        self.keyboardSnapshotView = self.keyboardView.snapshot;
        self.keyboardSnapshotView.frame = self.keyboardView.frame;
        [self.navigationController.view addSubview:self.keyboardSnapshotView];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.keyboardSnapshotView removeFromSuperview];
    self.keyboardSnapshotView = nil;
}

- (void)back {
    @CJWeakify(self)
    void (^back)(void) = ^{
        @CJStrongify(self)
        if (self.setModel.backCompletion) {
            self.setModel.backCompletion();
        } else {
            [super back];
        }
    };
    
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"确认放弃吗?")
                                       content:@""
                                leftButtonDesc:CJPayLocalizedStr(@"确认放弃")
                               rightButtonDesc:CJPayLocalizedStr(@"继续操作")
                               leftActionBlock:^{
        back();
    }
                               rightActioBlock:nil useVC:self];
}

- (void)trackerEventName:(NSString *)name params:(NSDictionary *)params {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
    [dict addEntriesFromDictionary:@{
        @"app_id": CJString(self.setModel.appID),
        @"merchant_id": CJString(self.setModel.merchantID),
        @"is_bind_mobile" : Check_ValidString(self.setModel.mobile) ? @"1" : @"0",
        @"is_chaselight" : @"1",
        @"process_id": CJString(self.setModel.processInfo.processId),
        @"source" : CJString(self.setModel.source),
        @"activity_info" : self.setModel.activityInfos ?: @[],
        @"addbcard_type" : self.setModel.isUnionBindCard ? @"云闪付" : @""}];
    
    [CJTracker event:name params:[dict copy]];
}

- (void)updateWithPassCodeType:(CJPayPassCodeType)type {
    self.passwordView.subTitle = self.setModel.subTitle;
    [self.passwordView updateWithPassCodeType:type];
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

- (void)p_setupUI {
    [self.view addSubview:self.passwordView];
    [self p_setupBackgroundImageView];
    
    CJPayMasMaker(self.passwordView, {
        if (CJ_SMALL_SCREEN) {
            make.top.equalTo(self.view).offset([self navigationHeight]);
        }
        else {
            make.top.equalTo(self.view).offset(134);
        }
        make.left.right.equalTo(self.view);
    });
    
    [self.view addSubview:self.keyboardView];
    CJPayMasMaker(self.keyboardView, {
        make.left.right.equalTo(self.view);
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.height.mas_equalTo(242 + CJ_TabBarSafeBottomMargin);
        } else {
            make.height.mas_equalTo(224 + CJ_TabBarSafeBottomMargin);
        }
        if (CJ_Pad) {
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            } else {
                make.bottom.equalTo(self.view);
            }
        } else {
            make.bottom.equalTo(self.view);
        }
    });
}

- (BOOL)cjAllowTransition {
    return NO;
}

- (void)clearInputContent {
    [self.passwordView.safeInputView clearInput];
}

- (void)showErrorText:(NSString *)text {
    [self clearInputContent];
    self.passwordView.errorLabel.text = text;
}

- (UIView <CJPayBaseLoadingProtocol> *)getLoadingView {
    return self.passwordView;
}

- (void)clearErrorText {
    self.passwordView.errorLabel.text = @"";
}

- (CJPayButtonInfoHandlerActionsModel *)buttonInfoActions:(CJPaySettingPasswordResponse *)response {
    @CJWeakify(self)
    CJPayButtonInfoHandlerActionsModel *actionsModel = [CJPayButtonInfoHandlerActionsModel new];
    actionsModel.backAction = ^{
        @CJStrongify(self)
        self.completion(@"", NO, YES);
    };
    actionsModel.errorInPageAction = ^(NSString *errorText) {
        @CJStrongify(self)
        [self clearInputContent];
        self.passwordView.errorLabel.text = errorText;
    };
    
    CJPayLogAssert(!actionsModel.closeAlertAction, @"actionsModel.closeAlertAction is already non-null.");
    actionsModel.closeAlertAction = ^{
        @CJStrongify(self)
        
        NSString *retCode = response.code;
        
        if ([retCode isEqualToString:@"MP040001"] ||
            [retCode isEqualToString:@"MP010016"] ||
            [retCode isEqualToString:@"MP020408"]) {
            CJ_CALL_BLOCK(self.completion, @"", NO, YES);
        } else if ([retCode isEqualToString:@"MP020409"] ||
                   [retCode isEqualToString:@"MP020410"]) {
            CJ_CALL_BLOCK(self.setModel.backFirstStepCompletion, @"");
        }
    };
    
    return actionsModel;
}

- (void)inputView:(CJPaySafeInputView *)inputView completeInputWithCurrentInput:(NSString *)currentStr {
    // 子类实现
}

- (BOOL)inputViewShouldResignFirstResponder:(CJPaySafeInputView *)inputView {
    return YES;
}

- (void)inputView:(CJPaySafeInputView *)inputView textDidChangeWithCurrentInput:(NSString *)currentStr {
    [self clearErrorText];
    if (currentStr.length < inputView.numCount) {
        self.passwordView.completeButton.enabled = NO;
    }
}

#pragma mark - Getter
- (CJPayPasswordView *)passwordView {
    if (!_passwordView) {
        _passwordView = [[CJPayPasswordView alloc] initWithFrame:CGRectZero];
        _passwordView.safeInputView.safeInputDelegate = self;
    }
    return _passwordView;
}

- (CJPayFixKeyboardView *)keyboardView {
    if (!_keyboardView) {
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            _keyboardView = [[CJPayFixKeyboardView alloc] initWithSafeGuardIconUrl:[CJPayAccountInsuranceTipView keyboardLogo]];
            _keyboardView.notShowSafeguard = NO;
        } else {
            _keyboardView = [CJPayFixKeyboardView new];
        }
        @CJWeakify(self)
        _keyboardView.safeKeyboard.numberClickedBlock = ^(NSInteger number) {
            @CJStrongify(self)
            if (self) {
                [self.passwordView.safeInputView inputNumber:number];
            }
        };
        _keyboardView.safeKeyboard.deleteClickedBlock = ^{
            @CJStrongify(self)
            if (self) {
                [self.passwordView.safeInputView deleteBackWord];
            }
        };
    }
    return _keyboardView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
    }
    return _backgroundImageView;
}

@end
