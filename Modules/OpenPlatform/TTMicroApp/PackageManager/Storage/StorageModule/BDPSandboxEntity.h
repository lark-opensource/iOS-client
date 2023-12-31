//
//  BDPSandboxEntity.h
//  Timor
//
//  Created by liubo on 2018/12/17.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/TMAKVDatabase.h>
#import <OPFoundation/BDPSandboxProtocol.h>
#import "BDPDefineBase.h"

#pragma mark BDPMinimalSandboxEntity

/**
 * 沙盒数据访问类，包含：
 * 1.沙盒文件目录管理
 * 2.应用私有数据kv存储（TMAKVStorage）
 * 3.小程序调用stroage模块的kv存储（TMAKVStorage）
 * 4.图片对象的访问
 *
 * 这个类不依赖 pkgName，H5 也可以使用
 */
@interface BDPMinimalSandboxEntity : NSObject<BDPMinimalSandboxProtocol>

@property (nonatomic, strong, readonly) BDPUniqueID *uniqueID;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/tmp
- (NSString *)tmpPath;

//xxx/Library/tma/app/tt00a0000bc0000def/sandbox
- (NSString *)userPath;

/// 内部逻辑使用的临时文件路径，appId 隔离，用户无法访问。
//xxx/Library/tma/app/tt00a0000bc0000def/private_tmp
- (NSString *)privateTmpPath;

@end


#pragma mark BDPSandboxEntity

/// 增加了对 pkgName 的支持，针对那些有 package 形态的小程序
@interface BDPSandboxEntity : BDPMinimalSandboxEntity <BDPSandboxProtocol>

@property (nonatomic, strong, readonly) TMAKVStorage *localStorage; // 用户storage存储
@property (nonatomic, strong, readonly) TMAKVStorage *privateStorage;   // 小程序内部逻辑使用到的storage存储

@property (nonatomic, copy, readonly) NSString *pkgName;

//xxx/Library/tma/app/tt00a0000bc0000def/pkgDirectory
- (NSString *)rootPath;

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID NS_UNAVAILABLE;
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;

/// 清理 tmp path
- (void)clearTmpPath;
/// 清理 private tmp path
- (void)clearPrivateTmpPath;
@end
