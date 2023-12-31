//
//  ACCRecordFlowComponentAdvancedSettingPlugin.m
//  Indexer
//
//  Created by Shichen Peng on 2021/11/2.
//

#import "ACCRecordFlowComponentAdvancedSettingPlugin.h"

// CameraClient
#import <CameraClient/ACCAdvancedRecordSettingService.h>
#import <CameraClient/ACCAdvancedRecordSettingComponent.h>
#import <CameraClient/ACCRecordFlowComponent.h>
#import <CameraClient/ACCLightningStyleRecordFlowComponent.h>

// AB
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCConfigKeyDefines.h>

@interface ACCRecordFlowComponentAdvancedSettingPlugin () <ACCAdvancedRecordSettingServiceSubScriber>

@property (nonatomic, strong) id<ACCAdvancedRecordSettingService> advancedService;

@end

@implementation ACCRecordFlowComponentAdvancedSettingPlugin

@synthesize component = _component;

+ (id)hostIdentifier
{
    return (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_enable_lightning_style_record_button)) ? ACCLightingStyleRecordFlowComponent.class : ACCRecordFlowComponent.class;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.advancedService = IESAutoInline(serviceProvider, ACCAdvancedRecordSettingService);
    [self.advancedService addSubscriber:self];
}

- (void)advancedRecordSettingService:(id<ACCAdvancedRecordSettingService>)service
                           configure:(ACCAdvancedRecordSettingType)type
                switchStatueChangeTo:(BOOL)status
                            needSync:(BOOL)needSync
{
    switch (type) {
        case ACCAdvancedRecordSettingTypeBtnAsShooting: {
            [self configBtnAsShooting:status needSync:needSync];
            break;
        }
        case ACCAdvancedRecordSettingTypeTapToTakePhoto: {
            [[self hostComponent] setEnableTapToTakePhoto:status];
            break;
        }
        default:
            break;
    }
}

- (void)advancedRecordSettingService:(id<ACCAdvancedRecordSettingService>)service
                           configure:(ACCAdvancedRecordSettingType)type
              segmentStatueChangeTo:(NSUInteger)index
                            needSync:(BOOL)needSync
{
    
}

#pragma mark - Private

- (void)configBtnAsShooting:(BOOL)status needSync:(BOOL)needSync
{
    if (status) {
        // 这里等到面板收起后再去做真正的打开逻辑
        // 真正的打开逻辑在ACCRecordFlowComponent中
        // call real open method in ACCRecordFlowComponent after the panel dismissed.
        [[self hostComponent] setEnableVolumeToShoot:YES];
        if (needSync) {
            [[self hostComponent] openVolumnButtonTriggersTheShoot];
        }
    } else {
        [[self hostComponent] closeVolumnButtonTriggersTheShootForce];
        [[self hostComponent] setEnableVolumeToShoot:NO];
    }
}

#pragma mark - Properties

- (ACCRecordFlowComponent *)hostComponent
{
    return self.component;
}

@end
