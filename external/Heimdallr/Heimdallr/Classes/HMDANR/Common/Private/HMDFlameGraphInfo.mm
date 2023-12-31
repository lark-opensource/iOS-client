//
//  HMDFlameGraphInfo.m
//  Heimdallr
//
//  Created by ByteDance on 2023/3/16.
//

#import "HMDFlameGraphInfo.h"
#import "HMDThreadBacktraceFrame.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDThreadBacktrace.h"
#import "HMDInfo+DeviceInfo.h"
#import "HMDBinaryImage.h"

static NSString *const kHMDCallTreeNodeAddress = @"address";
static NSString *const kHMDCallTreeNodeImageName = @"image_name";
static NSString *const kHMDCallTreeNodeImageAddress = @"image_address";
static NSString *const kHMDCallTreeNodeAppNode = @"is_app_node";
static NSString *const kHMDCallTreeImageUUID = @"image_uuid";
static NSString *const kHMDCallTreeImageCPUArch = @"cpu_arch";

@interface HMDFlameGraphInfo()

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, NSDictionary *> *binaryMap;
@property (nonatomic, assign, readwrite) BOOL isBinaryLoad;
@property (nonatomic, strong) NSMutableDictionary *cpuArchMap;
@property (nonatomic, strong) NSMutableSet<NSString *> *imageNameSet;

@end

@implementation HMDFlameGraphInfo

- (instancetype)initWithBacktraces:(std::vector<hmdbt_backtrace_t *>&)bts {
    self = [super init];
    if (self) {
        [self defaultInitialize];
        [self setupWithParams:bts];
    }
    
    return self;
}


- (void)defaultInitialize {
    self.cpuArchMap = [NSMutableDictionary dictionary];
    self.imageNameSet = [NSMutableSet set];
    self.binaryMap = [NSDictionary dictionary];
    self.isBinaryLoad = NO;
}

- (void)setupWithParams:(std::vector<hmdbt_backtrace_t *>&) bts {
    NSMutableArray<HMDThreadBacktrace *> *backtraces = [NSMutableArray array];
    for(auto bt: bts) {
        HMDThreadBacktrace *backtrace = [[HMDThreadBacktrace alloc] init];
        NSMutableArray<HMDThreadBacktraceFrame *> *stackFrames = [[NSMutableArray alloc] init];
        if (bt->frames != NULL) {
            for (int i = 0; i < bt->frame_count; i++) {
                HMDThreadBacktraceFrame *frame = [[HMDThreadBacktraceFrame alloc] init];
                hmdbt_frame_t *originFrame = &(bt->frames[i]);
                frame.stackIndex = originFrame->stack_index;
                frame.address = originFrame->address;
                [stackFrames addObject:frame];
            }
        }
        backtrace.stackFrames = stackFrames;
        hmdbt_dealloc_bactrace(&bt, 1);
        [backtraces addObject:backtrace];
    }
    self.backtraces = backtraces;
}

- (NSArray *)reportArray {
    NSMutableArray *backTraceArray = [NSMutableArray array];
    for(HMDThreadBacktrace *backtrace in self.backtraces) {
        NSMutableArray *frameArray = [NSMutableArray array];
        for (HMDThreadBacktraceFrame *backTraceFrame in backtrace.stackFrames) {
            [backTraceFrame symbolicate:NO];
            NSString *address = [NSString stringWithFormat:@"0x%lx", backTraceFrame.address];
            NSString *imageAddress = [NSString stringWithFormat:@"0x%lx", backTraceFrame.imageAddress];
            BOOL isUserNode = [backTraceFrame isAppAddress];
            if (backTraceFrame.imageName && backTraceFrame.imageName.length > 0) {
                [self.imageNameSet addObject:backTraceFrame.imageName];
            }
            NSDictionary *backTraceDict = @{
                kHMDCallTreeNodeAddress: address ?: @"",
                kHMDCallTreeNodeImageName: backTraceFrame.imageName ?: @"",
                kHMDCallTreeNodeImageAddress: imageAddress ?: @"",
                kHMDCallTreeNodeAppNode: @(isUserNode)
            };
            [frameArray hmd_addObject:backTraceDict];
        }
        [backTraceArray hmd_addObject:frameArray];
    }
    return backTraceArray ?: @[];
}

- (nullable NSDictionary<NSString*,NSDictionary *> *)reportImages{
    return [self getBinaryImagesWithBinaryImages:self.imageNameSet.allObjects];
}

- (nullable NSDictionary<NSString *,NSDictionary *> *)getBinaryImagesWithBinaryImages:(NSArray<NSString *> *)imageNames {
    NSMutableDictionary *binaryImageDicts = [NSMutableDictionary dictionary];
    if (!self.isBinaryLoad) {
        [self loadBinaryImage];
    }

    for (NSString *curName in imageNames) {
        NSDictionary *imageInfo = [self.binaryMap hmd_objectForKey:curName class:[NSDictionary class]];
        [binaryImageDicts hmd_setObject:imageInfo forKey:curName];
    }

    return [binaryImageDicts copy];
}

- (void)loadBinaryImage {
    if (self.binaryMap.count > 0) { return ; }
    NSMutableDictionary *imageUUIDMap = [NSMutableDictionary dictionary];
    [HMDBinaryImage enumerateImagesUsingBlock:^(HMDBinaryImage *imageInfo) {
            NSString *imageUUID = imageInfo.uuid;
            NSString *cpuArch = [self getCPUArchWithMajor:imageInfo.cpuType minor:imageInfo.cpuSubType];
            NSDictionary *infoDict = @{
                kHMDCallTreeImageUUID: imageUUID ?: @"",
                kHMDCallTreeImageCPUArch: cpuArch ?: @"",
            };
            [imageUUIDMap hmd_setSafeObject:infoDict forKey:imageInfo.name];
    }];
    self.isBinaryLoad = YES;
    self.binaryMap = imageUUIDMap;
}



- (nullable NSString *)getCPUArchWithMajor:(cpu_type_t)majorCode minor:(cpu_subtype_t)minorCode {
    if (!self.cpuArchMap) {
        self.cpuArchMap = [NSMutableDictionary dictionary];
    }
    NSString *searchKey = [NSString stringWithFormat:@"%d+%d", majorCode, minorCode];
    NSString *cpuArch = [self.cpuArchMap hmd_objectForKey:searchKey class:NSString.class];
    if (!cpuArch) {
        cpuArch = [HMDInfo CPUArchForMajor:majorCode minor:minorCode];
        [self.cpuArchMap hmd_setSafeObject:cpuArch forKey:searchKey];
    }
    return cpuArch;
}

@end
