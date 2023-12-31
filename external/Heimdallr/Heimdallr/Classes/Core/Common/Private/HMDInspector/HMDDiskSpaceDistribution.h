//
//	HMDDiskSpaceDistribution.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/6/3. 
//

#import <Foundation/Foundation.h>

// The greater the number, the higher the priority and the earlier the release
typedef NS_ENUM(NSUInteger, HMDDiskSpacePriority) {
    HMDDiskSpacePriorityMemoryGraph = 0,    // memorygraph
    HMDDiskSpacePriorityClassCoverage,       // class coverage
    HMDDiskSpacePriorityOOMLog,             // matrix
    HMDDiskSpacePriorityDataBase,           // database but useless
    HMDDiskSpacePriorityCoreDump,           // coredump
    
    HMDDiskSpacePriorityWatchdog,
    HMDDiskSpacePriorityOOMCrash,
    HMDDiskSpacePriorityCrash,
    
    HMDDiskSpacePriorityMax                 // 最高级别的清理
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

// The less the index, the earlier the release
// The index is also a priority of module
static NSArray* _Nonnull removableFileModules (void)
{
    /*
     支持清理的模块：MemoryGraph、Matrix、CoreDump。DataBase其实不支持
     */
    return @[
        @"HMDMemoryGraphUploader",
        @"HMDClassCoverageUploader",
        @"HMDMatrixMonitor",
        @"HMDRecordStore",
        @"HMDCDUploader"
    ];
}

#pragma clang diagnostic pop


NS_ASSUME_NONNULL_BEGIN

@protocol HMDInspectorDiskSpaceDistribution <NSObject>

@optional

+ (NSString *)removableFileDirectoryPath;

// Designate paths to be release and the others that under 'removableFileDirectoryPath' do not release
+ (NSArray *)removableFilePaths;

- (BOOL)removeFileImmediately:(NSArray *)pathArr;

@end


/// Call back
/// @param stop Make function stop traverseing
/// @param moreSpace Maybe there are more spaces for file
typedef void(^HMDDSDEnumerateBlock)(BOOL *stop, BOOL moreSpace);

@interface HMDDiskSpaceDistribution : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)registerModule:(id<HMDInspectorDiskSpaceDistribution>)module;

/// Get more disk space from remvable files.
/// Call back on the other thread asynchronously.
/// @param size     need space size, unit : byte
/// @param priority HMDDiskSpacePriority
/// @param block    traverse files and call back until "*stop = YES"
- (void)getMoreDiskSpaceWithSize:(size_t)size
                        priority:(HMDDiskSpacePriority)priority
                      usingBlock:(HMDDSDEnumerateBlock)block;

@end


@interface HMDDSDModuleInfo : NSObject

@end

NS_ASSUME_NONNULL_END
