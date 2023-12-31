//
//  HMDEvilMethodTracer.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/5/28.
//

#import "HMDEvilMethodTracer.h"
#include "HMDEMCollectData.h"
#import "HMDEMUploader.h"
#import "HMDEvilMethodTracer+private.h"
#import "HMDEvilMethodConfig.h"
#import "HMDUserDefaults.h"
#import "NSDictionary+HMDSafe.h"
#import "NSObject+HMDAttributes.h"
#import "Heimdallr+Private.h"
#include "HMDEMCollectTraceData.h"
#import "HeimdallrUtilities.h"
#import "HMDEvilMethodServiceProtocol.h"

#define kEVILMETHODCONFIG  @"kEVILMETHODCONFIG"

@interface HMDEvilMethodTracer() <HMDEvilMethodServiceProtocol>

@property (nonatomic, strong)HMDEvilMethodConfig *emConfig;

@end

@implementation HMDEvilMethodTracer

+ (instancetype)sharedInstance {
    static HMDEvilMethodTracer *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploader = [[HMDEMUploader alloc] init];
        self.emConfig = [self getEvilMethodConfig];
        setEMTTimeoutInterval(self.emConfig.hangTime);
        setEMFilterMillisecond(self.emConfig.filterMillisecond);
        setEMFilterEvilMethod(self.emConfig.filterEvilMethod);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveConfigNotification:) name:HMDConfigManagerDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emAppWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - HeimdallrModule Protocol Method

- (BOOL)needSyncStart {
    return NO;
}

- (void)start {
    [super start];
    [self.uploader zipAndUploadEMData];
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    HMDEvilMethodConfig *evilMethodConfig= (HMDEvilMethodConfig *)config;
    self.emConfig = evilMethodConfig;
    setEMTTimeoutInterval(self.emConfig.hangTime);
    setEMFilterMillisecond(self.emConfig.filterMillisecond);
    setEMFilterEvilMethod(self.emConfig.filterEvilMethod);
    setEMCollectFrameDrop(self.emConfig.collectFrameDrop);
    setEMCollectFrameDropThreshold(self.emConfig.collectFrameDropThreshold);
}

- (void)startTrace {
    hmd_dispatch_main_sync_safe(^{
        if (!heimdallrEvilMethodEnabled) {
            if(!kHMDEMCollectFrameDrop) {
                EMRunloopAddObserver();
            }
            heimdallrEvilMethodEnabled = YES;
            [self registerKVO];
        }
    });
}

- (void)stopTrace {
    hmd_dispatch_main_sync_safe(^{
        if (heimdallrEvilMethodEnabled) {
            heimdallrEvilMethodEnabled = NO;
            if(!kHMDEMCollectFrameDrop) {
                EMRunloopRemoveObserver();
            }
            [self removeKVO];
        }
    });
}

#pragma mark - private method

- (void)emAppWillTerminate:(NSNotification *)notification {
    __heimdallr_instrument_sync_close_file();
}

- (void)receiveConfigNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSArray *appIDs = notification.object[HMDConfigManagerDidUpdateAppIDKey];
        HMDConfigManager *updatedConfigManager = notification.object[HMDConfigManagerDidUpdateConfigKey];
        if (appIDs.count && updatedConfigManager.appID && [appIDs containsObject:updatedConfigManager.appID]) {
            [self storeEvilMethodConfig:updatedConfigManager.appID];
        }
    }
}

- (HMDEvilMethodConfig *)getEvilMethodConfig
{
    HMDEvilMethodConfig *evilMethodConfig = [[HMDEvilMethodConfig alloc] init];
    NSDictionary *dic = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kEVILMETHODCONFIG];
    if (dic) {
        evilMethodConfig.hangTime = [dic hmd_integerForKey:@"hang_time"];
        evilMethodConfig.filterEvilMethod = [dic hmd_boolForKey:@"filter_evil_method"];
        evilMethodConfig.filterMillisecond = [dic hmd_integerForKey:@"filter_millisecond"];
        evilMethodConfig.collectFrameDrop = [dic hmd_boolForKey:@"collect_frame_drop"];
        evilMethodConfig.collectFrameDropThreshold = [dic hmd_boolForKey:@"collect_frame_drop_threshold"];
    }
    else {
        evilMethodConfig.hangTime = 1;
        evilMethodConfig.filterEvilMethod = YES;
        evilMethodConfig.filterMillisecond = 1;
        evilMethodConfig.collectFrameDrop = NO;
        evilMethodConfig.collectFrameDropThreshold = 500;
    }
    return evilMethodConfig;
}

- (void)storeEvilMethodConfig:(NSString *)appID
{
    HMDEvilMethodConfig *evilMethodConfig;
    if (appID) {
        HMDHeimdallrConfig *config = [[HMDConfigManager sharedInstance] remoteConfigWithAppID:appID];
        NSArray *modules = config.activeModulesMap.allValues;
        for (HMDModuleConfig *config in modules) {
            id<HeimdallrModule> module = [config getModule];
            if ([[module moduleName] isEqualToString:kHMDModuleEvilMethodTracer]) {
                evilMethodConfig = (HMDEvilMethodConfig *)config;
                break;
            }
        }
    }
    [[HMDUserDefaults standardUserDefaults] removeObjectForKey:kEVILMETHODCONFIG];
    if (evilMethodConfig) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic hmd_setObject:@(evilMethodConfig.hangTime) forKey:@"hang_time"];
        [dic hmd_setObject:@(evilMethodConfig.filterEvilMethod) forKey:@"filter_evil_method"];
        [dic hmd_setObject:@(evilMethodConfig.filterMillisecond) forKey:@"filter_millisecond"];
        [dic hmd_setObject:@(evilMethodConfig.collectFrameDrop) forKey:@"collect_frame_drop"];
        [dic hmd_setObject:@(evilMethodConfig.collectFrameDropThreshold) forKey:@"collect_frame_drop_threshold"];
        
        [[HMDUserDefaults standardUserDefaults] setObject:dic.copy forKey:kEVILMETHODCONFIG];
    }
}

- (BOOL)enableCollectFrameDrop {
    return kHMDEMCollectFrameDrop && kHMDEvilMethodinstrumentationSuccess;
}

- (void)startCollectFrameDrop {
    if(kHMDEMCollectFrameDrop) {
        startEMCollect();
    }
}

- (void)endCollectFrameDropWithHitch:(NSTimeInterval)hitch isScrolling:(BOOL)isScrolling{
    if(kHMDEMCollectFrameDrop) {
        endEMCollect(hitch, isScrolling);
    }
}

@end
