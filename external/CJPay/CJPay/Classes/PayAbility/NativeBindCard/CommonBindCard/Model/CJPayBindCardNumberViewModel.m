//
//  CJPayBindCardNumberViewModel.m
//  Pods
//
//  Created by renqiang on 2021/7/1.
//

#import "CJPayBindCardNumberViewModel.h"
#import "CJPayBindCardNumberView.h"
#import "CJPayStyleButton.h"
#import "CJPayCenterTextFieldContainer.h"
#import "CJPayUIMacro.h"
#import "CJPayMemCardBinInfoRequest.h"
#import "CJPaySafeUtil.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayTimer.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAlertUtil.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayBindCardFourElementsViewController.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBindCardChooseIDTypeCell.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayBankCardOCRViewController.h"
#import "CJPayAuthPhoneRequest.h"
#import "CJPayBindCardHeaderView.h"
#import "CJPayBindCardFirstStepCardTipView.h"
#import "CJPayVerifyItemBindCardRecogFace.h"
#import "CJPayBindCardManager.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayWebViewService.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayBindCardRecommendBankView.h"
#import "CJPayBindCardFirstStepViewController.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayVoucherBankInfo.h"

@implementation CJPayBindCardNumberDataModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"isCertification" : CJPayBindCardShareDataKeyIsCertification,
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"bankMobileNoMask" : CJPayBindCardShareDataKeyBankMobileNoMask,
        @"voucherBankStr" : CJPayBindCardShareDataKeyVoucherBankStr,
        @"voucherMsgStr" : CJPayBindCardShareDataKeyVoucherMsgStr,
        @"firstStepMainTitle" : CJPayBindCardShareDataKeyFirstStepMainTitle,
        @"userInfo" : CJPayBindCardShareDataKeyUserInfo,
        @"cardBindSource" : CJPayBindCardShareDataKeyCardBindSource,
        @"bizAuthInfo" : CJPayBindCardShareDataKeyBizAuthInfoModel,
        @"isQuickBindCardListHidden" : CJPayBindCardPageParamsKeyIsQuickBindCardListHidden,
        @"isFromQuickBindCard" : CJPayBindCardPageParamsKeyIsFromQuickBindCard,
        @"pageFromCashierDesk" : CJPayBindCardPageParamsKeyPageFromCashierDesk,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBindCardNumberViewModel ()<CJPayCustomTextFieldContainerDelegate, CJPayTrackerProtocol, CJPayTimerProtocol>

@property (nonatomic, strong) CJPayVerifyItemBindCardRecogFace *recogFaceVerifyItem;

#pragma mark - model
@property (nonatomic, strong) CJPayBindCardNumberDataModel *dataModel;
@property (nonatomic, strong) CJPayMemBankInfoModel *latestCardBinInfo;
@property (nonatomic, strong) CJPayMemCardBinResponse *memCardBinResponse;
@property (nonatomic, strong) CJPaySendSMSResponse *latestSMSResponse;
@property (nonatomic, strong) CJPayCardOCRResultModel *latestOCRModel;
@property (nonatomic, strong) CJPayQuickBindCardModel *quickBindCardModel;

#pragma mark - flag
@property (nonatomic, assign) BOOL isPhoneNumReverseDisplay;
@property (nonatomic, assign) BOOL isCardBinSuccess;
@property (nonatomic, assign) BOOL hasTrackCardBinSuccess;
@property (nonatomic, assign) BOOL hasTrackValidInput;
@property (nonatomic, assign) BOOL hasTrackPhoneNum;
// 是否是OCR绑卡
@property (nonatomic, assign) BOOL isCardOCR;
// 控制短信参数是否使用银行预留加密手机号
@property (nonatomic, assign) BOOL isUseAuthPhoneNumber;
@property (nonatomic, assign) BOOL isNiceNetSpeed;//输入卡号添加弱网提示

#pragma mark - data
@property (nonatomic, assign) NSInteger requestID;
// 短信频控计时器
@property (nonatomic, strong) CJPayTimer *smsTimer;
@property (nonatomic, assign) NSUInteger lastInputContentHash;
// 银行预留手机号（被加密）
@property (nonatomic, copy) NSString *authPhoneNumber;
// 记录上次发起cardBin的卡号
@property (nonatomic, copy) NSString *latestCardBinNumber;
@property (nonatomic, copy) NSString *searchCardNoURL;

@property (nonatomic, assign) uint inputErrorBankNumberTimes;
@end

@implementation CJPayBindCardNumberViewModel

+ (NSArray <NSString *>*)dataModelKey {
    return [CJPayBindCardNumberDataModel keysOfParams];
}

- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict {
    if (self = [super init]) {
        if (dict.count > 0) {
            self.dataModel = [[CJPayBindCardNumberDataModel alloc] initWithDictionary:dict error:nil];
            self.dataModel.firstStepVCTimestamp = [[NSDate date] timeIntervalSince1970];
            [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyFirstStepVCTimestamp : @(self.dataModel.firstStepVCTimestamp)} completion:^(NSArray<NSString *> * _Nonnull modifyedKeysArray) {
                
            }];
        }
        self.isCardBinSuccess = NO;
        self.latestCardBinNumber = [NSString new];
        self.lastInputContentHash = 0;
        self.inputErrorBankNumberTimes = 0;
    }
    return self;
}

#pragma mark - private method
- (void)p_reverseDisplayMaskedPhoneNumber:(NSString *)phoneNumber {
    NSMutableString *phoneNumMaskStr = [NSMutableString stringWithString:phoneNumber];
    if (phoneNumMaskStr.length == 11) {
        [phoneNumMaskStr insertString:@" " atIndex:3];
        [phoneNumMaskStr insertString:@" " atIndex:8];
    }
    [self.frontBindCardView.phoneContainer preFillText:CJString(phoneNumMaskStr)];
    
    self.isPhoneNumReverseDisplay = YES;
    self.frontBindCardView.phoneContainer.textField.supportSeparate = NO;
    self.frontBindCardView.nextStepButton.enabled = [self p_isNextStepButtonEnable];
}

