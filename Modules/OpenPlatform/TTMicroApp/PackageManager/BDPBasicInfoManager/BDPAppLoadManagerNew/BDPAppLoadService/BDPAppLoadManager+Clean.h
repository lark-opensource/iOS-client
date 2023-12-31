//
//  BDPAppLoadManager+Clean.h
//  Timor
//
//  Created by lixiaorui on 2020/7/26.
//

#import "BDPAppLoadManager.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 清理操作
@interface BDPAppLoadManager (Clean)

- (void)releaseMemoryCache;

/** 移除所有pkg相关的IO/Memory缓存 */
- (void)releaseAllPkgFiles;

/// 删除所有meta缓存以及对应的pkg文件+文件句柄, 如果不传pkgName则删除app目录
- (void)removeAllMetaAndDataWithUniqueID:(BDPUniqueID *)uniqueID pkgName:(nullable NSString *)pkgName;

// 在新的数据表里清除（不大于N个版本的逻辑，常用应用也需要清除）
-(BOOL)cleanMetasInPKMDBWithAppID:(NSString *)appID error:(NSError **) deleteError;

///删除所有过期的pkg
-(void)deleteExpiredPkg;

/// 删除应用pkg和meta数据
- (void)deletePackageAndMeta:(NSArray<OPAppUniqueID *> *)uniqueIDs
                  completion:(void (^_Nonnull)(NSArray<OPAppUniqueID *>*))completion;
@end

NS_ASSUME_NONNULL_END
