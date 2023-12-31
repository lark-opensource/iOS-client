//
//  CJPayHalfVerifySMSViewController.m
//  CJPay
//
//  Created by 张海阳 on 2019/6/19.
//

#import "CJPayHalfVerifySMSViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayTracker.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayHalfVerifySMSHelpViewController.h"
#import "CJPayLineUtil.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPayCashDeskSendSMSRequest.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayCardSignRequest.h"
#import "CJPayCardSignResponse.h"
#import "CJPayChannelModel.h"
#import "CJPayVerifyManagerHeader.h"

@interface CJPayHalfVerifySMSViewController () <CJPaySMSInputViewDelegate>

@property (nonatomic, strong) UILabel *protocolLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayButton *helpBtn;
@property (nonatomic, assign) int codeCount;
@property (nonatomic, assign) CJPayVerifySMSBizType bizType;
@property (nonatomic, strong) NSMutableAttributedString *protocolString;
@property (nonatomic, strong) UIView *textFieldResponderView;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, copy) void (^stateButtonCompletion)(void);

@property (nonatomic, assign) NSUInteger trackerExecuteTimes;

@end

@implementation CJPayHalfVerifySMSViewController

@synthesize trackDelegate = _trackDelegate;
@synthesize needSendSMSWhenViewDidLoad;
@synthesize helpModel = _helpModel;
@synthesize orderResponse = _orderResponse;
@synthesize defaultConfig = _defaultConfig;

- (instancetype)init
{
    return [self initWithAnimationType:HalfVCEntranceTypeNone withBizType:CJPayVerifySMSBizTypePay];
}

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType withBizType:(CJPayVerifySMSBizType)bizType {
    self = [super init];
    if (self) {
        self.codeCount = 6;
        self.textInputFinished = NO;
        self.animationType = animationType;
        self.bizType = bizType;
    }
    return self;
}

- (NSString *)cj_performanceMonitorName {
    if (self.bizType == CJPayVerifySMSBizTypeSign) {
        return @"补签约页面";
    } else {
        return [super cj_performanceMonitorName];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isSupportClickMaskBack = NO;
    self.title = CJPayLocalizedStr(@"输入验证码");

#pragma mark protocol
    if (self.agreements.count > 0) {
        if (self.agreements.count > 1) {
            [self setProtocol:@"《服务协议》"];
        } else {
            [self setProtocol:[NSString stringWithFormat:@"《%@》", self.agreements.firstObject.title]];
        }
    } else {
        [self.protocolLabel setHidden:YES];
    }

    self.protocolLabel.attributedText = self.protocolString;
#pragma mark protocol end
    if (Check_ValidString(self.helpModel.phoneNum)) {
        self.titleLabel.text = [NSString stringWithFormat:CJPayLocalizedStr(@"验证码已发送到你的%@手机"), CJString(self.helpModel.phoneNum)];
    } else {
        self.titleLabel.text = CJPayLocalizedStr(@"验证码已发送至手机");
    }


    [self.navigationBar addSubview:self.helpBtn];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.smsInputView];
    [self.contentView addSubview:self.textFieldResponderView];
    [self.contentView addSubview:self.errorLabel];

    [self.contentView addSubview:self.protocolLabel];
    [self.contentView addSubview:self.timeView];

    [self makeConstraints];
    
    int startTime = 60;
    
    // 外部短信计时器计时能力移交给内部计时器，关闭外部计时器
    if (self.externTimer) {
        startTime = (self.externTimer.curCount <= 0) ? startTime : self.externTimer.curCount;
        [self.externTimer reset];
    }
    
    self.titleLabel.hidden = self.needSendSMSWhenViewDidLoad ? YES : NO;
    @CJWeakify(self)
    if (self.needSendSMSWhenViewDidLoad) {
        [self postSMSCode:^(CJPayBaseResponse *response) {
            @CJStrongify(self)
            self.titleLabel.hidden = NO;
            [self.timeView startTimerWithCountTime:startTime];
        } failure:^(CJPayBaseResponse *response) {

        }];
    } else {
        [self.timeView startTimerWithCountTime:startTime];
    }
    
    if (self.bizType == CJPayVerifySMSBizTypePay) {
        // 半屏短验埋点
        [self p_trackWithEventName:@"wallet_sms_check_halfscreen_page_imp" params:nil];
    } else if (self.bizType == CJPayVerifySMSBizTypeSign) {
        // 短信签约埋点
        [self p_trackWithEventName:@"wallet_bank_signup_imp" params:@{
            @"bank_name" : CJString(self.defaultConfig.title),
            @"signup_source" : CJString(self.signSource)
        }];
    }
}

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 579 : 545;
}

