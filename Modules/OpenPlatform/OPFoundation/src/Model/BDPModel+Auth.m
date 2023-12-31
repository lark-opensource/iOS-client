//
//  BDPModel+Auth.cpp
//  Timor
//
//  Created by lixiaorui on 2020/9/7.
//

#import "BDPModel+Auth.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation BDPModel (Auth)

// 域名校验白名单
- (NSDictionary<NSString *, NSArray<NSString *> *> *) domainsAuthMap {
    return [self.domainsAuthDict copy];
}

// 白名单API - 仅在下发的白名单列表中存在时才能调用
- (NSArray<NSString *> *)whiteAuthList {
    return [self.authList copy];
} //ttcode

// 黑名单API - 在下发的黑名单列表中存在则不能调用
- (NSArray<NSString *> *)blackAuthList {
    return [self.blackList copy];
} // ttblackcode

// authFree: 无需鉴权，直接通过，兼容小程序相关逻辑
- (NSInteger)authPass {
    return [self.extraDict bdp_integerValueForKey:@"auth_pass"];
}

// 租户权限
- (NSDictionary *)orgAuthMap {
    return [self.extraDict bdp_dictionaryValueForKey:@"orgAuthScope"];
}

// 用户权限
- (NSDictionary *)userAuthMap {
    return [self.extraDict bdp_dictionaryValueForKey:@"userAuthScope"];
}

@end