- (void)p_updateCardImgViewShowState:(BOOL)show {
    CJPayMasUpdate(self.frontBindCardView.cardImgView, {
        make.height.mas_equalTo(show ? 28 : 0);
    });
}

- (void)p_fetchAuthPhoneNumber {
    NSDictionary *params = @{
        @"app_id" : CJString(self.dataModel.appId),
        @"merchant_id" : CJString(self.dataModel.merchantId),
        @"need_encrypt" : @YES
    };
    
    @CJWeakify(self);
    [CJPayAuthPhoneRequest startWithParams:params completion:^(NSError * _Nullable error, CJPayAuthPhoneResponse * _Nonnull response) {
        @CJStrongify(self);
        
        NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
        [params addEntriesFromDictionary:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
        [self p_trackWithEventName:@"wallet_addbcard_page_phoneauth_result" params:[params copy]];
        
        if (![response isSuccess]) {
            [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:self.viewController.cj_window];
            return;
        }
        
        if (!self.hasTrackPhoneNum) {
            NSMutableDictionary *inputParams = [[self p_bankTrackerParamsWithCertType] mutableCopy];
            [inputParams addEntriesFromDictionary:@{@"input_type" : @"mobile"}];
            [self p_trackWithEventName:@"wallet_addbcard_page_input" params:inputParams];
            self.hasTrackPhoneNum = YES;
        }
        
        [self.frontBindCardView.phoneContainer clearTextWithEndAnimated:NO];
        [self p_reverseDisplayMaskedPhoneNumber:self.dataModel.userInfo.uidMobileMask];
        self.isUseAuthPhoneNumber = YES;
        self.authPhoneNumber = CJString(response.mobile);
        
        [self.frontBindCardView layoutAuthTipsView];
    }];
}

// 卡bin信息校验
- (void)p_validateCardInfoWithCardNum:(NSString *)cardNum {
    self.requestID += 1;
    NSInteger requestNum = self.requestID;
    self.latestCardBinNumber = cardNum;
    if (!self.isNiceNetSpeed && cardNum.length >= 10) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.isNiceNetSpeed) {
                [CJToast toastText:CJPayNoNetworkMessage inWindow:self.viewController.cj_window];
                self.isNiceNetSpeed = YES;
            }
        });
    }
    @CJWeakify(self)
    [CJPayMemCardBinInfoRequest startWithAppId:self.dataModel.appId
                                    merchantId:self.dataModel.merchantId
                             specialMerchantId:self.dataModel.specialMerchantId
                                   signOrderNo:self.dataModel.signOrderNo
                                       cardNum:[CJPaySafeUtil encryptField:cardNum]
                                  isFuzzyMatch:YES
                                cardBindSource:self.dataModel.cardBindSource
                                    completion:^(NSError * _Nullable error, CJPayMemCardBinResponse * _Nonnull response) {
        @CJStrongify(self)
        if (cardNum.length >= 10) {
            self.isNiceNetSpeed = YES;
        }
        if (requestNum == self.requestID) {
            if ([response isSuccess]) {
                // 比对银行卡信息，看是否是支持的卡种，是否在支持的银行卡列表中
                response.cardBinInfoModel.cardNumStr = cardNum;
                self.memCardBinResponse = response;
                
                [self p_passCardBinProcess:response.cardBinInfoModel];
            } else {
                NSString *msg = response.buttonInfo.page_desc ?: response.msg;
                if (error) {
                    self.frontBindCardView.nextStepButton.enabled = YES;
                } else {
                    if (Check_ValidString(msg) && cardNum.length > 6) {
                        [self.frontBindCardView updateCardTipsWithWarningText:msg];
                        self.frontBindCardView.recommendBankView.hidden = YES;
                    }
                }
                [self p_trackWithEventName:@"wallet_addbcard_first_page_error_info" params:@{
                    @"card_input_type" : [self p_cardInputType],
                    @"error_code" : CJString(response.code),
                    @"error_message" : CJString(msg)
                }];
            }
        }
    }];
}

- (NSString *)p_cardInputType {
    NSString *cardInputTypeStr = @"0";
    if (self.isCardOCR) {
        cardInputTypeStr = self.latestOCRModel.isFromUploadPhoto ? @"2" : @"1";
    }
    return cardInputTypeStr;
}

- (void)p_passCardBinProcess:(CJPayMemBankInfoModel *)binInfoModel {
    // 通过校验，显示校验出的银行卡,将下一步button置为可用状态
    self.latestCardBinInfo = binInfoModel;
    
    [self.frontBindCardView updateCardTipsMemBankInfoModel:binInfoModel];
    
    self.isCardBinSuccess = YES;
    
    if (!self.hasTrackCardBinSuccess) {
        [self p_trackWithEventName:@"wallet_addbcard_first_page_cardbin_verif_info" params:[self p_bankTrackerParams]];
        self.hasTrackCardBinSuccess = YES;
    }
    
    [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                     metric:@{@"timestamp" : CJString([self timeIntervalSinceFirstStepVC])}
                   category:@{@"userType" : [self p_isAuthorized] ? @"auth" : @"unAuth", @"stage" : @"cardBinSuccess"}
                      extra:@{}];
    
    self.frontBindCardView.nextStepButton.enabled = [self p_isNextStepButtonEnable];
    
    [self.frontBindCardView layoutFrontSecondStepBindCard:self.memCardBinResponse];
}

