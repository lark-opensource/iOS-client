//
//  CJPayHalfSignCardVerifySMSViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/18.
//

#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemberSignRequest.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPaySDKDefine.h"
#import "CJPayAlertUtil.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPayVerifySMSVCProtocol.h"
#import <TTReachability/TTReachability.h>
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"

@implementation CJPayHalfSignCardVerifySMSViewModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"outerClose" : CJPayBindCardShareDataKeyOuterClose,
        @"processInfo" : CJPayBindCardShareDataKeyProcessInfo,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"title" : CJPayBindCardShareDataKeyTitle,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"subTitle" : CJPayBindCardShareDataKeySubTitle,
        @"displayDesc": CJPayBindCardShareDataKeyDisplayDesc,
        @"frontIndependentBindCardSource" : CJPayBindCardShareDataKeyFrontIndependentBindCardSource,
        @"bindCardInfo" : CJPayBindCardShareDataKeyBindCardInfo,
        @"trackerParams" : CJPayBindCardShareDataKeyTrackerParams,
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"bindUnionCardType" : CJPayBindCardShareDataKeyBindUnionCardType,
        @"unionBindCardCommonModel" : CJPayBindCardShareDataKeyUnionBindCardCommonModel,
        @"isEcommerceAddBankCardAndPay" : CJPayBindCardShareDataKeyIsEcommerceAddBankCardAndPay,
        @"firstStepVCTimestamp" : CJPayBindCardShareDataKeyFirstStepVCTimestamp,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

- (NSString *)timeIntervalSinceFirstStepVC {
    return [NSString stringWithFormat:@"%.01f", [[NSDate date] timeIntervalSince1970] - self.firstStepVCTimestamp];
}

- (BOOL)isAuthorized {
    // 已实名 或者 用户已选择授权实名
    return [self.userInfo hasValidAuthStatus] || self.isCertification;
}

@end

@interface CJPayHalfSignCardVerifySMSViewController ()

@property (nonatomic, weak) CJPayFullPageBaseViewController *topVC;
@property (nonatomic, assign) BOOL hasCloseWithSuccess;
@property (nonatomic, assign) BOOL hasCaptchaInput;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;

@end

@implementation CJPayHalfSignCardVerifySMSViewController

- (instancetype)init {
    self = [super initWithAnimationType:HalfVCEntranceTypeFromBottom withBizType:CJPayVerifySMSBizTypePay];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hasCloseWithSuccess = NO;
    self.hasCaptchaInput = NO;
    if(Check_ValidString(self.sendSMSResponse.verifyTextMsg)){
        self.title = self.sendSMSResponse.verifyTextMsg;
    }else{
        self.title = CJPayLocalizedStr(@"输入验证码");
    }
    
    if (self.needShowProtocol) {
        [self p_showProtocol];
    }
}

- (void)p_showProtocol {
    if(!Check_ValidString(self.sendSMSResponse.verifyTextMsg)){
        self.title = CJPayLocalizedStr(@"手机号安全验证");
    }
    
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.guideDesc = CJPayLocalizedStr(@"同意");
    protocolModel.groupNameDic = self.sendSMSResponse.protocolGroupNames;
    protocolModel.agreements = self.sendSMSResponse.agreements;
    protocolModel.protocolFont = [UIFont cj_fontOfSize:14];
    protocolModel.protocolDetailContainerHeight = @([self containerHeight]);
    [self.protocolView updateWithCommonModel:protocolModel];
    
    [self.contentView addSubview:self.protocolView];
    
    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.smsInputView.mas_bottom).offset(21);
        make.left.equalTo(self.smsInputView);
        make.right.lessThanOrEqualTo(self.timeView.mas_left).offset(-3);
    });
    
    CJPayMasReMaker(self.timeView, {
        make.right.equalTo(self.contentView).offset(-16);
        make.centerY.equalTo(self.protocolView);
    });
}

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 579 : 545;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self trackWithEventName:@"wallet_addbcard_captcha_imp" params:@{
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
}

