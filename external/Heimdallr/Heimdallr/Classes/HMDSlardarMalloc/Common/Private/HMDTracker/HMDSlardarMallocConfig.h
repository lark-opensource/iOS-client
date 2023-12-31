//
//  SlardarMallocConfig.h
//  SlardarMalloc
//
//  Created by bytedance on 2021/10/18.
//

#import "HMDTrackerConfig.h"

extern NSString *const _Nonnull kHMDModuleSlardarMalloc;

typedef NS_ENUM(NSUInteger, HMDSlardarMallocOptimizeType) {
    HMDSlardarMallocOptimizeTypeDefault,
    HMDSlardarMallocOptimizeTypeScalable, // scalable zone
    HMDSlardarMallocOptimizeTypeNano  // nano zone
};

@interface HMDSlardarMallocConfig : HMDTrackerConfig

/*
@property(nonatomic, assign) NSTimeInterval timeInterval;//@note:定时器的检测间隔，单位s
@property(nonatomic, assign) NSUInteger slardarMallocThreshold;//@note:连续3次即(3*time_interval秒)阈值超过/低于slardar_malloc_threshold时切换至自定义/系统内存分配器
@property(nonatomic, assign) NSUInteger tolerateNumber;//@note:物理内存连续数次超过xxx时切换至自定义内存分配器，默认为内存阈值-200M，单位字节
@property(nonatomic, assign) BOOL shouldChangeBackWhenMemoryBelowLimit; // 内存低于slardarMallocThreshold是否可以切换会系统malloc，默认为true
 */
@property(nonatomic, assign) HMDSlardarMallocOptimizeType optimizeType; // 优化类型nano/scalable
/*
 scalable optimize
 */
@property(nonatomic, assign) NSUInteger fileMaxCapacity;//memoryfile的最大容量,单位MB
@property(nonatomic, copy) NSString* _Nullable remappedTagArray; // 需要进行重映射的memory tag数组，以","分割
@property(nonatomic, assign) NSUInteger fileInitialSize; // 文件初始大小,单位MB
@property(nonatomic, assign) NSUInteger fileGrowStep;  // 文件扩容的最小单位,单位MB
@property(nonatomic, assign) NSUInteger mlockSliceCount; // mlock分片的个数
@property(nonatomic, assign) NSUInteger mlockType; // mlock的类型，对应HMDMMapMlockType
/*
 nano optimize
 */
@property(nonatomic, assign) NSUInteger nanoZoneOptimizeSize; // nano优化的大小 单位M
@property(nonatomic, assign) BOOL nanoZoneOptimizeNeedMlock;  // nano优化是否需要mlock
@property(nonatomic, assign) BOOL nanoZoneOptimizeNeedDuration; // nano优化是否需要统计挂起时长
@end
