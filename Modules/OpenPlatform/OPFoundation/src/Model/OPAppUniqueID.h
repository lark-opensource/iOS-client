//
//  OPAppUniqueID.h
//  OPSDK
//  (本文件保持使用 OC 便于在旧的 OC代码头文件中被引用)
//
//  Created by yinyuan on 2020/12/16.
//

#import <Foundation/Foundation.h>
#import "OPAppType.h"
#import "OPAppVersionType.h"

// 止血类型
typedef NS_ENUM(NSUInteger, OPAppSilenceUpdateType) {
    OPAppSilenceUpdateTypeNone = 0, // 正常启动不走止血
    OPAppSilenceUpdateTypeSettings, // 老止血逻辑
    OPAppSilenceUpdateTypeProduct, // 产品话止血逻辑
};

NS_ASSUME_NONNULL_BEGIN

/// 通用应用的唯一复合ID，支持各种应用形态。运行时状态无关，应用未启动之前就已经确定。
@interface OPAppUniqueID : NSObject <NSCopying>

/// 应用 appID
@property (nonatomic, copy, readonly, nonnull) NSString *appID;
/// 应用子标识，小程序，网页，Tab小程序、bot就是appId，block是blockId，widget是cardId
@property (nonatomic, copy, readonly, nonnull) NSString *identifier;
/// 版本类型
@property (nonatomic, assign, readonly) OPAppVersionType versionType;
/// 应用类型
@property (nonatomic, assign, readonly) OPAppType appType;

/// 实例 ID，需要同一个应用同时运行多个时，需要指定该ID。如果不指定，则相同appID、identifier、versionType、appType 的应用只能同时运行一个。
@property (nonatomic, strong, readonly, nullable) NSString *instanceID;

/// 代表uniqueID内所有内容的字符串
@property (nonatomic, copy, readonly, nonnull) NSString *fullString;

/// 是否为止血方案启动, 用于埋点上报;(产品化止血方案: https://bytedance.feishu.cn/docx/doxcnvkVGnpBgzefnP4wtZeMcdg)
@property (nonatomic, assign) OPAppSilenceUpdateType silenceUpdateType;

/// 确保返回 Nonnull，把 appID 为空当做一种无效 ID 处理即可，versionType 如果为空就是 current。
+ (instancetype _Nonnull)uniqueIDWithAppID:(NSString * _Nonnull)appID
                                identifier:(NSString * _Nullable)identifier
                               versionType:(OPAppVersionType)versionType
                                   appType:(OPAppType)appType;

+ (instancetype _Nonnull)uniqueIDWithAppID:(NSString * _Nonnull)appID
                                identifier:(NSString * _Nullable)identifier
                               versionType:(OPAppVersionType)versionType
                                   appType:(OPAppType)appType
                                instanceID:(NSString * _Nullable)instanceID;

+ (instancetype _Nonnull)uniqueIDWithFullString:(NSString * _Nonnull)fullString;

- (BOOL)isValid;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

@interface OPAppUniqueID (OPDynamicComponentProperty)
//动态组件特有属性，表示组件依赖的版本
//如果当前非 OPDynamicComponent。设置该属性无效（get后也为空字符串）
@property (nonatomic, copy, readwrite, nonnull) NSString *requireVersion;
@end

NS_ASSUME_NONNULL_END