- (void)postSMSCode:(void (^)(CJPayBaseResponse *))success failure:(void (^)(CJPayBaseResponse * _Nonnull)) failure {
    [self trackWithEventName:@"wallet_addbcard_captcha_click" params:@{
        @"button_name" : @"获取验证码",
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
    
    self.timeView.enabled = NO;
    @CJWeakify(self)
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:self.ulBaseReqquestParam
                                       bizParam:self.sendSMSBizParam
                                     completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        self.timeView.enabled = YES;
        if (response) {
            if ([response isSuccess]) {
                if (success) {
                    success(response);
                }
                self.sendSMSResponse = response;
            } else {
                // 单button alert
                NSString *msg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
                [CJPayAlertUtil customSingleAlertWithTitle:msg
                                                   content:@""
                                                buttonDesc:CJPayLocalizedStr(@"我知道了")
                                               actionBlock:nil
                                                     useVC:self];
            }
        } else {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
        }
    }];
    
}

- (void)verifySMS {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    if (self.viewModel.isEcommerceAddBankCardAndPay) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.title];
    }
    @CJWeakify(self)
    [CJPayMemberSignRequest startWithBDPayVerifySMSBaseParam:self.ulBaseReqquestParam
                                                bizParam:[self buildVerifyParams]
                                              completion:^(NSError * _Nonnull error, CJPaySignSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        if (response && [response isSuccess]) {
            [self trackWithEventName:@"wallet_addbcard_captcha_submit_result"
                              params:@{
                                  @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0",
                                  @"captcha_result" : CJString(response.code),
                                  @"loading_time" : [NSString stringWithFormat:@"%f", response.responseDuration]
                              }];
            
            self.signResponse = response;
            self.bankCardInfo = response.cardInfoModel;
            
            [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                             metric:@{@"timestamp" : CJString([self.viewModel timeIntervalSinceFirstStepVC])}
                           category:@{@"userType" : self.viewModel.isAuthorized ? @"auth" : @"unAuth", @"stage" : @"smsVerifySuccess"}
                              extra:@{}];
            
            if ([self.viewModel.userInfo.pwdStatus isEqualToString:@"0"]) {
                // 没有密码，需要设置密码
                [[CJPayLoadingManager defaultService] stopLoading];
                [self p_setPwdWithRespone:response];
            } else {
                [self p_completeSignProcessWithSignNo:response.signNo
                                                token:response.pwdToken];
            }
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
            [self trackWithEventName:@"wallet_addbcard_captcha_submit_result" params:@{
                @"captcha_result" : CJString(response.code),
                @"loading_time" : [NSString stringWithFormat:@"%f", response.responseDuration],
                @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
            }];
            
            if (response) {
                CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
                actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
                    //处理返回红色字提示
                    [self updateErrorText:CJString(errorText)];
                };
                actionModel.closeAlertAction = ^{
                    [self close];
                };
                //buttoninfo 返回处理
                response.buttonInfo.code = response.code;
                @CJWeakify(self)
                [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                                  fromVC:self errorMsg:response.msg
                                                             withActions:actionModel
                                                               withAppID:self.viewModel.appId
                                                              merchantID:self.viewModel.merchantId
                                                         alertCompletion:^(UIViewController * _Nullable alertVC, BOOL handled) {
                    @CJStrongify(self)
                    if (alertVC) {
                        [self clearInput];
                        [CJKeyboard becomeFirstResponder:self.smsInputView];
                    }
                }];
            } else {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
                [self clearInput];
                [CJKeyboard becomeFirstResponder:self.smsInputView];
            }
        }
    }];
}

