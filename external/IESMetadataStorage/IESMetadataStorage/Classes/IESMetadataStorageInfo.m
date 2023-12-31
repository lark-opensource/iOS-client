//
//  IESMetadataStorageInfo.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "IESMetadataStorageInfo.h"

int const IESMetadataStorageInfoVersion = 2;
const char *IESMetadataStorageMagicHeader = "metadata";

static NSString * const IESMetadataStorageInfoVersionKey = @"version";
static NSString * const IESMetadataStorageInfoDuplicatedKey = @"duplicated";

@interface IESMetadataStorageInfo ()

@property (nonatomic, assign) int version;

@property (nonatomic, assign) BOOL checkDuplicatedMetadatas;

@end

@implementation IESMetadataStorageInfo

#pragma mark - Public

+ (instancetype)defaultInfo
{
    IESMetadataStorageInfo *info = [[self alloc] init];
    [info setupWithDictionary:@{ IESMetadataStorageInfoVersionKey : @(IESMetadataStorageInfoVersion) }];
    return info;
}

+ (instancetype)infoWithData:(NSData *)data
{
    IESMetadataStorageInfo *info = [[self alloc] init];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    [info setupWithDictionary:dictionary];
    if (info.version == 1 && IESMetadataStorageInfoVersion == 2) {
        info.checkDuplicatedMetadatas = YES;
    }
    return info;
}

- (NSData *)binaryData
{
    NSDictionary *dictionary = @{
        IESMetadataStorageInfoVersionKey : @(self.version),
        IESMetadataStorageInfoDuplicatedKey: @(self.checkDuplicatedMetadatas)
    };
    return [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL];
}

#pragma mark - Private

- (void)setupWithDictionary:(NSDictionary *)dictionary
{
    self.version = [dictionary[IESMetadataStorageInfoVersionKey] intValue];
    self.checkDuplicatedMetadatas = [dictionary[IESMetadataStorageInfoDuplicatedKey] boolValue];
}

@end

