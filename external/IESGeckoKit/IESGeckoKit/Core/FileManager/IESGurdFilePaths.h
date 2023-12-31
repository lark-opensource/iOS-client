//
//  IESGurdFilePaths.h
//  Pods
//
//  Created by 陈煜钏 on 2019/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdCacheRootDirectoryPath : NSObject

@property (class, nonatomic, copy) NSString *path;

@end

@interface IESGurdFilePaths : NSObject

@property (class, nonatomic, readonly, copy) NSString *cacheRootDirectoryPath;    //缓存根目录

@property (class, nonatomic, readonly, copy) NSString *settingsResponsePath;    //settings缓存路径

@property (class, nonatomic, readonly, copy) NSString *settingsResponseCrc32Path;   //settings crc32校验路径

@property (class, nonatomic, readonly, copy) NSString *blocklistChannelPath;   // 冷启动黑名单路径

@property (class, nonatomic, readonly, copy) NSString *blocklistChannelCrc32Path;   //冷启动黑名单 crc32 校验路径

@property (class, nonatomic, readonly, copy) NSString *inactiveDirectoryPath;   //未激活根目录

@property (class, nonatomic, readonly, copy) NSString *backupDirectoryPath;     //旧zip目录

@property (class, nonatomic, readonly, copy) NSString *backupSingleFileChannelPath; //旧的单文件channel目录

@property (class, nonatomic, readonly, copy) NSString *modifyTimeDirectoryPath; //modify_time根目录

@property (class, nonatomic, readonly, copy) NSString *inactiveMetaDataPath;    //旧的未激活元数据路径

@property (class, nonatomic, readonly, copy) NSString *activeMetaDataPath;      //旧的已激活元数据路径

@property (class, nonatomic, readonly, copy) NSString *inactiveMetadataPath;    //新的未激活元数据路径

@property (class, nonatomic, readonly, copy) NSString *activeMetadataPath;      //新的已激活元数据路径

@property (class, nonatomic, readonly, copy) NSString *packagesExtraPath;       //更新请求返回的extra字段的本地存储路径

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey;

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (NSString *)directoryPathForAccessKey:(NSString *)accessKey channel:(NSString *)channel path:(NSString *)path;

+ (NSString *)inactivePathForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (NSString *)inactivePathForAccessKeyAndVersion:(NSString *)accessKey channel:(NSString *)channel version:(uint64_t)version;

/**
 返回未解压的包路径
*/
+ (NSString *)inactivePackagePathForAccessKey:(NSString *)accessKey
                                      channel:(NSString *)channel
                                      version:(uint64_t)version
                                       isZstd:(bool)isZstd
                                          md5:(NSString *)md5;

/**
 返回备份包路径
*/
+ (NSString *)backupPathForMd5:(NSString *)md5;

/**
 返回单文件channel的旧文件路径
*/
+ (NSString *)backupSingleFilePathForMd5:(NSString *)md5;

@end

@interface IESGurdFilePaths (Helper)

/**
 返回文件大小
 */
+ (uint64_t)fileSizeAtPath:(NSString *)filePath;

/**
 返回文件夹大小，内部做深度遍历
 */
+ (uint64_t)fileSizeAtDirectory:(NSString *)directory;

/**
 返回文件大小字符串
 */
+ (NSString *)fileSizeStringAtPath:(NSString *)filePath;

/**
 返回文件路径在Gurd里的相对路径
 如：传入 Library/Caches/IESWebCache/accessKey/channel/path 会返回 accessKey/channel/path
 */
+ (NSString *)briefFilePathWithFullPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
