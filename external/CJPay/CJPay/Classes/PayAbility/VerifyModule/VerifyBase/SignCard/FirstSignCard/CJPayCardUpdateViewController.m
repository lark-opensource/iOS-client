//
//  CJPayCardUpdateViewController.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/30.
//

#import "CJPayCardUpdateViewController.h"

#import "CJPayQuickPayChannelModel.h"
#import "CJPayCardUpdateModel.h"
#import "CJPayBindCardScrollView.h"
#import "CJPayCardUpdateView.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayStyleButton.h"
#import "CJPayMemberSendSMSRequest.h"
#import "CJPayHalfCardUpdateVerifySMSViewController.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPaySafeUtil.h"
#import "CJPayCardSignInfoModel.h"
#import "CJPayBindCardProtocolView.h"
#import "CJPayAlertUtil.h"
#import "CJPayUIMacro.h"


@interface CJPayCardUpdateViewController ()<CJPayCustomTextFieldContainerDelegate, UIScrollViewDelegate>

@property (nonatomic,strong) CJPayBindCardScrollView *scrollView;
@property (nonatomic,strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayCardUpdateView *cardUpdateView;

@property (nonatomic, strong) CJPayCardUpdateModel *cardUpdateModel;

@property (nonatomic, assign) BOOL shouldHandleInputTracker; // 第一次输入时埋点上报

@end

@implementation CJPayCardUpdateViewController

- (instancetype)initWithCardUpdateModel:(CJPayCardUpdateModel *)cardUpdateModel {
        self = [super init];
        if (self) {
            self.cardUpdateModel = cardUpdateModel;
        }
        return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_trackWithEventName:@"update_bank_page_visit" params:nil];
    [CJKeyboard becomeFirstResponder:self.cardUpdateView.phoneContainer.textField];
}

- (void)back
{
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
    } else {
        [super back];
    }
}

- (void)p_endEdit
{
    [self.view endEditing:YES];
}

- (void)p_setupUI
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEdit)];
    [self.view addGestureRecognizer:tapGesture];

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.cardUpdateView];
    
    CJPayMasMaker(self.scrollView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.bottom.equalTo(self.view);
    });
    
    CJPayMasMaker(self.cardUpdateView, {
        make.top.equalTo(self.scrollContentView);
        make.left.right.bottom.equalTo(self.scrollContentView);
    });
    
    self.cardUpdateView.phoneContainer.delegate = self;
    [self.cardUpdateView updateWithBDPayCardUpdateModel:self.cardUpdateModel];
    [self.cardUpdateView.phoneContainer updateTips:CJPayLocalizedStr(@"与银行预留手机号码不一致")];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (NSDictionary *)p_buildULBDPaySendSMSBaseParam {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    [baseParams cj_setObject:self.cardUpdateModel.merchantId forKey:@"merchant_id"];
    [baseParams cj_setObject:self.cardUpdateModel.appId forKey:@"app_id"];
    return baseParams;
}

// 构造三方支付发短信请求参数
- (NSDictionary *)p_buildULSMSBizParam {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:self.cardUpdateModel.cardSignInfo.signOrderNo forKey:@"sign_order_no"];
    [bizContentParams cj_setObject:self.cardUpdateModel.cardSignInfo.smchId forKey:@"smch_id"];
    [bizContentParams cj_setObject:self.cardUpdateModel.cardModel.bankCardID forKey:@"bank_card_id"];
    //后续需加密处理
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:self.cardUpdateModel.cardModel.bankCardID] forKey:@"card_no"];
    NSString *phoneStr = self.cardUpdateView.phoneContainer.textField.userInputContent;
    NSMutableString *mutablePhoneStr = [NSMutableString stringWithString:phoneStr];
    NSString *noSpacePhoneStr = [mutablePhoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:noSpacePhoneStr] forKey:@"mobile"];
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    
    return bizContentParams;
}

