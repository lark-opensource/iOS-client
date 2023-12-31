//
//  HMDDiskUsage+Private.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/3/4.
//

#import "HMDDiskUsage.h"

@interface HMDDiskUsage (Private)

/**
 初始化方法
 
 @param days 指多少天算过期
 @param size 指文件夹大小超过多大算不合法
 @param count 指文件夹里文件个数超过多少算不合法
 @param ignoredRelativePathes 沙盒内的相对路径 (传入后, 会忽略改文件夹位置下所以文件的统计信息 相对于: NSHomeDictionary()位置)
 @param checkSparseFile 是否开启 sparse 文件检测
 @param leastPercentage 多大的 "假占用空间" 比例被认为是 sparse file (两者同时满足)
 @param leastDifferSizeInBytes 多大的 "假占用空间" 大小被认为是 sparse file
 @param minCollectSize 异常文件(夹), 过期数据取前几的数据, 0 代表所有
 @param visitors 遍历文件/目录时回调 visitor
 @return diskUsage
 */
- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                      minCollectSize:(NSUInteger)minCollectSize
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors;

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes
                            visitors:(NSHashTable<id<HMDDiskVisitor>> *)visitors;

- (instancetype)initWithOutdatedDays:(double)days
                  abnormalFolderSize:(NSInteger)size
            abnormalFolderFileNumber:(NSInteger)count
                ignoreRelativePathes:(NSArray<NSString *> *)ignoredRelativePathes
                     checkSparseFile:(BOOL)checkSparseFile
     sparseFileLeastDifferPercentage:(double)leastPercentage
           sparseFileLeastDifferSize:(NSUInteger)leastDifferSizeInBytes;

/**
 获取当前App占用硬盘空间总大小，单位 byte
 
 @return 当前App占用硬盘空间总大小
 */
- (double)getThisAppSpace;

/**
 获取当前目录占用硬盘空间总大小，单位 byte

 @return 获取当前目录占用硬盘空间总大小
 */
- (long long)getCurrenFolderSpace;

/**
 获取文件大小
 
 @param filePath 文件路径
 @return 文件大小
 */
- (unsigned long long)fileSizeAtPath:(NSString *)filePath;
/**
 获取指定目录下的硬盘空间大小明细，topN的文件排序
 
 @param folderPath 指定目录
 @param topRank 指定关心前多少大小的文件
 @return 指定目录下的硬盘空间大小明细
 */
- (NSArray<NSDictionary *> *)getFileListsAtPath:(NSString *)folderPath forTopRank:(NSUInteger)topRank;

/**
 获取当前App硬盘空间大小明细
 
 @param topRank 指定关心前多少大小的文件
 @return 当前App硬盘空间大小明细
 */
- (NSArray<NSDictionary *> *)getAppFileListForTopRank:(NSUInteger)topRank;
- (NSArray<NSDictionary *> *)getAppTopUsageFile;

- (NSArray<NSDictionary *> *)getExceptionFolders;
- (NSArray<NSDictionary *> *)getExceptionFoldersWithTopRank:(NSInteger)topRank;

- (NSArray<NSDictionary *> *)getOutDateFiles;
- (NSArray<NSDictionary *> *)getOutDateFilesWithTopRank:(NSInteger)topRank;

/**
 获取用户设备硬盘可用空间大小，单位 byte; 添加卡死保护，当在主线程调用时，等待超时之后返回上一次计算的值
 
 @param waitTime 等待时长(s)
 @return 用户设备硬盘可用空间大小
 */
+ (double)getFreeDiskSpaceWithWaitTime:(NSTimeInterval)waitTime;

/**
 合规 - 返回磁盘大小 - 以 300MB 为一个单位; 如 return 3 代表剩余磁盘容量 3 * 300MB = 900MB; 添加卡死保护， 当在主线程调用时， 等待超时之后返回上一次计算的值
 
 @param waitTime 等待时长(s)
 @return 用户设备硬盘可用空间大小范围
 */
+ (NSInteger)getFreeDisk300MBlockSizeWithWaitTime:(NSTimeInterval)waitTime;

@end
