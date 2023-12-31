//
//  HMDSubThteadRunloopInfo.h
//  Pods
//
//  Created by wangyinhui on 2023/4/25.
//

#import <Foundation/Foundation.h>

#ifndef HMDSubThreadRunloopInfo_h
#define HMDSubThreadRunloopInfo_h

#include "HMDPublicMacro.h"
#import "HMDThreadMonitorPluginProtocol.h"
#import "HMDThreadMonitorConfig.h"

HMD_EXTERN_SCOPE_BEGIN

void hmd_hook_runloop_run(void);

HMD_EXTERN_SCOPE_END


@interface HMDSubThreadRunloopMonitorPlugin : NSObject<HMDThreadMonitorPluginProtocol>

@property(nonatomic, assign) BOOL isRunning;

@property (nonatomic, copy) NSArray* observerThreadList;

@property (nonatomic, assign) NSInteger subThreadRunloopTimeoutDuration;

+ (instancetype)pluginInstance;
- (void)start;
- (void)stop;
- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config;

@end


#endif /* HMDSubThreadRunloopInfo_h */