- (BOOL)p_isPhoneNumValid {
    if (![self p_isAuthorized]) {
        return YES;
    }
    NSString *text = self.frontBindCardView.phoneContainer.textField.userInputContent;
    return text.length == 11;;
}

- (BOOL)p_isCardNumValid {
    // 卡号大于等于14位并且卡bin校验成功卡号才有效
    NSString *cardNo = self.frontBindCardView.cardNumContainer.textField.userInputContent;
    return cardNo.length >= 14 && self.isCardBinSuccess;
}

- (BOOL)p_isAuthorized {
    // 已实名 或者 用户已选择授权实名
    return [self.dataModel.userInfo hasValidAuthStatus] || self.dataModel.isCertification;
}

- (NSString *)timeIntervalSinceFirstStepVC {
    return [NSString stringWithFormat:@"%.01f", [[NSDate date] timeIntervalSince1970] - self.dataModel.firstStepVCTimestamp];
}

- (void)updateCertificationStatus:(BOOL)isCertification {
    self.dataModel.isCertification = isCertification;
    self.frontBindCardView.dataModel.isCertification = isCertification;
}

- (BOOL)p_isNextStepButtonEnable {
    // 卡号无效
    if (![self p_isCardNumValid]) {
        return NO;
    }
    
    // 输入手机号不合法 && 未反显手机号
    if (![self p_isPhoneNumValid] && !self.isPhoneNumReverseDisplay) {
        return NO;
    }
    
    return YES;
}

- (void)p_nextButtonClick {
    @CJWeakify(self)
    [self.frontBindCardView.protocolView executeWhenProtocolSelected:^{
        @CJStrongify(self)
        [self p_startBindCard];
    } notSeleted:^{
        @CJStrongify(self)
        [self.frontBindCardView endEditing:YES];
        CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.frontBindCardView.protocolView.protocolModel from:@"绑卡首页"];
        popupProtocolVC.confirmBlock = ^{
            @CJStrongify(self)
            [self.frontBindCardView.protocolView setCheckBoxSelected:YES];
            [self p_startBindCard];
        };
        [self.viewController.navigationController pushViewController:popupProtocolVC animated:YES];
    } hasToast:NO];
}

- (void)p_startBindCard {
    [self p_trackWithEventName:@"wallet_addbcard_first_page_next_click"
                        params:[self p_bankTrackerParams]];
    
    NSString *cardNoStr = self.frontBindCardView.cardNumContainer.textField.userInputContent;
    @CJStartLoading(self.frontBindCardView.nextStepButton)
    [CJPayMemCardBinInfoRequest startWithAppId:self.dataModel.appId
                                    merchantId:self.dataModel.merchantId
                             specialMerchantId:self.dataModel.specialMerchantId
                                   signOrderNo:self.dataModel.signOrderNo
                                       cardNum:[CJPaySafeUtil encryptField:cardNoStr]
                                  isFuzzyMatch:NO
                                cardBindSource:self.dataModel.cardBindSource
                                    completion:^(NSError * _Nullable error, CJPayMemCardBinResponse * _Nonnull response) {
        @CJStopLoading(self.frontBindCardView.nextStepButton)
        if ([response isSuccess]) {
            [self p_trackWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                @"scenes_name" : @"绑卡",
                @"sub_section" : @"普通绑卡输入卡号",
                @"time" : @(self.inputErrorBankNumberTimes)
            }];
            
            response.cardBinInfoModel.cardNumStr = cardNoStr;
            self.latestCardBinInfo = response.cardBinInfoModel;
            if ([self p_isAuthorized]) {
                // 已实名用户绑卡两步合一步
                [self p_endEditMode];
                NSUInteger curInputContentHash = [[NSString stringWithFormat:@"%@%@", self.latestCardBinInfo.cardNumStr, [self.frontBindCardView.phoneContainer.textField.userInputContent cj_noSpace]] hash];
                
                if (self.smsTimer.curCount <= 0 ||
                    self.lastInputContentHash != curInputContentHash ||
                    !self.latestSMSResponse) {
                    self.lastInputContentHash = curInputContentHash;
                    [self.smsTimer reset];
                    [self p_sendSMS];
                } else {
                    [self p_verifySMS:self.latestSMSResponse];
                }
            } else {
                [self p_gotoSecondStepVC];
            }
        } else {
            self.isCardBinSuccess = NO;
            if (error) {
                [self p_showNoNetworkToast];
            } else {
                self.inputErrorBankNumberTimes++;
                if ([response.code isEqualToString:@"MP020307"] ||
                    [response.code isEqualToString:@"MP020306"]) {
                    NSString *errorDesc = response.buttonInfo.page_desc ?: CJString(response.msg);
                    [self.frontBindCardView updateCardTipsWithWarningText:errorDesc];
                } else {
                    // alert
                    @CJWeakify(self)
                    void(^actionBlock)(void) = ^() {
                        @CJStrongify(self)
                        [self p_trackWithEventName:@"wallet_addbcard_first_page_error_info_click" params:[self p_bankTrackerParams]];

                    };
                    
                    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"请确认输入正确的卡号") content:[NSString stringWithFormat:@"(%@)", CJString(response.code)] buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:actionBlock useVC:self.viewController];
                }
            }
          }
        if (self.isCardOCR) {
            [self p_trackWithEventName:@"wallet_addbcard_orc_accuracy_result" params:@{
                @"result" : [response isSuccess] ? @"1" : @"0"
            }];
        }
    }];
}

