//
//  ZstdCompressor.h
//  zstandardlib
//
//  Created by ByteDance on 2022/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZstdCompressor : NSObject


@property (nonatomic, assign) int compressionLevel;

- (void)setDictioanry:(NSData *)data;

- (nullable NSData*)compressDataWithData:(NSData* _Nonnull)input
                               usingDict:(BOOL)usingDict
                                   error:(NSError **)error;







@property (class, nonatomic, assign, readonly) NSInteger defaultCompressionLevel;

/**
 Use zstd compress data
 The input is compressed via the Zstd algorithm.
 
 @param input Input data.
 @param compressionLevel Compression level.   Pass「 ZstdCompressor.defaultCompressionLevel」use default.
 @return Return the newly created compressed data.
 */
+ (nullable NSData*)compressDataWithData:(NSData* _Nonnull)input
                        compressionLevel:(NSInteger)compressionLevel
                              dictionary:(nullable NSData *)dictionary;

/**
 Zstd compress data, Use C style params
 The input is compressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @param compressionLevel Compression level.   Pass「 ZstdCompressor.defaultCompressionLevel」use default.
 @param dictionary compress dictionary. if not use dic pass nil；
 @return Return the newly created compressed data.
 */
+ (nullable NSData*)compressedDataWithBytes:(const void* _Nonnull)bytes
                                     length:(NSUInteger)length
                           compressionLevel:(NSInteger)compressionLevel
                                 dictionary:(nullable NSData *)dictionary;



@end

NS_ASSUME_NONNULL_END
