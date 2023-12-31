//
//  IESGurdDownloadPackageManager+Business.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/1.
//

#import "IESGurdDownloadPackageManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESGurdDownloadResourceCallback)(IESGurdResourceModel *model, BOOL succeed, IESGurdSyncStatus status);

@interface IESGurdDownloadPackageManager (Business)

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                          accessKey:(NSString *)accessKey
                        shouldApply:(BOOL)shouldApply
                            logInfo:(NSDictionary *)logInfo
                         completion:(IESGurdSyncStatusDictionaryBlock)completion;

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                            logInfo:(NSDictionary * _Nullable)logInfo;

+ (void)downloadResourcesWithModels:(NSArray<IESGurdResourceModel *> *)models
                            logInfo:(NSDictionary * _Nullable)logInfo
                           callback:(IESGurdDownloadResourceCallback _Nullable)callback;

@end

NS_ASSUME_NONNULL_END
