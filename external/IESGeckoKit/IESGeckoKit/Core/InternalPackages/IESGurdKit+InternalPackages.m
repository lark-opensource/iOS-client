//
//  IESGurdKit+InternalPackages.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/16.
//

#import "IESGurdKit+InternalPackages.h"

#import "IESGurdInternalPackagesManager.h"
#import "IESGurdFilePaths+InternalPackage.h"
#import "IESGurdKitUtil.h"
#import "IESGurdInternalPackageMetaInfo+Private.h"
#import "NSDictionary+IESGurdInternalPackage.h"

#import <objc/runtime.h>
#import <SSZipArchive/SSZipArchive.h>

//cache
#import "IESGurdExpiredCacheManager.h"

typedef void(^IESGurdActiveInternalPackageCompletion)(BOOL succeed);

@interface IESGurdInternalPackageMetaInfo (Private)
@property (nonatomic, copy) NSString *packagePath;
+ (instancetype)metaInfoWithDictionary:(NSDictionary *)dictionary;
@end

@implementation IESGurdKit (InternalPackages)

#pragma mark - Public

+ (void)activeAllInternalPackagesInMainBundleWithCompletion:(void (^)(BOOL succeed))completion
{
    [self activeAllInternalPackagesWithBundleName:nil
                                       completion:completion];
}

+ (void)activeAllInternalPackagesWithBundleName:(NSString * _Nullable)bundleName
                                     completion:(void (^)(BOOL succeed))completion
{
    NSString *message = [NSString stringWithFormat:@"Active all internal packages in %@ bundle", bundleName ? : @"main"];
    IESGurdInternalPackageMessageLog(message, NO, YES);
    
    [self activeInternalPackageWithBundleName:bundleName
                            shouldActiveBlock:nil
                                   completion:completion];
}

+ (void)activeInternalPackageInMainBundleWithAccessKey:(NSString *)accessKey
                                               channel:(NSString *)channel
                                            completion:(void (^)(BOOL succeed))completion
{
    [self activeInternalPackageWithBundleName:nil
                                    accessKey:accessKey
                                      channel:channel
                                   completion:completion];
}

+ (void)activeInternalPackageWithBundleName:(NSString * _Nullable)bundleName
                                  accessKey:(NSString *)accessKey
                                    channel:(NSString *)channel
                                 completion:(void (^)(BOOL succeed))completion
{
    NSString *message = [NSString stringWithFormat:@"Active internal package in %@ bundle", bundleName ? : @"main"];
    IESGurdInternalPackageBusinessLog(accessKey, channel, message, NO, YES);
    
    BOOL (^shouldActiveBlock)(IESGurdInternalPackageMetaInfo *) = ^BOOL (IESGurdInternalPackageMetaInfo *metaInfo) {
        return [metaInfo.accessKey isEqualToString:accessKey] && [metaInfo.channel isEqualToString:channel];
    };
    [self activeInternalPackageWithBundleName:bundleName
                            shouldActiveBlock:shouldActiveBlock
                                   completion:completion];
}

+ (void)clearInternalPackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    [IESGurdInternalPackagesManager clearInternalPackageForAccessKey:accessKey channel:channel];
}

+ (NSString *)internalRootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    return [IESGurdFilePaths internalRootDirectoryForAccessKey:accessKey channel:channel];
}

#pragma mark - Private

