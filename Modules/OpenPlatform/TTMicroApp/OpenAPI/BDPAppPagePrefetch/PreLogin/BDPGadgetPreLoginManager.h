//
//  BDPGadgetPreLoginManager.h
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/6/29.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

typedef void(^preloginRequestCallback)(NSError *error, id jsonObj);
NS_ASSUME_NONNULL_BEGIN

@interface BDPGadgetPreLoginManager : NSObject
+ (instancetype)sharedInstance;
//判断预登陆功能是否通过配置开启
-(BOOL)preloginEnableWithUniqueId:(BDPUniqueID *)uniqueId;
//最近一次获取的预登陆缓存是否过期
-(BOOL)isLastLoginResultExpired:(BDPUniqueID *)uniqueId;
//执行预登陆操作
//callback 为空的情况下，内部会判断过期策略（未过期不模拟发起tt.login网络请求）
-(void)preloginWithUniqueId:(BDPUniqueID *)uniqueId callback:(preloginRequestCallback)callback;
@end

NS_ASSUME_NONNULL_END
