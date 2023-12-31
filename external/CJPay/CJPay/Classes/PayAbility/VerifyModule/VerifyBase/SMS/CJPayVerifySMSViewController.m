//
//  CJPayVerifySMSViewController.m
//  CJPay
//
//  Created by liyu on 2020/3/24.
//

#import "CJPayVerifySMSViewController.h"

#import "CJPayVerifySMSInputModule.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayCashDeskSendSMSRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayChannelModel.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayHalfVerifySMSHelpViewController.h"
#import "CJPayToast.h"

@interface CJPayVerifySMSViewController ()<CJPayVerifySMSInputModuleDelegate>

@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, assign) NSInteger countDown;
@property (nonatomic, weak) NSTimer *timer;

@end

@implementation CJPayVerifySMSViewController

// protocol 声明的属性需要手动同步
@synthesize trackDelegate = _trackDelegate;
@synthesize needSendSMSWhenViewDidLoad;
@synthesize orderResponse;
@synthesize defaultConfig;
@synthesize helpModel;
@synthesize completeBlock;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self p_setupUI];
    
    [self p_applyStyle];

    self.descLabel.attributedText = [self p_attributedDesc];
    
    @CJWeakify(self)
    if (self.needSendSMSWhenViewDidLoad) {
        [self sendSMSWithCompletion:^{
            [weak_self fire];
        }];
    } else {
        [self fire];
    }
    
    [self trackWithEventName:@"wallet_sms_check_fullscreen_page_imp" params:@{}];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CJKeyboard becomeFirstResponder:self.inputModule];
}

- (void)back
{
    [self trackWithEventName:@"wallet_sms_check_fullscreen_page_click" params:@{
        @"button_name": @"关闭"
    }];
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    [super back];
}

#pragma mark - Private
- (void)p_applyStyle
{
    NSString *styleString = self.orderResponse.resultConfig.showStyle;
    if ([styleString length] == 0) {
        return;
    }
    
    if ([styleString isEqualToString:@"4"]) {
        UIColor *douyinRedColor = [UIColor cj_colorWithHexString:@"#FE2C55"];
        self.inputModule.tintColor = douyinRedColor;
        self.errorLabel.textColor = douyinRedColor;
    }
}

- (void)p_setupUI
{
    self.navigationBar.backgroundColor = [UIColor cj_f4f5f6ff];
    self.view.backgroundColor = UIColor.cj_f4f5f6ff;

    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.descLabel];
    [self.view addSubview:self.inputModule];
    [self.view addSubview:self.errorLabel];
    
    CGFloat top = 112 - 64 + self.navigationHeight;
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.view.mas_top).offset(top);
        make.centerX.equalTo(self.view);
        make.height.equalTo(@24);
        make.width.equalTo(self.view);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.centerX.equalTo(self.titleLabel.mas_centerX);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.height.equalTo(@21);
        make.width.equalTo(self.view);
    });
    
    CJPayMasMaker(self.inputModule, {
        make.centerX.equalTo(self.titleLabel.mas_centerX);
        make.top.equalTo(self.descLabel.mas_bottom).offset(24);
        make.height.equalTo(@56);
        make.width.equalTo(self.view);
    });
    
    CJPayMasMaker(self.errorLabel, {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.inputModule.mas_bottom).offset(24);
    });

    [[CJPayVerifySMSInputModule appearance] setCursorColor:[CJPayThemeStyleManager shared].serverTheme.cursorColor];
}

- (NSAttributedString *)p_attributedDesc {
    BOOL showPhoneNum = Check_ValidString(self.helpModel.phoneNum);
    NSString *preStr = showPhoneNum ? @"验证码已发送到你的 " : @"验证码已发送至手机";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(preStr)
                                                                             attributes:@{
                                                                                 NSForegroundColorAttributeName: UIColor.cj_999999ff,
                                                                                 NSFontAttributeName: [UIFont cj_fontOfSize:13]
                                                                             }];
    if (!showPhoneNum) {
        return attr;
    }
    [attr appendAttributedStringWith:CJString(self.helpModel.phoneNum) textColor:UIColor.cj_222222ff font:[UIFont cj_fontOfSize:13]];
    [attr appendAttributedStringWith:CJPayLocalizedStr(@" 手机") textColor:UIColor.cj_999999ff font:[UIFont cj_fontOfSize:13]];
    return attr;
}

#pragma mark - Subviews

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = UIColor.cj_222222ff;
        _titleLabel.font = [UIFont cj_boldFontOfSize:24];
        _titleLabel.text = CJPayLocalizedStr(@"输入验证码");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _descLabel;
}

