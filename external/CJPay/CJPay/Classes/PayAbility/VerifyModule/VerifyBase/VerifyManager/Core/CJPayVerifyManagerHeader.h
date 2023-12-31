//
//  CJPayVerifyManagerHeader.h
//  Pods
//
//  Created by 王新华 on 10/20/19.
//

#ifndef CJPayVerifyManagerHeader_h
#define CJPayVerifyManagerHeader_h

#import "CJPayBDOrderResultResponse.h"
#import "CJPayOrderConfirmResponse.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, CJPayVerifyType) {
    CJPayVerifyTypeLast, // 上次验证方式
    CJPayVerifyTypeSignCard,
    CJPayVerifyTypePassword,
    CJPayVerifyTypeSMS,
    CJPayVerifyTypeBioPayment,
    CJPayVerifyTypeDecLive,
    CJPayVerifyTypeIDCard,
    CJPayVerifyTypeUploadIDCard,
    CJPayVerifyTypeAddPhoneNum,
    CJPayVerifyTypeRealNameConflict,
    CJPayVerifyTypeFaceRecog,
    CJPayVerifyTypeFaceRecogRetry,
    CJPayVerifyTypeSkipPwd, // 免密支付
    CJPayVerifyTypeSkip, // 免验密码(在没有开通免密支付时免验密码，仅用在二次支付)
    CJPayVerifyTypeForgetPwdFaceRecog,
    CJPayVerifyTypeToken,
    CJPayVerifyTypeAdditionalSignCard //补签约加验
};

typedef NS_ENUM(NSUInteger, CJPayBioEvent) {
    CJPayBioEventSystemCancelToPWD,     // 系统取消拉起验密页
    CJPayBioEventCancelToPWD            // 点击取消拉起验密页
};


@class CJPayBDCreateOrderResponse;
@class CJPayVerifyItem;
@class CJPayEvent;

// 唤醒指定验证方式，获取验证方式的数据
@protocol CJPayWakeVerifyItemProtocol <NSObject>

- (void)wakeSpecificType:(CJPayVerifyType)type orderRes:(CJPayBDCreateOrderResponse *)response event:(nullable CJPayEvent *)event;
- (NSDictionary *)loadSpecificTypeCacheData:(CJPayVerifyType)type;

@end

// 流程节点的方法。
@protocol CJPayVerifyManagerEventFlowProtocol <NSObject>

// CJPayHomeVC使用
- (void)begin;
- (void)submitConfimRequest:(NSDictionary *)extraParams fromVerifyItem:(nullable CJPayVerifyItem *)verifyItem;
- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType) channelType;
- (void)submitQueryRequest;

@end

// 埋点的各个网络请求代理
@protocol CJPayVerifyManagerRequestProtocol <NSObject>

- (void)requestConfirmPayWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                           withExtraParams:(NSDictionary *)extraParams
                                completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock;

- (void)requestQueryOrderResultWithTradeNo:(NSString *)tradeNo
                               processInfo:(CJPayProcessInfo *)processInfo
                                completion:(void(^)(NSError *error, CJPayBDOrderResultResponse *response))completionBlock;

@end

@protocol CJPayVerifyManagerPayNewCardProtocol <NSObject>

- (void)onBindCardAndPayAction;

@end

NS_ASSUME_NONNULL_END
#endif /* CJPayVerifyManagerHeader_h */
