//
//  HMDLaunchOptimizer.m
//  Heimdallr-1f4902a4
//
//  Created by xushuangqing on 2022/2/21.
//

#import "HMDLaunchOptimizer.h"
#import "hmd_section_data_utility.h"
#import "NSObject+HMDAttributes.h"
#import "HMDThreadQosOptimizer.h"
#import "HMDDyld.h"
#import "HMDGCD.h"

NSString * const kHMDModuleLaunchOptimizerName = @"launch_optimizer";

HMD_MODULE_CONFIG(HMDLaunchOptimizerConfig)

@interface HMDLaunchOptimizerConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL enableThreadQoSMocker;
@property (nonatomic, copy) NSArray<NSString *> *QoSMockerWhiteList;
@property (nonatomic, assign) BOOL enableKeyQueueCollector;
@property (nonatomic, assign) BOOL enableDylibPreload;

@end

@implementation HMDLaunchOptimizerConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableThreadQoSMocker, enable_thread_qos_mocker, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(QoSMockerWhiteList, qos_mocker_white_list, @[], @[])
        HMD_ATTR_MAP_DEFAULT(enableKeyQueueCollector, enable_key_queue_collector, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableDylibPreload, enable_dylib_preload, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleLaunchOptimizerName;
}

- (id<HeimdallrModule>)getModule {
    return [HMDLaunchOptimizer sharedOptimizer];
}

@end

@interface HMDLaunchOptimizer ()
@property (atomic, assign, readwrite) HMDQosMockerCustomSwitch qosMockerCustomSwitch;
@property (nonatomic, assign) BOOL enableDylibPreload;
@end

@implementation HMDLaunchOptimizer

+ (instancetype)sharedOptimizer {
    static HMDLaunchOptimizer *sharedOptimizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOptimizer = [[HMDLaunchOptimizer alloc] init];
    });
    return sharedOptimizer;
}

- (void)start {
    [super start];
}

- (void)updateConfig:(HMDLaunchOptimizerConfig *)config {
    static dispatch_once_t onceToken;
    if(config.enableOpen && config.enableDylibPreload){
        self.enableDylibPreload = true;
        dispatch_once(&onceToken, ^{
            hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [HMDDyld saveAppDylibPath];
            });
        });
    } else{
        self.enableDylibPreload = false;
        [HMDDyld removeAppDylibPath];
    }
    [super updateConfig:config];
    [self configDidUpdated];
}

- (void)stop {
    [super stop];
}

- (void)configDidUpdated {
    HMDLaunchOptimizerConfig *config = (HMDLaunchOptimizerConfig *)self.config;
    if (![config isKindOfClass:[HMDLaunchOptimizerConfig class]]) {
        return;
    }
    BOOL enableThreadQoSMocker = config.enableThreadQoSMocker;
    if (self.qosMockerCustomSwitch == HMDQosMockerCustomSwitchOpen) {
        enableThreadQoSMocker = YES;
    }
    else if (self.qosMockerCustomSwitch == HMDQosMockerCustomSwitchClose) {
        enableThreadQoSMocker = NO;
    }
    [HMDThreadQosOptimizer toggleNextLaunchQosMockerEnabled:config.enableOpen && enableThreadQoSMocker
                                   keyQueueCollectorEnabled:config.enableOpen && config.enableKeyQueueCollector
                                                  whiteList:config.QoSMockerWhiteList];
}

- (void)markLaunchFinished {
    [HMDThreadQosOptimizer markLaunchFinished];
}

- (HMDLaunchOptimizerFeature)appliedLaunchOptimizerFeature {
    HMDLaunchOptimizerFeature appliedFeature = HMDLaunchOptimizerFeatureNone;
    if ([HMDThreadQosOptimizer threadQoSMockerEnabled]) {
        appliedFeature |= HMDLaunchOptimizerFeatureThreadQoSMocker;
    }
    if ([HMDThreadQosOptimizer keyQueueCollectorEnabled]) {
        appliedFeature |= HMDLaunchOptimizerFeatureKeyQueueCollector;
    }
    if (self.enableDylibPreload) {
        appliedFeature |= HMDLaunchOptimizerFeatureDylibPreload;
    }
    return appliedFeature;
}

- (void)updateQoSMockerCustomSwitch:(HMDQosMockerCustomSwitch)qosMockerCustomSwitch {
    self.qosMockerCustomSwitch = qosMockerCustomSwitch;
    [self configDidUpdated];
}


@end
