//
//  IESMetadataIndexesMap.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/9/1.
//

#import <Foundation/Foundation.h>

#import "IESMetadataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESMetadataIndexesMap : NSObject

- (int)indexForMetadata:(NSObject<IESMetadataProtocol> *)metadata;

- (void)setIndex:(int)index forMetadata:(NSObject<IESMetadataProtocol> *)metadata;

- (void)clearAllIndexes;

@end

NS_ASSUME_NONNULL_END
