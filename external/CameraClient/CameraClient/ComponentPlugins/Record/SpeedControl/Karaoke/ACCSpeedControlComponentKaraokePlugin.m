//
//  ACCSpeedControlComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/05/07.
//

#import "ACCSpeedControlComponentKaraokePlugin.h"
#import "ACCSpeedControlComponent.h"
#import "ACCRecordFlowService.h"
#import "ACCKaraokeService.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitArch/ACCRecorderToolBarDefines.h>

@interface ACCSpeedControlComponentKaraokePlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCSpeedControlComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;

@property (nonatomic, strong) ACCSpeedControlShouldShowPredicate showSpeedControlPanelPredicate;
@property (nonatomic, strong) id barItemShowPredicate;

@property (nonatomic, assign) BOOL savedSelectedState;
@property (nonatomic, assign) HTSVideoSpeed savedSpeed;

@end

@implementation ACCSpeedControlComponentKaraokePlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCSpeedControlComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    self.flowService = IESAutoInline(serviceProvider, ACCRecordFlowService);
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        self.savedSpeed = self.flowService.selectedSpeed;
        [self.hostComponent externalSelectSpeed:HTSVideoSpeedNormal];
        self.showSpeedControlPanelPredicate = ^BOOL{
            return NO;
        };
        [self.hostComponent.viewModel addShouldShowPrediacte:self.showSpeedControlPanelPredicate forHost:self];
        [self.hostComponent showSpeedControlIfNeeded];
        
        self.barItemShowPredicate = ^BOOL{
            return NO;
        };
        [self.hostComponent.viewModel.barItemShowPredicate addPredicate:self.barItemShowPredicate with:self];
        [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSpeedControlContext];
    } else {
        [self.hostComponent externalSelectSpeed:self.savedSpeed];
        self.savedSpeed = HTSVideoSpeedNormal;
        [self.hostComponent.viewModel removeShouldShowPredicate:self.showSpeedControlPanelPredicate];
        self.showSpeedControlPanelPredicate = nil;
        [self.hostComponent showSpeedControlIfNeeded];
        [self.hostComponent.viewModel.barItemShowPredicate removePredicate:self.barItemShowPredicate];
        self.barItemShowPredicate = nil;
        [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarSpeedControlContext];
    }
}

#pragma mark - Properties

- (ACCSpeedControlComponent *)hostComponent
{
    return self.component;
}

@end
