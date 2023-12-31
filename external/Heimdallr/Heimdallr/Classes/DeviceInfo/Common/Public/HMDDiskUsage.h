//
//  HMDDiskUsage.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/23.
//

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const kHMDDiskUsageFileInfoPath;
extern NSString * _Nonnull const kHMDDiskUsageFileInfoSize;

@protocol HMDDiskVisitor <NSObject>

@optional
- (void)visitFile:(NSString * _Nullable)path size:(NSUInteger)size lastAccessDate:(NSDate * _Nullable)date;
- (void)visitDirectory:(NSString * _Nullable)path size:(NSUInteger)size fileCount:(NSUInteger)fileCount lastAccessDate:(NSDate * _Nullable)date;
/// deepLevel : 相对于传入目录的遍历深度
- (void)visitDirectory:(NSString * _Nullable)path size:(NSUInteger)size deepLevel:(NSUInteger)deepLevel;
/// deepLevel : 相对于传入目录的遍历深度
- (void)visitFile:(NSString * _Nullable)path size:(NSUInteger)size lastAccessDate:(NSDate * _Nullable)date deepLevel:(NSInteger)deepLevel;

@end

/**
 HMDDiskUsage 查询文件/文件夹大小 以及特定大文件在此的分布情况
 Multi-Thread: not safe
 */
@interface HMDDiskUsage : NSObject

/**
 当前的返回值是否正常;

 @return 是否是异常返回值;
 */
- (BOOL)isAbnormalReturnValue;

/**
 获取用户设备硬盘空间总大小，单位 byte

 @return 用户设备硬盘空间总大小
 */
+ (double)getTotalDiskSpace;

/**
 获取用户设备硬盘可用空间大小，单位 byte
 ⚠️ Don't call it in MainThread, may be trigger watch dog or ANR
 @return 用户设备硬盘可用空间大小
 */
+ (double)getFreeDiskSpace;

+ (NSInteger)getDisk300MBBlocksFrom:(NSInteger)oriSize;

#pragma mark --- wxb接口
/**
 合规 - 获取用户设备硬盘空间总大小的范围
 0: 16G
 1: 32G
 2: 64G
 3: 128G
 4: 256G
 5: 512G
 6: 依次递增 磁盘大小范围 16 * (2 ^ N)
 @return 用户设备硬盘空间总大小范围 N (代表磁盘大小: 16 * (2 ^ N))
 */
+ (int)getTotalDiskSizeLevel;

/**
 合规 - 返回磁盘大小 - 以 300MB 为一个单位; 如 return 3 代表剩余磁盘容量 3 * 300MB = 900MB

 @return 用户设备硬盘可用空间大小范围
 */
+ (NSInteger)getFreeDisk300MBlockSize;

/**
  get free disk space info by calling statf function
 合规 - 返回磁盘大小 - 以 300MB 为一个单位; 如 return 3 代表剩余磁盘容量 3 * 300MB = 90MB

 @return 用户设备硬盘可用空间大小范围
 */
+ (NSInteger)getFreeDisk300MBlockSizeByStatf;

#pragma mark --- end
/**
  get free disk space info by calling statf function
 */
+ (size_t)getFreeDiskSpaceByStatf;

/**
Get user device disk free space. Returns the size of the disk in the last few seconds and it will call 'getFreeDiskSpace'  if there is no cache
⚠️ Don't call it in MainThread, may be trigger watch dog or ANR

@return  Returns the size of the disk in the last few seconds
*/
+ (double)getRecentCachedFreeDiskSpace;

+ (void)setFreeDiskSpaceCacheTimeInterval:(NSTimeInterval)cacheTimeInterval;
// -- 合规接口
+ (NSInteger)getRecentCachedFreeDisk300MBlockSize;

/*
 true代表需要中断遍历，false会继续遍历
 */
typedef bool (^HMDDiskRecursiveSwitchBlock)(void);
/**
 获取文件夹大小（递归）
 
 @param folderPath 文件夹路径
 @return 文件夹大小（递归）
 */
+ (unsigned long long)folderSizeAtPath:(NSString * _Nullable)folderPath;

+ (unsigned long long)folderSizeAtPath:(NSString * _Nullable)folderPath switchBlock:(HMDDiskRecursiveSwitchBlock _Nullable)block;

+ (unsigned long long)folderSizeAtPath:(NSString * _Nullable)folderPath visitor:(id<HMDDiskVisitor> _Nullable)visitor;
+ (unsigned long long)folderSizeAtPath:(NSString * _Nullable)folderPath visitor:(id<HMDDiskVisitor> _Nullable)visitor switchBlock:(HMDDiskRecursiveSwitchBlock _Nullable)block;
/**
 获取指定目录下文件大小靠前的文件信息(大->小)

 @param path 相对NSHomeDictionary()的路径
 @param topRank 取文件大小前几大的文件
 @return 文件的信息(字典{kHMDDiskUsageFileInfoName: 路径, kHMDDiskUsageFileInfoSize: 大小})数组
 */
+ (NSArray<NSDictionary *> * _Nullable)fetchTopSizeFilesAtPath:(NSString * _Nullable)path topRank:(NSUInteger)topRank;

@end
