//
//  ACCFilterComponentDPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by yangying on 2021/05/20.
//

#import "ACCFilterComponentDPlugin.h"
#import "ACCKaraokeService.h"
#import "ACCBarItem+Adapter.h"
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@interface ACCFilterComponentDPlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCFilterComponentDPlugin

@synthesize component = _component;

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

#pragma mark - ACCFeatureComponent

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (void)componentDidAppear
{
}

- (void)loadComponentView
{
    self.viewContainer = IESAutoInline(self.serviceProvider, ACCRecorderViewContainer);
    ACCBarItemResourceConfig *barConfig = [[self.serviceProvider resolveObject:@protocol(ACCBarItemResourceConfigManagerProtocol)] configForIdentifier:ACCRecorderToolBarFilterContext];
    if (barConfig) {
        ACCBarItem *filterBarItem = [[ACCBarItem alloc] initWithImageName:barConfig.imageName title:barConfig.title itemId:ACCRecorderToolBarFilterContext];
        filterBarItem.type = ACCBarItemFunctionTypeCover;
        @weakify(self);
        filterBarItem.needShowBlock = ^BOOL{
            @strongify(self);
            if (self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio) {
                return NO;
            }
            if ([self.cameraService.recorder isRecording]) {
                return NO;
            }
            return YES;
        };
        filterBarItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            if (!self.isMounted) {
                return;
            }
            [self.component handleClickFilterAction];
        };
        [self.viewContainer.barItemContainer addBarItem:filterBarItem];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.karaokeService addSubscriber:self];
}

#pragma mark - Karaoke Subscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFilterContext];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarFilterContext];
}

@end
