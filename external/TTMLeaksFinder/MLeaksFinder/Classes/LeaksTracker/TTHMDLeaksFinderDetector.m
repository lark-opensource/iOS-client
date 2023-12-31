//
//  HMDTTLeaksFinderDetector.m
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import "TTHMDLeaksFinderDetector.h"
#import "TTHMDLeaksFinderConfig.h"
#import "TTHMDLeaksFinderRecord.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <TTMLeaksFinder/TTMLeaksFinder.h>
#import <Heimdallr/HMDTTMonitor.h>
#import <Heimdallr/HMDInjectedInfo.h>
#import <TTMLeaksFinder/TTMLBlockNodeInterpreter.h>
#import <ByteDanceKit/ByteDanceKit.h>

@interface TTHMDLeaksFinderDetector ()<TTMLeaksFinderDelegate>

@property (nonatomic, strong) TTHMDLeaksFinderConfig *config;
@property (nonatomic, strong) NSCache *leaksCache;
@property (nonatomic, weak) TTMLeaksConfig *leaksConfig;
@property (nonatomic, copy, readonly) NSString *version;

@end

@implementation TTHMDLeaksFinderDetector

@synthesize version = _version;

#pragma mark - public
+ (instancetype)shareInstance {
    static TTHMDLeaksFinderDetector *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.leaksCache = [[NSCache alloc] init];
    });
    return instance;
}

- (void)start {
    // MLeaksFinder只能在主线程初始化
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configLeaksFinder];
    });
}

- (void)stop {
    self.delegate = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [TTMLeaksFinder stopDetectMemoryLeak];
    });
}

- (void)updateConfig:(TTHMDLeaksFinderConfig *)config {
    self.config = config;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMLeaksConfig];
    });
}

#pragma mark - private
// 做一些初始化的操作
- (void)configLeaksFinder {
    MLeaksGetUserInfoBlock userBlock = ^(void) {
        return [HMDInjectedInfo defaultInfo].deviceID;
    };
    
    // 头条专用的buildInfo信息
    NSString *buildInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"BuildInfo"];//[[HMDInjectedInfo defaultInfo].customContext btd_stringValueForKey:@"leaks_build_info"];
    
    TTMLeaksConfig *config = [[TTMLeaksConfig alloc] initWithAid:[HMDInjectedInfo defaultInfo].appID
                                  enableAssociatedObjectHook:self.config.enableAssociatedObjectHook
                                       enableNoVcAndViewHook:self.config.enableNoVcAndViewHook
                                                     filters:self.config.filtersDic
                                              classWhitelist:self.config.classWhitelist
                                               viewStackType:self.config.viewStackType
                                                  appVersion:self.version
                                                   buildInfo:buildInfo
                                               userInfoBlock:userBlock
                                                  doubleSend:self.config.doubleSend
                                                  enableAlogOpen:self.config.enableAlogOpen
                                         enableDetectSystemClass:self.config.enableDetectSystemClass
                                               delegateClass:[self class]];
    [TTMLeaksFinder startDetectMemoryLeakWithConfig:config];
    self.leaksConfig = config;
}

- (void)updateMLeaksConfig {
    if (!self.leaksConfig) {
        return;
    }
    
#define HMD_UPDATE_LEAKS_CONFIG(x) ({if (self.leaksConfig.x != self.config.x) {self.leaksConfig.x = self.config.x;}})
        HMD_UPDATE_LEAKS_CONFIG(enableNoVcAndViewHook);
        HMD_UPDATE_LEAKS_CONFIG(enableAssociatedObjectHook);
        HMD_UPDATE_LEAKS_CONFIG(viewStackType);
        HMD_UPDATE_LEAKS_CONFIG(doubleSend);
        HMD_UPDATE_LEAKS_CONFIG(enableAlogOpen);
        HMD_UPDATE_LEAKS_CONFIG(enableDetectSystemClass);
#undef HMD_UPDATE_LEAKS_CONFIG

    if (![self.leaksConfig.classWhitelist isEqualToArray:self.config.classWhitelist]) {
        self.leaksConfig.classWhitelist = self.config.classWhitelist;
    }
    
    if (![self.leaksConfig.filters isEqualToDictionary:self.config.filtersDic]) {
        self.leaksConfig.filters = self.config.filtersDic;
    }
}