- (void)showHelpInfo:(BOOL)showHelpInfo {
    self.helpBtn.hidden = !showHelpInfo;
}

- (CJPayVerifyCodeTimerLabel *)timeView {
    if (!_timeView) {
        _timeView = [[CJPayVerifyCodeTimerLabel alloc] init];
        _timeView.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_timeView addTarget:self action:@selector(tapResendButton) forControlEvents:UIControlEventTouchUpInside];
        [_timeView configTimerLabel:CJPayLocalizedStr(@"重新获取(%d)") silentT:CJPayLocalizedStr(@"获取验证码") dynamicColor:[UIColor cj_cacacaff] silentColor:[UIColor cj_douyinBlueColor]];
        _timeView.timeRunOutBlock = ^{
            //
        };
    }
    return _timeView;
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

- (UILabel *)protocolLabel {
    if (!_protocolLabel) {
        UILabel *label = [UILabel new];
        label.font = [UIFont cj_fontOfSize:14];
        label.textColor = UIColor.blackColor;
        label.text = CJPayLocalizedStr(@"同意服务协议");
        label.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProtocolLabel)];
        tap.cancelsTouchesInView = NO;
        [label addGestureRecognizer:tap];
        _protocolLabel = label;
    }
    return _protocolLabel;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *label = [UILabel new];
        _titleLabel = label;
        label.font = [UIFont cj_fontOfSize:14];
        label.textColor = [UIColor cj_colorWithHexString:@"999999" alpha:1];
    }
    return _titleLabel;
}

- (CJPayButton *)helpBtn {
    if (!_helpBtn) {
        _helpBtn = [CJPayButton new];
        [_helpBtn cj_setImageName:@"cj_help_2_icon" forState:UIControlStateNormal];
        [_helpBtn addTarget:self action:@selector(goToHelpVC) forControlEvents:UIControlEventTouchUpInside];
    }
    return _helpBtn;
}

- (void)goToHelpVC {
    if (self.bizType == CJPayVerifySMSBizTypePay) {
        [self p_trackWithEventName:@"wallet_sms_check_halfscreen_page_click" params:@{
            @"button_name": @"帮助'问号'"
        }];
    } else if (self.bizType == CJPayVerifySMSBizTypeSign) {
        [self p_trackWithEventName:@"wallet_bank_signup_click" params:@{
            @"button_name" : @"收不到验证码"
        }];
    }
    
    CJPayHalfVerifySMSHelpViewController *helpVC = [CJPayHalfVerifySMSHelpViewController new];
    helpVC.cjpay_referViewController = self;
    helpVC.helpModel = self.helpModel;
    helpVC.designContentHeight = [self containerHeight];
    if (CJ_Pad){
        [helpVC cj_presentWithNewNavVC];
    } else {
        if (self.navigationController) {
            [self.navigationController pushViewController:helpVC animated:YES];
        }
    }
}

- (CJPaySMSInputView *)smsInputView {
    if (!_smsInputView) {
        _smsInputView = [CJPaySMSInputView new];
        _smsInputView.font = [UIFont cj_fontOfSize:28];
        _smsInputView.smsInputDelegate = self;
    }
    return _smsInputView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CJKeyboard becomeFirstResponder:self.smsInputView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [CJKeyboard resignFirstResponder:self.smsInputView];
}

