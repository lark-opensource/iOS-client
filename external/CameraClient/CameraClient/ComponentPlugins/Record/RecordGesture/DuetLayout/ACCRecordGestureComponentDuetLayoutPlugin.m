//
//  ACCRecordGestureComponentDuetLayoutPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by <#Bytedance#> on 2021/03/09.
//

#import "ACCRecordGestureComponentDuetLayoutPlugin.h"
#import "ACCRecordGestureComponent.h"
#import "ACCDuetLayoutService.h"

@interface ACCRecordGestureComponentDuetLayoutPlugin ()

@property (nonatomic, strong, readonly) ACCRecordGestureComponent *hostComponent;

@end

@implementation ACCRecordGestureComponentDuetLayoutPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordGestureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    @weakify(self);
    [[IESAutoInline(serviceProvider, ACCDuetLayoutService) duetLayoutDidChangedSignal] subscribeNext:^(ACCDuetLayoutModelPack  _Nullable x) {
        @strongify(self);
        BOOL enableTouchGes = [x.second boolValue];
        [self.hostComponent duetLayoutDidApplyDuetEffect:enableTouchGes];
    }];
}

#pragma mark - Properties

- (ACCRecordGestureComponent *)hostComponent
{
    return self.component;
}

@end
