//
//  BDPAppLoadManager+Util.hpp
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager.h"
#import <OPFoundation/BDPModel.h>

@protocol BDPCommonUpdateModelProtocol <NSObject>
@property (nonatomic, copy, readonly) BDPUniqueID * uniqueID;
@property (nonatomic, copy, readonly) NSString * version;
@property (nonatomic, assign, readonly) int64_t  version_code;
@property (nonatomic, copy, readonly) NSString * pkgName;
@end

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 工具方法

@interface BDPAppLoadManager (Util)

/// Meta缓存获取
- (BDPModel * _Nullable)getUpdateInfoWithUniqueID:(BDPUniqueID *)uniqueID;

// 异步/同步线程相关
- (BOOL)isInSelfQueue;

- (void)executeBlockSync:(BOOL)sync inSelfQueue:(dispatch_block_t)block;

//  TODO: 这里的逻辑存在问题，无法兼容多实例同时运行的情况
/// 获取小程序pkg文件句柄, 若有内存缓存则直接返回, 否则将创建新的句柄
- (nullable BDPPkgFileReader)tryGetReaderInMemoryWithAppID:(NSString *)appID pkgName:(NSString *)pkgName;
/// 支持多实例运行的读取，后续稳定后删掉上面的方法
- (nullable BDPPkgFileReader)tryGetReaderInMemoryWithUniqueID:(OPAppUniqueID *)uniqueID;

/**
 迁移方法: 以下类方法迁移自原workaround文件
 */
+ (void)clearMetaWithUniqueID:(BDPUniqueID *)uniqueID;

+ (void)clearAllMetas;

+ (nullable id<BDPCommonUpdateModelProtocol> )getModelWithUniqueID:(BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
