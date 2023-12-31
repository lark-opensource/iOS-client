//
//  BDPowerLogConfig.m
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/29.
//

#import "BDPowerLogConfig.h"

@implementation BDPowerLogConfig

- (instancetype)init {
    if (self = [super init]) {
        self.sceneUpdateSessionMinTime = 2;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BDPowerLogConfig *newObject = [[BDPowerLogConfig alloc] init];
    newObject.enableNetMonitor = self.enableNetMonitor;
    newObject.enableURLSessionMetrics = self.enableURLSessionMetrics;
    newObject.enableSceneUpdateSession = self.enableSceneUpdateSession;
    newObject.enableWebKitMonitor = self.enableWebKitMonitor;
    newObject.sceneUpdateSessionMinTime = self.sceneUpdateSessionMinTime;
    newObject.ignoreSceneUpdateBackgroundSession = self.ignoreSceneUpdateBackgroundSession;
    newObject.highpowerConfig = self.highpowerConfig;
    newObject.subsceneConfig = self.subsceneConfig;
    return newObject;
}

@end