+ (void)activeInternalPackageWithBundleName:(NSString *)bundleName
                          shouldActiveBlock:(BOOL (^)(IESGurdInternalPackageMetaInfo *metaInfo))shouldActiveBlock
                                 completion:(void (^)(BOOL))completion
{
    IESGurdInternalPackageAsyncExecuteBlock(^{
        NSDictionary *configDictionary = [NSDictionary gurd_configDictionaryWithBundleName:bundleName];
        if (configDictionary.count == 0) {
            NSString *message = [NSString stringWithFormat:@"❌ Internal package config is empty in %@ bundle", bundleName ? : @"main"];
            IESGurdInternalPackageMessageLog(message, YES, YES);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ? : completion(NO);
            });
            return;
        }
        
        __block BOOL activeSucceed = YES;
        dispatch_group_t group = dispatch_group_create();
        
        NSString *bundlePath = [IESGurdFilePaths bundlePathWithName:bundleName];
        [configDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *packageName, NSDictionary *info, BOOL *stop) {
            IESGurdInternalPackageMetaInfo *metaInfo = [IESGurdInternalPackageMetaInfo metaInfoWithDictionary:info];
            if (!metaInfo) {
                NSString *message = [NSString stringWithFormat:@"❌ Create meta info failed, info : %@", [info description]];
                IESGurdInternalPackageMessageLog(message, YES, YES);
                return;
            }
            
            BOOL shouldActive = YES;
            if (shouldActiveBlock) {
                shouldActive = shouldActiveBlock(metaInfo);
            }
            if (!shouldActive) {
                return;
            }
            
            NSString *accessKey = metaInfo.accessKey;
            NSString *channel = metaInfo.channel;
            // check local package id
            uint64_t localPackageId = [IESGurdInternalPackagesManager internalPackageIdForAccessKey:accessKey
                                                                                             channel:channel];
            if (metaInfo.packageId == localPackageId) {
                NSString *message = [NSString stringWithFormat:@"Internal package is active, package id : %llu", localPackageId];
                IESGurdInternalPackageBusinessLog(accessKey, channel, message, NO, YES);
                
                [IESGurdInternalPackagesManager updateDataAccessPolicy:metaInfo.dataAccessPolicy
                                                             accessKey:accessKey
                                                               channel:channel];
                return;
            }
            
            // check package path
            NSString *packagePath = [bundlePath stringByAppendingPathComponent:packageName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:packagePath]) {
                NSString *message = @"❌ Internal package file does not exist";
                IESGurdInternalPackageBusinessLog(accessKey, channel, message, YES, YES);
                
                activeSucceed = NO;
                return;
            }
            metaInfo.packagePath = packagePath;
            
            if (![self preparePackageDirectoryWithAccessKey:accessKey channel:channel]) {
                activeSucceed = NO;
                return;
            }
            
            IESGurdActiveInternalPackageCompletion activeCompletion = ^(BOOL succeed) {
                if (succeed) {
                    metaInfo.bundleName = bundleName;
                    [IESGurdInternalPackagesManager saveInternalPackageMetaInfo:metaInfo];
                }
                activeSucceed &= succeed;
                dispatch_group_leave(group);
            };
            if (metaInfo.fileType == 0) {
                dispatch_group_enter(group);
                [self unzipInternalPackageWithMetaInfo:metaInfo completion:activeCompletion];
            } else if (metaInfo.fileType == 1) {
                dispatch_group_enter(group);
                [self copyInternalPackageWithMetaInfo:metaInfo completion:activeCompletion];
            }
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            !completion ? : completion(activeSucceed);
        });
    });
}

+ (BOOL)preparePackageDirectoryWithAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    // 内置包根目录
    NSString *internalPackagesDirectory = [IESGurdFilePaths internalPackagesDirectory];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createDirectoryAtPath:internalPackagesDirectory
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
        NSString *message = [NSString stringWithFormat:@"❌ Create internal package root directory failed, reason : %@",
                             error.localizedDescription ? : @"unknown"];
        IESGurdInternalPackageMessageLog(message, YES, YES);
        return NO;
    }
    
    NSString *channelDirectory = [IESGurdFilePaths internalRootDirectoryForAccessKey:accessKey channel:channel];
    if ([fileManager fileExistsAtPath:channelDirectory]) {
        [fileManager removeItemAtPath:channelDirectory error:NULL];
    }
    return YES;
}

