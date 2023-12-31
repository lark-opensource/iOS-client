//
//  HMDQoSMockerConfig.m
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/4/12.
//

#import "HMDQoSMockerConfig.hpp"
#import "HMDFileTool.h"
#import "HMDJSON.h"
#import "NSDictionary+HMDSafe.h"
#import "HeimdallrUtilities.h"

@interface HMDQoSMockerConfig() {
    dispatch_queue_t _flushQueue;
}

@end

@implementation HMDQoSMockerConfig

static NSString * const kHMD_Launch_Optimization_DirectoryName = @"HMD_Launch_Info";
static NSString * const kHMDConfigKey_enable_key_queue_collector = @"enable_key_queue_collector";
static NSString * const kHMDConfigKey_enable_qos_mocker = @"enable_qos_mocker";
static NSString * const kHMDConfigKey_white_list_queue_array = @"white_list_queue_array";
static NSString * const kHMDConfigKey_key_queue_array = @"key_queue_array";

bool HMDQosMockerConfigForCurrentLaunch::collectorEnabled{};
bool HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled{};
std::atomic_bool HMDQosMockerConfigForCurrentLaunch::launchFinished{};
std::unordered_set<std::string> *HMDQosMockerConfigForCurrentLaunch::whiteListQueue;

+ (instancetype)sharedConfig {
    static HMDQoSMockerConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[HMDQoSMockerConfig alloc] init];
    });
    return config;
}

- (instancetype)init {
    if (self = [super init]) {
        _flushQueue = dispatch_queue_create("com.hmd.qos_mocker_config_flush", NULL);
    }
    return self;
}

//Heimdallr 0.8.6
//{
//  "enable_open": true,
//  "white_list_queue_array": [
//    "clientDataWrapperQueue"
//  ],
//  "key_queue_array": [
//    [
//      "NSOperationQueue 0x283f36c80 (QOS: USER_INTERACTIVE)",
//      "Rust Client Send",
//      "Rust Client Callback",
//      "NSOperationQueue 0x283f36c80 (QOS: USER_INTERACTIVE)",
//      "Rust Client Send",
//      "Rust Client Callback",
//      "NSOperationQueue 0x283f36c80 (QOS: USER_INTERACTIVE)",
//      "Rust Client Send",
//      "Rust Client Callback",
//      "NSOperationQueue 0x283f36c80 (QOS: USER_INTERACTIVE)",
//      "Rust Client Send",
//      "Rust Client Callback",
//      "NSOperationQueue 0x283f0c4c0 (QOS: USER_INTERACTIVE)",
//      "com.apple.main-thread"
//    ]
//  ]
//}

- (void)flush {
    dispatch_async(_flushQueue, ^{
        if (hmdCheckAndCreateDirectory([HMDQoSMockerConfig switchDirectory])) {
            NSMutableDictionary *json = [@{
                kHMDConfigKey_enable_key_queue_collector: @(self.enableKeyQueueCollector),
                kHMDConfigKey_enable_qos_mocker: @(self.enableQosMocker),
            } mutableCopy];
            [json setValue:self.whiteListQueueNames forKey:kHMDConfigKey_white_list_queue_array];
            if (self.enableKeyQueueCollector) {
                //关闭采集后 key_queue_array 作废
                [json setValue:self.keyQueueNamesArray forKey:kHMDConfigKey_key_queue_array];
            }
            NSData *jsonData = [json hmd_jsonData];
            if (jsonData == nil) {
                jsonData = [@{} hmd_jsonData];
            }
            [jsonData writeToFile:[HMDQoSMockerConfig switchPath] atomically:YES];
        }
    });
}

- (void)readFromDisk {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[HMDQoSMockerConfig switchPath]]) {
        NSData *data = [NSData dataWithContentsOfFile:[HMDQoSMockerConfig switchPath]];
        id json = [data hmd_jsonObject];
        if ([json isKindOfClass:[NSDictionary class]]) {
            self.keyQueueNamesArray = [json hmd_arrayForKey:kHMDConfigKey_key_queue_array] ?: @[];
            self.whiteListQueueNames = [json hmd_arrayForKey:kHMDConfigKey_white_list_queue_array] ?: @[];
            HMDQosMockerConfigForCurrentLaunch::collectorEnabled = [json hmd_boolForKey:kHMDConfigKey_enable_key_queue_collector];
            HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled = [json hmd_boolForKey:kHMDConfigKey_enable_qos_mocker];
            if (HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled) {
                [self initWhiteListForCurrentLaunch];
            }
        }
        //此时先将 enable_key_queue_collector = 0 和 enable_qos_mocker = 0 写入，
        //防止因模块整体关闭，导致一直无法触发 flush，导致实际功能未关闭的问题
        [self flush];
    }
}

+ (NSString *)switchDirectory {
    NSString *dir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_Launch_Optimization_DirectoryName];
    return dir;
}

+ (NSString *)switchPath {
    NSString *dir = [self switchDirectory];
    return [dir stringByAppendingPathComponent:@"launch_mocker_switch.json"];
}

- (NSString *)updatedWhiteListQueueName:(NSString *)originQueueName {
    // NSOperationQueue 的 GCD 队列名是 "NSOperationQueue 0x104d0ed40 (QOS: UNSPECIFIED)"，所以直接处理成 NSOperationQueue
    if ([originQueueName hasPrefix:@"NSOperationQueue"]) {
        return @"NSOperationQueue";
    }
    return originQueueName;
}

- (void)initWhiteListForCurrentLaunch {
    HMDQosMockerConfigForCurrentLaunch::whiteListQueue = new std::unordered_set<std::string>();
    [[HMDQoSMockerConfig sharedConfig].keyQueueNamesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            NSArray *queueNames = (NSArray *)obj;
            [queueNames enumerateObjectsUsingBlock:^(id  _Nonnull nameObj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([nameObj isKindOfClass:[NSString class]]) {
                    NSString *queueName = nameObj;
                    NSString *updatedQueueName = [self updatedWhiteListQueueName:queueName];
                    std::string name = std::string([updatedQueueName UTF8String]);
                    HMDQosMockerConfigForCurrentLaunch::whiteListQueue->insert(name);
                }
            }];
        }
    }];
    [[HMDQoSMockerConfig sharedConfig].whiteListQueueNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *queueName = obj;
            std::string name = std::string([queueName UTF8String]);
            HMDQosMockerConfigForCurrentLaunch::whiteListQueue->insert(name);
        }
    }];
}

@end
