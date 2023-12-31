//
//  MVPBarItemResourceConfigRecorderManagerImpl.m
//  MVP
//
//  Created by Liu Deping on 2020/12/30.
//

#import "MVPBarItemResourceConfigRecorderManagerImpl.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CameraClient/ACCSettingsProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>


@interface MVPBarItemResourceConfigRecorderManagerImpl ()

@property (nonatomic, strong) NSMutableDictionary *configHash;

@end

@implementation MVPBarItemResourceConfigRecorderManagerImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.configHash = @{}.mutableCopy;
        [self setupBarItemConfig];
    }
    return self;
}

- (void)setupBarItemConfig {
    [self.configHash setObject:self.swapCameraResourceConfig forKey:[NSValue valueWithPointer:ACCRecorderToolBarSwapContext]];
    [self.configHash setObject:self.filterResourceConfig forKey:[NSValue valueWithPointer:ACCRecorderToolBarFilterContext]];
    [self.configHash setObject:[self speedResourceConfig] forKey:[NSValue valueWithPointer:ACCRecorderToolBarSpeedControlContext]];
    
    ACCBarItemResourceConfig *config = [ACCBarItemResourceConfig new];
    [self.configHash setObject:config forKey:[NSValue valueWithPointer:ACCRecorderToolBarModernBeautyContext]];
    
    config = [ACCBarItemResourceConfig new];
    [self.configHash setObject:config forKey:[NSValue valueWithPointer:ACCRecorderToolBarFlashContext]];
}

- (ACCBarItemResourceConfig *)configForIdentifier:(void *)itemId {
    ACCBarItemResourceConfig *config = [self.configHash objectForKey:[NSValue valueWithPointer:itemId]];
    return config;
}

- (NSArray<ACCBarItem *> *)allowListInPureMode {
    return nil;
}


- (BOOL)enableTitle {
    return [ACCSetting() showTitleInVideoCamera];
}

#pragma mark - config

- (ACCBarItemResourceConfig *)swapCameraResourceConfig
{
    ACCBarItemResourceConfig *config = [ACCBarItemResourceConfig new];
    config.imageName = @"ic_camera_filp";
    config.title = [self enableTitle] ? ACCLocalizedCurrentString(@"reverse") : @"";
    config.itemId = ACCRecorderToolBarSwapContext;
    return config;
}

- (ACCBarItemResourceConfig *)filterResourceConfig
{
    ACCBarItemResourceConfig *config = [ACCBarItemResourceConfig new];
    config.imageName = @"ic_camera_filerts_off";
    config.title = [self enableTitle] ? ACCLocalizedString(@"filter", @"滤镜") : @"";
    config.itemId = ACCRecorderToolBarFilterContext;
    return config;
}

- (ACCBarItemResourceConfig *)speedResourceConfig
{
    ACCBarItemResourceConfig *config = [ACCBarItemResourceConfig new];
    config.imageName = @"icon_camera_speed_off";
    config.title = [self enableTitle] ? ACCLocalizedString(@"speed", @"速度") : @"";
    config.itemId = ACCRecorderToolBarSpeedControlContext;
    return config;
}

@end