- (void)p_sendSMS
{
    @CJWeakify(self)
    @CJStartLoading(self.cardUpdateView.nextStepButton)
    [CJPayMemberSendSMSRequest startWithBDPaySendSMSBaseParam:[self p_buildULBDPaySendSMSBaseParam]
                                       bizParam:[self p_buildULSMSBizParam]
                                     completion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStopLoading(self.cardUpdateView.nextStepButton)
        
        if (error) {
            [self showNoNetworkToast];
            [self p_trackWithEventName:@"update_bank_result" params:@{
                @"result" : @"0",
                @"error_code" : @(error.code),
                @"error_message" : CJString(error.localizedDescription)
            }];
            return;
        }
        
        if ([response isSuccess]) {
            
            [self p_trackWithEventName:@"update_bank_result" params:@{
                @"result" : @"1",
                @"error_code" : @(0), // 传默认code
                @"error_message" : @""
            }];
            
            [self.view endEditing:YES];
            CJPayHalfCardUpdateVerifySMSViewController *verifySMSVC = [[CJPayHalfCardUpdateVerifySMSViewController alloc] initWithAnimationType:HalfVCEntranceTypeFromBottom withBizType:CJPayVerifySMSBizTypePay];
            verifySMSVC.ulBaseReqquestParam = [self p_buildULBDPaySendSMSBaseParam];
            verifySMSVC.cardUpdateModel = self.cardUpdateModel;
            verifySMSVC.sendSMSResponse = response;
            verifySMSVC.sendSMSBizParam = [self p_buildULSMSBizParam];
            verifySMSVC.cardSignSuccessCompletion = ^(CJPaySignSMSResponse * _Nonnull response) {
                @CJStrongify(self)
                CJPayLogInfo(@"签名成功");
                if (self.cardUpdateSuccessCompletion) {
                    self.cardUpdateSuccessCompletion([response isSuccess]);
                }
            };
            if (!CJ_Pad) {
                [verifySMSVC useCloseBackBtn];
            }
            
            NSMutableString *mutablePhoneStr = [self.cardUpdateView.phoneContainer.textField.userInputContent mutableCopy];
            NSString *noSpacePhoneStr = [mutablePhoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableString *phoneNoMaskStr = [[NSMutableString alloc] initWithString:CJString(noSpacePhoneStr)];
            
            if (phoneNoMaskStr.length == 11) {
                [phoneNoMaskStr replaceCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
            }
            CJPayVerifySMSHelpModel *helpModel = [CJPayVerifySMSHelpModel new];
            helpModel.cardNoMask = self.cardUpdateModel.cardModel.cardNoMask;//.cardInfoModel.cardNumStr;
            helpModel.frontBankCodeName = self.cardUpdateModel.cardModel.frontBankCodeName;//.cardInfoModel.bankName;
            helpModel.phoneNum = phoneNoMaskStr;
            
            verifySMSVC.helpModel = helpModel;
            verifySMSVC.animationType = HalfVCEntranceTypeFromBottom;
            [verifySMSVC showMask:YES];
            [self.navigationController pushViewController:verifySMSVC animated:YES];
        } else {
            // 单button alert
            [self p_showSingleButtonAlertWithResponse:response];
        }
    }];
}

- (void)p_showSingleButtonAlertWithResponse:(CJPaySendSMSResponse *)response {
    if(Check_ValidString(response.msg)) {
        [CJPayAlertUtil customSingleAlertWithTitle:CJString(response.msg) content:CJString(response.code) buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:nil useVC:self];
    }
}

- (CGFloat)navigationHeight {
    if (CJ_Pad) {
        return [super navigationHeight];
    }
    if (self.navigationBar.hidden) {
        return 0.0;
    } else {
        return CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT;
    }
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[CJPayBindCardScrollView alloc] init];
        _scrollView.bounces  = YES;
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
    }
    return _scrollContentView;
}

- (CJPayCardUpdateView *)cardUpdateView
{
    if (!_cardUpdateView) {
        _cardUpdateView = [[CJPayCardUpdateView alloc] init];
        @CJWeakify(self)
        _cardUpdateView.confirmBlock = ^{
            @CJStrongify(self)
            [self p_sendSMS];
        };
        _cardUpdateView.protocolView.protocolClickCompletion = ^{
            @CJStrongify(self)
            [self p_endEdit];
        };
    }
    return _cardUpdateView;
}

- (BOOL)p_isPhoneNumInvalid
{
   return self.cardUpdateView.phoneContainer.textField.userInputContent.length == 11;
}

#pragma mark CJPayCustomTextFieldContainerDelegate
- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    self.cardUpdateView.nextStepButton.enabled = [self p_isPhoneNumInvalid];
    if ([self p_isPhoneNumInvalid] || [curText isEqualToString:@""]) {
        [self.cardUpdateView.phoneContainer updateTips:@""];
    }
    
    if (!self.shouldHandleInputTracker) {
        [self p_trackWithEventName:@"update_bank_page_input" params:nil];
        self.shouldHandleInputTracker = YES;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (![self p_isPhoneNumInvalid] && ![self.cardUpdateView.phoneContainer.textField.userInputContent isEqualToString:@""]) {
        [self.cardUpdateView.phoneContainer updateTips:CJPayLocalizedStr(@"请输入正确的手机号码")];
    }
}

- (void)textFieldWillClear:(CJPayCustomTextFieldContainer *)textContainer {
    self.cardUpdateView.nextStepButton.enabled = NO;
    [textContainer updateTips:@""];
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

@end
