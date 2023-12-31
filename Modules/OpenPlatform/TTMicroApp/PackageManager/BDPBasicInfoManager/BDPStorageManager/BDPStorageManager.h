//
//  BDPStorageManager.h
//  Timor
//
//  Created by liubo on 2019/1/17.
//

#import "BDPAppManagerCommonObj.h"
#import <OPFoundation/BDPModel.h>
#import <ECOInfra/TMAKVDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPStorageManager : NSObject

+ (instancetype)sharedManager;

/// 用于退出登陆时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearSharedManager;

///时间戳timestamp均采用毫秒单位

#pragma mark - Common
- (void)clearAllTable;

@end

#pragma mark - 老版本数据库替换相关接口
@interface BDPStorageManager (OldVersion)

- (BOOL)isExistedOldVersionDB;
- (void)removeOldVersionDB;
- (NSArray<BDPModel *> *)queryOldInUsedModels;
- (void)deleteOldInUsedModelWithUniqueID:(BDPUniqueID *)uniqueID;
- (NSArray<BDPModel *> *)queryOldUpdatedModels;
- (void)deleteOldUpdatedModelWithUniqueID:(BDPUniqueID *)uniqueID;

@end

@interface BDPStorageManager (Helper)

#pragma mark - App Model Helper
+ (BDPModel *)appModelFromData:(NSData *)modelData;

@end

NS_ASSUME_NONNULL_END
