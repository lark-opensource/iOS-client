//
//  ACCBeautyFeatureComponentTrackerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/15.
//

#import "ACCBeautyFeatureComponentTrackerPlugin.h"
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>

#import <CreationKitComponents/ACCBeautyTrackerSender.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCRecordFlowService.h"
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitComponents/ACCBeautyService.h>

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <IESInject/IESInject.h>

static NSString *const kACCRecordFlowComponentNeedAddBeautyParam = @"acc_record_flow_component_need_add_beauty_param";

@interface ACCBeautyFeatureComponentTrackerPlugin ()

@property (nonatomic, strong, readonly) ACCBeautyFeatureComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;

@end

@implementation ACCBeautyFeatureComponentTrackerPlugin

@synthesize component = _component;

IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)
#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCBeautyFeatureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    [self bindTrackEvent];
    
}

#pragma mark - Bind track event

- (void)bindTrackEvent
{
    id<ACCBeautyTrackSenderProtocol> trackSender = [self.serviceProvider resolveObject:@protocol(ACCBeautyTrackSenderProtocol)];
    

    @weakify(trackSender);
    [trackSender.modernBeautyButtonClickedSignal subscribeNext:^(id  _Nullable x) {
        @strongify(trackSender);
        
        NSMutableDictionary *params = [trackSender.publishModel.repoTrack referExtra].mutableCopy;
        [params removeObjectForKey:@"shoot_entrance"];
        params[@"enter_from"] = @"video_shoot_page";
        [ACCTracker() trackEvent:@"click_beautify_entrance"
                          params:params
                 needStagingFlag:NO];
    }];
    
    @weakify(self);
    [trackSender.flowServiceDidCompleteRecordSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSInteger segmentCount = [self.flowService markedTimesCount];
        AVCaptureDevicePosition position = [self.cameraService.cameraControl currentCameraPosition];
    
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"camera" : position == AVCaptureDevicePositionBack ? @"rear" : @"front",
                                                                                      @"subsection" : [NSString stringWithFormat:@"%ld", (long)segmentCount]}];
        if ([NSNumber acc_boolValueWithName:kACCRecordFlowComponentNeedAddBeautyParam]) {
            [params setValue:self.beautyService.beautyOn ? @"on" : @"off" forKey:@"beauty"];
        }
        [ACCTracker() trackEvent:@"take_video" attributes:params];
        
    }];
    
    [trackSender.composerBeautyViewControllerDidSwitchSignal subscribeNext:^(RACTwoTuple<NSNumber *,NSNumber *> * _Nullable x) {
        @strongify(trackSender);
        if (trackSender == nil) {
            return;
        }
        
        AWEVideoPublishViewModel *publishModel = trackSender.publishModel;
        BOOL isOn = [x.first boolValue];
        BOOL isManually = [x.second boolValue];
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSDictionary *referExtra = publishModel.repoTrack.referExtra;

        params[@"enter_from"] = [publishModel.repoTrack.enterFrom isEqualToString:@"video_edit_page"] ? @"video_edit_page" : @"video_shoot_page";
        params[@"shoot_way"] = publishModel.repoTrack.referString; // referstring
        params[@"creation_id"] = publishModel.repoContext.createId;
        params[@"content_source"] = referExtra[@"content_source"];
        params[@"content_type"] = referExtra[@"content_type"];
        params[@"status"] = isOn ? @"enable" : @"disable";
        if (isOn) {
            params[@"enable_by"] = isManually ? @"user" : @"auto"; // 点击任意小项大打开美颜开关
        } else {
            params[@"enable_by"] = @"";
        }
        [ACCTracker() trackEvent:@"enable_beautify" params:params];
    }];
}

#pragma mark - Properties

- (ACCBeautyFeatureComponent *)hostComponent
{
    return self.component;
}

@end
