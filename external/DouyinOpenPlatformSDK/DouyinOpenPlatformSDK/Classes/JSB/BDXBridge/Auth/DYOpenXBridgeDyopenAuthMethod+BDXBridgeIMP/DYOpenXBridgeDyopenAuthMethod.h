//
//  DYOpenXBridgeDyopenAuthMethod.h
//  BDXBridgeKit
//  ticketId:27894
// ❗️❗️ DON'T CHANGE THIS FILE CONTENT ❗️❗️
//

#import <BDXBridgeKit/BDXBridgeMethod.h>

#pragma mark - Method

@interface DYOpenXBridgeDyopenAuthMethod : BDXBridgeMethod

@end

#pragma mark - Param
@interface BDXBridgeDyopenAuthCertificationlnfo: BDXBridgeModel
@property (nonatomic, copy, nullable) NSString *verifyTicket;
@property (nonatomic, copy, nullable) NSString *verifyOpenId;
@property (nonatomic, copy, nullable) NSString *verifyScope;
@end

@interface DYOpenXBridgeDyopenAuthMethodParamModel : BDXBridgeModel


// 1:拉端授权、2:H5授权、3:宿主手机号授权(全屏)、4:宿主手机号授权(半屏)
@property (nonatomic, strong, nonnull) NSNumber *openAuthType;

// 是否展示授权UI，1展示，0不展示
@property (nonatomic, strong, nullable) NSNumber *notSkipConfirm;

// 授权备注ID
@property (nonatomic, copy, nullable) NSString *commentId;

// 来源
@property (nonatomic, copy, nullable) NSString *enterFrom;

// 回包时透传，业务方可用于确认本次授权请求
@property (nonatomic, copy, nullable) NSString *state;

// 宿主手机号授权，手机号参数(可带*号)
@property (nonatomic, copy, nullable) NSString *phoneNumber;

// 宿主手机号授权，ticket参数
@property (nonatomic, copy, nullable) NSString *phoneAuthTicket;
@property (nonatomic, copy, nonnull) NSDictionary *scopes;
@property (nonatomic, strong, nullable) BDXBridgeDyopenAuthCertificationlnfo *certificationlnfo;
@property (nonatomic, copy, nullable) NSDictionary *extraInfo;

@end

#pragma mark - Result

@interface DYOpenXBridgeDyopenAuthMethodResultModel : BDXBridgeModel


// 授权 code
@property (nonatomic, copy, nullable) NSString *ticket;

// 完成授权的 scope 列表，多个用英文逗号隔开
@property (nonatomic, copy, nullable) NSString *grantPermissions;

// 业务自定义返回码
@property (nonatomic, strong, nullable) NSNumber *busiCode;

// 业务自定义错误信息
@property (nonatomic, copy, nullable) NSString *busiErrMsg;

// 透传请求传入的值，业务方可用于确认本次授权请求
@property (nonatomic, copy, nullable) NSString *state;
@end
