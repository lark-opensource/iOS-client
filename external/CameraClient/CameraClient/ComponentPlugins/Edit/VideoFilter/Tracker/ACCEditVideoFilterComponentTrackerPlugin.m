//
//  ACCEditVideoFilterComponentTrackerPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by xiangpeng on 2021/03/15.
//

#import "ACCEditVideoFilterComponentTrackerPlugin.h"
#import "ACCEditVideoFilterComponent.h"

#import "ACCEditVideoFilterTrackSenderProtocol.h"
#import "ACCRepoKaraokeModelProtocol.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>

@interface ACCEditVideoFilterComponentTrackerPlugin ()

@property (nonatomic, strong, readonly) ACCEditVideoFilterComponent *hostComponent;
@property (nonatomic, strong) id<IESServiceProvider> serviceProvider;

@end

@implementation ACCEditVideoFilterComponentTrackerPlugin

@synthesize component = _component;


#pragma mark - ACCFeatureComponentPlugin
+ (id)hostIdentifier
{
    return [ACCEditVideoFilterComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.serviceProvider = serviceProvider;
    [self bindTrackEvent];
}

#pragma mark - Bind track event
- (void)bindTrackEvent
{
    id<ACCEditVideoFilterTrackSenderProtocol> trackSender = [self.serviceProvider resolveObject:@protocol(ACCEditVideoFilterTrackSenderProtocol)];

    @weakify(self);
    [trackSender.filterClickedSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (self.hostComponent.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.hostComponent.repository.repoTrack.referExtra];
            [referExtra addEntriesFromDictionary:self.hostComponent.repository.repoTrack.mediaCountInfo];
            id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.hostComponent.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
            [referExtra addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
            [ACCTracker() trackEvent:@"click_modify_entrance" params:[referExtra copy] needStagingFlag:NO];
        }
    }];
    
    [trackSender.filterSwitchManagerCompleteSignal subscribeNext:^(IESEffectModel * _Nullable filter) {
        @strongify(self);
        NSMutableDictionary *attributes = [@{@"is_photo" : @0} mutableCopy];
        [attributes addEntriesFromDictionary:self.hostComponent.repository.repoTrack.referExtra];
        [attributes addEntriesFromDictionary:@{@"position" : @"mid_page"}];

        [ACCTracker() trackEvent:@"filter_slide"
                                          label:@"mid_page"
                                          value:nil
                                          extra:nil
                                     attributes:attributes];
        attributes[@"enter_method"] = @"slide";
        attributes[@"enter_from"] = self.hostComponent.repository.repoTrack.enterFrom;
        attributes[@"filter_name"] = filter.pinyinName ? : @"";
        attributes[@"filter_id"] = filter.effectIdentifier ? : @"";
        if (self.hostComponent.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
            [ACCTracker() trackEvent:@"select_filter" params:attributes needStagingFlag:NO];
        }
    }];
    
    [trackSender.tabFilterControllerWillDismissSignal subscribeNext:^(IESEffectModel * _Nullable selectedFilter) {
        @strongify(self);
        NSString *label = selectedFilter.pinyinName;
        if (label) {
            NSMutableDictionary *attributes = [@{@"is_photo" : @0} mutableCopy];
            [attributes addEntriesFromDictionary:self.hostComponent.repository.repoTrack.referExtra];
            [ACCTracker() trackEvent:@"filter_confirm" label:@"mid_page" value:nil extra:label attributes:attributes];
        }
    }];
}

#pragma mark - Properties

- (ACCEditVideoFilterComponent *)hostComponent
{
    return self.component;
}

@end
