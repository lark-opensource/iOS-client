//
//  CJPaySignRequestUtil.h
//  AlipaySDK-AlipaySDKBundle
//
//  Created by 王新华 on 2022/9/14.
//

#import "CJPayBaseRequest.h"
#import "CJPayIntergratedBaseResponse.h"
#import "CJPayTypeInfo.h"
#import "CJPayMerchantInfo.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignCreateResponse : CJPayIntergratedBaseResponse
@property (nonatomic, strong) CJPayTypeInfo *signTypeInfo;
@property (nonatomic, strong) CJPayMerchantInfo *merchantInfo;

@end

@interface CJPaySignConfirmResponse : CJPayIntergratedBaseResponse

@property (nonatomic, copy)NSString *channelData;
@property (nonatomic, copy) NSString *tradeType;
@property (nonatomic, copy)NSString *ptCode;

- (NSDictionary *)payDataDict;

@end


@interface CJPaySignQueryPaymentDescInfo : JSONModel

@end
@interface CJPaySignQueryResponse : CJPayIntergratedBaseResponse

@property (nonatomic, strong) CJPaySignQueryPaymentDescInfo *paymentDescInfo;
@property (nonatomic, copy) NSString *ptCode;
@property (nonatomic, copy) NSString *signStatus; // 仅前端使用，客户端使用signOrderStatus字段
@property (nonatomic, copy) NSString *signOrderStatus;

@end

@interface CJPaySignRequestUtil : CJPayBaseRequest


/// 签约下单接口
/// @param requestParams 请求参数字典
/// @param completionBlock 结果的回调
+ (void)startSignCreateRequestWithParams:(NSDictionary *)requestParams completion:(void(^)(NSError *error, CJPaySignCreateResponse *response))completionBlock;

+ (void)startSignConfirmRequestWithParams:(NSDictionary *)requestParams bizContentParams:(NSDictionary *)requestParams completion:(nonnull void (^)(NSError * _Nonnull, CJPaySignConfirmResponse * _Nonnull))completionBlock;

+ (void)startSignQueryRequestWithParams:(NSDictionary *)requestParams completion:(void(^)(NSError *error, CJPaySignQueryResponse *response))completionBlock;

+ (NSDictionary *)buildSignRequestParams:(NSDictionary *)bizContent;

@end

NS_ASSUME_NONNULL_END
