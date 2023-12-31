//
//  BDPStorageModule.h
//  Timor
//
//  Created by houjihu on 2020/3/23.
//

#import <Foundation/Foundation.h>
#import "BDPModuleProtocol.h"
#import <ECOInfra/TMAKVDatabase.h>
#import "BDPSandboxProtocol.h"
#import "BDPUniqueID.h"
#import "BDPLocalFileConst.h"
#import "BDPLocalFileManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDPStorageModuleProtocol <BDPModuleProtocol>

#pragma mark - BDPSandboxProtocol

/// 通过 UniqueID + pkgName 创建 Sandbox （注意内部隐含创建文件夹和storage逻辑）
- (id<BDPSandboxProtocol>)createSandboxWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;

// 通过 UniqueID 创建 MinimalSandbox, 不需要 pkgName 的可以用这个方法 （注意内部隐含创建文件夹逻辑）
- (id<BDPMinimalSandboxProtocol>)minimalSandboxWithUniqueID:(BDPUniqueID *)uniqueID;

/// 获取不同形态当前的 sandbox
///
/// for gadget:
///     - get from BDPCommon
/// for block:
///     - get from OPContainerProtocol
/// others
///     - return nil
- (nullable id<BDPSandboxProtocol>)sandboxForUniqueId:(OPAppUniqueID *)uniqueId;

/// 重置 应用的 Sandbox 对象映射记录
- (void)restSandboxEntityMap;

#pragma mark - BDPLocalFileManagerProtocol

/// 获取文件管理器对象
- (id<BDPLocalFileManagerProtocol>)sharedLocalFileManager;

/// 用于退出登陆时，清理跟所有应用类型文件目录相关的单例对象，便于再次登录时重新初始化
- (void)clearAllSharedLocalFileManagers;

/// 用于退出登陆时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
- (void)clearSharedLocalFileManagerForType:(BDPType)type;

#pragma mark Folder Name

//@"__dev__"
- (NSString *)JSLibFolderName;

//@"__dev__/h5jssdk"
- (NSString *)H5JSLibFolderName;

//@"offline"
- (NSString *)offlineFolderName;

- (BOOL)hasAccessRightsForPath:(NSString *)path onSandbox:(id<BDPSandboxProtocol> )sandbox;

#pragma mark ttfile支持
/** 生成随机file:路径 */
- (NSString *)generateRandomFilePathWithType:(BDPFolderPathType)type
                                     sandbox:(id<BDPMinimalSandboxProtocol> )sandbox
                                   extension:(NSString *)extension
                               addFileScheme:(BOOL)addFileScheme;

@end

NS_ASSUME_NONNULL_END
