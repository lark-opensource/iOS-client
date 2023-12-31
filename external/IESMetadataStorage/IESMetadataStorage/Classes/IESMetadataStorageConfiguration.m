//
//  IESMetadataStorageConfiguration.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "IESMetadataStorageConfiguration.h"

static int IESMetadataDefaultCapacity = 512;

@interface IESMetadataStorageConfiguration ()

@property (nonatomic, copy) NSString *filePath;

@end

@implementation IESMetadataStorageConfiguration

+ (instancetype)configurationWithFilePath:(NSString *)filePath
{
    NSAssert(filePath.length > 0, @"File path is empty : %@", filePath);
    IESMetadataStorageConfiguration *configuration = [[self alloc] init];
    configuration.filePath = filePath;
    configuration.metadataCapacity = IESMetadataDefaultCapacity;
    return configuration;
}

- (BOOL)isValid
{
    return self.filePath.length > 0;
}

#pragma mark - Accessor

- (void)setMetadataCapacity:(int)metadataCapacity
{
    _metadataCapacity = MAX(IESMetadataDefaultCapacity, metadataCapacity);
}

@end
