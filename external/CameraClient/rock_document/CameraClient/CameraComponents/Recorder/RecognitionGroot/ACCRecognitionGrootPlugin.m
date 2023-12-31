//
//  ACCRecognitionGrootPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import "ACCRecognitionGrootPlugin.h"
#import <UIKit/UIKit.h>
#import "ACCRecognitionGrootComponent.h"
#import "ACCRecognitionService.h"
#import "ACCRecognitionSpeciesPanelViewModel.h"
#import "ACCRecognitionPropPanelViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCRecognitionGrootPlugin ()

@property (nonatomic, strong, readonly) ACCRecognitionGrootComponent *hostComponent;
@property (nonatomic, weak) id<ACCRecognitionService> recognitionService;

@end

@implementation ACCRecognitionGrootPlugin

@synthesize component = _component;

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCRecognitionGrootComponent class];
}

- (ACCRecognitionSpeciesPanelViewModel *)speciesViewModel
{
    return [self.hostComponent getViewModel:ACCRecognitionSpeciesPanelViewModel.class];
}

- (ACCRecognitionPropPanelViewModel *)propPanelViewModel
{
    return [self.hostComponent getViewModel:ACCRecognitionPropPanelViewModel.class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.recognitionService = IESAutoInline(serviceProvider, ACCRecognitionService);
    @weakify(self)
    [self.speciesViewModel.checkGrootSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self)
        [self.hostComponent updateCheckGrootResearch:x.boolValue];
    }];

    self.propPanelViewModel.homeItem = [[ACCPropPickerItem alloc] initWithType:ACCPropPickerItemTypeHome];

    [self.propPanelViewModel.selectItemSignal subscribeNext:^(RACTwoTuple<ACCPropPickerItem *,NSNumber *> * _Nullable x) {
        @strongify(self)
        [self.hostComponent updateStickerState:x.first.type == ACCPropPickerItemTypeHome];
    }];

}

#pragma mark - Properties

- (ACCRecognitionGrootComponent *)hostComponent
{
    return self.component;
}

@end