- (void)makeConstraints {
    CJPayMasMaker(self.helpBtn, {
        make.centerY.equalTo(self.navigationBar);
        make.width.height.mas_equalTo(20);
        make.right.mas_equalTo(-16);
    });

    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.titleLabel.superview);
        make.centerY.equalTo(self.contentView.mas_top).offset(31);
        make.height.mas_equalTo(30);
    });
    CJPayMasMaker(self.smsInputView, {
        make.left.equalTo(self.smsInputView.superview).offset(16);
        make.right.equalTo(self.smsInputView.superview).offset(-16);
        make.top.equalTo(self.contentView).offset(54);
        make.height.mas_equalTo(50);
    });
    CJPayMasMaker(self.errorLabel, {
        make.centerX.centerY.equalTo(self.titleLabel);
        make.height.mas_equalTo(30);
    });
    
    CJPayMasMaker(self.protocolLabel, {
        make.top.equalTo(self.smsInputView.mas_bottom).offset(21);
        make.left.equalTo(self.smsInputView);
        make.right.lessThanOrEqualTo(self.timeView.mas_left).offset(-3);
    });

    if (self.protocolLabel.isHidden) {
        CJPayMasMaker(self.timeView, {
            make.centerX.equalTo(self.contentView);
            make.centerY.equalTo(self.contentView.mas_top).offset(131);
        });
    } else {
        CJPayMasMaker(self.timeView, {
            make.right.equalTo(self.contentView).offset(-16);
            make.centerY.equalTo(self.protocolLabel);
        });
    }
}

- (void)reset {
    self.errorLabel.text = @"";
    [self clearInput];
    [self.timeView reset];
}

- (void)back {
    switch (self.bizType) {
        case CJPayVerifySMSBizTypePay:
            [self p_trackWithEventName:@"wallet_sms_check_halfscreen_page_click" params:@{
                @"button_name": @"关闭"
            }];
            break;
        case CJPayVerifySMSBizTypeSign:
            [self p_trackWithEventName:@"wallet_bank_signup_click" params:@{
                @"button_name": @"关闭"
            }];
            break;
        default:
            break;
    }
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    // 如果存在外部计时器，则将以短验页面内计时器的curCount启动外部计时器
    [self.externTimer startTimerWithCountTime:self.timeView.curCount];
    [self.timeView reset];
    [super back];
}

#pragma mark - action

- (void)tapResendButton {
    [self.timeView startTimerWithCountTime:60];
    if (self.bizType == CJPayVerifySMSBizTypeSign) {
        [self p_trackWithEventName:@"wallet_bank_signup_click" params:@{
            @"button_naem": @"重新发送"
        }];
        @CJWeakify(self)
        [self p_postCardSignSMSCode:^(CJPayBaseResponse *response) {
            @CJStrongify(self)
            [self.smsInputView clearText];
            [CJKeyboard becomeFirstResponder:self.smsInputView];
            if ([response isSuccess]) {
                self.titleLabel.hidden = NO;
                self.errorLabel.hidden = YES;
            }
        } failure:^(CJPayBaseResponse * _Nonnull response) {
            @CJStrongify(self)
            [self.timeView reset];
        }];
    } else if (self.bizType == CJPayVerifySMSBizTypePay) {
        [self p_trackWithEventName:@"wallet_sms_check_halfscreen_page_click" params:@{
            @"button_name": @"重新发送"
        }];
        @CJWeakify(self)
        [self postSMSCode:^(CJPayBaseResponse *response) {
            @CJStrongify(self)
            [self.smsInputView clearText];
            [CJKeyboard becomeFirstResponder:self.smsInputView];
            [self.timeView startTimerWithCountTime:60];
            if ([response isSuccess]) {
                self.titleLabel.hidden = NO;
                self.errorLabel.hidden = YES;
            }
        } failure:^(CJPayBaseResponse *response) {
            @CJStrongify(self)
            [self.timeView reset];
        }];
    }
}

