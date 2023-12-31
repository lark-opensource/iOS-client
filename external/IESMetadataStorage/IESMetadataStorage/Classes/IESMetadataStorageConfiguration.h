//
//  IESMetadataStorageConfiguration.h
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import <Foundation/Foundation.h>

#import "IESMetadataStorageDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESMetadataStorageConfiguration : NSObject

@property (nonatomic, readonly, copy) NSString *filePath;

@property (nonatomic, assign) int metadataCapacity;

@property (nonatomic, assign) IESMetadataLogLevel logLevel;

+ (instancetype)configurationWithFilePath:(NSString *)filePath;

- (BOOL)isValid;

@end

NS_ASSUME_NONNULL_END
