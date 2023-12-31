//
//  IESGurdKit+ByteSync.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/10/23.
//

#import "IESGeckoKit.h"

#import "IESGeckoResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (ByteSync)

+ (BOOL)shouldHandleByteSyncMessageWithTimestamp:(NSInteger)timestamp;

+ (void)syncResourcesWithTargetChannelsDictionary:(NSDictionary *)targetChannelsDictionary
                             groupNamesDictionary:(NSDictionary *)groupNamesDictionary
                           customParamsDictionary:(NSDictionary *)customParamsDictionary
                                           taskId:(int)taskId
__attribute__((deprecated("deprecated")));

+ (void)clearCacheWithCleanInfoDictionary:(NSDictionary *)cleanInfoDictionary taskId:(int)taskId;

+ (void)downloadResourcesWithModelsArray:(NSArray<IESGurdResourceModel *> *)modelsArray taskId:(int)taskId;

@end

NS_ASSUME_NONNULL_END