- (void)p_postCardSignSMSCode:(void (^)(CJPayBaseResponse *))success failure:(void (^)(CJPayBaseResponse *_Nonnull))failure {
    [self.timeView startTimerWithCountTime:60];
    [CJPayCardSignRequest startWithAppId:self.orderResponse.merchant.appId
                              merchantId:self.orderResponse.merchant.merchantId
                              bankCardId:self.defaultConfig.cjIdentify
                             processInfo:self.orderResponse.processInfo
                              completion:^(NSError * _Nonnull error, CJPayCardSignResponse * _Nonnull response) {
        self.errorLabel.hidden = YES;
        
        if (response) {
            if (success) {
                success(response);
            }
        }
        if (response.isSuccess) {
            self.titleLabel.hidden = NO;
            self.errorLabel.hidden = YES;
        } else {
            response.buttonInfo.code = response.code;
            @CJWeakify(self)
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self errorMsg:response.msg
                                                         withActions:self.defineButtonInfoActions
                                                           withAppID:self.orderResponse.merchant.appId
                                                          merchantID:self.orderResponse.merchant.merchantId
                                                     alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                @CJStrongify(self)
                if (alertVC) {
                    [self.timeView reset];
                }
            }];
        }
    }];
}

- (void)postSMSCode:(void (^)(CJPayBaseResponse *))success failure:(void (^)(CJPayBaseResponse *_Nonnull))failure {
    self.timeView.enabled = NO;

    @CJWeakify(self)

    [CJPayCashDeskSendSMSRequest
        startWithParams:@{
            @"app_id": CJString(self.orderResponse.merchant.appId),
            @"merchant_id": CJString(self.orderResponse.merchant.merchantId)
        }
        bizContent:@{
            @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
            @"pwd_level": @"2",
            @"service": @"pay",
            @"process_info": [self.orderResponse.processInfo toDictionary] ?: @{}
        }
        callback:^(NSError *error, CJPayCashDeskSendSMSResponse *response) {
            @CJStrongify(self)
            self.timeView.enabled = YES;
            self.errorLabel.hidden = YES;
            // 这个接口也会返回这个字段
            self.helpModel.phoneNum = response.mobileMask;

            // 收到后台回复，不管有没有业务错误都开启倒计时
            if (response) {
                if (success) {
                    success(response);
                }
            }
            
            if (response.isSuccess) {
                self.titleLabel.hidden = NO;
                self.errorLabel.hidden = YES;
            } else {
                self.titleLabel.hidden = YES;
                response.buttonInfo.code = response.code;
                [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                  fromVC:self
                                                                errorMsg:response.msg
                                                             withActions:self.defineButtonInfoActions
                                                               withAppID:self.orderResponse.merchant.appId
                                                              merchantID:self.orderResponse.merchant.merchantId];
            }
        }];
}

- (CJPayButtonInfoHandlerActionsModel *)defineButtonInfoActions {
    @CJWeakify(self)
    CJPayButtonInfoHandlerActionsModel *actionsModel = [CJPayButtonInfoHandlerActionsModel new];
    actionsModel.backAction = ^{};
    actionsModel.errorInPageAction = ^(NSString *errorText) {
        @CJStrongify(self)
        [self updateErrorText:errorText];
    };
    return actionsModel;
}

- (void)showState:(CJPayStateType)stateType {
    [super showState:stateType];
    if (stateType != CJPayStateTypeNone) {
        [CJKeyboard resignFirstResponder:self.smsInputView];
    }
}

#pragma mark - CJPaySMSInputViewDelegate
- (void)didFinishInputSMS:(NSString *)content {
    self.textInputFinished = YES;
    self.errorLabel.hidden = YES;
    self.titleLabel.hidden = NO;
    [CJKeyboard resignFirstResponder:self.smsInputView];
    [self gotoNextStep];
}

