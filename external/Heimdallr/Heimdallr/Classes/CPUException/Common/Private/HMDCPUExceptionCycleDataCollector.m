//
//  HMDCPUExceptionPool.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/4/24.
//

#import "HMDCPUExceptionCycleDataCollector.h"
#import "HMDCPUExceptionV2Record.h"
#import "HMDCPUThreadInfo.h"
#import "HMDThreadBacktrace.h"
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"
#import "HMDBinaryImage.h"
#import "HMDImageLog.h"
#import "HMDThreadBacktraceFrame.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HeimdallrUtilities.h"
#import "HMDInfo+SystemInfo.h"
#import "NSArray+HMDSafe.h"
#import "HMDCPUBinaryImageInfo.h"
#import "HMDCPUExceptionSampleInfo.h"

#define kHMDCPUExceptionIssueDeep 5
#define kHMDCPUExceptionMaxStackTraceLength 50

typedef NSString* HMDThreadCallTree;
static HMDThreadCallTree const kHMDThreadCallTreeHeaderKey = @"kHMDThreadCallTreeHeaderKey";  // 栈顶函数为header (方便生成总调用树)
static HMDThreadCallTree const kHMDThreadCallTreeInvertHeaderKey = @"kHMDThreadCallTreeInvertHeaderKey"; // 栈底函数为header （方便生成线程调用树）

#pragma mark
#pragma mark ---------- HMDCPUExceptionSamplePool ----------

@interface HMDCPUExceptionCycleDataCollector ()

@property (nonatomic, assign) NSInteger sampleCount;
@property (nonatomic, strong) NSMutableArray *collectInfo;
@property (nonatomic, strong) NSMutableDictionary *sceneDict;
@property (nonatomic, strong) NSMutableDictionary *customSceneDict;
@property (nonatomic, assign) NSInteger thermalSeriousState;
@property (nonatomic, assign) int totalThreadCount;
@property (nonatomic, assign) float totalCPUUsage;
@property (nonatomic, strong) NSMutableSet<NSString *> *imageNameSet;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *imageCPUArchMap;
@property (nonatomic, assign) BOOL isFindUserNode;
@property (nonatomic, assign) BOOL hasLowPowerModel;
@property (nonatomic, copy) NSString *possibleScene;
@property (nonatomic, copy) NSDictionary<NSString *, HMDBinaryImage *> *imageUUIDMap;
@property (nonatomic, strong) HMDCPUBinaryImageInfo *binaryInfo;

@end

@implementation HMDCPUExceptionCycleDataCollector

#pragma mark --- super method ---
- (instancetype)init {
    self = [super init];
    if (self) {
        self.collectInfo = [NSMutableArray array];
        self.sceneDict = [NSMutableDictionary dictionary];
        self.customSceneDict = [NSMutableDictionary dictionary];
        self.imageNameSet = [NSMutableSet set];
        self.thermalSeriousState = -1; // 默认没有状态;
        self.totalCPUUsage = 0;
        self.maxTreeDepth = 50;
        self.totalThreadCount = 0;
    }
    return self;
}

- (void)preparImageUUIDMap { // v2 版本不再调用
    long long startTime = 0;
    if (hmd_log_enable()) {
        startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    self.imageUUIDMap = [[HMDCPUExceptionCycleDataCollector fetchCurrenImageList] copy];
    self.imageCPUArchMap = [NSMutableDictionary dictionary];
    if (hmd_log_enable()) {
        long long endTime = [[NSDate date] timeIntervalSince1970] * 1000;
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr CPU Exception Get Image List Cost: %lld ms",endTime - startTime);
    }
}

+ (NSDictionary *)fetchCurrenImageList {
    static NSDictionary *imageUUIDOnceMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *imageUUIDMap = [NSMutableDictionary dictionary];
        
        [HMDBinaryImage enumerateImagesUsingBlock:^(HMDBinaryImage *imageInfo){
            [imageUUIDMap setValue:imageInfo forKey:imageInfo.name];
        }];
        
        imageUUIDOnceMap = [imageUUIDMap copy];
    });
    return imageUUIDOnceMap;
}

#pragma mark --- public method implementation ---
- (void)pushOnceSampledInfo:(HMDCPUExceptionSampleInfo *)sampleInfo {
    if (!sampleInfo) { return; }
    [self.collectInfo hmd_addObject:sampleInfo];
    for (HMDCPUThreadInfo *threadInfo in sampleInfo.threadsInfo) {
        for (HMDThreadBacktraceFrame *backTraceFrame in threadInfo.backtrace.stackFrames) {
            if (backTraceFrame.imageName && backTraceFrame.imageName.length > 0) {
                [self.imageNameSet addObject:backTraceFrame.imageName];
            }
        }
    }
    if (!self.binaryInfo || !self.binaryInfo.isBinaryLoad) {
        self.binaryInfo = [[HMDCPUBinaryImageInfo alloc] init];
        [self.binaryInfo loadBinaryImage];
    }
}

