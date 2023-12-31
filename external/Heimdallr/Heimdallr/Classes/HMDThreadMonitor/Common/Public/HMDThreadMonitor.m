//
//  HMDThreadMonitor.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/9/8.
//

#import "HMDThreadMonitor.h"
#import "HMDThreadMonitorConfig.h"
#import "HMDThreadMonitorPluginProtocol.h"
#import "HMDThreadInversionMonitorPlugin.h"
#import "HMDThreadSamplingMonitorPlugin.h"
#import "HMDThreadCountMonitorPlugin.h"
#import "HMDUserExceptionTracker.h"
#import "HMDALogProtocol.h"
#import "HMDThreadMonitorTool.h"
#import "HMDSubThreadRunloopMonitorPlugin.h"
// Utility
#import "HMDMacroManager.h"

@interface HMDThreadMonitor ()

@property (nonatomic, strong) HMDThreadMonitorConfig *threadConfig;
@property (nonatomic, strong) NSMutableArray *threadSubModules;

@end

@implementation HMDThreadMonitor

+ (instancetype)shared {
    static HMDThreadMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDThreadMonitor alloc] init];
    });
    return instance;
}

#pragma mark --- life cycle
- (instancetype)init {
    if (self = [super init]) {
        self.threadSubModules = [NSMutableArray array];
    }
    return self;
}

- (void)start {
    if (!self.isRunning) {
        [super start];
        dispatch_on_thread_monitor_queue(^{
            [self loadSubModuleIfNeed];
        });
    }
}

- (void)stop {
    if (self.isRunning) {
        [super stop];
        dispatch_on_thread_monitor_queue(^{
            [self unloadSubModulesIfNeed];
        });
    }
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    dispatch_on_thread_monitor_queue(^{
        if ([config isKindOfClass:[HMDThreadMonitorConfig class]]) {
            self.threadConfig = (HMDThreadMonitorConfig *)config;
            [[HMDThreadMonitorTool shared] updateWithBussinessList:self.threadConfig.businessList];
            if (self.isRunning) {
                for (id<HMDThreadMonitorPluginProtocol> subModule in self.threadSubModules) {
                    if ([subModule respondsToSelector:@selector(setupThreadConfig:)]) {
                        [subModule setupThreadConfig:(HMDThreadMonitorConfig *)config];
                    }
                }
            }
        }
    });
}

#pragma mark --- sub module manager
- (void)loadSubModuleIfNeed {
    if (self.threadConfig.enableThreadCount
        || self.threadConfig.enableSpecialThreadCount) {
        HMDThreadCountMonitorPlugin *countMonitor = [HMDThreadCountMonitorPlugin pluginInstance];
        [self.threadSubModules addObject:countMonitor];
    }
    
    if (self.threadConfig.enableThreadInversionCheck && !HMD_IS_DEBUG) {
        if (@available(iOS 10.0, *)) {
            HMDThreadInversionMonitorPlugin *inversionMonitor = [HMDThreadInversionMonitorPlugin pluginInstance];
            [self.threadSubModules addObject:inversionMonitor];
        }
    }
    
    if (self.threadConfig.enableThreadSample) {
        HMDThreadSamplingMonitorPlugin *sampleMonitor = [HMDThreadSamplingMonitorPlugin pluginInstance];
        [self.threadSubModules addObject:sampleMonitor];
    }
    
    if (self.threadConfig.enableObserverSubThreadRunloop) {
        HMDSubThreadRunloopMonitorPlugin *subRunloopMonitor = [HMDSubThreadRunloopMonitorPlugin pluginInstance];
        [self.threadSubModules addObject:subRunloopMonitor];
    }

    for (id<HMDThreadMonitorPluginProtocol> subModule in self.threadSubModules) {
        if ([subModule respondsToSelector:@selector(setupThreadConfig:)]) {
            [subModule setupThreadConfig:(HMDThreadMonitorConfig *)self.config];
        }
        if ([subModule respondsToSelector:@selector(start)]) {
            [subModule start];
        }
    }
    
}

- (void)unloadSubModulesIfNeed {
    for (id<HMDThreadMonitorPluginProtocol> subModule in self.threadSubModules) {
        if ([subModule respondsToSelector:@selector(stop)]) {
            [subModule stop];
        }
    }
}

@end
