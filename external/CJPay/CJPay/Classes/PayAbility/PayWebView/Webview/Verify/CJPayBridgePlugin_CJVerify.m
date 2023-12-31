//
//  CJPayBridgePlugin_CJVerify.m
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import "CJPayBridgePlugin_CJVerify.h"

#import "CJPayBizWebViewController.h"
#import "CJPayHalfScreenSMSVerificationViewController.h"
#import "CJPayHalfScreenSMSVerificationH5Presenter.h"
#import "CJPaySMSVerificationRequestModel.h"
#import "UIViewController+CJTransition.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPayUIMacro.h"

@interface CJPayBridgePlugin_CJVerify ()

@property (nonatomic, strong) CJPayHalfScreenSMSVerificationViewController *verifyVC;

@end

@implementation CJPayBridgePlugin_CJVerify

+ (void)registerBridge
{
    TTRegisterBridgeMethod
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_CJVerify, CJVerify), @"ttcjpay.CJVerify");
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_CJVerify, CJVerifyNotify), @"ttcjpay.CJVerifyNotify");

}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)CJVerifyWithParam:(NSDictionary *)param
                 callback:(TTBridgeCallback)callback
                   engine:(id<TTBridgeEngine>)engine
               controller:(UIViewController *)controller
{
    CJPayBizWebViewController *webViewController = (CJPayBizWebViewController *)controller;
    if (webViewController == nil || ![webViewController isKindOfClass:CJPayBizWebViewController.class]) {
        TTBRIDGE_CALLBACK_FAILED_MSG(@"webViewController初始化失败");
        return;
    }

    NSError *err = nil;
    CJPaySMSVerificationRequestModel *model = [[CJPaySMSVerificationRequestModel alloc] initWithDictionary:param error:&err];
    if (err) {
        CJPayLogInfo(@"json error: %@", err);
        TTBRIDGE_CALLBACK_FAILED_MSG(@"json解析异常");
        return;
    }
    
    self.verifyVC = [self p_verifyVCFromModel:model];
    [webViewController.navigationController pushViewController:self.verifyVC animated:YES];
    TTBRIDGE_CALLBACK_SUCCESS;
}

- (void)CJVerifyNotifyWithParam:(NSDictionary *)param
                       callback:(TTBridgeCallback)callback
                         engine:(id<TTBridgeEngine>)engine
                     controller:(UIViewController *)controller
{
    NSDictionary *dict = (NSDictionary *)param;
    if ([dict count] == 0) {
        CJPayLogInfo(@"CJVerifyNotify param error");
        TTBRIDGE_CALLBACK_FAILED_MSG(@"Notify param error");
        return;
    }
    
    [[self p_presenter] onReceiveH5Message:dict];
    TTBRIDGE_CALLBACK_SUCCESS;
}

#pragma mark - Private

- (CJPayHalfScreenSMSVerificationViewController *)p_verifyVCFromModel:(CJPaySMSVerificationRequestModel *)model
{
    CJPayHalfScreenSMSVerificationViewController *vc = [[CJPayHalfScreenSMSVerificationViewController alloc] initWithAnimationType:model.animationType];
    vc.cjVCIdentify = model.identify;
    [vc showMask:YES];
    if (model.usesCloseButton) {
        [vc useCloseBackBtn];
    }
    
    @CJWeakify(self)
    CJPayHalfScreenSMSVerificationH5Presenter *presenter
    = [[CJPayHalfScreenSMSVerificationH5Presenter alloc] initWithVC:vc
                                                             model:model
                                                      sendingBlock:^(NSInteger code, NSString *type, NSString *data) {
        @CJStrongify(self)
        [self p_sendMessage:code type:type data:data];
    }];
    vc.viewDelegate = presenter;

    return vc;
}

- (void)p_sendMessage:(NSInteger)code type:(NSString *)type data:(NSString *)data
{
    NSDictionary *result = @{
        @"type": CJString(type),
        @"data": CJString(data),
    };

    [self p_callJSEvent:result];
}

- (CJPayHalfScreenSMSVerificationH5Presenter *)p_presenter
{
    CJPayHalfScreenSMSVerificationH5Presenter *presenter = nil;
    if ([(id)self.verifyVC.viewDelegate isKindOfClass:CJPayHalfScreenSMSVerificationH5Presenter.class]) {
        presenter = (CJPayHalfScreenSMSVerificationH5Presenter *)self.verifyVC.viewDelegate;
    }
    return presenter;
}

- (void)p_callJSEvent:(NSDictionary *)eventData
{
    NSDictionary *params = @{@"type": @"CJVerifyRes", @"data": eventData};
    [self.engine fireEvent:@"ttcjpay.receiveSDKNotification" params:params];
}

@end
