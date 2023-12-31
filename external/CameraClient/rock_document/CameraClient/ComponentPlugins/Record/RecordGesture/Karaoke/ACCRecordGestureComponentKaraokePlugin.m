//
//  ACCRecordGestureComponentKaraokePlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/7/18.
//

#import "ACCRecordGestureComponentKaraokePlugin.h"
#import "ACCRecordGestureComponent.h"

#import "ACCKaraokeService.h"

@interface ACCRecordGestureComponentKaraokePlugin () <ACCKaraokeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCRecordGestureComponent *hostComponent;
@property (nonatomic, assign) BOOL wasEnabled;
@property (nonatomic, assign) BOOL disabledByMe;

@end

@implementation ACCRecordGestureComponentKaraokePlugin

@synthesize component = _component;


+ (id)hostIdentifier
{
    return [ACCRecordGestureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(serviceProvider, ACCKaraokeService) addSubscriber:self];
}

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    if (mode == ACCKaraokeRecordModeAudio) {
        [self disableHostGesture];
    } else {
        [self enableHostGesture];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (!state) {
        [self enableHostGesture];
    }
}

- (void)disableHostGesture
{
    self.wasEnabled = [self.hostComponent cameraTapGestureEnabled];
    [self.hostComponent enableAllCameraGesture:NO];
    self.disabledByMe = YES;
}

- (void)enableHostGesture
{
    if (self.disabledByMe && self.wasEnabled) {
        [self.hostComponent enableAllCameraGesture:self.wasEnabled];
    }
    self.wasEnabled = NO;
    self.disabledByMe = NO;
}

#pragma mark - Properties

- (ACCRecordGestureComponent *)hostComponent
{
    return self.component;
}

@end
