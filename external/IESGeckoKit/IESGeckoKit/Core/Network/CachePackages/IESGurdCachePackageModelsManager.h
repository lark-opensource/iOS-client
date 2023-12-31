//
//  IESGurdCachePackageModelsManager.h
//  Aspects
//
//  Created by bytedance on 2021/12/29.
//

#import <Foundation/Foundation.h>

#import "IESGeckoResourceModel.h"
#import "IESGurdActivePackageMeta.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IESGurdCachePackageStatus) {
    IESGurdCachePackageStatusNotFound, // 没有缓存包
    IESGurdCachePackageStatusNotFoundButExist, // 没有缓存包，但是本地有包
    IESGurdCachePackageStatusAlreadyNewest, // 缓存了包，但是本地已经是最新的
    IESGurdCachePackageStatusNewVersion // 缓存了包，可以更新
};

@interface IESGurdCachePackageInfo : NSObject

@property (nonatomic, assign, readonly) IESGurdCachePackageStatus status;

@property (nonatomic, strong, readonly) IESGurdResourceModel * _Nullable model;

@property (nonatomic, strong, readonly) IESGurdActivePackageMeta * _Nullable metadata;

@end

@interface IESGurdCachePackageModelsManager : NSObject

+ (instancetype)sharedManager;

- (void)addModel:(IESGurdResourceModel *)model;

- (void)removeModel:(IESGurdResourceModel *)model;

- (IESGurdCachePackageInfo *)packageInfoWithAccessKey:(NSString *)accessKey channel:(NSString *)channel;

- (NSArray<IESGurdCachePackageInfo *> *)packageInfosWithAccessKey:(NSString *)accessKey group:(NSString *)group;

@end

NS_ASSUME_NONNULL_END
