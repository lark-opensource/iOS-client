//
//  ACCRecordSwitchModeComponentRecognitionPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiafeiyu on 2021/04/11.
//

#import "ACCRecordSwitchModeComponentRecognitionPlugin.h"
#import <UIKit/UIKit.h>
#import "ACCRecordSwitchModeComponent.h"
#import "ACCRecognitionService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CameraClient/ACCRecognitionConfig.h>

@interface ACCRecordSwitchModeComponentRecognitionPlugin () < ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong, readonly) ACCRecordSwitchModeComponent *hostComponent;
@property (nonatomic, weak) id<ACCRecognitionService> recognitionService;
@property (nonatomic, strong) BOOL(^predicate)(id  _Nullable input, __autoreleasing id * _Nullable output);

@end

@implementation ACCRecordSwitchModeComponentRecognitionPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecordSwitchModeComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.recognitionService = IESAutoInline(serviceProvider, ACCRecognitionService);
    @weakify(self)
    [self.recognitionService.hiddenSwitchModeSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.hostComponent updateSwitchModeViewHidden:[x boolValue]];
    }];

    self.predicate = ^BOOL(id  _Nullable input, __autoreleasing id * _Nullable output) {
        @strongify(self)
        if ([ACCRecognitionConfig supportScene]){
            return [self.recognitionService shouldShowSwitchMode];
        }
        return YES;
    };
    [self.hostComponent.shouldShowSwitchModeView addPredicate:self.predicate with:self];
}

#pragma mark - Properties

- (ACCRecordSwitchModeComponent *)hostComponent
{
    return self.component;
}

@end
