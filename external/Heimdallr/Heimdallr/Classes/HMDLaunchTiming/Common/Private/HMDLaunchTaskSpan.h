//
//  HMDLaunchStageInfo.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/6/22.
//

#import <Foundation/Foundation.h>
#import "HMDLaunchTimingRecord.h"
#import "HMDLaunchTimingDefine.h"

typedef struct {
    u_int64_t proc_exec;
    u_int64_t cls_load;
    u_int64_t finish_launch;
    u_int64_t first_render;
    u_int64_t user_finish;
    u_int64_t start;
    u_int64_t end;
    bool prewarm;
} HMDLaunchTimingStruct;

typedef NS_ENUM(NSUInteger, HMDLaunchTimingCollectType) {
    HMDLaunchTimingCollectFromDefault = 1,
    HMDLaunchTimingCollectFromUser = 2,
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark
#pragma mark --- HMDLaunchTaskSpan
@interface HMDLaunchTaskSpan : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *module;
@property (nonatomic, assign) long long start;
@property (nonatomic, assign) long long end;
@property (nonatomic, assign) BOOL isFinish;
@property (nonatomic, assign) BOOL isSubThread;

+ (instancetype)defaultWithName:(NSString *)name start:(long long)start end:(long long)end;

+ (NSArray<HMDLaunchTaskSpan *> *)defaultSpansWithTimingStruct:(HMDLaunchTimingStruct)timing
                                                   endTaskName:(NSString *)endTaskName;

@end

#pragma mark
#pragma mark --- HMDLaunchTraceTimingInfo
@interface HMDLaunchTraceTimingInfo : NSObject

@property (nonatomic, strong) NSArray<HMDLaunchTaskSpan *> *taskSpans;
@property (nonatomic, assign) long long start;
@property (nonatomic, assign) long long end;
@property (nonatomic, assign) NSInteger collectFrom;
@property (nonatomic, assign) BOOL prewarm;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *customLaunchModel;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *pageType;

@end

#pragma mark
#pragma mark --- HMDLaunchTimingRecord Category
@interface HMDLaunchTimingRecord (LaunchStage)

- (void)hmd_insertTraceModel:(HMDLaunchTraceTimingInfo *)timing;

@end

NS_ASSUME_NONNULL_END
