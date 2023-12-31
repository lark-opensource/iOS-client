//
//  HMDUIFrozenRecord.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import "HMDTrackerRecord.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHMDUIFrozenRecordTableName;

@interface HMDUIFrozenRecord : HMDTrackerRecord

// 监控数据
@property(nonatomic, strong) NSString *frozenType; //SendEvent or HitTest
@property(nonatomic, strong) NSString *targetViewDescription;
@property(nonatomic, strong) NSString *targetWindowDescription;
@property(nonatomic, strong) NSDictionary *viewHierarchy;
@property(nonatomic, strong) NSString *viewControllerHierarchy;
@property(nonatomic, strong) NSString *responseChain;
@property(nonatomic, strong) NSString *nearViewController;
@property(nonatomic, strong) NSString *nearViewControllerDesc;
@property(nonatomic, assign) NSTimeInterval startTS;
@property(nonatomic, assign) NSUInteger operationCount;
@property(nonatomic, assign, getter=isLaunchCrash) BOOL launchCrash;
@property(nonatomic, strong) NSDictionary *settings;

// 性能数据
@property(nonatomic, assign) double memoryUsage;
@property(nonatomic, assign) double freeMemoryUsage;
@property(nonatomic, assign) double freeDiskUsage;
@property (nonatomic, assign) NSInteger freeDiskBlocks;
@property(nonatomic, strong) NSString *_Nullable connectionTypeName;

// 业务数据
@property(nonatomic, strong) NSString *_Nullable internalSessionID;
@property(nonatomic, strong) NSString *_Nullable business;
@property(nonatomic, strong) NSString *_Nullable lastScene;
@property(nonatomic, strong) NSDictionary *_Nullable operationTrace;
@property(nonatomic, strong) NSDictionary<NSString*, id> *_Nullable customParams;
@property(nonatomic, strong) NSDictionary<NSString*, id> *_Nullable filters;

@end

NS_ASSUME_NONNULL_END