+ (void)unzipInternalPackageWithMetaInfo:(IESGurdInternalPackageMetaInfo *)metaInfo
                              completion:(IESGurdActiveInternalPackageCompletion)completion
{
    NSString *accessKey = metaInfo.accessKey;
    NSString *channel = metaInfo.channel;
    
    NSString *accessKeyDirectory = [IESGurdFilePaths internalPackageDirectoryForAccessKey:accessKey];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:accessKeyDirectory
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        NSString *message = [NSString stringWithFormat:@"❌ Create internal package accessKey directory failed, reason : %@",
                             error.localizedDescription ? : @"unknown"];
        IESGurdInternalPackageBusinessLog(accessKey, channel, message, YES, YES);
        
        !completion ? : completion(NO);
        return;
    }
    
    [SSZipArchive unzipFileAtPath:metaInfo.packagePath toDestination:accessKeyDirectory progressHandler:nil completionHandler:^(NSString *path, BOOL succeeded, NSError *unzipError) {
        if (succeeded) {
            NSString *message = [NSString stringWithFormat:@"✅ Unzip internal package successfully, package id : %llu", metaInfo.packageId];
            IESGurdInternalPackageBusinessLog(accessKey, channel, message, NO, NO);
        } else {
            // 清理过期缓存（一期试验先不开启）
//            if (unzipError.code == SSZipArchiveErrorCodeFailedToWriteFile) {
//                [[IESGurdExpiredCacheManager sharedManager] clearCache:nil];
//            }
            NSString *message = [NSString stringWithFormat:@"❌ Unzip internal package failed, reason : %@",
                                 unzipError.localizedDescription ? : @"unknown"];
            IESGurdInternalPackageBusinessLog(accessKey, channel, message, YES, YES);
        }
        
        !completion ? : completion(succeeded);
    }];
}

+ (void)copyInternalPackageWithMetaInfo:(IESGurdInternalPackageMetaInfo *)metaInfo
                             completion:(IESGurdActiveInternalPackageCompletion)completion
{
    NSString *accessKey = metaInfo.accessKey;
    NSString *channel = metaInfo.channel;
    
    NSString *channelDirectory = [IESGurdFilePaths internalRootDirectoryForAccessKey:accessKey channel:channel];
    
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager createDirectoryAtPath:channelDirectory
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
        NSString *message = [NSString stringWithFormat:@"❌ Create internal package channel directory failed, reason : %@",
                             error.localizedDescription ? : @"unknown"];
        IESGurdInternalPackageBusinessLog(accessKey, channel, message, YES, YES);
        
        !completion ? : completion(NO);
        return;
    }
    
    NSString *packagePath = metaInfo.packagePath;
    NSString *fileName = packagePath.lastPathComponent;
    NSString *targetPath = [channelDirectory stringByAppendingPathComponent:fileName];
    
    BOOL copyItem = [fileManager copyItemAtPath:packagePath toPath:targetPath error:&error];
    if (copyItem) {
        NSString *message = [NSString stringWithFormat:@"✅ Copy internal package successfully, package id : %llu", metaInfo.packageId];
        IESGurdInternalPackageBusinessLog(accessKey, channel, message, NO, NO);
    } else {
        NSString *message = [NSString stringWithFormat:@"❌ Copy internal package failed, reason : %@",
                             error.localizedDescription ? : @"unknown"];
        IESGurdInternalPackageBusinessLog(accessKey, channel, message, YES, YES);
    }
    
    !completion ? : completion(copyItem);
}

@end

@implementation IESGurdInternalPackageMetaInfo (Private)

+ (instancetype)metaInfoWithDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        NSAssert(NO, @"Internal package info should be dictionary.");
        return nil;
    }
    
    NSString *accessKey = dictionary[kIESGurdInternalPackageConfigKeyAccessKey];
    NSString *channel = dictionary[kIESGurdInternalPackageConfigKeyChannel];
    if (accessKey.length == 0 || channel.length == 0) {
        NSAssert(NO, @"Internal package accessKey or channel should not be empty.");
        return nil;
    }
    
    uint64_t packageId = [dictionary[@"package_id"] unsignedLongLongValue];
    if (packageId == 0) {
        NSAssert(NO, @"Internal package id should not be zero");
        return nil;
    }
    
    NSNumber *dataAccessPolicyNumber = dictionary[@"data_access_policy"];
    IESGurdDataAccessPolicy dataAccessPolicy = IESGurdDataAccessPolicyInternalPackageFirst;
    if (dataAccessPolicyNumber != nil) {
        dataAccessPolicy = [dataAccessPolicyNumber integerValue];
    }
    
    IESGurdInternalPackageMetaInfo *metaInfo = [[IESGurdInternalPackageMetaInfo alloc] init];
    metaInfo.accessKey = accessKey;
    metaInfo.channel = channel;
    metaInfo.packageId = packageId;
    metaInfo.fileType = [dictionary[@"file_type"] integerValue];
    metaInfo.dataAccessPolicy = dataAccessPolicy;
    return metaInfo;
}

- (NSString *)packagePath
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPackagePath:(NSString *)packagePath
{
    objc_setAssociatedObject(self, @selector(packagePath), packagePath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
