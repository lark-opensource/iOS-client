//
//  ACCFilterComponentTrackerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by haoyipeng on 2021/03/04.
//

#import "ACCFilterComponentTrackerPlugin.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <IESInject/IESInject.h>

#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitComponents/ACCFilterComponent.h>
#import <CreationKitComponents/ACCFilterTrackerSender.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/ACCRepoContextModel.h>

@interface ACCFilterComponentTrackerPlugin ()

@property (nonatomic, strong, readonly) ACCFilterComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@end

@implementation ACCFilterComponentTrackerPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
#pragma mark - ACCFeatureSubComponent

+ (id)hostIdentifier
{
    return [ACCFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    [self bindTrackEvent];
}

#pragma mark - Bind track event

- (void)bindTrackEvent
{
    id<ACCFilterTrackSenderProtocol> trackSender = [self.serviceProvider resolveObject:@protocol(ACCFilterTrackSenderProtocol)];
    @weakify(self);
    @weakify(trackSender);
    [trackSender.filterViewWillShowSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        @strongify(trackSender);
        AWEVideoPublishViewModel *publishModel = trackSender.publishModel;
        NSMutableDictionary *attributes = @{
            @"is_photo" : self.cameraService.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0
        }.mutableCopy;
        NSMutableDictionary *referExtra = [publishModel.repoTrack.referExtra mutableCopy];
        referExtra[@"enter_from"] = @"video_shoot_page";
        if (referExtra) {
            [attributes addEntriesFromDictionary:referExtra];
        }

        [ACCTracker() trackEvent:@"add_filter"
                           label:@"shoot_page"
                           value:nil
                           extra:nil
                      attributes:attributes];
        if (publishModel.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"click_modify_entrance"
                              params:referExtra
                     needStagingFlag:NO];
        }
    }];
    
    [trackSender.filterViewWillDisappearSignal subscribeNext:^(IESEffectModel *  _Nullable currentFilter) {
        @strongify(self);
        @strongify(trackSender);
        AWEVideoPublishViewModel *publishModel = trackSender.publishModel;
        NSMutableDictionary *attributes = [@{
            @"is_photo" : self.cameraService.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0
        } mutableCopy];
        [attributes addEntriesFromDictionary:publishModel.repoTrack.referExtra];
        [ACCTracker() trackEvent:@"filter_confirm"
                           label:@"shoot_page"
                           value:nil
                           extra:currentFilter.pinyinName
                      attributes:attributes];
    }];
    
    [trackSender.filterSlideSwitchCompleteSignal subscribeNext:^(IESEffectModel * _Nullable filter) {
        @strongify(self);
        @strongify(trackSender);
        AWEVideoPublishViewModel *publishModel = trackSender.publishModel;
        NSString *filterName = filter ? (filter.pinyinName ?: @"") : @"empty";
        NSString *filterId = filter ? (filter.effectIdentifier ?: @"") : @"0";
        NSMutableDictionary *attributes = [@{
            @"is_photo" : self.cameraService.recorder.cameraMode == HTSCameraModePhoto ? @1 : @0
        } mutableCopy];
        [attributes addEntriesFromDictionary:publishModel.repoTrack.referExtra];
        [attributes addEntriesFromDictionary:@{@"position" : @"shoot_page"}];
        [attributes addEntriesFromDictionary:@{@"filter_name" : filterName}];
        [attributes addEntriesFromDictionary:@{@"filter_id" : filterId}];
        [ACCTracker() trackEvent:@"filter_slide"
                            label:@"shoot_page"
                            value:nil
                            extra:nil
                       attributes:attributes];
        attributes[@"enter_method"] = @"slide";
        if (publishModel.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"select_filter" params:attributes needStagingFlag:NO];
        }
    }];
}

#pragma mark - Properties

- (ACCFilterComponent *)hostComponent
{
    return self.component;
}

@end
