//
//  CJPayAppInfoConfig.h
//  CJPay
//
//  Created by 尚怀军 on 2019/8/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAppInfoConfig : NSObject <NSCopying>

@property (nonatomic,copy)NSString *appId;
@property (nonatomic,copy)NSString *(^deviceIDBlock)(void);
@property (nonatomic, copy)NSString *(^userIDBlock)(void);
@property (nonatomic, copy) NSString *(^userNicknameBlock)(void); // 登录用户昵称
@property (nonatomic, copy) NSString *(^userPhoneNumberBlock)(void); // 用户手机号
@property (nonatomic, copy) NSString *(^accessTokenBlock)(void);  // // SaaS容器内支付账户信息
@property (nonatomic, copy) NSURL *(^userAvatarBlock)(void); // 登录用户头像
@property (nonatomic, copy) NSDictionary *(^infoConfigBlock)(void);  // 登录用户态信息
@property (nonatomic,copy)NSString *appName;
@property (nonatomic,copy)NSString *secLinkDomain;
@property (nonatomic,copy,nullable) NSString * _Nullable (^transferSecLinkSceneBlock)(NSDictionary * _Nullable fromDic);
@property (nonatomic, assign) BOOL adapterIpadStyle;
@property (nonatomic, assign) BOOL enableSaasEnv;  // 是否适配SaaS场景，默认为NO。

@end

NS_ASSUME_NONNULL_END
