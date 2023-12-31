//
//  zstandardlibCompressor.h
//  zstandardlib
//
//  Created by JinyDu on 2021/6/22.
//  Copyright © 2021 JinyDu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZstdDecompressor : NSObject

@property (class, nonatomic, assign, readonly) NSInteger defaultCompressionLevel;


//+ (nullable NSData*)compressedDataWithData:(NSData *)input dict:(NSData *)dict;

+ (nullable NSData*)decompressedDataWithData:(NSData* _Nonnull)input dict:(NSData * _Nullable)dict;

/**
 Creates a newly created NSData, with the default compression level.
 The input is compressed via the Zstd algorithm.
 
 @param input Input data.
 @return Return the newly created compressed data.
 */
//+ (nullable NSData*)compressedDataWithData:(NSData* _Nonnull)input;

/**
 Creates a newly created NSData.
 The input is compressed via the Zstd algorithm.
 
 @param input Input data.
 @param compressionLevel Compression level.
 @return Return the newly created compressed data.
 */
//+ (nullable NSData*)compressedDataWithData:(NSData* _Nonnull)input compressionLevel:(NSInteger)compressionLevel;

/**
 Creates a newly created NSData, with the default compression level.
 The input is compressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @return Return the newly created compressed data.
 */
//+ (nullable NSData*)compressedDataWithBytes:(const void* _Nonnull)bytes length:(NSUInteger)length;

/**
 Creates a newly created NSData.
 The input is compressed via the Zstd algorithm.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @param compressionLevel Compression level.
 @return Return the newly created compressed data.
 */
//+ (nullable NSData*)compressedDataWithBytes:(const void* _Nonnull)bytes length:(NSUInteger)length compressionLevel:(NSInteger)compressionLevel;

/**
 Creates a newly created NSData.
 The input is decompressed via the Zstd algorithm.
 Will return nil (error) if the input was only partial.
 
 @param input Input data.
 @return Return the newly created decompressed data.
 */
+ (nullable NSData*)decompressedDataWithData:(NSData* _Nonnull)input;

+ (BOOL)decompressedDataWithData:(NSData* _Nonnull)input fileName:(NSString * _Nonnull)filePath;

/**
 Creates a newly created NSData.
 The input is decompressed via the Zstd algorithm.
 Will return nil (error) if the input was only partial.
 
 @param bytes Input bytes.
 @param length Input length (number of bytes).
 @return Return the newly created decompressed data.
 */
+ (nullable NSData*)decompressedDataWithBytes:(const void* _Nonnull)bytes length:(NSUInteger)length;

@end
