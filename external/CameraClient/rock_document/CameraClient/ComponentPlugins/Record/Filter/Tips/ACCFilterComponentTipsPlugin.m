//
//  ACCFilterComponentTipsPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by hehai on 2021/03/31.
//

#import "ACCFilterComponentTipsPlugin.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@interface ACCFilterComponentTipsPlugin ()

@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, getter=isFirstAppear) BOOL firstAppear;

@end

@implementation ACCFilterComponentTipsPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

#pragma mark - ACCFeatureComponent

- (void)componentDidMount
{
    self.firstAppear = YES;
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.firstAppear = NO;
        if (!self.filterService.currentFilter.isEmptyFilter) {
            NSString *currentFilterCategoryName = [self.component tabNameForFilter:self.filterService.currentFilter];
            [[AWERecorderTipsAndBubbleManager shareInstance] showFilterHintWithContainer:self.viewContainer.interactionView
                                                                              filterName:self.filterService.currentFilter.effectName
                                                                            categoryName:currentFilterCategoryName];
        }
    }
}

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    @weakify(self);
    [[self.filterService.showFilterNameSignal deliverOnMainThread] subscribeNext:^(IESEffectModel * _Nullable x) {
        @strongify(self);
        NSString *categoryName = [self.component tabNameForFilter:x];
        [[AWERecorderTipsAndBubbleManager shareInstance] showFilterHintWithContainer:self.viewContainer.interactionView
                                                                          filterName:x.effectName
                                                                        categoryName:categoryName];
    }];
    
    [self.filterService.applyFilterSignal subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        BOOL isCompelete = [x boolValue];
        if (isCompelete) {
            NSString *categoryName = [self.component tabNameForFilter:self.filterService.currentFilter];
            [[AWERecorderTipsAndBubbleManager shareInstance] showFilterHintWithContainer:self.viewContainer.interactionView
                                                                              filterName:self.filterService.currentFilter.effectName
                                                                            categoryName:categoryName];
        }
    }];
}

#pragma mark - Properties

- (ACCFilterComponent *)hostComponent
{
    return self.component;
}

@end
