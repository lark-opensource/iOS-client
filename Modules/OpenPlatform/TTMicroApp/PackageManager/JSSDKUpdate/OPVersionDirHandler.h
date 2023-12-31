//
//  OPVersionDirHandler.h
//  TTMicroApp
//
//  Created by yi on 2022/5/31.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPVersionManager.h>

NS_ASSUME_NONNULL_BEGIN
/*
 js sdk 多版本目录管理
 目录格式：
 - lastest_sdk_version 本地最新的版本号
 - lastest_greyhash 本地最新的greyhash
 - 1.1.1.1_greyhash
    - js sdk解压文件
 - 1.1.1.1
    - js sdk解压文件
 */
@interface OPVersionDirHandler : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign) BOOL enableFixBlockCopyBundleIssue; // lark 升级后，copy 和download 不在一个队列，导致顺序无法固定

- (void)appendUpdateVersion:(NSString *)version; // 添加Lark生命周期中更新过的version

+ (NSString *)latestVersionDir:(OPAppType)appType; // 获取本地最新版本文件夹名字
+ (NSString *)versionDir:(OPAppType)appType version:(NSString *)version greyHash:(NSString *)greyHash; // 根据指定verison和greyhash获取对应的文件夹名字

+ (void)updateLatestSDKVersionFile:(NSString *)version appType:(OPAppType)appType; // 更新记录本地最新的version的文件
+ (NSString *)latestSDKVersion:(OPAppType)appType; // 本地最新的version
+ (void)updateLatestSDKGreyHashFile:(NSString *)greyHash appType:(OPAppType)appType; // 更新本地greyhash文件
+ (NSString *)latestSDKGreyHash:(OPAppType)appType; // 最新的greyhash

+ (void)clearCacheSDK:(OPAppType)appType; // 清理js sdk 缓存
+ (NSString *)latestVersionBlockPath; // 获取本地最新的block路径
//返回应用形态内置包的版本号
+ (NSString *)innerBundleVersionWith:(OPAppType)appType;
@end
NS_ASSUME_NONNULL_END
