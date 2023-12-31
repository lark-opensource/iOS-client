//
//  ACCRecordSwitchModeComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/04/11.
//

#import "ACCRecordSwitchModeComponentKaraokePlugin.h"
#import "ACCRecordSwitchModeComponent.h"
#import "ACCKaraokeService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreativeKit/ACCRecorderViewContainer.h>

@interface ACCRecordSwitchModeComponentKaraokePlugin () <ACCKaraokeServiceSubscriber, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong, readonly) ACCRecordSwitchModeComponent *hostComponent;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) BOOL(^predicate)(id  _Nullable input, __autoreleasing id * _Nullable output);
@property (nonatomic, assign) BOOL isFromKaraokeSelectMusicPage;

@end

@implementation ACCRecordSwitchModeComponentKaraokePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordSwitchModeComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        [self hideSwitchModeView];
    } else {
        [self showSwitchModeView];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service musicDidChangeFrom:(id<ACCMusicModelProtocol>)prevMusic to:(id<ACCMusicModelProtocol>)music musicSourceDidChangeFrom:(ACCKaraokeMusicSource)prevSource to:(ACCKaraokeMusicSource)source
{
    self.isFromKaraokeSelectMusicPage = source == ACCKaraokeMusicSourceKaraokeSelectMusic;
}

- (void)hideSwitchModeView
{
    self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        return NO;
    };
    [self.hostComponent.shouldShowSwitchModeView addPredicate:self.predicate with:self];
    [self.hostComponent updateSwitchModeViewHidden:YES];
    UIView *interactionView = (IESAutoInline(self.serviceProvider, ACCRecorderViewContainer)).interactionView;
    interactionView.isAccessibilityElement = NO;
    interactionView.accessibilityElementsHidden = NO;
}

- (void)showSwitchModeView
{
    [self.hostComponent.shouldShowSwitchModeView removePredicate:self.predicate];
    [self.hostComponent updateSwitchModeViewHidden:NO];
    if (self.isFromKaraokeSelectMusicPage) {
        UIView *interactionView = (IESAutoInline(self.serviceProvider, ACCRecorderViewContainer)).interactionView;
        interactionView.isAccessibilityElement = NO;
        interactionView.accessibilityElementsHidden = YES;
        self.isFromKaraokeSelectMusicPage = NO;
    }
}

#pragma mark - Properties

- (ACCRecordSwitchModeComponent *)hostComponent
{
    return self.component;
}

@end
