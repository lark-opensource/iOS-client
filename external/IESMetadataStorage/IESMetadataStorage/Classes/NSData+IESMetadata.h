//
//  NSData+IESMetadata.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (IESMetadata)

- (uint32_t)iesmetadata_crc32;

- (BOOL)iesmetadata_checkCrc32:(uint32_t)crc32;

@end

NS_ASSUME_NONNULL_END