- (void)p_sendSMS {
    @CJStartLoading(self.frontBindCardView.nextStepButton)
    @CJWeakify(self)
    
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:[self p_buildBDPaySendSMSBaseParam]
                                                     bizParam:[self p_buildULSMSBizParam]
                                                   completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStopLoading(self.frontBindCardView.nextStepButton)
        
        [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                         metric:@{@"timestamp" : CJString([self timeIntervalSinceFirstStepVC])}
                       category:@{@"userType" : [self p_isAuthorized] ? @"auth" : @"unAuth", @"stage" : @"smsSend"}
                          extra:@{}];
        
        if (error) {
            [self p_showNoNetworkToast];
            return;
        }
        
        [self p_trackWithEventName:@"wallet_businesstopay_auth_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"url" : @"bytepay.member_product.send_sign_sms",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
        
        if (self.isCardOCR) {
            [self p_trackWithEventName:@"wallet_addbcard_orc_accuracy_result_2" params:@{
                @"result" : [response isSuccess] ? @"1" : @"0"
            }];
        }
        if ([response isSuccess]) {
            if (response.faceVerifyInfo && response.faceVerifyInfo.needLiveDetection) {
                
                NSDictionary *params = @{
                    @"app_id" : CJString(self.dataModel.appId),
                    @"merchant_id" : CJString(self.dataModel.merchantId),
                    @"member_biz_order_no" : CJString(self.dataModel.signOrderNo),
                    @"bind_card_source" : @"card_sign"
                };
                
                [self.recogFaceVerifyItem startFaceRecogWithParams:params faceVerifyInfo:[response.faceVerifyInfo getFaceVerifyInfoModel] completion:^(BOOL isSuccess) {
                                    if (isSuccess) {
                                        @CJStrongify(self)
                                        [self p_sendSMS];
                                    } else {
                                        @CJStrongify(self)
                                        [self.viewController.navigationController popToViewController:self.viewController animated:YES];
                                    }
                }];
            } else {
                [self p_verifySMS:response];
            }
        } else if (response.buttonInfo) {
            response.buttonInfo.trackCase = @"3.2";
            response.buttonInfo.code = response.code;
            CJPayButtonInfoHandlerActionsModel *actionModels = [self p_buttonInfoActions:response];
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo
                                                              fromVC:self.viewController
                                                            errorMsg:response.buttonInfo.page_desc ?: CJString(response.msg) withActions:actionModels
                                                           withAppID:self.dataModel.appId
                                                          merchantID:self.dataModel.merchantId];
        } else {
            // 单button alert
            [self p_showSingleButtonAlertWithResponse:response];
        }
    }];
}

- (NSDictionary *)p_buildBDPaySendSMSBaseParam {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams cj_setObject:self.dataModel.merchantId forKey:@"merchant_id"];
    [baseParams cj_setObject:self.dataModel.appId forKey:@"app_id"];
    return baseParams;
}

// 构造三方支付发短信请求参数
- (NSDictionary *)p_buildULSMSBizParam {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:self.dataModel.signOrderNo forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:self.dataModel.specialMerchantId forKey:@"smch_id"];
    //后续需加密处理
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:self.latestCardBinInfo.cardNumStr] forKey:@"card_no"];
    
    NSString *phoneStr = self.isUseAuthPhoneNumber ? CJString(self.authPhoneNumber) : [self.frontBindCardView.phoneContainer.textField.userInputContent cj_noSpace];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:phoneStr] forKey:@"mobile"];
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    
    return bizContentParams;
}

- (void)p_showSingleButtonAlertWithResponse:(CJPaySendSMSResponse *)response {
    if (!Check_ValidString(response.msg)) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:self.viewController.cj_window];
        return;
    }
    
    @CJWeakify(self)
    void(^actionBlock)(void) = ^() {
        @CJStrongify(self)
        NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
        [params addEntriesFromDictionary:@{ @"button_name" : @"2"}];
        [self p_trackWithEventName:@"wallet_addbcard_page_error_click" params:[params copy]];
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJPayAlertUtil customSingleAlertWithTitle:response.msg
                                           content:[NSString stringWithFormat:@"(%@)", response.code]
                                        buttonDesc:CJPayLocalizedStr(@"知道了")
                                       actionBlock:actionBlock
                                             useVC:self.viewController];
    });
    
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    [params addEntriesFromDictionary:@{
        @"button_number" : @"1",
        @"errorcode" : CJString(response.code),
        @"errordesc" : CJString(response.msg)
    }];
    [self p_trackWithEventName:@"wallet_addbcard_page_error_imp" params:[params copy]];
}

- (void)p_showNoNetworkToast {
    [CJToast toastText:CJPayNoNetworkMessage inWindow:self.viewController.cj_window];
}

- (CJPayButtonInfoHandlerActionsModel *)p_buttonInfoActions:(CJPaySendSMSResponse *)response {
    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
    @CJWeakify(self)
    
    actionModel.logoutBizRealNameAction = ^{
        // 去注销宿主端实名能力降级处理，只展示提示文案
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_businesstopay_auth_fail_click" params:@{}];
    };
    
    actionModel.alertPresentAction = ^{
        @CJStrongify(self)
        [self p_trackWithEventName:@"wallet_businesstopay_auth_fail_imp" params:@{}];
    };
    
    NSString *retCode = CJString(response.code);
    actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
        @CJStrongify(self);
        if ([retCode isEqualToString:@"MP020306"] ||
            [retCode isEqualToString:@"MP020307"]) {
            [self.frontBindCardView.cardNumContainer.textField becomeFirstResponder];
            [self.frontBindCardView updateCardTipsWithWarningText:errorText];
            self.frontBindCardView.recommendBankView.hidden = YES;
        } else if ([retCode isEqualToString:@"MP020308"]) {
            [self.frontBindCardView.phoneContainer.textField becomeFirstResponder];
            [self.frontBindCardView updatePhoneTipsWithWarningText:errorText];
        } else {
            [CJToast toastText:errorText inWindow:self.viewController.cj_window];
        }
    };
    
    return actionModel;
}

