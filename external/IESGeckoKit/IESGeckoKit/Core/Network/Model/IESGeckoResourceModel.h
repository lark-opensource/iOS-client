//
//  IESGurdResourceModel.h
//  IESGurdKit
//
//  Created by 01 on 17/6/30.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdUpdateStatisticModel;

@interface IESGurdResourceStrategies : NSObject

@property (nonatomic, assign) BOOL deleteIfDownloadFailed;
@property (nonatomic, assign) BOOL deleteBeforeDownload;

@end

@interface IESGurdResourceURLInfo : NSObject

// 包id, 只有增量会有
@property (nonatomic, assign) uint64_t ID;

@property (nonatomic, copy) NSArray<NSString *> *urlList;

// 包MD5值
@property (nonatomic, copy) NSString *md5;

// zstd解压以后的md5
@property (nonatomic, copy) NSString *decompressMD5;

// 包大小
@property (nonatomic, assign) uint64_t packageSize;

- (BOOL)parseUrlList:(NSDictionary *)dict;

@end

@interface IESGurdResourceModel : NSObject

// 版本号
@property (nonatomic, assign) uint64_t version;

// 本地版本号
@property (nonatomic, assign) uint64_t localVersion;

// accessKey
@property (nonatomic, copy) NSString *accessKey;

// 所属频道
@property (nonatomic, copy) NSString *channel;

// 文件类型
@property (nonatomic, assign) IESGurdChannelFileType packageType;

// 全量包信息
@property (nonatomic, strong) IESGurdResourceURLInfo *package;

// 增量包信息
@property (nonatomic, strong) IESGurdResourceURLInfo * _Nullable patch;

// 离线包策略
@property (nonatomic, strong) IESGurdResourceStrategies * _Nullable strategies;

// update统计埋点相关字段
@property (nonatomic, strong) IESGurdUpdateStatisticModel *updateStatisticModel;

// 是否是zstd
@property (nonatomic, assign) BOOL isZstd;

// 是否是按需
@property (nonatomic, assign) BOOL onDemand;

// 使用过这个channel以后，是否还是按需
@property (nonatomic, assign) BOOL alwaysOnDemand;

// 是否需要重试下载
@property (nonatomic, assign) BOOL retryDownload;

// 组名
@property (nonatomic, copy) NSArray<NSString *> *groups;

// 先保持group的逻辑不变
@property (nonatomic, copy) NSString *groupName;

// 下载优先级
@property (nonatomic, assign) IESGurdDownloadPriority downloadPriority;

// 业务identifier
@property (nonatomic, copy) NSArray<NSString *> *businessIdentifiers;

@property (nonatomic, readonly, copy) NSString *logId;

// 当channel为kIESGurdOfflinePrefixChannel时有效
@property (nonatomic, copy) NSArray<NSString *> *offlinePrefixURLsArray;

@property (nonatomic, assign) BOOL forceDownload;

+ (instancetype _Nullable)instanceWithDict:(NSDictionary *)dict local:(NSDictionary *)local logId:(NSString *)logId;

- (IESGurdResourceModel *)fullPackageInstance;

- (void)putDataToDict:(NSMutableDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
