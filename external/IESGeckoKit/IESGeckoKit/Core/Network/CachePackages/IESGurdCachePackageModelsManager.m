//
//  IESGurdCachePackageModelsManager.m
//  Aspects
//
//  Created by bytedance on 2021/12/29.
//

#import "IESGurdCachePackageModelsManager.h"
#import "IESGurdResourceMetadataStorage.h"
#import "IESGeckoKit.h"

@interface IESGurdCachePackageInfo ()
@property (nonatomic, assign, readwrite) IESGurdCachePackageStatus status;
@property (nonatomic, strong, readwrite) IESGurdResourceModel * _Nullable model;
@property (nonatomic, strong, readwrite) IESGurdActivePackageMeta * _Nullable metadata;
@end

@implementation IESGurdCachePackageInfo

- (void)updateStatus
{
    IESGurdResourceModel *model = self.model;
    // 当model为空的时候，这里model.accessKey也是空，metadata也是空
    // 因此下面的IESGurdCachePackageStatusNotFoundButExist状态永远走不到
    IESGurdActivePackageMeta *metadata = [IESGurdResourceMetadataStorage activeMetaForAccessKey:model.accessKey channel:model.channel];
    
    IESGurdCachePackageStatus status = IESGurdCachePackageStatusNotFound;
    if (model) {
        uint64_t packageID = model.package.ID;
        if (packageID > 0 && packageID == metadata.packageID) {
            status = IESGurdCachePackageStatusAlreadyNewest;
        } else {
            status = IESGurdCachePackageStatusNewVersion;
        }
    } else if (metadata.packageID > 0) {
        status = IESGurdCachePackageStatusNotFoundButExist;
    }
    
    self.status = status;
    self.metadata = metadata;
}

@end

@interface IESGurdCachePackageModelsManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, IESGurdCachePackageInfo *> *> *packageInfosMap;

@end

@implementation IESGurdCachePackageModelsManager

+ (instancetype)sharedManager
{
    static IESGurdCachePackageModelsManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.packageInfosMap = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (void)addModel:(IESGurdResourceModel *)model
{
    NSString *accessKey = model.accessKey;
    NSString *channel = model.channel;
    if (accessKey.length == 0 || channel.length == 0 || !model) {
        return;
    }
    @synchronized (self) {
        [self createPackageInfoWithAccessKey:accessKey channel:channel];
        
        self.packageInfosMap[accessKey][channel].model = model;
    }
}

- (void)removeModel:(IESGurdResourceModel *)model
{
    NSString *accessKey = model.accessKey;
    NSString *channel = model.channel;
    if (accessKey.length == 0 || channel.length == 0 || !model) {
        return;
    }
    @synchronized (self) {
        self.packageInfosMap[accessKey][channel].model = nil;
    }
}

- (IESGurdCachePackageInfo *)packageInfoWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return nil;
    }
    @synchronized (self) {
        [self createPackageInfoWithAccessKey:accessKey channel:channel];
        
        IESGurdCachePackageInfo *packageInfo = self.packageInfosMap[accessKey][channel];
        [packageInfo updateStatus];
        return packageInfo;
    }
}

- (NSArray<IESGurdCachePackageInfo *> *)packageInfosWithAccessKey:(NSString *)accessKey group:(NSString *)group
{
    if (accessKey.length == 0 || group.length == 0) {
        return @[];
    }
    @synchronized (self) {
        NSMutableArray<IESGurdCachePackageInfo *> *packageInfos = [NSMutableArray array];
        
        [self.packageInfosMap[accessKey] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull channel, IESGurdCachePackageInfo * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.model && [obj.model.groups containsObject:group]) {
                // 对于以group按需更新的，把groupName改成此group，用于update_aggr埋点上传
                obj.model.groupName = group;
                [obj updateStatus];
                [packageInfos addObject:obj];
            }
        }];

        return [packageInfos copy];
    }
}

#pragma mark - Private

// 调用处加锁
- (void)createPackageInfoWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    static NSMutableDictionary *flags = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flags = [NSMutableDictionary dictionary];
    });
    NSString *key = [NSString stringWithFormat:@"%@-%@", accessKey, channel];
    if ([flags[key] boolValue]) {
        return;
    }
    flags[key] = @(YES);
    
    NSMutableDictionary<NSString *, IESGurdCachePackageInfo *> *packageInfosMap = self.packageInfosMap[accessKey];
    if (!packageInfosMap) {
        packageInfosMap = [NSMutableDictionary dictionary];
        self.packageInfosMap[accessKey] = packageInfosMap;
    }
    packageInfosMap[channel] = [[IESGurdCachePackageInfo alloc] init];
}

@end