- (void)p_verifySMS:(CJPaySendSMSResponse *)response {
    [self p_endEditMode];
    self.latestSMSResponse = response;
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageTypeHalfVerifySMS params:nil completion:nil];
    
    if (![vc isKindOfClass:CJPayHalfSignCardVerifySMSViewController.class]) {
        return;
    }
    CJPayHalfSignCardVerifySMSViewController *verifySMSVC = (CJPayHalfSignCardVerifySMSViewController *)vc;
    verifySMSVC.ulBaseReqquestParam = [self p_buildBDPaySendSMSBaseParam];
    verifySMSVC.sendSMSResponse = response;
    verifySMSVC.sendSMSBizParam = [self p_buildULSMSBizParam];
    verifySMSVC.bankCardInfo = self.latestCardBinInfo;
    verifySMSVC.externTimer = self.smsTimer;
    if (!CJ_Pad) {
        [verifySMSVC useCloseBackBtn];
    }
    NSMutableString *phoneNoMaskStr = [[self.frontBindCardView.phoneContainer.textField.userInputContent cj_noSpace] mutableCopy];

    if (phoneNoMaskStr.length == 11) {
        [phoneNoMaskStr replaceCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
    }
    CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
    helpModel.cardNoMask = self.latestCardBinInfo.cardNumStr;
    helpModel.frontBankCodeName = self.latestCardBinInfo.bankName;
    helpModel.phoneNum = phoneNoMaskStr;

    verifySMSVC.helpModel = helpModel;
    verifySMSVC.animationType = HalfVCEntranceTypeFromBottom;
    [verifySMSVC showMask:YES];
    [self.viewController.navigationController pushViewController:verifySMSVC animated:YES];
}

- (void)p_gotoSecondStepVC {
    [self.frontBindCardView.cardNumContainer.textField resignFirstResponder];
    UIViewController *vc = [[CJPayBindCardManager sharedInstance]
                            openPage:CJPayBindCardPageTypeCommonFourElements
                            params:@{CJPayBindCardPageParamsKeyInfoModel : [self.latestCardBinInfo toDictionary] ?: @{},
                                     CJPayBindCardPageParamsKeyMemCardBinResponse : [self.memCardBinResponse toDictionary] ?: @{},
                                     CJPayBindCardPageParamsKeyIsFromCardOCR : @(self.isCardOCR)
                                   }
                            completion:nil];
    if ([vc isKindOfClass:CJPayBindCardFourElementsViewController.class]) {
        CJPayBindCardFourElementsViewController *secondStepVC = (CJPayBindCardFourElementsViewController *)vc;
        secondStepVC.smsTimer = self.smsTimer;
    } else {
        CJPayLogAssert(NO, @"不应该走到这里");
    }
}

- (void)p_gotoCardOCR {
    [self p_trackWithEventName:@"wallet_addbcard_first_page_orc_click" params:nil];
    
    
    CJPayBankCardOCRViewController *cardOCRVC = [CJPayBankCardOCRViewController new];
    cardOCRVC.appId = self.dataModel.appId;
    cardOCRVC.merchantId = self.dataModel.merchantId;
    cardOCRVC.minLength = 12;
    cardOCRVC.maxLength = 23;
    cardOCRVC.trackDelegate = self;
    
    cardOCRVC.BPEAData.requestAccessPolicy = @"bpea-caijing_ocr_bankcardID_camera_permission";
    cardOCRVC.BPEAData.jumpSettingPolicy = @"bpea-caijing_ocr_bankcardID_available_goto_setting";
    cardOCRVC.BPEAData.startRunningPolicy = @"bpea-caijing_ocr_bankcardID_avcapturesession_start_running";
    cardOCRVC.BPEAData.stopRunningPolicy = @"bpea-caijing_ocr_bankcardID_avcapturesession_stop_running";
    
    @CJWeakify(self)
    cardOCRVC.completionBlock = ^(CJPayCardOCRResultModel * _Nonnull resultModel) {
        @CJStrongify(self)
        self.latestOCRModel = resultModel;
        switch (resultModel.result) {
            case CJPayCardOCRResultSuccess:
                [self p_fillCardNoAndCardImg:resultModel];
                break;
            case CJPayCardOCRResultUserCancel: // 用户取消识别
            case CJPayCardOCRResultUserManualInput: // 用户手动输入
                self.isCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoCameraAuthority: //BPEA降级导致无法获取相机权限
                [CJToast toastText:@"没有相机权限" inWindow:self.viewController.cj_window];
                self.isCardOCR = NO;
                break;
            case CJPayCardOCRResultBackNoJumpSettingAuthority: //BPEA降级导致无法跳转系统设置开启相机权限
                [CJToast toastText:@"没有跳转系统设置权限" inWindow:self.viewController.cj_window];
                self.isCardOCR = NO;
                break;
            default:
                break;
        }
    };
    [self.viewController.navigationController pushViewController:cardOCRVC animated:YES];
}

- (void)p_fillCardNoAndCardImg:(CJPayCardOCRResultModel *)resultModel {
    NSString *cardInputTypeStr = self.latestOCRModel.isFromUploadPhoto ? @"2" : @"1";
    [self p_trackWithEventName:@"wallet_addbcard_first_page_input" params:@{@"card_input_type": cardInputTypeStr}];
    self.hasTrackValidInput = YES;
    
    [self.frontBindCardView.cardNumContainer clearText];
    self.isCardBinSuccess = NO;
    
    [self.frontBindCardView.cardNumContainer textFieldBeginEditAnimation];
    CJPayCustomTextField *textField = self.frontBindCardView.cardNumContainer.textField;
    [textField textField:textField shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:CJString(resultModel.cardNoStr)];
    
    self.frontBindCardView.cardImgView.image = [UIImage imageWithData:[[resultModel.cropImgStr cj_remove:@"\r\n"] base64DecodeData]];
    if (self.frontBindCardView.cardImgView.image) {
        [self p_updateCardImgViewShowState:YES];
    }
    
    [self textFieldContentChange:[self.frontBindCardView.cardNumContainer.textField.text cj_noSpace] textContainer:self.frontBindCardView.cardNumContainer];
    self.isCardOCR = YES;
    [self.frontBindCardView showOCRButton:YES];
}

