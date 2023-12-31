//
//  IESMetadataMappedFile.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESMetadataMappedFile : NSObject

@property (nonatomic, readonly, copy) NSString *filePath;

@property (nonatomic, readonly, assign) int fileSize;

+ (instancetype)mappedFileWithPath:(NSString *)filePath mapLength:(int)mapLength;

- (BOOL)extendFile;

- (BOOL)resetToNewFile;

#pragma mark - Read

- (NSData *)dataAtLocation:(int)location length:(int)length;

- (bool)boolValueAtLocation:(int)location;

- (int)intValueAtLocation:(int)location;

- (const char *)charsAtLocation:(int)location length:(int)length;

- (uint32_t)crc32AtLocation:(int)location;

#pragma mark - Write

- (void)writeData:(NSData *)data location:(int)location;

- (void)writeBool:(bool)boolValue location:(int)location;

- (void)writeIntValue:(int)intValue location:(int)location;

- (void)writeChars:(const char *)chars location:(int)location;

- (void)writeCrc32:(uint32_t)crc32 location:(int)location;

@end

NS_ASSUME_NONNULL_END
