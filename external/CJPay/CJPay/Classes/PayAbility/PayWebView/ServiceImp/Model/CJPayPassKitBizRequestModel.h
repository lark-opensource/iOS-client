//
//  CJPayPassKitBizRequestModel.h
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 调起密码组件和授权页面的请求模型
@interface CJPayPassKitBizRequestModel : NSObject <NSCopying>

/// 必须
@property (nonatomic, copy) NSString *appID;
/// 必须
@property (nonatomic, copy) NSString *merchantID;

@property (nonatomic, copy) NSString *sessionKey;

/// 绑卡后设置密码必须，加密用
@property (nonatomic, copy, nullable) NSString *uid;

/// 手机号，用户填写手机号发送验证的情况下，需要填写
@property (nonatomic, copy) NSString *mobile;

//@property (nonatomic, copy) NSString *smchID;

@end

NS_ASSUME_NONNULL_END
