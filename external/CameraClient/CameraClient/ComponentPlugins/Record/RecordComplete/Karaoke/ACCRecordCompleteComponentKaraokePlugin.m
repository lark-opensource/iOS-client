//
//  ACCRecordCompleteComponentKaraokePlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/04/26.
//

#import "ACCRecordCompleteComponentKaraokePlugin.h"
#import "ACCRecordCompleteComponent.h"

#import <CreationKitInfra/ACCConfigManager.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCRecordFlowComponent.h"
#import "ACCKaraokeService.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>

@interface ACCRecordCompleteComponentKaraokePlugin () <ACCKaraokeServiceSubscriber, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCRecordCompleteComponent *hostComponent;

@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong, nullable) BOOL(^predicate)(id _Nullable input, id *_Nullable output);

@end

@implementation ACCRecordCompleteComponentKaraokePlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordCompleteComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.karaokeService = IESAutoInline(serviceProvider, ACCKaraokeService);
    [self.karaokeService addSubscriber:self];
}


- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    if (state) {
        @weakify(self);
        self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
            @strongify(self);
            return !self.karaokeService.isCountingDown;
        };
        [self.hostComponent.shouldShow addPredicate:self.predicate with:self];
    } else {
        [self.hostComponent.shouldShow removePredicate:self.predicate];
    }
}

- (void)karaokeService:(id<ACCKaraokeService>)service isCountingDownDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self.hostComponent updateCompleteButtonHidden:state];
}

#pragma mark - Properties

- (ACCRecordCompleteComponent *)hostComponent
{
    return self.component;
}

@end