- (void)p_supportListButtonClick {
    NSString *supportCardListUrl = [NSString stringWithFormat:@"%@/cardbind/banklist?merchant_id=%@&app_id=%@&smch_id=%@&sign_order_no=%@&title=%@", [CJPayBaseRequest bdpayH5DeskServerHostString], self.dataModel.merchantId, self.dataModel.appId, @"SmchID", self.dataModel.signOrderNo, CJPayLocalizedStr(@"支持银行列表")];
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self.viewController useNewNavi:YES toUrl:supportCardListUrl params:@{} nativeStyleParams:@{} closeCallBack:^(id  _Nonnull data) {
        
    }];
    [self p_trackWithEventName:@"wallet_addbcard_first_page_support_banklist_click" params:nil];
}

- (NSDictionary *)p_bankTrackerParams
{
    NSMutableDictionary *cardTypeNameDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"DEBIT" : @"储蓄卡",
        @"CREDIT" : @"信用卡"
    }];
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *activityInfo = [self.memCardBinResponse toActivityInfoTracker];
    if (activityInfo.count > 0 ) {
        [activityInfos addObject:activityInfo];
    }
    
    return @{
        @"bank_name" : CJString(self.latestCardBinInfo.bankName),
        @"bank_type" : CJString([cardTypeNameDic cj_stringValueForKey:CJString(self.latestCardBinInfo.cardType)]),
        @"activity_info" : activityInfos,
        @"card_input_type" : [self p_cardInputType]
    };
}

- (NSDictionary *)p_bankTrackerParamsWithCertType {
    NSString *selectedType = @"";
    if ([self.dataModel.userInfo hasValidAuthStatus]) {
        selectedType = [CJPayBindCardChooseIDTypeModel getIDTypeWithCardTypeStr:self.dataModel.userInfo.certificateType];
    } else {
        selectedType = [CJPayBindCardChooseIDTypeModel getIDTypeWithCardTypeStr:self.dataModel.bizAuthInfo.idType];
    }
    NSMutableDictionary *params = [[self p_bankTrackerParams] mutableCopy];
    [params addEntriesFromDictionary:@{@"type" : CJString(selectedType)}];
    
    return [params copy];
}

- (void)p_endEditMode {
    [self.viewController.view endEditing:YES];
}

- (NSDictionary *)p_genDictionaryByKeys:(NSArray <NSString *>*)keys fromViewModel:(CJPayBindCardNumberDataModel *)viewModel {
    if (keys == nil || keys.count == 0 || viewModel == nil) {
        return nil;
    }
    
    NSDictionary *allSharedDataDict = [viewModel toDictionary];
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict cj_objectForKey:key]) {
            [returnDict cj_setObject:[allSharedDataDict cj_objectForKey:key] forKey:key];
        }
    }];
    
    return [returnDict copy];
}

- (void)p_gotoSearchCardNo {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayWebViewService) i_openCjSchemaByHost:self.searchCardNoURL fromVC:self.viewController useModal:YES];
}

- (void)p_restoreBankCardVoucherMsg {
    if (Check_ValidString(self.quickBindCardModel.voucherMsg)) {
        [self.frontBindCardView updateCardTipsWithQuickBindCardModel:self.quickBindCardModel];
        return;
    }
    
    if (self.dataModel.isQuickBindCardListHidden && self.dataModel.pageFromCashierDesk) {
        [self.frontBindCardView updateCardTipsAsVoucherMsgWithResponse:self.bankSupportListResponse];
        return;
    }
    
    if (self.dataModel.isQuickBindCardListHidden && self.dataModel.isFromQuickBindCard) {//从一键绑卡跳只有输入卡号的绑卡首页
        self.frontBindCardView.cardTipView.hidden = YES;
        return;
    }
    
    [self.frontBindCardView updateCardTipsAsVoucherMsgWithResponse:self.bankSupportListResponse];
}

- (void)p_resetTipsPlace {
    if ([self.frontBindCardView.recommendBankView isTipsShow]) {
        self.frontBindCardView.cardTipView.hidden = YES;
        self.frontBindCardView.recommendBankView.hidden = NO;
    } else if (self.frontBindCardView.isShowBankCardVoucher) {
        [self p_restoreBankCardVoucherMsg];
    } else {
        self.frontBindCardView.cardTipView.hidden = YES;
        self.frontBindCardView.recommendBankView.hidden = YES;
    }
}

- (void)updateBankAndVoucherInfo:(CJPayQuickBindCardModel *)quickBindCardModel {
    self.quickBindCardModel = quickBindCardModel;
    [self.frontBindCardView updateCardTipsWithQuickBindCardModel:quickBindCardModel];
}

#pragma mark - CJPayCustomTextFieldContainerDelegate
- (void)textFieldBeginEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (self.frontBindCardView.phoneContainer == textContainer) {
        [self.frontBindCardView layoutAuthTipsView];
        CJ_CALL_BLOCK(self.rollUpQuickBindCardListBlock);
    } else if (self.frontBindCardView.cardNumContainer == textContainer) {
        CJ_CALL_BLOCK(self.rollUpQuickBindCardListBlock);
    }
}

