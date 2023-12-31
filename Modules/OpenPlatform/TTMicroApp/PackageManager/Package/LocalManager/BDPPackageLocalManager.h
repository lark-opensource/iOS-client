//
//  BDPPackageLocalManager.h
//  Timor
//
//  Created by houjihu on 2020/5/21.
//

#import <Foundation/Foundation.h>
#import "BDPPackageContext.h"

NS_ASSUME_NONNULL_BEGIN

/// 代码包文件存储管理类
@interface BDPPackageLocalManager : NSObject

/// 返回本地包文件
/// @param context 包管理上下文信息
+ (nullable NSString *)localPackagePathForContext:(BDPPackageContext *)context;

/// 返回本地包目录。用于下载包或检测目录是否存在
/// @param context 包管理上下文信息
+ (nullable NSString *)localPackageDirectoryPathForContext:(BDPPackageContext *)context;

/// 检查本地包是否存在
/// @param context 包管理上下文信息
+ (BOOL)isLocalPackageExsit:(BDPPackageContext *)context;

/// 检查本地包是否存在
/// @param uniqueID 唯一ID对象，packageName 包名
+ (BOOL)isLocalPackageExsit:(BDPUniqueID *)uniqueID packageName:(NSString *)packageName;
/// 判断本地包是否存在，主要兼容分包场景
/// @param uniqueID
/// @param packageName
/// @param metaString
/// @param targetPage 
+ (BOOL)isLocalPackageExsit:(BDPUniqueID *)uniqueID packageName:(NSString*)packageName originalMetaStr:(NSString *)metaString targetPage:(nullable NSString *)targetPage;

/// 检查代码包目录是否存在
+ (BOOL)isPackageDirectoryExistForUniqueID:(OPAppUniqueID *)uniqueID packageName:(NSString *)packageName;

/// create file handle
/// @param contetxt 包管理上下文信息
/// @param error error
+ (nullable NSFileHandle *)createFileHandleForContext:(BDPPackageContext *)context error:(NSError **)error;

/// 删除本地包目录
/// @param context 包管理上下文信息
/// @param error 删除错误信息
+ (BOOL)deleteLocalPackageWithContext:(BDPPackageContext *)context error:(NSError **)error;

/// 删除除了当前指定本地包的其他本地包目录
/// @param context 包管理上下文信息
/// @param error 删除错误信息
+ (BOOL)deleteLocalPackagesExcludeContext:(BDPPackageContext *)context error:(NSError **)error;

/// 删除指定应用类型和标识的所有本地包目录
/// @param appType 应用类型
/// @param identifier 应用标识
/// @param error 删除错误信息
+ (BOOL)deleteAllLocalPackagesWithUniqueID:(BDPUniqueID *)uniqueID error:(NSError **)error;

//删除指定AppID下，除了 excludedPackages 包名在内的所有其他包(多包场景下使用)
+ (BOOL)deleteLocalPackagesForUniqueID:(BDPUniqueID *)uniqueID
                  excludedPackageNames:(NSArray<NSString *> *)excludedPackages
                                 error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