//没有密码，需要设置密码
- (void)p_setPwdWithRespone:(CJPaySignSMSResponse *)response{
    
    CJPayPasswordSetModel *model = [CJPayPasswordSetModel new];
    model.appID = self.viewModel.appId;
    model.merchantID = self.viewModel.merchantId;
    model.smchID = self.viewModel.specialMerchantId;
    model.signOrderNo = self.viewModel.signOrderNo;
    model.isNeedCardInfo = [self p_isNeedCardInfo:self.viewModel.cardBindSource];
    model.mobile = self.viewModel.userInfo.mobile;
    model.isSetAndPay = self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay;
    model.processInfo = self.viewModel.processInfo;
    model.activityInfos = self.activityInfos;
    model.subTitle = self.viewModel.displayDesc;
    model.isUnionBindCard = self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign || self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind;
    @CJWeakify(self)
    model.backCompletion = ^{
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self closeBindCardProcessWithFail];
        });
    };
    model.source = [[CJPayBindCardManager sharedInstance] bindCardTrackerSource];
    
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageSetPWDFirstStep params:@{} completion:nil];
    
    if (![vc isKindOfClass:[CJPayPasswordSetFirstStepViewController class]]) {
        CJPayLogAssert(NO, @"vc类型异常%@", [vc cj_trackerName]);
        return;
    }
    
    CJPayPasswordSetFirstStepViewController *setPassViewController = (CJPayPasswordSetFirstStepViewController *)vc;
    setPassViewController.setModel = model;
    @CJWeakify(model);
    setPassViewController.completion = ^(NSString * _Nullable token, BOOL isSuccess, BOOL isExit) {
        @CJStrongify(self)
        @CJStrongify(model);
        if (isSuccess) {
            
            [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                             metric:@{@"timestamp" : CJString([self.viewModel timeIntervalSinceFirstStepVC])}
                           category:@{@"userType" : self.viewModel.isAuthorized ? @"auth" : @"unAuth", @"stage" : @"pwdSetting"}
                              extra:@{}];
            
            if (self) {
               self.bankCardInfo = model.bankCardInfo;
               [self p_completeSignProcessWithSignNo:response.signNo
                                                     token:token];
             }
        }
        
        // exit: 退出绑卡流程
        if (isExit) {
            [self closeBindCardProcessWithResult:NO signNo:response.signNo token:@"" completionBlock:^{}];
        }
    };
}
//构造签约验证短信参数
- (NSDictionary *)buildVerifyParams{
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:self.viewModel.signOrderNo forKey:@"sign_order_no"];
    [bizParams cj_setObject:self.viewModel.specialMerchantId forKey:@"smch_id"];
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:CJString([self.smsInputView getText]) forKey:@"sms"];
    [bizParams cj_setObject:encParams forKey:@"enc_params"];
    [bizParams cj_setObject:CJString(self.sendSMSResponse.smsToken) forKey:@"sms_token"];
    
    if ([self p_isNeedCardInfo:self.viewModel.cardBindSource]) {
        [bizParams cj_setObject:@(YES) forKey:@"is_need_card_info"];
    }
    return bizParams;
}

- (BOOL)p_isNeedCardInfo:(CJPayCardBindSourceType)cardBindSource {
    NSArray *sourceArray = @[@(CJPayCardBindSourceTypeBalanceWithdraw),
                             @(CJPayCardBindSourceTypeBalanceRecharge),
                             @(CJPayCardBindSourceTypeIndependent)];
    if ([sourceArray containsObject:@(cardBindSource)]) {
        return YES;
    }
    return NO;
}

- (void)p_completeSignProcessWithSignNo:(NSString *)signNo
                                  token:(NSString *)token {
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSignSuccessNotification object:nil];
    
    if (self.hasCloseWithSuccess) {
        return;
    } else {
        self.hasCloseWithSuccess = YES;
    }
     
    [[CJPayLoadingManager defaultService] stopLoading];
    
    // 重置密码流程中，签约绑卡成功后，将结果回调给外部处理   需要进一步处理signSuccessCompletion
    if (self.signSuccessCompletion) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSuccessNotification object:nil];
        NSString * bizOrderNumStr = self.viewModel.signOrderNo;
        CJPaySignSMSResponse *response = self.signResponse;
        response.pwdToken = self.sendSMSResponse.smsToken;
        CJ_CALL_BLOCK(self.signSuccessCompletion, response, CJString(bizOrderNumStr));
        return;
    }
    
    NSArray *sceneWithoutToast = @[@(CJPayCardBindSourceTypeBindAndPay), @(CJPayCardBindSourceTypeFrontIndependent), @(CJPayCardBindSourceTypeIndependent), @(CJPayCardBindSourceTypeBalanceWithdraw), @(CJPayCardBindSourceTypeBalanceRecharge)];
    if (![sceneWithoutToast containsObject:@(self.viewModel.cardBindSource)]) {
        [CJToast toastText:CJPayLocalizedStr(@"绑卡成功") duration:0.5 inWindow:self.cj_window];
    }
    
    [self.timeView reset];
    [self trackWithEventName:@"wallet_addbcard_page_toast_info" params:@{
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
    [self closeBindCardProcessWithResult:YES signNo:signNo token:token completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayBindCardSuccessNotification object:nil];
    }];
}

