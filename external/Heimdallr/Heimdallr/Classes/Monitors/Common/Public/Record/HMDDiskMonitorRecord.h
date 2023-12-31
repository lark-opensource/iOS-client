//
//  HMDDiskMonitorRecord.h
//  Heimdallr
//
//  Created by joy on 2018/6/13.
//

#import <Foundation/Foundation.h>
#import "HMDMonitorRecord.h"

@interface HMDDiskMonitorRecord : HMDMonitorRecord

@property (nonatomic, assign) HMDMonitorRecordValue appUsage;               // App占用磁盘空间
@property (nonatomic, assign) HMDMonitorRecordValue totalCapacity;          // 用户设备磁盘空间容量
@property (nonatomic, assign) HMDMonitorRecordValue freeCapacity;           // 用户设备可用磁盘空间容量
@property (nonatomic, assign) HMDMonitorRecordValue appRatio;               // App占用磁盘空间/用户磁盘剩余空间
@property (nonatomic, assign) HMDMonitorRecordValue pageUsage;              // 特定页面造成的磁盘空间增量
@property (nonatomic, assign) NSInteger freeBlockCounts;
@property (nonatomic, assign) NSInteger totalDiskLevel;
@property (nonatomic, assign) NSInteger documentsAndDataUsage; // documents and data size
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *topFileLists;        // 最大的topN文件
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *exceptionFolders;    // 大小或数量异常的文件夹
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *outdatedFiles;       // 过期的文件或者文件夹
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *diskInfo;       // 磁盘目录信息


@end
