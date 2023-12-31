//
//  BDPSandboxProtocol.h
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/TMAKVDatabase.h>
#import "OPAppUniqueID.h"

#ifndef BDPSandboxProtocol_h
#define BDPSandboxProtocol_h

/// 这是一个 H5 应用和小程序都可以使用的 Sandbox
@protocol BDPMinimalSandboxProtocol <NSObject>

@required

@property (nonatomic, strong, readonly) OPAppUniqueID *uniqueID;

//xxx/Library/tma/app/tt00a0000bc0000def/tmp
- (NSString *)tmpPath;

//xxx/Library/tma/app/tt00a0000bc0000def/sandbox
- (NSString *)userPath;

/// 内部逻辑使用的临时文件路径，appId 隔离，用户无法访问。
//xxx/Library/tma/app/tt00a0000bc0000def/private_tmp
- (NSString *)privateTmpPath;

@end

/// 带有 Package 形态的小程序可以使用这个 Sandbox
@protocol BDPSandboxProtocol <BDPMinimalSandboxProtocol>

@property (nonatomic, strong, readonly, nullable) TMAKVStorage *localStorage; // 用户storage存储
@property (nonatomic, strong, readonly) TMAKVStorage *privateStorage;   // 小程序内部逻辑使用到的storage存储

/// xxx/Library/tma/app/tt00a0000bc0000def/pkgDirectory
- (NSString *)rootPath;

/// 清理临时目录
- (void)clearTmpPath;

/// 清理内部临时目录
- (void)clearPrivateTmpPath;

@property (nonatomic, copy, readonly) NSString *pkgName;
@end

#endif
