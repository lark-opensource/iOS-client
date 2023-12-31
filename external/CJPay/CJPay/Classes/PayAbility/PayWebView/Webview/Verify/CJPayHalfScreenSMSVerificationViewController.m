//
//  CJPayHalfScreenSMSVerificationViewController.m
//  CJPay
//
//  Created by liyu on 2020/7/9.
//

#import "CJPayHalfScreenSMSVerificationViewController.h"

#import "CJPayStyleErrorLabel.h"
#import "CJPayLineUtil.h"
#import "CJPaySMSInputView.h"
#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"

@interface CJPayHalfScreenSMSVerificationViewController () <CJPaySMSInputViewDelegate>

@end

@implementation CJPayHalfScreenSMSVerificationViewController

#pragma mark - Public

- (instancetype)init
{
    return [self initWithAnimationType:HalfVCEntranceTypeFromBottom];
}

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType
{
    self = [super init];
    if (self) {
        self.animationType = animationType;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

//    NSParameterAssert(self.viewDelegate != nil);
    
    [self.viewDelegate render:self];

    [self.contentView addSubview:self.titleLabel];
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.containerView);
        make.centerY.equalTo(self.contentView.mas_top).offset(31);
        make.height.equalTo(@30);
    });
    
    [self.contentView addSubview:self.smsInputView];
    CJPayMasMaker(self.smsInputView, {
        make.leading.trailing.equalTo(self.contentView).inset(15);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16 - (self.titleLabel.font.lineHeight - 14) / 2);
        make.height.equalTo(@50);
    });
    
    [self.contentView addSubview:self.countDownTimerView];
    CJPayMasMaker(self.countDownTimerView, {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView.mas_top).offset(131);
    });

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.presentedViewController) {
        [self.smsInputView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.smsInputView resignFirstResponder];
}

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 579 : 545;
}

#pragma mark - Subviews

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:14];
        _titleLabel.textColor = [UIColor cj_colorWithHexString:@"999999" alpha:1];
    }
    return _titleLabel;
}

- (CJPayStyleErrorLabel *)errorLabel {
    if (!_errorLabel) {
        _errorLabel = [[CJPayStyleErrorLabel alloc] init];
        _errorLabel.font = [UIFont cj_fontOfSize:14];
        _errorLabel.hidden = YES;
        _errorLabel.numberOfLines = 1;
        _errorLabel.clipsToBounds = NO;
        _errorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _errorLabel;
}

- (CJPayButton *)helpButton {
    if (!_helpButton) {
        _helpButton = [CJPayButton new];
        [_helpButton cj_setImageName:@"cj_help_icon" forState:UIControlStateNormal];
    }
    return _helpButton;
}

- (CJPaySMSInputView *)smsInputView {
    if (!_smsInputView) {
        _smsInputView = [CJPaySMSInputView new];
        _smsInputView.font = [UIFont cj_fontOfSize:28];
        _smsInputView.smsInputDelegate = self;
        _smsInputView.inputFieldCount = self.codeCount > 0 ? self.codeCount : 6;
    }
    return _smsInputView;
}


- (CJPayVerifyCodeTimerLabel *)countDownTimerView {
    if (!_countDownTimerView) {
        _countDownTimerView = [[CJPayVerifyCodeTimerLabel alloc] init];
        _countDownTimerView.translatesAutoresizingMaskIntoConstraints = NO;
        _countDownTimerView.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_countDownTimerView addTarget:self action:@selector(tapResendButton) forControlEvents:UIControlEventTouchUpInside];
        [_countDownTimerView configTimerLabel:CJPayLocalizedStr(@"重新获取(%d)") silentT:CJPayLocalizedStr(@"获取验证码") dynamicColor:[UIColor cj_cacacaff] silentColor:[UIColor cj_douyinBlueColor]];

        _countDownTimerView.timeRunOutBlock = ^{
            //
        };
    }
    return _countDownTimerView;
}

#pragma mark - Events

- (void)back
{
    // TODO 关闭之后timer未关闭
    [self.smsInputView endEditing:YES];
    [self.viewDelegate didTapCloseButton];
    [super back];
}

- (void)showErrorMessage:(NSString *)message
{
    if ([message length] > 0) {
        self.titleLabel.hidden = YES;
        self.errorLabel.hidden = NO;
        
        if (self.errorLabel.superview == nil) {
            [self.contentView addSubview:self.errorLabel];
            
            
            CJPayMasMaker(self.errorLabel, {
                make.center.equalTo(self.titleLabel);
                make.height.equalTo(@30);
            });
        }
        
        self.errorLabel.text = message;
    } else {
        self.titleLabel.hidden = NO;
        self.errorLabel.hidden = YES;
    }
}

- (void)tapResendButton {
    [self.viewDelegate didTapResendButton];
}

- (void)gotoNextStep {
 
    self.errorLabel.hidden = YES;
    self.titleLabel.hidden = NO;
    
    if (self.textInputFinished) {
        [self verifySMS];
    }
}

- (void)verifySMS {
    self.errorLabel.hidden = YES;
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.title];
    [self.viewDelegate didEnterCode:[self.smsInputView getText]];
}

#pragma mark - CJPaySMSInputViewDelegate

- (void)didDeleteLastSMS {
    self.textInputFinished = NO;
}

- (void)didFinishInputSMS:(NSString *)content {
    self.textInputFinished = YES;
    [self.smsInputView resignFirstResponder];
    [self gotoNextStep];
}

@end
