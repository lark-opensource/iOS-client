//
//  BDPPackageModule.h
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPPackageModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class BDPPackageDownloadDispatcher;

/// 包管理模块
/// 功能：应用代码包/JS SDK的下载更新、缓存机制，更新引擎配置信息，更新meta信息
@interface BDPPackageModule : NSObject <BDPPackageModuleProtocol>

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

/// 代码包下载信息管理
@property (nonatomic, strong, readonly) id<BDPPackageInfoManagerProtocol> packageInfoManager;

/// 管理代码包下载任务
@property (nonatomic, strong, readonly) BDPPackageDownloadDispatcher *packageDownloadDispatcher;

@end

// BSPatch封装类
@interface BDPBSPatcher: NSObject

/// 进行bsPatch
/// - Parameters:
///   - oldPath: 老包路径
///   - patchPath: diff包路径
///   - newPath: 最终合成包路径
+ (BOOL)bsPatch:(NSString *)oldPath
      patchPath:(NSString *)patchPath
        newPath:(NSString *)newPath;
@end

NS_ASSUME_NONNULL_END