- (CJPayStyleErrorLabel *)errorLabel
{
    if (!_errorLabel) {
        _errorLabel = [CJPayStyleErrorLabel new];
        _errorLabel.font = [UIFont cj_fontOfSize:14];
        _errorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _errorLabel;
}

- (CJPayVerifySMSInputModule *)inputModule
{
    if (!_inputModule) {
        _inputModule = [CJPayVerifySMSInputModule new];
        _inputModule.textCount = 6;
        _inputModule.backgroundColor = UIColor.whiteColor;
        _inputModule.bigTitle = CJPayLocalizedStr(@"验证码_全屏");
        _inputModule.placeholder = CJPayLocalizedStr(@"填写验证码_全屏");
        _inputModule.delegate = self;
        @CJWeakify(self)
        _inputModule.buttonAction = ^(BOOL isEnabled) {
            @CJStrongify(self)
            if (isEnabled) {
                [self trackWithEventName:@"wallet_sms_check_fullscreen_page_click" params:@{
                    @"button_name": @"重新发送"
                }];
                [self sendSMSWithCompletion:^{
                    @CJStrongify(self)
                    [self p_clearInputContent];
                    [CJKeyboard becomeFirstResponder:self.inputModule];
                    [self fire];
                }];
            }
        };
    }
    return _inputModule;
}

#pragma mark - Events


- (void)sendSMSWithCompletion:(void (^)(void))completion
{
    if (self.sendSMSLock) { return; }
    self.sendSMSLock = YES;

    @CJStartLoading(self)
    @CJWeakify(self)
    [CJPayCashDeskSendSMSRequest startWithParams:@{
        @"app_id": CJString(self.orderResponse.merchant.appId),
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId)
    } bizContent:@{
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
        @"pwd_level": @"2",
        @"service": @"pay",
        @"process_info": [self.orderResponse.processInfo toDictionary] ?: @{}
    } callback:^(NSError *error, CJPayCashDeskSendSMSResponse *response) {
        @CJStrongify(self)
        @CJStopLoading(self)
        self.sendSMSLock = NO;

//        if ([response.processInfo isValid]) {
//            self.orderResponse.processInfo = response.processInfo;
//        }
        self.errorLabel.hidden = YES;
        // 收到后台回复，不管有没有业务错误都开启倒计时
        if(response) {
            CJ_CALL_BLOCK(completion);
        }

        if (response.isSuccess) {
            self.titleLabel.hidden = NO;
            self.errorLabel.hidden = YES;
        } else {
            NSString *msg = response.msg;
            if (!response || !Check_ValidString(msg)) {
                msg = CJPayNoNetworkMessage;
            }
            
            [CJToast toastText:msg inWindow:self.cj_window];
        }
    }];
}

- (void)p_clearInputContent
{
    [self.inputModule clearText];
}

#pragma mark - CJPayVerifySMSInputModuleDelegate

- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule completeInputWithText:(NSString *)text {
    if (self.completeBlock) {
        self.trackerInputTimes += 1;
        [self trackWithEventName:@"wallet_sms_check_fullscreen_page_input" params:@{
            @"time": @(self.trackerInputTimes)
        }];
        self.completeBlock(YES, text);
    }
}

- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule textDidChange:(NSString *)text {
//    [self showErrorText:@""];
    self.errorLabel.text = @"";
}

#pragma mark - Tracker

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

#pragma mark - Timer

- (void)fire {
    self.countDown = 60;
    [self timerSelector];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(timerSelector) userInfo:nil repeats:YES];
}

- (void)invalidate {
    [self.timer invalidate];
    self.timer = nil;
    [self.inputModule setButtonEnable:YES title:CJPayLocalizedStr(@"获取验证码")];
}

- (void)timerSelector {
    [self.inputModule setButtonEnable:NO title:[NSString stringWithFormat:CJPayLocalizedStr(@"重新获取(%d)"), self.countDown]];
    self.countDown--;
    if (self.countDown < 0) {
        [self invalidate];
    }
}

#pragma mark - CJPayVerifySMSVCProtocol

- (void)reset {
    self.errorLabel.text = nil;
    [self clearInput];
    [self invalidate];
}

- (void)updateTips:(NSString *)tip {
    [self updateErrorText:CJString(tip)];
    [self clearInput];
}

- (void)clearInput {
    [self.inputModule clearText];
    [CJKeyboard becomeFirstResponder:self.inputModule];
}

- (void)updateErrorText:(NSString *)text {
    if (!self.navigationController) { // 有可能VC已经溢出了
        [CJToast toastText:text inWindow:self.cj_window];
        return;
    }
    self.errorLabel.text = text;
    if (Check_ValidString(text)) {
        self.errorLabel.hidden = NO;
    } else {
        self.errorLabel.hidden = YES;
    }

    [self clearInput];
}

- (void)startLoading {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self];
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

@end
