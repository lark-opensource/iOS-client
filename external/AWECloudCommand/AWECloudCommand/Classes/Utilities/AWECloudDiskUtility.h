//
//  AWECloudDiskUtility.h
//  AWECloudCommand
//
//  Created by songxiangwu on 2017/9/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECloudDiskUtility : NSObject

// Total Disk Space
+ (nullable NSString *)diskSpace;

// Total Free Disk Space
+ (nullable NSString *)freeDiskSpace:(BOOL)inPercent;

// Total Used Disk Space
+ (nullable NSString *)usedDiskSpace:(BOOL)inPercent;

// Get the total disk space in long format
+ (long long)longDiskSpace;

// Get the total free disk space in long format
+ (long long)longFreeDiskSpace;

// Get the size of a single file in long format
+ (long long)fileSizeAtPath:(NSString *)filePath;

// Get the size of a folder in long format
+ (long long)folderSizeAtPath:(NSString *)folderPath;

@end

NS_ASSUME_NONNULL_END
