//
//  BDXBridgeCertOpenByteCertMethod.h
//  BDXBridgeKit
//  ticketId:28874
// ❗️❗️ DON'T CHANGE THIS FILE CONTENT ❗️❗️
//

#import <BDXBridgeKit/BDXBridgeMethod.h>

#pragma mark - Method


@interface BDXBridgeCertOpenByteCertMethod : BDXBridgeMethod

@end

#pragma mark - Param


@interface BDXBridgeCertOpenByteCertMethodParamModel : BDXBridgeModel


// 实名场景scene，from实名中台
@property (nonatomic, copy, nonnull) NSString *scene;

// 实名场景flow，from实名中台
@property (nonatomic, copy, nullable) NSString *flow;

// 实名场景ticket，from实名中台RPC服务，非必传
@property (nonatomic, copy, nullable) NSString *ticket;

// 调用appId，默认是当前宿主
@property (nonatomic, copy, nullable) NSString *certAppId;

// 仅人脸
@property (nonatomic, strong, nullable) NSNumber *faceOnly;

// 身份证名
@property (nonatomic, copy, nullable) NSString *identityName;

// 身份证号
@property (nonatomic, copy, nullable) NSString *identityCode;
@property (nonatomic, copy, nullable) NSDictionary *extraParams;
@property (nonatomic, copy, nullable) NSDictionary *h5QueryParams;

@end

#pragma mark - Result


@interface BDXBridgeCertOpenByteCertMethodResultModel : BDXBridgeModel


// 0为成功，其他为服务端错误码
@property (nonatomic, strong, nonnull) NSNumber *errorCode;

// 错误信息
@property (nonatomic, copy, nullable) NSString *errorMsg;

// 实名票据，认证失败为空
@property (nonatomic, copy, nullable) NSString *ticket;

// 实名状态 0-失败;1-成功
@property (nonatomic, strong, nullable) NSNumber *certStatus;

// 是否在人工审核 1-是;0-否
@property (nonatomic, strong, nullable) NSNumber *manualStatus;

// 年龄段：0-未知;1-(0,14);2-[14,18);3-[18,+)
@property (nonatomic, strong, nullable) NSNumber *ageRange;
@property (nonatomic, copy, nullable) NSDictionary *extData;
@end
