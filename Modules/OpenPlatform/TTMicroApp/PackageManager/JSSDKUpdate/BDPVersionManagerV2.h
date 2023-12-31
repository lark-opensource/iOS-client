//
//  BDPVersionManager.h
//  Timor
//
//  Created by muhuai on 2018/2/7.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/OPAppType.h>
#import <OPFoundation/BDPVersionManagerDelegate.h>

NS_ASSUME_NONNULL_BEGIN
// 迁移到: BDPVersionManager.h 
//extern NSString * const kLocalTMASwitchKeyV2;
@interface BDPVersionManagerV2 : NSObject<BDPVersionManagerDelegate>

// 安装本地内置基础库
+ (void)setupDefaultVersionIfNeed;

// 小程序/小游戏总开关
+ (BOOL)serviceEnabled;

// JSSDK及客户端SDK版本号
//【注意！！！动了JSLibPath文件夹后请务必调用resetLocalLibVersionCache方法清空缓存！！！】
+ (long long)localLibVersion;               // JSSDK版本号数值(4位) - 1020304
+ (NSString * _Nullable)localLibVersionString;        // JSSDK版本号(4位) - 1.2.3.4 默认为小程序
+ (NSString *)localLibVersionString:(OPAppType)appType;
+ (NSString * _Nullable)localLibGreyHash;             // 当前JSSDK的greyHash 默认为小程序
+ (NSString * _Nullable)localLibGreyHash:(OPAppType)appType;
+ (long long)localLibBaseVersion;           // JSSDK版本号数值(3位) - 10203
+ (NSString * _Nullable)localLibBaseVersionString;    // JSSDK版本号(3位) - 1.2.3
+ (long long)localSDKVersion;               // 客户端SDK版本号 - 10305
+ (NSString * _Nonnull)localSDKVersionString;        // 客户端SDK版本号 - 1.3.5
// 清空内存中JSSDK版本号的缓存。
+ (void)resetLocalLibVersionCache:(OPAppType)appType;
+ (void)resetLocalLibCache;                 // 清空内存版本信息、DB版本信息、本地存储的JSSDK文件。

// 判断某个版本 & greyHash 是否需要升级
+ (BOOL)isNeedUpdateLib:(NSString *)version greyHash:(NSString *)greyHash appType:(OPAppType)appType;
// 判断基础库版本号
+ (BOOL)isLocalSdkLowerThanVersion:(NSString *)version;

/// 判断最低兼容lark版本号(gadget使用)
/// @param minLarkVersion meta中minLarkVersion(开发者后台配置)
+ (BOOL)isLocalLarkVersionLowerThanVersion:(nullable NSString *)minLarkVersion;

/// 本地的lark版本是否合法
+ (BOOL)isValidLocalLarkVersion;

/// lark版本是否合法
/// @param larkVersion 需要校验的lark版本
+ (BOOL)isValidLarkVersion:(nullable NSString *)larkVersion;

/// lark客户端版本(可能会有-alpha/-beta)
+ (NSString *)localLarkVersion;

/// 将传入的版本通过正则矫正. 获取到正确的2段版本号或者3段版本号;
/// e.g. 传入 1.2-alpha => 1.2  传入 5.1.4-beta => 5.1.4
+ (NSString *)versionCorrect:(nullable NSString *)version;

// 下载指定基础库
+ (void)downloadLibWithURL:(NSString *)url
             updateVersion:(NSString *)updateVersion
               baseVersion:(NSString *)baseVersion
                  greyHash:(NSString *)greyHash
                   appType:(OPAppType)appType
                completion:(void (^)(BOOL, NSString *))completion;
/// 下载完基础库之后，需要提前预加载小程序执行环境
+ (void)updateLibComplete:(BOOL)isSuccess;

// 当js sdk内置版本大于沙盒内的版本或者沙盒内还没有js sdk，则使用内置版本
+ (void)setupBundleVersionIfNeed:(OPAppType)appType;

/// 设置local_test 模式下是否可以更新基础库
+ (BOOL)localTestEnable;
+ (void)setLocalTestEnable:(BOOL)localTestEnable;

/// 将字符串的版本号转成 Int，方便比较大小
+ (NSInteger)iosVersion2Int:(NSString *)str;

/// 对版本号进行适当的调整，如果不是正常的版本号，则返回 kBDPErrorVersion
+ (NSString *)versionStringWithContent:(NSString *)content;

/// 统一的JSLibVersionManager埋点接口，同时提供给EMAVersionManager
+ (void)eventV3WithLibEvent:(NSString *)event
                       from:(NSString *)from
              latestVersion:(NSString *)latestVersion
             latestGreyHash:(NSString *)greyHash
                 resultType:(NSString *)resultTypes
                     errMsg:(NSString *)errMsg
                   duration:(NSUInteger)duration
                    appType:(OPAppType)appType;

/// 比较两个版本，
/// 若v1>v2，返回 1
/// 若v1<v2,返回 -1
/// 相同，返回 0
/// @param v1 ，若传入空版本，则认为是0
/// @param v2 ，若传入空版本，则认为是0
+(NSInteger)compareVersion:(NSString * _Nullable)v1 with:(NSString * _Nullable)v2;

/// //返回两个版本中较大的版本，若相同返回第一个参数（v1）
/// @param v1 v1 description
/// @param v2 v2 description
+(NSString *)returnLargerVersion:(NSString * _Nullable)v1 with:(NSString * _Nullable)v2;

+ (NSString *)latestVersionBlockPath;
+ (NSString *)latestVersionMsgCardSDKPath;

+ (NSString *)latestVersionCardWithPath:(NSString *)path;
@end


NS_ASSUME_NONNULL_END