- (void)textFieldContentChange:(NSString *)curText
                 textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.frontBindCardView.phoneContainer) {
        // 实时校验手机号码，如果合法或者为空就把错误提示消除
        [self.frontBindCardView layoutAuthTipsView];
        if (!self.isPhoneNumReverseDisplay && ([self p_isPhoneNumValid] || [curText isEqualToString:@""])) {
            [self.frontBindCardView updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
        }
        
        // 反显手机号掩码编辑一次就全部删除
        if (self.isPhoneNumReverseDisplay) {
            [self.frontBindCardView.phoneContainer clearTextWithEndAnimated:NO];
            self.isPhoneNumReverseDisplay = NO;
            self.frontBindCardView.phoneContainer.textField.supportSeparate = YES;
        }
        
        if (!self.hasTrackPhoneNum) {
            NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
            [params addEntriesFromDictionary:@{@"input_type" : @"mobile"}];
            [self p_trackWithEventName:@"wallet_addbcard_page_input" params:params];
            self.hasTrackPhoneNum = YES;
        }
    } else if (textContainer == self.frontBindCardView.cardNumContainer) {
        // 前缀是否匹配
        BOOL isMatchPrefix = [curText hasPrefix:self.latestCardBinNumber] || [self.latestCardBinNumber hasPrefix:curText];
        // 卡号大于6位且前缀不匹配需重新校验
        BOOL needReValidateCardBin = !isMatchPrefix && Check_ValidString(self.latestCardBinNumber) && (curText.length >= 6);
        
        if ((curText.length == 6 || curText.length >= 10) && !self.isCardBinSuccess) {
            // 超过6位如果卡bin校验没成功就继续校验
            [self p_validateCardInfoWithCardNum:curText];
        } else if (needReValidateCardBin) {
            [self p_validateCardInfoWithCardNum:curText];
        }

        if (curText.length < 6) {
            [self p_resetTipsPlace];
            self.frontBindCardView.nextStepButton.enabled = NO;
            self.isCardBinSuccess = NO;
        }
        
        if (curText.length == 0) {
            [self p_updateCardImgViewShowState:NO];
        }
        self.isCardOCR = NO; // 用户手动修改输入框则设置为非OCR输入卡号模式
        if (!self.hasTrackValidInput) {
            [self p_trackWithEventName:@"wallet_addbcard_first_page_input" params:@{@"card_input_type": @"0"}];
            self.hasTrackValidInput = YES;
        }
    }
    self.frontBindCardView.nextStepButton.enabled = [self p_isNextStepButtonEnable];
}

- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer {
    
    NSString *monitorStage = [NSString new];
    
    if (self.frontBindCardView.phoneContainer == textContainer) {
        [self.frontBindCardView layoutAuthTipsView];
        BOOL isLegal = YES;
        if (!self.isPhoneNumReverseDisplay && ![self p_isPhoneNumValid] &&
            ![self.frontBindCardView.phoneContainer.textField.userInputContent isEqualToString:@""]) {
            [self.frontBindCardView updatePhoneTipsWithWarningText:CJPayLocalizedStr(@"请输入正确的手机号码")];
            isLegal = NO;
        }
        
        monitorStage = @"phoneNumInput";
        
        NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
        [params addEntriesFromDictionary:@{
            @"input_type" : @"mobile",
            @"is_legal" : isLegal ? @"1" : @"0"
        }];
        [self p_trackWithEventName:@"wallet_addbcard_page_input_inform_verif_info" params:params];
    }
    
    [CJMonitor trackService:@"wallet_rd_bindcard_stage_timestamp"
                     metric:@{@"timestamp" : CJString([self timeIntervalSinceFirstStepVC])}
                   category:@{@"userType" : [self p_isAuthorized] ? @"auth" : @"unAuth", @"stage" : CJString(monitorStage)}
                      extra:@{}];
}

- (void)textFieldWillClear:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.frontBindCardView.cardNumContainer) {
        self.isCardBinSuccess = NO;
        [self p_updateCardImgViewShowState:NO];
    } else if (textContainer == self.frontBindCardView.phoneContainer) {
        if (self.isPhoneNumReverseDisplay) {
            self.isPhoneNumReverseDisplay = NO;
            self.frontBindCardView.phoneContainer.textField.supportSeparate = YES;
        }
    }
    
    self.frontBindCardView.nextStepButton.enabled = NO;
}

- (void)textFieldDidClear:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.frontBindCardView.phoneContainer) {
        [self.frontBindCardView layoutAuthTipsView];
    } else if (textContainer == self.frontBindCardView.cardNumContainer) {
        [self p_resetTipsPlace];
    }
}

