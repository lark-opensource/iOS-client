//
//  IESMetadataStorage.h
//  IESMetadataStorage_Example
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

#import "IESMetadataStorageDefines.h"
#import "IESMetadataProtocol.h"
#import "IESMetadataStorageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSObject<IESMetadataProtocol> IESMetadataType;
typedef IESMetadataType *_Nonnull(^IESMetadataTransformBlock)(NSData *data);
typedef BOOL (^IESMetadataCompareBlock)(IESMetadataType *first, IESMetadataType *another); // 返回重复时是否新的覆盖旧的

@interface IESMetadataStorage<MetadataType> : NSObject

@property (nonatomic, readonly, assign) int version;

@property (nonatomic, readonly, strong) IESMetadataStorageConfiguration *configuration;

+ (instancetype)storageWithConfiguration:(IESMetadataStorageConfiguration *)configuration;

- (NSArray<MetadataType> *)metadatasArrayWithTransformBlock:(IESMetadataTransformBlock)transformBlock;

- (NSArray<MetadataType> *)metadatasArrayWithTransformBlock:(IESMetadataTransformBlock)transformBlock
                                               compareBlock:(IESMetadataCompareBlock _Nullable)compareBlock;

- (int)writeMetadata:(IESMetadataType *)metadata error:(NSError **)error;

- (void)deleteMetadata:(IESMetadataType *)metadata;

- (void)deleteAllMetadata;

- (void)setNeedCheckDuplicatedMetadatas;

- (int)indexForMetadata:(IESMetadataType *)metadata;

@end

NS_ASSUME_NONNULL_END
