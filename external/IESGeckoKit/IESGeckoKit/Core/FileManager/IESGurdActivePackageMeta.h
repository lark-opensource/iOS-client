//
//  IESGurdActivePackageMeta.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/28.
//

#import <Foundation/Foundation.h>

#import "IESGurdMetadataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdActivePackageMeta : NSObject <NSSecureCoding, IESGurdMetadataProtocol>

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, copy) NSString *md5;

@property (nonatomic, assign) uint64_t version;

@property (nonatomic, assign) uint64_t packageID;

@property (nonatomic, assign) int packageType;

@property (nonatomic, assign) int64_t lastUpdateTimestamp;

@property (nonatomic, assign) int64_t lastReadTimestamp;

@property (nonatomic, assign) uint64_t packageSize;

@property (nonatomic, assign) BOOL isUsed;

@property (nonatomic, copy) NSString *groupName;

@property (nonatomic, copy) NSArray<NSString *> *groups;

@end

NS_ASSUME_NONNULL_END
