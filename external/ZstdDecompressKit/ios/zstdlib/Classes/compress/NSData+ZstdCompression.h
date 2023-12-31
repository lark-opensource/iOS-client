//
//  NSData+ZstdCompression.h
//  zstandardlib
//
//  Created by ByteDance on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ZstdCompression)
- (nullable NSData *)awe_compressZstdWithDict:(NSData *)dict;
- (nullable NSData*)awe_compressZstd;
@end

NS_ASSUME_NONNULL_END
