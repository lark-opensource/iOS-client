//
//  EMAOrgAuthorization.h
//  EEMicroAppSDK
//
//  Created by yin on 2019/11/13.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAOrgAuthorization : NSObject

+ (BOOL)orgAuthWithAuthScopes:(NSDictionary *)orgAuth invokeName:(NSString *)invokeName;
+ (NSDictionary<NSString *, NSString *> *)mapForOrgAuthToInvokeName;

@end

//组织授权情况，iOS 行为与安卓表现不一致：map 为空时默认返回 True，对这种情况进行数据统计
typedef NS_ENUM(NSUInteger, EMAOrgAuthorizationMapState) {
    EMAOrgAuthorizationMapStateUnknown = 0,
    EMAOrgAuthorizationMapStateEmpty,
    EMAOrgAuthorizationMapStateNotEmpty
};

NS_ASSUME_NONNULL_END