- (void)closeBindCardProcessWithFail {
    [self closeBindCardProcessWithResult:NO signNo:@"" token:@"" completionBlock:^{
        
    }];
}

- (void)closeBindCardProcessWithResult:(BOOL)isSuccess signNo:(NSString *)signNo token:(NSString *)token
                       completionBlock:(void(^)(void))completionBlock {
    if (isSuccess && self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSignCard) {
        [self.timeView reset];
        [self.navigationController popViewControllerAnimated:YES];
        CJ_CALL_BLOCK(self.completeBlock, isSuccess, @"");
        return;
    }
    
    CJPayBindCardResult result = isSuccess ? CJPayBindCardResultSuccess : CJPayBindCardResultFail;
    CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
    resultModel.result = result;
    resultModel.token = token;
    resultModel.signNo = signNo;
    resultModel.bankCardInfo = self.bankCardInfo;
    resultModel.memberBizOrderNo = self.viewModel.signOrderNo;
    
    [[CJPayBindCardManager sharedInstance] finishBindCard:resultModel completionBlock:completionBlock];
}

- (void)gotoNextStep {
    if (!self.hasCaptchaInput) {
        [self trackWithEventName:@"wallet_addbcard_captcha_input" params:@{
            @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
        }];
        self.hasCaptchaInput = YES;
    }
    if (self.textInputFinished) {
        [self verifySMS];
    }
}

- (void)goToHelpVC {
    [super goToHelpVC];
    [self trackWithEventName:@"wallet_addbcard_captcha_click" params:@{
        @"button_name" : @"问号",
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
    [self trackWithEventName:@"wallet_addbcard_captcha_nosms_imp" params:@{
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
}

- (void)updateErrorText:(NSString *)text {
    [super updateErrorText:text];
    [self trackWithEventName:@"wallet_addbcard_captcha_error_info" params:@{
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
}

- (void)back {
    [super back];
    [self trackWithEventName:@"wallet_addbcard_captcha_click" params:@{
        @"button_name" : @"关闭",
        @"is_alivecheck" : self.viewModel.unionBindCardCommonModel.isAliveCheck ? @"1" : @"0"
    }];
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

#pragma mark - Tracker

- (void)trackWithEventName:(NSString *)eventName
                    params:(nullable NSDictionary *)params {
    NSDictionary *baseDic = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] initWithDictionary:baseDic];
    if (params) {
        [paramsDic addEntriesFromDictionary:params];
    }
    NSMutableDictionary *cardTypeNameDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"DEBIT" : @"储蓄卡",
        @"CREDIT" : @"信用卡"
    }];
    NSString *bankTypeName = [cardTypeNameDic btd_stringValueForKey:self.bankCardInfo.cardType];
    [paramsDic addEntriesFromDictionary:@{
        @"bank_name" : CJString(self.bankCardInfo.bankName),
        @"bank_type" : CJString(bankTypeName),
        @"activity_info" : self.activityInfos ?: @[]
    }];
    
    [CJTracker event:eventName params:paramsDic];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayHalfSignCardVerifySMSViewModel alloc] initWithDictionary:dict error:&error];
        if (error) {
            CJPayLogAssert(NO, @"创建 CJPayHalfSignCardVerifySMSViewModel 失败.");
        }
    }
}

+ (Class)associatedModelClass {
    return [CJPayHalfSignCardVerifySMSViewModel class];
}

@end