- (void)didDeleteLastSMS {
    self.textInputFinished = NO;
}

#pragma mark - call by presenter

- (void)updateTips:(NSString *)tip {
    [self updateErrorText:CJString(tip)];
    [self clearInput];
    [CJKeyboard becomeFirstResponder:self.smsInputView];
}

- (void)clearInput {
    [self.smsInputView clearText];
}

#pragma mark - action

- (void)gotoNextStep {
    if (self.textInputFinished) {
        [self executeCompletionBlock:NO withContent:[self.smsInputView getText]];
        return;
    }
}

- (void)executeCompletionBlock:(BOOL)result withContent:(NSString *)content {
    self.trackerExecuteTimes += 1;
    
    if (self.bizType == CJPayVerifySMSBizTypePay) {
        [self p_trackWithEventName:@"wallet_sms_check_halfscreen_page_input" params:@{
            @"time" : @(self.trackerExecuteTimes)
        }];
    } else if (self.bizType == CJPayVerifySMSBizTypeSign) {
        [self p_trackWithEventName:@"wallet_bank_signup_input" params:@{
            @"time" : @(self.trackerExecuteTimes)
        }];
    }
    CJ_CALL_BLOCK(self.completeBlock, result, content);
}

- (void)updateErrorText:(NSString *)text {
    if (!self.navigationController) { // 有可能VC已经溢出了
        [CJToast toastText:text inWindow:self.cj_window];
        return;
    }
    NSMutableAttributedString *errorAttr = [[NSMutableAttributedString alloc] initWithString:CJString(text)];
    NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
    paraghStyle.cjMaximumLineHeight = 16;
    paraghStyle.cjMinimumLineHeight = 16;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont cj_fontOfSize:14], NSParagraphStyleAttributeName: paraghStyle,

    };
    [errorAttr addAttributes:attributes range:NSMakeRange(0, errorAttr.length)];
    self.errorLabel.attributedText = errorAttr;
    if (text == nil || text.length < 1) {
        self.errorLabel.hidden = YES;
    } else {
        self.errorLabel.hidden = NO;
        self.titleLabel.hidden = YES;
    }
    self.errorLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.errorLabel.textAlignment = NSTextAlignmentLeft;
    [self clearInput];
    [CJKeyboard becomeFirstResponder:self.smsInputView];
}

- (void)startLoading {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

#pragma mark - protocol

- (void)tapProtocolLabel {
    if (self.agreements.count <= 0) {return;}

    if (self.agreements.count > 1) {
        CJPayProtocolListViewController *vc = [CJPayProtocolListViewController new];
        vc.userAgreements = self.agreements;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        CJPayQuickPayUserAgreement *agreement = self.agreements.firstObject;
        CJPayProtocolDetailViewController *vc = [CJPayProtocolDetailViewController new];
        vc.url = agreement.contentURL;
        vc.navTitle = agreement.title;
        vc.showContinueButton = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSMutableAttributedString *)protocolString {
    if (!_protocolString) {
        NSMutableAttributedString *attrStr = [NSMutableAttributedString new];
        _protocolString = attrStr;
    }
    return _protocolString;
}

- (void)setProtocol:(NSString *)protocol {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"同意%@", protocol]];
    [attrStr addAttributes:@{NSForegroundColorAttributeName: [UIColor cj_colorWithHexString:@"222222"],
                    NSFontAttributeName: [UIFont cj_fontOfSize:14]}
                     range:NSMakeRange(0, 2)];
    [attrStr addAttributes:@{NSForegroundColorAttributeName: [UIColor cj_colorWithHexString:@"2a90d7"],
                    NSFontAttributeName: [UIFont cj_fontOfSize:14]}
                     range:NSMakeRange(2, protocol.length)];
    self.protocolString = attrStr;
}

#pragma mark - Private

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    // self.trackDelegate 为空时不上报埋点
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

@end
