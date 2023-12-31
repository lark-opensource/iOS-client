//
//  HMDCaptureBacktraceManager.m
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/21.
//

#import "HMDCaptureBacktraceManager.h"
#import "HMDThreadBacktrace.h"
#import "HMDBinaryImage.h"
#import "HMDThreadBacktraceFrame.h"
#import "HMDALogProtocol.h"
#import "HMDDeviceTool.h"
#import "HMDInfo+AppInfo.h"
#import "HeimdallrUtilities.h"
#import "HMDInfo+SystemInfo.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDDynamicCall.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDMonitorService.h"

NSString *const kHMDCaptureBacktraceAddress = @"address";
NSString *const kHMDCaptureBacktraceImageName = @"image_name";
NSString *const kHMDCaptureBacktraceImageAddress = @"image_address";
NSString *const kHMDCaptureBacktraceImageUUID = @"image_uuid";
NSString *const kHMDCaptureBacktraceImagePath = @"image_path";
NSString *const kHMDCaptureBacktraceImageIsMainBinary = @"is_main_binary";
NSString *const kHMDCaptureBacktraceImageCPUArch = @"cpu_arch";
NSString *const kHMDCaptureBacktraceAppNode = @"is_app_node";

@interface HMDCaptureBacktraceManager()

@property(nonatomic, assign, setter=setValid:)BOOL isValid;
@property(nonatomic, assign)long long startTime;
@property(nonatomic, assign)long long finishTime;
@property (nonatomic, strong) NSMutableArray<HMDThreadBacktrace *> *backtraces;
@property (nonatomic, copy) NSDictionary *imageUUIDMap;

@end

@implementation HMDCaptureBacktraceManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isValid = YES;
        _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
        _backtraces = [NSMutableArray array];
    }
    return self;
}

- (void)addBacktrace:(HMDThreadBacktrace *)backtrace
{
    if (!backtrace || !self.isValid) return;
    if ((self.backtraceThreshold > 0) && (self.backtraces.count > self.backtraceThreshold)) {
        self.isValid = NO;
    }
    else
    {
        if ([backtrace isKindOfClass:HMDThreadBacktrace.class]) {
            [self.backtraces addObject:backtrace];
        }
    }
}

- (void)finishRecord:(BOOL)uploadData withReportBlock:(nonnull void (^)(void))block
{
    if (self.isValid) {
        self.isValid = uploadData;
        if (self.isValid) {
            [self processRecord:block];
        }
    }
}

- (NSArray *)CaptureBacktracesReportData
{
    NSDictionary *dict = [self reportDictionary];
    NSMutableArray *dataArray = [NSMutableArray array];
    if (dict) {
        [dataArray addObject:dict];
    }
    return dataArray.copy;
}

#pragma mark - private method

- (void)setValid:(BOOL)isValid
{
    _isValid = isValid;
    if (!_isValid) {
        [self dropRecord];
    }
}

- (void)processRecord:(nonnull void (^)(void))block
{
    self.finishTime = [[NSDate date] timeIntervalSince1970] * 1000;
    long long time= self.backtraces.count * 1000 / 60;
    if ((self.errorTime > 0) && (self.finishTime - self.startTime - time > self.errorTime)) {
        self.isValid = NO;
    }
    else
    {
        if (block)
        {
            block();
        }
    }
}

