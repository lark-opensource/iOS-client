//
//  ACCBeautyComponentBarItemPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by machao on 2021/5/28.
//

#import "ACCBeautyComponentBarItemPlugin.h"
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import "ACCKaraokeService.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@interface ACCBeautyComponentBarItemPlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCBeautyFeatureComponent *hostComponent;

@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCBeautyComponentBarItemPlugin
@synthesize component = _component;

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCBeautyFeatureComponent class];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.karaokeService addSubscriber:self];
}

- (void)loadComponentView
{
    [self setupUI];
}

- (void)setupUI
{
    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarModernBeautyContext];
    if (barConfig) {
        AWECameraContainerToolButtonWrapView *modernBeautyCustomView = self.hostComponent.componentView.modernBeautyButtonWarpView;
        ACCBarItem *modernBeautyBarItem = [[ACCBarItem alloc] initWithCustomView:modernBeautyCustomView itemId:ACCRecorderToolBarModernBeautyContext];
        @weakify(self);
        modernBeautyBarItem.needShowBlock = ^BOOL{
            @strongify(self);
            if (self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio) {
                return NO;
            }
            if ([self.cameraService.recorder isRecording]) {
                return NO;
            }
            return YES;
        };
        [self.viewContainer.barItemContainer addBarItem:modernBeautyBarItem];
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarModernBeautyContext];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarModernBeautyContext];
}

#pragma mark - getter

- (ACCBeautyFeatureComponent *)hostComponent {
    return self.component;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

@end
