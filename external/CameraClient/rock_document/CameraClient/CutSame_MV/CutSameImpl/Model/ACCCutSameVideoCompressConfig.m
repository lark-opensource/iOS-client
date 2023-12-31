//
//  ACCCutSameVideoCompressConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import "ACCCutSameVideoCompressConfig.h"
#import <VideoTemplate/VideoTemplateDevice.h>

@implementation ACCCutSameVideoCompressConfig

+ (instancetype)defaultConfig
{
    ACCCutSameVideoCompressConfig *config = [[ACCCutSameVideoCompressConfig alloc] init];
    config.originConfig = [LVVideoCompressConfig defaultConfig];
    
    return config;
}

- (instancetype)initWithFps:(NSInteger)fps resolution:(ACCCutSameVideoCompressResolution)resolution
{
    self = [self init];
    
    if (self) {
        self.originConfig = [[LVVideoCompressConfig alloc] initWithFps:fps resolution:(LVExportResolution)resolution];
    }
    
    return self;
}

- (void)setMaxFps:(NSInteger)maxFps
{
    self.originConfig.maxFps = maxFps;
}

- (NSInteger)maxFps
{
    return self.originConfig.maxFps;
}

- (ACCCutSameVideoCompressResolution)maxResolution
{
    return (ACCCutSameVideoCompressResolution)self.originConfig.maxResolution;
}

- (void)setMaxResolution:(ACCCutSameVideoCompressResolution)maxResolution
{
    self.originConfig.maxResolution = (LVExportResolution)maxResolution;
}

- (BOOL)isIgnore
{
    return self.originConfig.isIgnore;
}

- (void)setIgnore:(BOOL)ignore
{
    self.originConfig.ignore = ignore;
}

+ (BOOL)isWorseThanIPhone6s
{
    return [VideoTemplateDevice isWorseThanIPhone6s];
}

@end
