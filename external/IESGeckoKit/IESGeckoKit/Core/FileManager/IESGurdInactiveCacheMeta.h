//
//  IESGurdInactiveCacheMeta.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/9.
//

#import <Foundation/Foundation.h>

#import "IESGurdMetadataProtocol.h"
#import "IESGeckoResourceModel.h"
#import "IESGurdUpdateStatisticModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdInactiveCacheMeta : NSObject <NSSecureCoding, IESGurdMetadataProtocol>

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy) NSString *md5;

@property (nonatomic, copy) NSString *decompressMD5;

@property (nonatomic, assign) uint64_t version;

@property (nonatomic, assign) uint64_t packageID;

@property (nonatomic, assign) uint64_t patchID;

@property (nonatomic, assign) uint64_t localVersion;

@property (nonatomic, assign) int packageType;

@property (nonatomic, assign) BOOL fromPatch;

@property (nonatomic, assign) BOOL isZstd;

@property (nonatomic, copy) NSString *fileName; //单文件激活后的文件名

@property (nonatomic, copy) NSString *groupName;

@property (nonatomic, copy) NSArray<NSString *> *groups;

@property (nonatomic, copy) NSString *logId;

@property (nonatomic, assign) uint64_t packageSize;

@property (nonatomic, assign) uint64_t patchPackageSize;

// 这里面的数据不写入文件
@property (nonatomic, strong) IESGurdUpdateStatisticModel *updateStatisticModel;

- (void)putDataToDict:(NSMutableDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
