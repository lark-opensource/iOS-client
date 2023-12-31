//
//  BDPLocalFileManagerProtocol.h
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#ifndef BDPLocalFileManagerProtocol_h
#define BDPLocalFileManagerProtocol_h

#import "BDPLocalFileInfo.h"
#import <ECOInfra/TMAKVDatabase.h>
#import "BDPSandboxProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 应用目录/文件路径类型
typedef NS_ENUM(NSUInteger, BDPLocalFilePathType) {
    /// xxx/Library/tma
    BDPLocalFilePathTypeBase,
    /// xxx/Library/tma/app
    BDPLocalFilePathTypeApp,
    /// xxx/Library/tma/app_tmp
    BDPLocalFilePathTypeTemp,
    /// xxx/Library/tma/app/__dev__
    BDPLocalFilePathTypeJSLib,
    /// xxx/Library/tma/app/__dev__/h5jssdk
    BDPLocalFilePathTypeH5JSLib,
    /// xxx/Library/tma/app/__resources__
    BDPLocalFilePathTypeResource,
    /// xxx/Library/tma/app/__components__
    BDPLocalFilePathTypeComponents,
    /// xxx/Library/tma/app/offline
    BDPLocalFilePathTypeOffline,
    /// xxx/Library/tma/app/internalBundle
    BDPLocalFilePathTypeInternalBundle,
    /// xxx/Library/tma/app/__dev__/tma-core.js
    BDPLocalFilePathTypeJSLibAppCore,
    /// xxx/Library/tma/app/__dev__/webp-hook.js
    BDPLocalFilePathTypeJSLibWebpHook
};

@class FMDatabaseQueue;

@protocol BDPLocalFileManagerProtocol <NSObject>

#pragma mark - Database

/// 供应用全局存储数据的数据库操作队列
@property (nonatomic, strong, readonly, nonnull) FMDatabaseQueue *dbQueue;

/// 支持分用户维度存储KV键值对的Storage
@property (nonatomic, strong, readonly) TMAKVStorage *kvStorage;

#pragma mark - Life Cycle

+ (instancetype)sharedInstanceForType:(BDPType)type;

/// 用于退出登陆时，清理跟所有应用类型文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearAllSharedInstances;

/// 用于退出登陆时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearSharedInstanceForType:(BDPType)type;

#pragma mark - Folder Name

//@"__dev__"
+ (NSString *)JSLibFolderName;

//@"__dev__/h5jssdk"
+ (NSString *)H5JSLibFolderName;

//"__components__"
+ (NSString *)componentsFolderName;

//@"offline"
+ (NSString *)offlineFolderName;

#pragma mark - Basic Path

/// 获取指定应用目录/文件路径类型的路径
/// @param type 应用目录/文件路径类型
- (NSString *)pathForType:(BDPLocalFilePathType)type;

#pragma mark - App Data Path

///xxx/Library/tma/appListCache/[userID]：小程序最近使用列表所在目录
- (NSString *)appListCachePathWithUserID:(NSString *)userID;

