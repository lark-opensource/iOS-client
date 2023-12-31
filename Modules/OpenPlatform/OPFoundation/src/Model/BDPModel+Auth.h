//
//  BDPModel+Auth.hpp
//  Timor
//
//  Created by lixiaorui on 2020/9/7.
//

#import "BDPModel.h"
#import "BDPAppMetaBriefProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPModel (Auth) <BDPAppAuthProtocol>

// 域名校验白名单
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *domainsAuthMap;
// 白名单API - 仅在下发的白名单列表中存在时才能调用
@property (nonatomic, copy, readonly) NSArray<NSString *> *whiteAuthList; //ttcode
// 黑名单API - 在下发的黑名单列表中存在则不能调用
@property (nonatomic, copy, readonly) NSArray<NSString *> *blackAuthList; // ttblackcode

// authFree: 无需鉴权，直接通过，兼容小程序相关逻辑
@property (nonatomic, assign, readonly) NSInteger authPass;

// 租户权限
@property (nonatomic, copy, readonly) NSDictionary *orgAuthMap;
// 用户权限
@property (nonatomic, copy, readonly) NSDictionary *userAuthMap;

@end

NS_ASSUME_NONNULL_END