- (void)dropRecord
{
    if (self.backtraces.count>0) {
        NSString *reasonStr = @"dropLaunchRecord";
        NSDictionary *category = @{@"reason":reasonStr};
        NSDictionary *metric = @{@"recordCount":@(self.backtraces.count)};

        [HMDMonitorService trackService:@"hmd_app_launch_analyse" metrics:metric dimension:category extra:nil];
        
        
        [self.backtraces removeAllObjects];
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

- (void)preparImageUUIDMap {
    long long startTime = 0;
    if (hmd_log_enable()) {
        startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    self.imageUUIDMap = [[HMDCaptureBacktraceManager fetchCurrenImageList] copy];
    if (hmd_log_enable()) {
        long long endTime = [[NSDate date] timeIntervalSince1970] * 1000;
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr CaptureBacktrace Get Image List Cost: %lld ms",endTime - startTime);
    }
}

- (NSArray *)getCaptureBacktraces
{
    NSMutableArray *arrM = [NSMutableArray array];
    for (HMDThreadBacktrace *backtrace in self.backtraces) {
        NSMutableArray *frames = [NSMutableArray array];
        for (HMDThreadBacktraceFrame *frame in backtrace.stackFrames) {
            HMDBinaryImage *binaryImage = [self.imageUUIDMap hmd_objectForKey:frame.imageName?:@"" class:[HMDBinaryImage class]];
            if (!binaryImage) continue;
            
            char * _Nullable arch = hmd_cpu_arch(binaryImage.cpuType, binaryImage.cpuSubType, false);
            
            NSString *cpuArch;
            
            if(arch) cpuArch = [NSString stringWithUTF8String:arch];
            else     cpuArch = @"unknown";
            
            NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
            NSString *str = [NSString stringWithFormat:@"0x%lx",frame.address];
            [dicM hmd_setObject:str forKey:kHMDCaptureBacktraceAddress];
            str = frame.imageName ?: @"";
            [dicM hmd_setObject:str forKey:kHMDCaptureBacktraceImageName];
            str = [NSString stringWithFormat:@"0x%lx",frame.imageAddress];
            [dicM hmd_setObject:str forKey:kHMDCaptureBacktraceImageAddress];
            str = binaryImage.uuid?:@"";
            [dicM hmd_setObject:str forKey:kHMDCaptureBacktraceImageUUID];
            str = binaryImage.path?:@"";
            [dicM hmd_setObject:str forKey:kHMDCaptureBacktraceImagePath];
            [dicM hmd_setObject:@(binaryImage.isExecutable) forKey:kHMDCaptureBacktraceImageIsMainBinary];
            [dicM hmd_setObject:cpuArch forKey:kHMDCaptureBacktraceImageCPUArch];
            [dicM hmd_setObject:@([frame isAppAddress]) forKey:kHMDCaptureBacktraceAppNode];
            [frames addObject:dicM.copy];
        }
        [arrM addObject:frames.copy];
    }
    return arrM.copy;
}

- (NSDictionary *)reportDictionary
{
    if (!self.imageUUIDMap) {
        [self preparImageUUIDMap];
    }
    NSArray *arr = [self getCaptureBacktraces];
    NSMutableDictionary *reportDict = [NSMutableDictionary dictionary];
    if(!arr) {
        return nil;
    }
    [reportDict hmd_setObject:arr forKey:@"main_thread_backtraces"];
    [reportDict hmd_setObject:[[HMDInfo defaultInfo] bundleIdentifier]?:@"unknown" forKey:@"bundle_id"];
    [reportDict hmd_setObject:@"capture_backtraces" forKey:@"event_type"];
    [reportDict hmd_setObject:@(self.startTime) forKey:@"start_time"];
    [reportDict hmd_setObject:@(self.finishTime) forKey:@"end_time"];
    [reportDict hmd_setObject:self.sceneType?:@"unknown" forKey:@"scene_type"];
    NSString *OSVersion = HeimdallrUtilities.systemVersion;
    NSString *OSBuildVersion = [[HMDInfo defaultInfo] osVersion];
    NSString *fullOSVersion = [NSString stringWithFormat:@"%@ (%@)",OSVersion, OSBuildVersion];
    [reportDict hmd_setObject:fullOSVersion?:@"unknown" forKey:@"os_full_version"];
    
    if (hermas_enabled()) {
        NSInteger sequenceCode = [[HMDHermasCounter shared] generateSequenceCode:@"CaptureBacktrace"];
        [reportDict setValue:@(sequenceCode) forKey:@"sequence_code"];
    }
    return reportDict.copy;
}

@end
