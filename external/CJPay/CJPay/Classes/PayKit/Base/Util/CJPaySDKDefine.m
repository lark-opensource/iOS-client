//
//  CJPaySDKDefine.m
//  CJPay
//
//  Created by 王新华 on 9/18/19.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

NSString * const CJPayDeskThemeKey = @"CJPayDeskThemeKey";
NSString * const CJPayHandleCompletionNotification = @"CJPayHandleCompletionNotification";
NSString * const CJPayBindCardSignSuccessNotification = @"CJPayBindCardSignSuccessNotification";
NSString * const CJPayBindCardSuccessNotification = @"CJPayBindCardSuccessNotification";
NSString * const CJPayH5BindCardSuccessNotification = @"CJPayH5BindCardSuccessNotification";
NSString * const CJPayBindCardSuccessPreCloseNotification = @"CJPayBindCardSuccessPreCloseNotification";
NSString * const CJCloseWithdrawHomePageVCNotifiction = @"CJCloseWithdrawHomePageVCNotifiction";
NSString * const CJPayCancelBindCardNotification = @"CJPayCancelBindCardNotification";
NSString * const CJPayShowPasswordKeyBoardNotification = @"CJPayShowPasswordKeyBoardNotification";

NSString * const CJPayVerifyPageDidChangedHeightNotification = @"CJPayVerifyPageDidChangedHeightNotification";

NSString * const CJPayManagerReloadWithdrawDataNotification =  @"CJPayManagerReloadWithdrawDataNotification";
NSString * const CJPayPassCodeChangeNotification = @"CJPayPassCodeChangeNotification";

NSString * const BDPaySignSuccessAndConfirmFailNotification = @"BDPaySignSuccessAndConfirmFailNotification";
NSString * const BDPayMircoQuickBindCardSuccessNotification = @"BDPayMircoQuickBindCardSuccessNotification";
NSString * const BDPayMircoQuickBindCardFailNotification = @"BDPayMircoQuickBindCardFailNotification";

NSString * const BDPayBindCardSuccessRefreshNotification = @"BDPayBindCardSuccessRefreshNotification";

NSString * const BDPayClosePayDeskNotification = @"BDPayClosePayDeskNotification";

NSString * const BDPayUniversalLoginSuccessNotification = @"BDPayUniversalLoginSuccessNotification";

NSString * const CJPayUnionBindCardUnavailableNotification = @"CJPayUnionBindCardUnavailableNotification";

NSString * const CJPayBindCardSetPwdShowNotification = @"CJPayBindCardSetPwdShowNotification"; //设密第一步页面展示
NSString * const CJPayCardsManageSMSSignSuccessNotification = @"CJPayCardsManageSMSSignSuccessNotification";//银行卡管理短信签约成功

NSString * const CJPayClickRetainPerformNotification = @"CJPayClickRetainPerformConfirmActionNotification"; //点击挽留弹窗, 前端返回数据需要执行事件的时候发通知

CJPayOrderStatus CJPayOrderStatusFromString (NSString *statusSting) {
    if ([statusSting isEqualToString:@"PROCESSING"]) {
        return CJPayOrderStatusProcess;
    } else if ([statusSting isEqualToString:@"SUCCESS"]) {
        return CJPayOrderStatusSuccess;
    } else if ([statusSting isEqualToString:@"FAIL"]) {
        return CJPayOrderStatusFail;
    } else if ([statusSting isEqualToString:@"TIMEOUT"]) {
        return CJPayOrderStatusTimeout;
    }
    return CJPayOrderStatusProcess;  //默认
}

NSErrorDomain CJPayErrorDomain = @"cjpay.error";

CJPayPropertyKey const CJPayPropertyPayDeskTitleKey = @"CJPayPropertyPayDeskTitleKey";
CJPayPropertyKey const CJPayPropertyReferVCKey = @"CJPayPropertyReferVCKey";
CJPayPropertyKey const CJPayPropertyIsHiddenLoadingKey = @"CJPayPropertyIsHiddenLoadingKey";

@implementation CJPayAPIBaseResponse

@end

@interface CJPayAPICallBack()

@property (nonatomic, copy) void(^callback)(CJPayAPIBaseResponse * _Nonnull baseResponse);

@end

@implementation CJPayAPICallBack

- (instancetype)initWithCallBack:(void (^)(CJPayAPIBaseResponse * _Nonnull))callback {
    if (self = [super init]) {
        self.callback = [callback copy];
    }
    return self;
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if (self.callback) {
        self.callback(response);
    }
}

- (void)callState:(BOOL)success fromScene:(CJPayScene)scene {
    if (!success && self.callback) {
        CJPayAPIBaseResponse *response = [CJPayAPIBaseResponse new];
        response.scene = scene;
        response.error = [NSError errorWithDomain:CJPayErrorDomain code:CJPayErrorCodeCallFailed userInfo:@{NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"吊起失败", nil)}];
        response.data = @{
            @"sdk_code": @(CJPayErrorCodeCallFailed),
            @"sdk_msg": @"吊起失败"
        };
        self.callback(response);
        self.callback = nil; // 只回调一次
    }
}

@end
