//
//  ACCRecognitionSpeciesPanelPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/9/9.
//

#import "ACCRecognitionSpeciesPanelPlugin.h"

#import "ACCRecognitionSpeciesPanelComponent.h"
#import "ACCRecognitionGrootStickerViewModel.h"
#import "ACCRecognitionSpeciesPanelViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCRecognitionSpeciesPanelPlugin()

@property (nonatomic, strong, readonly) ACCRecognitionSpeciesPanelComponent *hostComponent;

@end

@implementation ACCRecognitionSpeciesPanelPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecognitionSpeciesPanelComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    @weakify(self);
    [[[self.grootStickerViewModel.clickViewSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.hostComponent showPanelIfNeeded];
    }];

    [[[RACObserve(self.panelViewModel, isShowingPanel) takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(NSNumber*  _Nullable x) {
        @strongify(self);
        if (!x.boolValue) {
            [self.grootStickerViewModel.grootStickerHandler stopEditStickerView];
        }
    }];
}

#pragma mark - Properties

- (ACCRecognitionGrootStickerViewModel *)grootStickerViewModel
{
    return [self.hostComponent getViewModel:ACCRecognitionGrootStickerViewModel.class];
}

- (ACCRecognitionSpeciesPanelViewModel *)panelViewModel
{
    return [self.hostComponent getViewModel:ACCRecognitionSpeciesPanelViewModel.class];
}

- (ACCRecognitionSpeciesPanelComponent *)hostComponent
{
    return self.component;
}

@end
