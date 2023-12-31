//
//  BDTuringTVDefine.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/2.
//

#import <Foundation/Foundation.h>

//Twice Verify Block type
typedef NS_ENUM(NSUInteger, kBDTuringTVBlockType) {
    kBDTuringTVBlockTypeUnknown, /// 未知
    kBDTuringTVBlockTypeSms, /// 下行短信
    kBDTuringTVBlockTypeUpsms, /// 上行短信
    kBDTuringTVBlockTypePassword /// 密码验证
};

typedef NS_ENUM(NSInteger, kBDTuringTVErrorCodeType) {
    kBDTuringTVErrorCodeTypeUnknown = -1000, /// 未知
    kBDTuringTVErrorCodeTypeCancel = -1001, /// 手动取消
    kBDTuringTVErrorCodeTypeWebFailure = -1002, /// 流程失败，h5返回错误
};

@interface BDTuringTwiceVerifyRequest : NSObject

@property (nonatomic, copy) NSDictionary *params; // 请求参数，key: kBDTuringTVecisionConfig，kBDTuringTVMobile，kBDTuringTVScene
@property (nonatomic, strong) UIViewController *superVC; // 父view，不设置默认取topvc

@end

@interface BDTuringTwiceVerifyResponse : NSObject

@property (nonatomic, copy) NSDictionary *params;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) kBDTuringTVBlockType type;

@end

typedef void(^BDTuringTVResponseCallBack)(BDTuringTwiceVerifyResponse *response);


// 入参
FOUNDATION_EXTERN NSString * const kBDTuringTVDecisionConfig; /// decision_config;
FOUNDATION_EXTERN NSString * const kBDTuringTVVerifyTicket; /// verify_ticket;
FOUNDATION_EXTERN NSString * const kBDTuringTVVerifyData;  /// verify_data
FOUNDATION_EXTERN NSString * const kBDTuringTVMobile; /// 手机号
FOUNDATION_EXTERN NSString * const kBDTuringTVScene; /// 业务场景，"IM 私信 post 投稿 delete_post 删除投稿 edit_profile 修改资料 comment 评论"

FOUNDATION_EXTERN NSString * const kBDTuringTVBusinessDomain; /// 业务方domain
FOUNDATION_EXTERN NSString * const kBDTuringTVByteCertMerchantId; /// 实名验证传的商户id，实名SDKv4.0之前版本使用

// 验证类型
FOUNDATION_EXTERN NSString * const kBDTuringTVBlockSms; /// 下行短信
FOUNDATION_EXTERN NSString * const kBDTuringTVBlockUpsms; /// 上行短信
FOUNDATION_EXTERN NSString * const kBDTuringTVBlockPassword; /// 密码验证
FOUNDATION_EXTERN NSString * const kBDTuringTVBlockInfoVerify; /// 实名验证
FOUNDATION_EXTERN NSString * const kBDTuringTVBlockEmail; ///邮箱验证

/// 其他
FOUNDATION_EXTERN NSString * const kBDTuringTVErrorDomain; /// 错误domain

