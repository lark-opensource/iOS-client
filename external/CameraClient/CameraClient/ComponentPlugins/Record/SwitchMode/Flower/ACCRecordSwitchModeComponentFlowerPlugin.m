//
//  ACCRecordSwitchModeComponentFlowerPlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/14.
//

#import "ACCRecordSwitchModeComponentFlowerPlugin.h"
#import <UIKit/UIKit.h>
#import "ACCRecordSwitchModeComponent.h"
#import "ACCFlowerService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCRecordSwitchModeComponentFlowerPlugin () < ACCRecordSwitchModeServiceSubscriber, ACCFlowerServiceSubscriber>

@property (nonatomic, strong, readonly) ACCRecordSwitchModeComponent *hostComponent;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;
@property (nonatomic, strong) BOOL(^predicate)(id  _Nullable input, __autoreleasing id * _Nullable output);

@end

@implementation ACCRecordSwitchModeComponentFlowerPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordSwitchModeComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
    @weakify(self);
    self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self)
        return !self.flowerService.inFlowerPropMode;
    };
    [self.hostComponent.shouldShowSwitchModeView addPredicate:self.predicate with:self];
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    [self.hostComponent updateSwitchModeViewHidden:YES];
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    [self.hostComponent updateSwitchModeViewHidden:NO];
}

#pragma mark - Properties

- (ACCRecordSwitchModeComponent *)hostComponent
{
    return self.component;
}

@end
