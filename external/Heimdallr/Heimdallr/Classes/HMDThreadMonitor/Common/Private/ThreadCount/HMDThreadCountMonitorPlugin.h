//
//  HMDThreadCountManager.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/9/9.
//

#import <Foundation/Foundation.h>
#import "HMDThreadMonitorPluginProtocol.h"
#import "HMDThreadMonitorConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadCountMonitorPlugin : NSObject <HMDThreadMonitorPluginProtocol>

+ (instancetype)pluginInstance;
- (void)start;
- (void)stop;
- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config;

- (void)reciveAllThreadCountException:(NSInteger)curCount;
- (void)threadCreated:(pthread_t)pthread_id;
- (void)threadDestroy:(pthread_t)pthread_id;

@end

NS_ASSUME_NONNULL_END
