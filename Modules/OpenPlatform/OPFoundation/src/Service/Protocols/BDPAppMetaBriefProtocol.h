//
//  BDPAppMetaBriefProtocol.h
//  Timor
//
//  Created by 傅翔 on 2019/4/26.
//

#import <Foundation/Foundation.h>
#import "BDPUniqueID.h"

@protocol BDPAppMetaProtocol, BDPAppPackageProtocol;

NS_ASSUME_NONNULL_BEGIN

#pragma 基础协议-basic protocols

// 包含各形态对应的基础信息，只允许添加真·元信息，包/权限相关的不能添加在这
@protocol BDPAppMetaProtocol <NSObject>

/// 基础信息相关
@property (nonatomic, strong, readonly) BDPUniqueID *uniqueID;

/// 应用名称
@property (nonatomic, copy, readonly) NSString *name;

/// 应用图标地址
@property (nonatomic, copy, readonly) NSString *icon;

/// 版本
@property (nonatomic, copy, readonly) NSString *version;

/** 版本更新时间戳 */
@property (nonatomic, assign, readonly) int64_t version_code;

@end


// 包含各形态对应的安装包相关信息
@protocol BDPAppPackageProtocol <NSObject>

/// 包名
@property (nonatomic, copy, readonly) NSString *pkgName;

/// 代码包下载地址数组
@property (nonatomic, strong, readonly) NSArray<NSURL *> *urls;

/// 包校验码md5
@property (nonatomic, copy, readonly) NSString *md5;

@end


//  包含各形态对应权限相关数据
@protocol BDPAppAuthProtocol <NSObject>

// 域名校验白名单，兼容小程序相关逻辑
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *domainsAuthMap;

// 白名单API - 仅在下发的白名单列表中存在时才能调用，兼容小程序相关逻辑
@property (nonatomic, copy, readonly) NSArray<NSString *> *whiteAuthList; //ttcode

// 黑名单API - 在下发的黑名单列表中存在则不能调用，兼容小程序相关逻辑
@property (nonatomic, copy, readonly) NSArray<NSString *> *blackAuthList; // ttblackcode

// authFree: 无需鉴权，直接通过，兼容小程序相关逻辑
@property (nonatomic, assign, readonly) NSInteger authPass;

// 租户权限
@property (nonatomic, copy, readonly) NSDictionary *orgAuthMap;

// 用户权限
@property (nonatomic, copy, readonly) NSDictionary *userAuthMap;

@end


#pragma 组合协议-根据不同地方业务需要的数据组合不同的协议以及附加功能
//  小程序老版本特化meta协议
/** 简版meta协议 */
@protocol BDPAppMetaBriefProtocol <BDPAppMetaProtocol, BDPAppPackageProtocol>

@end

// 权限数据源
@protocol BDPMetaWithAuthProtocol <BDPAppMetaProtocol, BDPAppAuthProtocol>

@end

NS_ASSUME_NONNULL_END