/// 如果appIdMoveToCacheFolder为YES, 目录将迁移至/Library/Cache/tma_cache/identifier; 否则依旧为/Library/tma/app/identifier
- (NSString *)appBasicPathWithUniqueID:(BDPUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/1.0.0
- (NSString *)appVersionPathWithUniqueID:(BDPUniqueID *)uniqueID version:(NSString *)version;

/** 包目录: xxx/Library/tma/app/tt00a0000bc0000def/name */
- (NSString *)appPkgDirPathWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name;

/** app包路径: xxx/Library/tma/app/tt00a0000bc0000def/name/app.ttpkg */
- (NSString *)appPkgPathWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name;

/** app包辅助文件目录路径: xxx/Library/tma/app/tt00a0000bc0000def/name/__auxiliary__ */
- (NSString *)appPkgAuxiliaryDirWithUniqueID:(BDPUniqueID *)uniqueID name:(NSString *)name;

/** app包辅助文件路径: xxx/Library/tma/app/tt00a0000bc0000def/name/auxiliary/file.mp3 */
- (NSString *)appPkgAuxiliaryPathWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName fileName:(NSString *)fileName;

//xxx/Library/tma/app/tt00a0000bc0000def/tmp
- (NSString *)appTempPathWithUniqueID:(BDPUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/sandbox
- (NSString *)appSandboxPathWithUniqueID:(BDPUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/private_tmp
- (NSString *)appPrivateTmpPathWithUniqueID:(OPAppUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/userStorage.db
- (NSString *)appStorageFilePathWithUniqueID:(BDPUniqueID *)uniqueID;

/// 小程序目录下的特殊文件名集合
- (NSSet<NSString *> *)appFolderSpecialFileNames;

#pragma mark - App Resource Path

//xxx/Library/tma/app/tt00a0000bc0000def/resources
- (NSString *)appResourceFolderPathWithUniqueID:(BDPUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/resources/resID
- (NSString *)appResourcePathWithUniqueID:(BDPUniqueID *)uniqueID resourceID:(NSString *)resID;

#pragma mark - Common Resource Path
- (BDPLocalFileInfo *)fileInfoWithRelativePath:(NSString *)rPath
                          uniqueID:(BDPUniqueID *)uniqueID
                                       pkgName:(NSString *)pkgName
                                 useFileScheme:(BOOL)useFileScheme DEPRECATED_MSG_ATTRIBUTE("You shouldn't use it due to encryption, use [OPFileSystemCompatible getSystemFileFrom: context: error:] instead");

- (BDPLocalFileInfo *)universalFileInfoWithRelativePath:(NSString *)rPath
                                               uniqueID:(BDPUniqueID *)uniqueID
                                          useFileScheme:(BOOL)useFileScheme DEPRECATED_MSG_ATTRIBUTE("You shouldn't use it due to encryption, use [OPFileSystemCompatible getSystemFileFrom: context: error:] instead");

//xxx/Library/tma/app/__resources__/resID
- (NSString *)resourcePathWithResourceID:(NSString *)resID;

#pragma mark - Clean
/// 主端自动清理磁盘缓存使用, 仅清理老目录tma/app下的App缓存
/// @param identifiers 要排除的identifier集合
- (void)cleanOldAppCacheExceptIdentifiers:(nullable NSSet<NSString *> *)identifiers;

/// 清理所有用户缓存数据, 可指定要排除的应用
/// @param identifiers 要排除应用的identifier集合
- (void)cleanAllUserCacheExceptIdentifiers:(nullable NSSet<NSString *> *)identifiers;

/// 清理所有小程序目录的缓存, 目前还包含storage、sanbox这些
- (void)cleanAllAppCacheExceptIdentifiers:(nullable NSSet<NSString *> *)identifiers;

//删除 xxx/Library/tma/app 与 xxx/Library/tma/app_tmp目录并重建
//注意:xxx/Library/tma/app/__dev__将被保留
- (void)restoreToOriginalState;

/** 初始化除了tma/app目录的其他相关目录 */
- (void)restoreToOriginalStateExceptAppFolder;

/** 初始化tma/app目录 */
- (void)restoreAppFolderToOriginalState;

#pragma mark - 路径权限
/// 检查是否有在path下的写权限
- (BOOL)hasWriteRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID;
/// 检查是否能够在path路径下载文件
- (BOOL)hasDownloadFileRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID;
/** 检查是否具有删除文件的权限。在user/temp目录下的文件可以允许被删除 使用场景：因为KA-R文件预览需求要求删除downloadFile保存的文件，而下载默认把文件保存在temp目录，因此需要支持temp目录下文件删除
 * 上下文：原removeSavedFile的实现只支持删除user目录下的文件——通过hasWriteRightsForPath判断，但是直接扩展hasWriteRightsForPath支持temp有风险，
 * 因此建议在removeSavedFile前组合判断isUserDir和isTempDir，若是则可以删除，若否则提示无权限。
 */
- (BOOL)hasRemoveRightsForPath:(NSString *)path onUniqueID:(BDPUniqueID *)uniqueID;
- (BOOL)hasWriteRightsForRootPathOrSubpath:(NSString *)directory onUniqueID:(BDPUniqueID *)uniqueID;
+ (BOOL)hasAccessRightsForPath:(NSString *)path onSandbox:(id<BDPSandboxProtocol> )sandbox;

/// 支持全应用形态的文件访问权限判断接口，内部会判断有包目录和无包目录的情况
/// 用户有读权限的目录：包文件夹目录，user目录，tmp目录; 有写权限的目录：user目录，tmp目录
/// 标准化读写能力，根目录可读不可写
- (BOOL)hasAccessRightsForPath:(NSString *)path onUniqueID:(OPAppUniqueID *)uniqueID;
#pragma mark - ttfile支持
/** 生成随机file:路径 */
+ (NSString *)generateRandomFilePathWithType:(BDPFolderPathType)type
                                     sandbox:(id<BDPMinimalSandboxProtocol> )sandbox
                                   extension:(NSString *)extension
                               addFileScheme:(BOOL)addFileScheme;

@end
NS_ASSUME_NONNULL_END

#endif /* BDPLocalFileManagerProtocol_h */
