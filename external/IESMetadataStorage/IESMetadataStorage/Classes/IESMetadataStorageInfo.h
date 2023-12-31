//
//  IESMetadataStorageInfo.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern int const IESMetadataStorageInfoVersion;
extern const char *IESMetadataStorageMagicHeader;

@interface IESMetadataStorageInfo : NSObject

@property (nonatomic, readonly, assign) int version;

@property (nonatomic, readonly, assign) BOOL checkDuplicatedMetadatas;

+ (instancetype)defaultInfo;

+ (instancetype)infoWithData:(NSData *)data;

- (NSData *)binaryData;

@end

NS_ASSUME_NONNULL_END
