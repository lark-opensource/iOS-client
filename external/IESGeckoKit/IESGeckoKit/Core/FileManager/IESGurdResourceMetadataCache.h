//
//  IESGurdResourceMetadataCache.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/2/3.
//

#import <Foundation/Foundation.h>

#import "IESGurdMetadataProtocol.h"
#import <IESMetadataStorage/IESMetadataStorageConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESMetadataStorageConfiguration (IESGurdKit)
@property (nonatomic, assign) BOOL enableIndexLog;
@end

@interface IESGurdResourceMetadataCache<MetadataType> : NSObject

@property (nonatomic, readonly, assign) int version;

@property (nonatomic, readonly, assign) NSInteger metadataCount;

+ (instancetype)metadataCacheWithConfiguration:(IESMetadataStorageConfiguration *)configuration
                                 metadataClass:(Class<IESGurdMetadataProtocol>)metadataClass;

- (void)saveMetadata:(id<IESGurdMetadataProtocol>)metadata;

- (void)deleteMetadataForAccessKey:(NSString *)accessKey
                           channel:(NSString *)channel;

- (void)clearAllMetadata;

- (NSDictionary<NSString *, NSDictionary<NSString *, MetadataType> *> *)copyMetadataDictionary;

- (NSMutableDictionary *)objectForKeyedSubscript:(NSString *)key;

- (void)setObject:(NSMutableDictionary *)obj forKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
