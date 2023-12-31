//
//  TSPKNetworkConfigs.m
//  TSPrivacyKit
//
//  Created by admin on 2022/9/17.
//

#import "TSPKNetworkConfigs.h"
#import "TSPKNetworkEvent.h"
#import "TSPKLogger.h"
#import "TSPKNetworkUtil.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKNetworkAllowConfig

@end

@interface TSPKNetworkConfigs ()

@property (nonatomic, strong, nullable) NSDictionary *configs;
@property (nonatomic) NSInteger startGuardTimeInterval;
@property (nonatomic, strong, nullable) NSArray<TSPKNetworkAllowConfig *> *networkAllowConfigArray;

@end

@implementation TSPKNetworkConfigs

+ (instancetype)sharedConfigs {
    static TSPKNetworkConfigs *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [TSPKNetworkConfigs new];
    });
    return config;
}

+ (void)setConfigs:(NSDictionary *)configs {
    [[self sharedConfigs] setConfigs:configs];
    [self setupWithConfig];
    [[self sharedConfigs] setStartGuardTimeInterval:[configs btd_intValueForKey:@"start_guard_time_interval" default:0]];
}

+ (void)setupWithConfig {
    // build network allow config
    NSMutableArray<TSPKNetworkAllowConfig *> *networkAllowConfigArrayTemp = [NSMutableArray array];
    NSArray *networkAllowDict = [[[self sharedConfigs] configs] btd_arrayValueForKey:@"network_allow_configs"];
    [networkAllowDict enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)obj;
            TSPKNetworkAllowConfig *allowConfig = [TSPKNetworkAllowConfig new];
            allowConfig.startWithPaths = [dict btd_arrayValueForKey:@"start_with_paths"];
            allowConfig.endWithDomains = [dict btd_arrayValueForKey:@"end_with_domains"];
            allowConfig.invokeType = [dict btd_stringValueForKey:@"invoke_type"];
            [networkAllowConfigArrayTemp addObject:allowConfig];
        }
    }];
    [[self sharedConfigs] setNetworkAllowConfigArray:networkAllowConfigArrayTemp];
}

+ (BOOL)enableReuqestAnalyzeSubscriber {
    return [[[self sharedConfigs] configs] btd_boolValueForKey:@"enable_request_anaylze_control" default:YES];
}

+ (BOOL)enableNetworkFuseSubscriber {
    return [[[self sharedConfigs] configs] btd_boolValueForKey:@"enable_fuse_engine_control" default:NO];
}

+ (BOOL)enableNetworkSubscriber {
    return [[[self sharedConfigs] configs] btd_boolValueForKey:@"enable_guard_engine_control" default:NO];
}

+ (BOOL)canReportAllowNetworkEvent:(TSPKNetworkEvent *)event {
    if ([self isAllowEvent:event]) {
        NSUInteger currentTime = (NSUInteger)CFAbsoluteTimeGetCurrent();
        NSNumber *sampleRate = [[[self sharedConfigs] configs] btd_numberValueForKey:@"network_allow_configs_report_sample_rate"];
        NSInteger sampleRateInt = sampleRate != nil? [sampleRate intValue] : 10;
        return currentTime % sampleRateInt == 0;
    }
    return YES;
}

+ (BOOL)canAnalyzeRequest {
    NSUInteger currentTime = (NSUInteger)CFAbsoluteTimeGetCurrent();
    NSNumber *sampleRate = [[[self sharedConfigs] configs] btd_numberValueForKey:@"network_request_analyze_sample_rate"];
    NSInteger sampleRateInt = sampleRate != nil? [sampleRate intValue] : 100;
    return currentTime % sampleRateInt == 0;
}

+ (BOOL)enableURLProtocolURLSessionInvalidate {
    return [[[self sharedConfigs] configs] btd_boolValueForKey:@"enable_url_protocol_urlsession_invalidate" default:NO];
}

+ (BOOL)canReportJsonBody {
    NSUInteger currentTime = (NSUInteger)CFAbsoluteTimeGetCurrent();
    NSNumber *sampleRate = [[[self sharedConfigs] configs] btd_numberValueForKey:@"json_body_sample_rate"];
    NSInteger sampleRateInt = sampleRate != nil? [sampleRate intValue] : 100;
    return currentTime % sampleRateInt == 0;
}

+ (BOOL)canReportNetworkBacktrace {
    NSUInteger currentTime = (NSUInteger)CFAbsoluteTimeGetCurrent();
    NSNumber *sampleRate = [[[self sharedConfigs] configs] btd_numberValueForKey:@"network_backtrace_sample_rate"];
    NSInteger sampleRateInt = sampleRate != nil? [sampleRate intValue] : 100;
    return currentTime % sampleRateInt == 0;
}

+ (NSArray *)uploadBacktraceURL:(NSString *)source {
    NSDictionary *result = [[[self sharedConfigs] configs] btd_dictionaryValueForKey:@"upload_backtrace_url"];
    NSArray *sourceArray = [result btd_arrayValueForKey:source];
    if ([sourceArray count] > 0) {
        return sourceArray;
    }
    return [result btd_arrayValueForKey:@"default"];
}

+ (BOOL)isEnable {
    return [[[self sharedConfigs] configs] btd_boolValueForKey:@"enable" default:YES];
}

+ (NSArray *)reportBlockList {
    return [[[self sharedConfigs] configs] btd_arrayValueForKey:@"report_block_list"];
}

+ (BOOL)isAllowEvent:(TSPKNetworkEvent *)event {
    if (CFAbsoluteTimeGetCurrent() - [TSPKNetworkUtil monitorStartTime] < [[self sharedConfigs] startGuardTimeInterval]) {
        return YES;
    }
    
    BOOL isRequest = (event.response == nil);
    
    NSString *inputPath = isRequest ? [TSPKNetworkUtil realPathFromURL:event.request.tspk_util_url] : [TSPKNetworkUtil realPathFromURL:event.response.tspk_util_url];
    NSString *inputDomain = isRequest ? event.request.tspk_util_url.host : event.response.tspk_util_url.host;
    
    NSArray<TSPKNetworkAllowConfig *> *array = [[self sharedConfigs] networkAllowConfigArray];
    for (TSPKNetworkAllowConfig *config in array) {
        if (isRequest && [config.invokeType isEqualToString:@"response"]) {
            continue;
        }
        
        if (!isRequest && [config.invokeType isEqualToString:@"request"]) {
            continue;
        }
        
        BOOL isHitPath = config.startWithPaths.count == 0;
        if (!isHitPath && inputPath) {
            for (NSString *path in config.startWithPaths) {
                isHitPath = [inputPath hasPrefix:path];
                if (isHitPath) break;
            }
        }
        
        if (!isHitPath) {
            continue;
        }
        
        BOOL isHitDomain = config.endWithDomains.count == 0;
        if (!isHitDomain && inputDomain) {
            for (NSString *domain in config.endWithDomains) {
                isHitDomain = [inputDomain hasSuffix:domain];
                if (isHitDomain) break;
            }
        }
        
        if (isHitPath && isHitDomain) {
            return YES;
        }
    }
    return NO;
}

@end