#pragma mark - TTMLeaksFinderDelegate
+ (void)leakDidCatched:(TTMLeaksCase *)leakCase {
    if (!leakCase.cycleID) {
        BDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[TTHMDLeaksFinder] not leaks cycleID");
        return;
    }
    
    TTHMDLeaksFinderDetector *detector = [TTHMDLeaksFinderDetector shareInstance];
    if ([detector.leaksCache objectForKey:leakCase.cycleID]) {
        BDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[TTHMDLeaksFinder] repeated leaks: %@", [leakCase transToParams] );
        return;
    }
    
    [detector.leaksCache setObject:@(YES) forKey:leakCase.cycleID];
    
    TTHMDLeaksFinderRecord *record = [[TTHMDLeaksFinderRecord alloc] init];
    record.retainCycle = leakCase.retainCycle;
    record.viewStack = [leakCase.viewStack description];
    record.leaksId = leakCase.cycleID;
    record.buildInfo = leakCase.buildInfo;
    record.cycleKeyClass = leakCase.cycleKeyClass;
    record.leakSize = leakCase.leakCycle.leakSize;
    // cal leak size round
    u_int64_t leakSize = [leakCase.leakCycle.leakSize integerValue];
    if (leakSize < 10000) {
        record.leakSizeRound = @"< 10KB";
    } else if (leakSize < 50000) {
        record.leakSizeRound = @"10KB ~ 50KB";
    }else if (leakSize < 100000) {
        record.leakSizeRound = @"50KB ~ 100KB";
    }else if (leakSize < 200000) {
        record.leakSizeRound = @"100KB ~ 200KB";
    }else if (leakSize < 300000) {
        record.leakSizeRound = @"200KB ~ 300KB";
    }else if (leakSize < 400000) {
        record.leakSizeRound = @"300KB ~ 400KB";
    }else if (leakSize < 500000) {
        record.leakSizeRound = @"400KB ~ 500KB";
    }else if (leakSize < 600000) {
        record.leakSizeRound = @"500KB ~ 600KB";
    }else if (leakSize < 700000) {
        record.leakSizeRound = @"600KB ~ 700KB";
    }else if (leakSize < 800000) {
        record.leakSizeRound = @"700KB ~ 800KB";
    }else if (leakSize < 900000) {
        record.leakSizeRound = @"800KB ~ 900KB";
    }else if (leakSize < 1000000) {
        record.leakSizeRound = @"900KB ~ 1MB";
    }else if (leakSize < 10000000) {
        record.leakSizeRound = @"1MB ~ 10MB";
    }else if (leakSize < 20000000) {
        record.leakSizeRound = @"10MB ~ 20MB";
    }else if (leakSize < 30000000) {
        record.leakSizeRound = @"20MB ~ 30MB";
    }else if (leakSize < 40000000) {
        record.leakSizeRound = @"30MB ~ 40MB";
    }else {
        record.leakSizeRound = @"> 40MB";
    }
    NSMutableArray *addressList = [NSMutableArray new];
    for (TTMLLeakCycleNode *node in leakCase.leakCycle.nodes) {
        NSNumber *address = [node.extra objectForKey:TTMLBlockNodeAddressKey];
        NSString *name = [node.extra objectForKey:TTMLBlockNodeNameKey];
        if (address && name) {
            HMDAddressUnit *unit = [HMDAddressUnit new];
            unit.address = address.unsignedLongLongValue;
            unit.name = name;
            [addressList addObject:unit];
        }
    }
    record.addressList = [addressList copy];
    if (detector.delegate && [detector.delegate respondsToSelector:@selector(detector:didDetectData:)]) {
        [detector.delegate detector:detector didDetectData:record];
    }
}

+ (void)trackService:(NSString *)serviceName metric:(nullable NSDictionary<NSString *,NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue {
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName metric:metric category:category extra:extraValue];
}

#pragma mark - getter
- (NSString *)version {
    if (!_version) {
        _version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    return _version;;
}

@end
