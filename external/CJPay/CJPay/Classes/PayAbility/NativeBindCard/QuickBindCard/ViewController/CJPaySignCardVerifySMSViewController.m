//
//  CJPaySignCardVerifySMSViewController.m
//  Pods
//
//  Created by 尚怀军 on 2020/12/30.
//

#import "CJPaySignCardVerifySMSViewController.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayButton.h"
#import "CJPayVerifySMSInputModule.h"
#import "CJPayHalfVerifySMSHelpViewController.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayMemberFaceVerifyInfoModel.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemberSignRequest.h"
#import "CJPayCardManageModule.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAlertUtil.h"
#import "CJPayQuickBindCardTypeChooseViewController.h"
#import "CJPayMetaSecManager.h"
#import "CJPayToast.h"

@interface CJPaySignCardVerifySMSViewController ()

@property (nonatomic, copy) NSDictionary *schemaParams;
@property (nonatomic, strong) CJPayButton *helpButton;
@property (nonatomic, strong) CJPaySendSMSResponse *sendSMSResponse;
@property (nonatomic, assign) BOOL signLock;

@end

@implementation CJPaySignCardVerifySMSViewController

- (instancetype)initWithSchemaParams:(NSDictionary *)schemaParams
{
    self = [super init];
    if (self) {
        _schemaParams = schemaParams;
        _signLock = NO;
        [self p_parseFromSchemaParams];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.helpButton];
    
    CJPayMasMaker(self.helpButton, {
        make.top.equalTo(self.inputModule.mas_bottom).offset(24);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(14);
    });
    
    CJPayMasReMaker(self.errorLabel, {
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.top.equalTo(self.helpButton.mas_bottom).offset(20);
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self trackWithEventName:@"wallet_addbcard_captcha_imp" params:@{}];
}

- (void)sendSMSWithCompletion:(void (^)(void))completion {
    [self trackWithEventName:@"wallet_addbcard_captcha_click"
                      params:@{@"button_name" : @"获取验证码"}];
    
    // 发短信鉴权
    if (self.sendSMSLock) {
        return;
    }
    self.sendSMSLock = YES;
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self];
    @CJWeakify(self)
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:[self p_buildSendSMSBaseParam]
                                                     bizParam:[self p_buildSendSMSBizParam]
                                                   completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        self.sendSMSLock = NO;
        self.errorLabel.hidden = YES;
        // 收到后台回复，不管有没有业务错误都开启倒计时
        if(response) {
            CJ_CALL_BLOCK(completion);
        }

        if (response && [response isSuccess]) {
            self.sendSMSResponse = response;
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


- (void)helpButtonClicked {
    [self.inputModule resignFirstResponder];
    CJPayHalfVerifySMSHelpViewController *helpVC = [CJPayHalfVerifySMSHelpViewController new];
    helpVC.animationType = HalfVCEntranceTypeFromBottom;
    helpVC.helpModel = self.helpModel;
    [helpVC useCloseBackBtn];
    [helpVC showMask:YES];
    helpVC.isSupportClickMaskBack = YES;
    [self trackWithEventName:@"wallet_addbcard_captcha_nosms_imp" params:@{}];
    [self trackWithEventName:@"wallet_addbcard_captcha_click"
                      params:@{@"button_name" : @"收不到验证码"}];
 
    if (CJ_Pad) {
//        [helpVC cj_presentWithNewNavVC];
        [helpVC presentWithNavigationControllerFrom:self useMask:YES completion:nil];
    } else {
        [self.navigationController pushViewController:helpVC animated:YES];
    }
}



- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule completeInputWithText:(NSString *)text {
    // 输完短信之后签约
    self.trackerInputTimes += 1;
    [self trackWithEventName:@"wallet_addbcard_captcha_input"
                      params:@{@"time": @(self.trackerInputTimes)}];

    [self p_verifySMSToSignCardWithInput:text];
}

- (void)back {
    // 弹窗挽留
    @CJWeakify(self)
    void(^leftActionBlock)(void) = ^() {
        @CJStrongify(self)
        [self trackWithEventName:@"wallet_addbcard_captcha_keep_pop_click"
                                params:@{@"button_name": @"放弃"}];
        
        if (self.cjBackBlock) {
            CJ_CALL_BLOCK(self.cjBackBlock);
        } else {
            [super back];
        }
    };
    
    void(^rightActionBlock)(void) = ^() {
        @CJStrongify(self)
        [self trackWithEventName:@"wallet_addbcard_captcha_keep_pop_click"
                                params:@{@"button_name": @"继续绑卡"}];
        [self.inputModule becomeFirstResponder];

    };
    NSString *maskCardNo = [self.schemaParams cj_stringValueForKey:@"mask_cardno"];
    NSString *alertTitle = CJPayLocalizedStr(@"要放弃绑定银行卡吗?");
    if (Check_ValidString(maskCardNo)) {
        alertTitle = [NSString stringWithFormat:@"要放弃绑定银行卡（%@）吗?", maskCardNo];
    }
    [self trackWithEventName:@"wallet_addbcard_captcha_keep_pop_imp" params:@{}];
    [self trackWithEventName:@"wallet_addbcard_captcha_click"
                      params:@{@"button_name": @"关闭"}];
    [self.inputModule resignFirstResponder];
    
    [CJPayAlertUtil customDoubleAlertWithTitle:alertTitle
                                       content:@""
                                leftButtonDesc:CJPayLocalizedStr(@"放弃")
                               rightButtonDesc:CJPayLocalizedStr(@"继续绑卡")
                               leftActionBlock:leftActionBlock
                               rightActioBlock:rightActionBlock
                                         useVC:self];
}

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *trackParam = [NSMutableDictionary new];
    if (self.extTrackParam) {
        [trackParam addEntriesFromDictionary:self.extTrackParam];
    }
    
    if (params) {
        [trackParam addEntriesFromDictionary:params];
    }
    
    [CJTracker event:eventName params:trackParam];
}

- (void)p_verifySMSToSignCardWithInput:(NSString *)inputText {
    if (!self.sendSMSResponse) {
        CJPayLogInfo(@"短信发送成功之前不能进行验证！");
        return;
    }
    
    if (self.signLock) {
        return;
    }
    self.signLock = YES;
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self];
    NSMutableDictionary *signBaseParam = [NSMutableDictionary new];
    [signBaseParam cj_setObject:CJString(self.oneKeyOrderResponse.merchantId) forKey:@"merchant_id"];
    [signBaseParam cj_setObject:CJString(self.oneKeyOrderResponse.appId) forKey:@"app_id"];
    
    
    @CJWeakify(self)
    [CJPayMemberSignRequest startWithBDPayVerifySMSBaseParam:signBaseParam
                                                    bizParam:[self p_buildVerifyParamWithInputText:inputText]
                                              completion:^(NSError * _Nonnull error, CJPaySignSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        self.signLock = NO;
        if (response && [response isSuccess]) {
            [self trackWithEventName:@"wallet_addbcard_captcha_submit_result"
                                    params:@{@"captcha_result": CJString(response.code),
                                             @"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration],
                                             @"error_code": CJString(response.code),
                                             @"error_message": CJString(response.msg)
                                    }];
            
            [self trackWithEventName:@"wallet_addbcard_onestepbind_result"
                                    params:@{@"result": @"1",
                                             @"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration],
                                             @"error_code": CJString(response.code),
                                             @"error_message": CJString(response.msg)}];
            
            CJ_CALL_BLOCK(self.signCardSuccessBlock, response);
        } else {
            [self trackWithEventName:@"wallet_addbcard_captcha_submit_result"
                                    params:@{@"captcha_result": CJString(response.code),
                                             @"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration],
                                             @"error_code": CJString(response.code),
                                             @"error_message": CJString(response.msg)
            }];
            
            [self.inputModule becomeFirstResponder];
            
            CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
            actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
                //处理返回红色字提示
                [self updateErrorText:CJString(errorText)];
            };
            //buttoninfo 返回处理
            response.buttonInfo.code = response.code;
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self
                                                            errorMsg:response.msg
                                                         withActions:actionModel
                                                           withAppID:self.oneKeyOrderResponse.appId
                                                          merchantID:self.oneKeyOrderResponse.appId];
        }
    }];
}