- (HMDCPUExceptionV2Record *_Nullable)makeSummaryInExceptionCycle  {
    if (self.collectInfo.count == 0) {return nil;}

    HMDCPUExceptionV2Record *record = [HMDCPUExceptionV2Record record];
    NSArray *exceptionInfo = [self.collectInfo copy];

    double peakUsage = 0;
    double totoalUsage = 0;
    BOOL hasLowPowerModel = NO;
    NSInteger thermalState = -1;
    int totalThreadCount = 0;
    int sampleCount = 0;

    NSMutableSet *appStatesSet = [NSMutableSet set];
    NSMutableArray<HMDCPUThreadInfo *> *threadsInfo = [NSMutableArray array];
    for (HMDCPUExceptionSampleInfo *sampleInfo in exceptionInfo) {
        if (sampleInfo.timestamp < self.startTime) { continue; }
        if (sampleInfo.threadsInfo.count > 0) {
            [threadsInfo addObjectsFromArray:sampleInfo.threadsInfo?:@[]];
        }
        if (sampleInfo.averageUsage > peakUsage) {
            peakUsage = sampleInfo.averageUsage;
        }
        if (sampleInfo.thermalModel > thermalState) {
            thermalState = sampleInfo.thermalModel;
        }
        if (sampleInfo.isLowPowerModel) { // 只要有一次是低电量模式,本次循环采样就默认为 低电量模式
            hasLowPowerModel = YES;
        }

        totalThreadCount += sampleInfo.threadCount;
        totoalUsage += sampleInfo.averageUsage;
        sampleCount ++;
        // 场景
        if (sampleInfo.scene) {
            NSNumber *number = [self.sceneDict valueForKey:sampleInfo.scene];
            if (number) {
                int newValue = (number.intValue + 1);
                [self.sceneDict setValue:@(newValue) forKey:sampleInfo.scene];
            } else {
                [self.sceneDict setValue:@(1) forKey:sampleInfo.scene];
            }
        }
        if (sampleInfo.customScene) {
            NSInteger newValue = [self.customSceneDict hmd_integerForKey:sampleInfo.customScene] + 1;
            [self.customSceneDict setValue:@(newValue) forKey:sampleInfo.customScene];
        }
        [appStatesSet addObject: sampleInfo.isBack ? @"back": @"front"];
    }

    if (sampleCount <= 0) { return nil ; }
    // thread back trace
    record.threadsInfo = threadsInfo;
    record.binaryImages = [self.binaryInfo getBinaryImagesWithBinaryImages:self.imageNameSet.allObjects];
    self.sampleCount = sampleCount;
    record.peakUsage = peakUsage;
    int averageThreadCount = totalThreadCount / sampleCount;
    float averageUsage = totoalUsage / (float)sampleCount;
    record.threadCount = averageThreadCount;
    record.averageUsage = averageUsage;
    record.sampleCount = sampleCount;
    record.thermalState = thermalState;
    record.isLowPowerModel = hasLowPowerModel;
    if (appStatesSet.count > 0) {
        record.appStates = appStatesSet.allObjects;
    }

    [self fetchBasicEvnInfoWithRecord:record];
    [self.collectInfo removeAllObjects];

    return record;
}

/// must call it  after makeCallTreeAndFindCPUPeakInfo
- (void)fetchBasicEvnInfoWithRecord:(HMDCPUExceptionV2Record *)record {
    record.configUsage = self.thresholdConfig;
    record.processorCount = [NSProcessInfo processInfo].processorCount;
    record.startTime = self.startTime;
    record.endTime = self.endTime;
    record.lastScene = DC_IS(DC_OB(DC_CL(HMDUITrackerManager, sharedManager), scene), NSString);
    record.bundleId = [[HMDInfo defaultInfo] bundleIdentifier];
    NSString *osVersion = HeimdallrUtilities.systemVersion;
    NSString *osBuildVersion = [[HMDInfo defaultInfo] osVersion];
    NSString *fullOSVersion = [NSString stringWithFormat:@"%@ (%@)",osVersion, osBuildVersion];
    record.osVersion = fullOSVersion;
    record.customScene = [self getMostScene:self.customSceneDict];
    record.possibleScene = record.customScene ? record.customScene : [self getMostScene:self.sceneDict];
}

- (NSString *)getMostScene:(NSDictionary *)sceneDict {
    __block NSString *mostScene = nil;
    __block int maxValue = 0;
    [sceneDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        int value = ((NSNumber *)obj).intValue;
        if (value > maxValue) {
            maxValue = value;
            mostScene = key;
        }
    }];
    return maxValue ? mostScene : nil;
}

- (void)clearAllSampleInfo {
    [self.collectInfo removeAllObjects];
}

#pragma mark --- override setter ---

- (void)dealloc {

}

@end