#pragma mark - setter&getter
- (CJPayBindCardNumberView *)frontBindCardView {
    if (!_frontBindCardView) {
        NSArray *needParams = [CJPayBindCardNumberView dataModelKey];
        NSDictionary *paramsDict = [self p_genDictionaryByKeys:needParams fromViewModel:self.dataModel];
        _frontBindCardView = [[CJPayBindCardNumberView alloc] initWithBindCardDictonary:paramsDict];
        _frontBindCardView.clipsToBounds = YES;
        _frontBindCardView.delegate = self;
        _frontBindCardView.viewModel = self;
        
        @CJWeakify(self)
        _frontBindCardView.didFrontSecondStepBindCardAppearBlock = ^{
            @CJStrongify(self)
            if (self.isPhoneNumReverseDisplay && !self.hasTrackPhoneNum) {
                NSMutableDictionary *params = [[self p_bankTrackerParamsWithCertType] mutableCopy];
                [params addEntriesFromDictionary:@{@"input_type" : @"mobile"}];
                [self p_trackWithEventName:@"wallet_addbcard_page_input" params:params];
                self.hasTrackPhoneNum = YES;
            }
        };
        
        _frontBindCardView.didNextButtonClickBlock = ^{
            @CJStrongify(self)
            [self p_nextButtonClick];
        };
        _frontBindCardView.headerView.didSupportListButtonClickBlock = ^{
            @CJStrongify(self)
            [self p_supportListButtonClick];
        };
        _frontBindCardView.didAuthButtonAppearBlock = ^{
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_addbcard_page_phoneauth_imp" params:[self p_bankTrackerParamsWithCertType]];
        };
        _frontBindCardView.didClickAgreeAuthButtonBlock = ^{
            @CJStrongify(self)
            [self p_fetchAuthPhoneNumber];
            [self p_trackWithEventName:@"wallet_addbcard_page_phoneauth_click" params:[self p_bankTrackerParamsWithCertType]];
        };
        _frontBindCardView.didClickCloseAuthButtonBlock = ^{
            @CJStrongify(self)
            [self.frontBindCardView layoutAuthTipsView];
            [self p_trackWithEventName:@"wallet_addbcard_page_phoneauth_close" params:[self p_bankTrackerParamsWithCertType]];
        };
        _frontBindCardView.didClickOCRButtonBlock = ^{
            @CJStrongify(self)
            [self p_gotoCardOCR];
            CJ_CALL_BLOCK(self.rollUpQuickBindCardListBlock);
        };
        _frontBindCardView.didClickProtocolBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)

            NSString *nameList = [NSString new];
            if ([[agreements valueForKey:@"name"] isKindOfClass:[NSArray class]]) {
                nameList = [(NSArray *)[agreements valueForKey:@"name"] componentsJoinedByString:@","];
            }
            [self p_trackWithEventName:@"wallet_agreement_click" params:@{
                @"agreement_type" : CJString(nameList)
            }];
        };
        
        _frontBindCardView.headerView.didClickSearchCardNoBlock = ^{
            @CJStrongify(self)
            [self p_endEditMode];
            [self p_gotoSearchCardNo];
        };
        
        if (Check_ValidString(self.dataModel.bankMobileNoMask) &&
            [self p_isAuthorized]) {
            [self p_reverseDisplayMaskedPhoneNumber:self.dataModel.bankMobileNoMask];
        }
    }
    return _frontBindCardView;
}

- (CJPayTimer *)smsTimer {
    if (!_smsTimer) {
        _smsTimer = [CJPayTimer new];
        _smsTimer.delegate = self;
    }
    return _smsTimer;
}

- (CJPayVerifyItemBindCardRecogFace *)recogFaceVerifyItem {
    if (!_recogFaceVerifyItem) {
        _recogFaceVerifyItem = [CJPayVerifyItemBindCardRecogFace new];
        @CJWeakify(self)
        _recogFaceVerifyItem.loadingBlock = ^(BOOL isLoading) {
            @CJStrongify(self)
            if (isLoading) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
            } else {
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinLoading];
            }
        };
        _recogFaceVerifyItem.referVC = self.viewController;
        _recogFaceVerifyItem.verifySource = @"普通绑卡";
    }
    return _recogFaceVerifyItem;
}

- (void)setIsPhoneNumReverseDisplay:(BOOL)isPhoneNumReverseDisplay {
    _isPhoneNumReverseDisplay = isPhoneNumReverseDisplay;
    if (!_isPhoneNumReverseDisplay) {
        self.isUseAuthPhoneNumber = NO;
    }
}

- (void)setBankSupportListResponse:(CJPayMemBankSupportListResponse *)bankSupportListResponse {
    _bankSupportListResponse = bankSupportListResponse;
    if (bankSupportListResponse.exts) {
        self.searchCardNoURL = [bankSupportListResponse.exts cj_stringValueForKey:@"search_card_no"];
    }
    
    //输入卡号框下方是否展示特定X银行Y卡营销
    self.frontBindCardView.isShowBankCardVoucher = [bankSupportListResponse.voucherBankInfo hasVoucher] || Check_ValidString(bankSupportListResponse.voucherMsg);
    //是否展示地方性推荐银行
    self.frontBindCardView.isShowRecommendBanks = Check_ValidArray(bankSupportListResponse.recommendBanks);
    
    self.frontBindCardView.headerView.searchCardNoBtn.hidden = !Check_ValidString(self.searchCardNoURL);
    [self.frontBindCardView updateCardTipsAsVoucherMsgWithResponse:bankSupportListResponse];
    BDPayBindCardHeaderViewDataModel *bindCardHeaderViewDM = [BDPayBindCardHeaderViewDataModel new];
    bindCardHeaderViewDM.firstStepMainTitle = bankSupportListResponse.cardNoInputTitle;
    [self.frontBindCardView.headerView updateHeaderView:bindCardHeaderViewDM];
    
    if (self.frontBindCardView.isShowBankCardVoucher) {
        [self.frontBindCardView changeShowTypeTo:CJPayBindCardNumberViewShowTypeOriginalShowBankCardVoucher];
    } else if (self.frontBindCardView.isShowRecommendBanks) {
        [self.frontBindCardView.recommendBankView updateContent:bankSupportListResponse.recommendBanks];
        [self.frontBindCardView changeShowTypeTo:CJPayBindCardNumberViewShowTypeShowRecommendBank];
    }
    
    self.frontBindCardView.firstShowType = self.frontBindCardView.curShowType;
}

#pragma mark - CJPayTimerProtocol
- (void)currentCountChangeTo:(int)value {
    if (value <= 0) {
        [self.smsTimer reset];
    }
}

#pragma mark - tracker
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackerDelegate && [self.trackerDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackerDelegate event:eventName params:params];
    }
}

- (void)event:(NSString * _Nonnull)event params:(NSDictionary * _Nullable)params {
    [self p_trackWithEventName:event params:params];
}

@end