- (NSDictionary *)p_buildVerifyParamWithInputText:(NSString *)smsText {
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:CJString(self.oneKeyOrderResponse.memberBizOrderNo) forKey:@"sign_order_no"];
    [bizParams cj_setObject:CJString(self.oneKeyOrderResponse.faceVerifyInfoModel.smchId) forKey:@"smch_id"];
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:CJString(smsText) forKey:@"sms"];
    [bizParams cj_setObject:encParams forKey:@"enc_params"];
    [bizParams cj_setObject:CJString(self.sendSMSResponse.smsToken) forKey:@"sms_token"];
    
    NSArray *sourceArray = @[@(CJPayCardBindSourceTypeBalanceWithdraw),
                             @(CJPayCardBindSourceTypeBalanceRecharge)];
    if ([sourceArray containsObject:@(self.cardBindSource)]) {
        [bizParams cj_setObject:@(YES) forKey:@"is_need_card_info"];
    }
    return bizParams;
}

- (NSDictionary *)p_buildSendSMSBizParam {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:CJString(self.oneKeyOrderResponse.memberBizOrderNo) forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:CJString(self.oneKeyOrderResponse.faceVerifyInfoModel.smchId) forKey:@"smch_id"];
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    NSString *bankEncInfoStr = [self.schemaParams cj_stringValueForKey:@"enc_bindelem"];
    [encParams cj_setObject:CJString(bankEncInfoStr) forKey:@"bank_enc_info"];
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    [bizContentParams cj_setObject:CJString([self.schemaParams cj_stringValueForKey:@"gw_channel_order_no"]) forKey:@"gw_channel_order_no"];
    return bizContentParams;
}

- (NSDictionary *)p_buildSendSMSBaseParam {
    NSMutableDictionary *baseParamDic = [NSMutableDictionary dictionary];
    [baseParamDic cj_setObject:CJString(self.oneKeyOrderResponse.merchantId) forKey:@"merchant_id"];
    [baseParamDic cj_setObject:CJString(self.oneKeyOrderResponse.appId) forKey:@"app_id"];
    return baseParamDic;
}

- (void)p_parseFromSchemaParams {
    CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
    helpModel.frontBankCodeName = CJPayLocalizedStr(@"工商银行");
    helpModel.phoneNum = [self.schemaParams cj_stringValueForKey:@"mask_phoneno"];
    helpModel.cardNoMask = [self.schemaParams cj_stringValueForKey:@"mask_cardno"];
    self.helpModel = helpModel;
}

- (CJPayButton *)helpButton {
    if (!_helpButton) {
        _helpButton = [CJPayButton new];
        [_helpButton setTitle:CJPayLocalizedStr(@"收不到验证码？") forState:UIControlStateNormal];
        [_helpButton setTitleColor:[UIColor cj_douyinBlueColor] forState:UIControlStateNormal];
        _helpButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_helpButton addTarget:self action:@selector(helpButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _helpButton;
}

@end
