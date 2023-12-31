//
//  CJPayHalfVerifyPasswordWithSkipPwdGuideViewController.m
//  Pods
//
//  Created by chenbocheng on 2022/4/2.
//

#import "CJPayHalfVerifyPasswordWithSkipPwdGuideViewController.h"
#import "CJPayPasswordWithSkipPwdGuideView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

@interface CJPayHalfVerifyPasswordWithSkipPwdGuideViewController ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordWithSkipPwdGuideView *baseContentView;

@end

@implementation CJPayHalfVerifyPasswordWithSkipPwdGuideViewController

#pragma mark - life cycle

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    return [self initWithAnimationType:HalfVCEntranceTypeNone viewModel:viewModel];
}

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType viewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.animationType = animationType;
        self.viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

#pragma mark - private method

- (void)p_setupUI {
    [self.contentView addSubview:self.baseContentView];
    
    CJPayMasMaker(self.baseContentView, {
        make.edges.equalTo(self.contentView);
    });
    
    [self.navigationBar addSubview:self.viewModel.forgetPasswordBtn];
        
    CJPayMasMaker(self.viewModel.forgetPasswordBtn, {
        make.right.equalTo(self.navigationBar).offset(-16);
        make.centerY.equalTo(self.navigationBar);
        make.height.mas_equalTo(20);
    });
}

- (BOOL)p_isShowGuideButton {
    return self.viewModel.response.skipPwdGuideInfoModel.isShowButton;
}

- (BOOL)p_isShowMarketing {
    return [self.viewModel.response.payInfo.voucherType integerValue] != 0;
}

- (BOOL)p_isShowCombinePay {
    return self.viewModel.response.payInfo.isCombinePay;
}

- (void)p_onConfirmClick {
    if (self.viewModel.inputPasswordView.contentText.length != 6) {
        return;
    }
    self.viewModel.confirmBtnClickTimes = self.viewModel.confirmBtnClickTimes + 1;
    [self.viewModel trackPageClickWithButtonName:@"1"];
    CJ_CALL_BLOCK(self.viewModel.inputCompleteBlock, self.viewModel.inputPasswordView.contentText);
    [CJKeyboard resignFirstResponder:self.viewModel.inputPasswordView];
    if ([self.viewModel.response.topRightBtnInfo.action isEqualToString:@"forget_pwd_verify"]) {
        self.viewModel.otherVerifyButton.hidden = YES;
    }
    [self.viewModel reset];
}

#pragma mark - tracker

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.viewModel.trackDelegate && [self.viewModel.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.viewModel.trackDelegate event:eventName params:params];
    }
}

#pragma mark - override

- (CGFloat)containerHeight {
    if ([self p_isShowGuideButton]) {
        return CJ_HALF_SCREEN_HEIGHT_HIGH;
    } else {
        return CJ_HALF_SCREEN_HEIGHT_MIDDLE;
    }
}

#pragma mark - lazy views

- (CJPayPasswordWithSkipPwdGuideView *)baseContentView {
    if (!_baseContentView) {
        _baseContentView = [[CJPayPasswordWithSkipPwdGuideView alloc] initWithViewModel:self.viewModel containerHeight:[self containerHeight]];
        @CJWeakify(self)
        _baseContentView.onConfirmClickBlock = ^{
            @CJStrongify(self)
            [self p_onConfirmClick];
        };
        _baseContentView.protocolClickBlock = ^{
            @CJStrongify(self)
            [self trackWithEventName:@"wallet_onesteppswd_setting_agreement_imp"
                              params:@{@"pswd_source": @"支付验证页"}];
        };
    }
    return _baseContentView;
}

@end
