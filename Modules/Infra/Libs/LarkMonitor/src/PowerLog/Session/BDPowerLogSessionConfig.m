//
//  BDPowerLogSessionConfig.m
//  LarkMonitor
//
//  Created by ByteDance on 2022/12/21.
//

#import "BDPowerLogSessionConfig.h"
#import "BDPowerLogUtility.h"
@implementation BDPowerLogSessionConfig

- (instancetype)init {
    if (self = [super init]) {
        self.autoUpload = YES;
        self.uploadWhenAppStateChanged = YES;
        self.ignoreBackground = NO;
        self.uploadWithExtraData = NO;
        self.dataCollectInterval = BD_POWERLOG_DEFAULT_INTERVAL;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BDPowerLogSessionConfig *newObject = [[BDPowerLogSessionConfig alloc] init];
    newObject.autoUpload = self.autoUpload;
    newObject.uploadWhenAppStateChanged = self.uploadWhenAppStateChanged;
    newObject.ignoreBackground = self.ignoreBackground;
    newObject.uploadWithExtraData = self.uploadWithExtraData;
    newObject.dataCollectInterval = self.dataCollectInterval;
    return newObject;
}


@end
