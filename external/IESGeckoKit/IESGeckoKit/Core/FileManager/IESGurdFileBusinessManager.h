//
//  IESGurdFileBusinessManager.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import <Foundation/Foundation.h>

#import "IESGurdFilePaths.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESGurdFileOperationCompletion)(BOOL succeed, NSDictionary * _Nullable info, NSError * _Nullable error);

@interface IESGurdFileBusinessManager : NSObject

+ (void)setup;

#pragma mark - Data

/**
 是否有缓存数据
 */
+ (BOOL)hasCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path;

/**
 根据accessKey和channel返回数据
 */
+ (NSData * _Nullable)dataForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                                  path:(NSString *)path
                               options:(NSDataReadingOptions)options;

+ (NSData * _Nullable)offlineDataForAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                         path:(NSString *)path;

#pragma mark - Create Directory

/**
 创建channel目录
 */
+ (NSString * _Nullable)createDirectoryForAccessKey:(NSString *)accessKey
                                            channel:(NSString *)channel
                                              error:(NSError **)error;

/**
 根据accessKey、channel、version、md5创建zip包存放路径
 */
+ (NSString * _Nullable)createInactivePackagePathForAccessKey:(NSString *)accessKey
                                                      channel:(NSString *)channel
                                                      version:(uint64_t)version
                                                          md5:(NSString *)md5
                                                       isZstd:(BOOL)isZstd
                                                        error:(NSError **)error;

/**
 创建备份目录
*/
+ (void)createBackupDirectoryIfNeeded;

/**
 创建单文件channel的备份目录
*/
+ (void)createBackupSingleFilePathIfNeeded;

#pragma mark - Paths

/**
 返回激活临时文件路径
 */
+ (NSString *)applyTempFilePath;

/**
 返回下载临时文件路径
 */
+ (NSString *)downloadTempFilePath;

/**
 根据accessKey、channel返回备份包路径
 */
+ (NSString * _Nullable)backupPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

/**
 根据accessKey、channel返回旧文件路径
 */
+ (NSString * _Nullable)oldFilePathForAccessKey:(NSString *)accessKey
                                        channel:(NSString *)channel;

#pragma mark - Business

/**
 异步执行任务
 */
+ (void)asyncExecuteBlock:(dispatch_block_t)block
                accessKey:(NSString *)accessKey
                  channel:(NSString *)channel;

/**
 同步执行任务
 */
+ (void)syncExecuteBlock:(dispatch_block_t)block
               accessKey:(NSString *)accessKey
                 channel:(NSString *)channel;

#pragma mark - Clean

+ (void)addCacheWhitelistWithAccessKey:(NSString *)accessKey
                              channels:(NSArray<NSString *> *)channels;
/**
 清理缓存
 */
+ (void)clearCache;

/**
 清理白名单以外的缓存
 */
+ (void)clearCacheExceptWhitelist;

/**
 根据accessKey和channel清理对应的缓存
 */
+ (void)cleanCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                    completion:(IESGurdFileOperationCompletion)completion;
+ (void)cleanCacheForAccessKey:(NSString *)accessKey
                       channel:(NSString *)channel
                        isSync:(BOOL)isSync
                    completion:(IESGurdFileOperationCompletion)completion;

/**
 根据accessKey和channel清理zip包
 */
+ (void)cleanInactiveCacheForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
