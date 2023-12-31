//
//  ACCSpeedControlViewModel.m
//  Pods
//
//  Created by liyingpeng on 2020/6/23.
//

#import "ACCSpeedControlViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

#import <CreationKitInfra/ACCGroupedPredicate.h>

@interface ACCSpeedControlViewModel ()

@property (nonatomic, copy) NSString *showingTips;
@property (nonatomic, strong) RACSubject *speedControlViewShowIfNeededSubject;
@property (nonatomic, strong, readwrite) RACSignal *speedControlViewShowIfNeededSignal;
@property (nonatomic, strong) NSMapTable<ACCSpeedControlShouldShowPredicate, id> *predicates;
@property (nonatomic, strong) ACCGroupedPredicate *barItemShowPredicate;

@end

@implementation ACCSpeedControlViewModel

- (void)dealloc
{
    [self.speedControlViewShowIfNeededSubject sendCompleted];
}

- (void)setSpeedControlButtonSelected:(BOOL)speedControlButtonSelected
{
    _speedControlButtonSelected = speedControlButtonSelected;
    if (speedControlButtonSelected) {
        [ACCCache() setBool:YES forKey:@"AWESpeedControlShowKey"];
    } else {
        [ACCCache() setBool:NO forKey:@"AWESpeedControlShowKey"];
    }
}

- (BOOL)defalutEnableSpeedControl
{
    BOOL isPhotoToVideoDraft = self.inputData.publishModel.repoContext.videoType == AWEVideoTypePhotoToVideo && (self.inputData.publishModel.repoDraft.isDraft || self.inputData.publishModel.repoDraft.isBackUp);
    if (!ACC_isEmptyString(self.inputData.localSticker.commerceBuyText)) {
        [ACCCache() setBool:NO forKey:@"AWESpeedControlShowKey"];
        _speedControlButtonSelected = NO;
    } else if ([ACCCache() boolForKey:@"AWESpeedControlShowKey"] && !isPhotoToVideoDraft && !ACCConfigBool(kConfigBool_hide_bottom_speed_panel)) {
        _speedControlButtonSelected = YES;
    } else {
        _speedControlButtonSelected = NO;
    }
    return _speedControlButtonSelected;
}

- (void)shouldShowSpeedControl:(BOOL)show
{
    [self.speedControlViewShowIfNeededSubject sendNext:@(show)];
}

- (RACSubject *)speedControlViewShowIfNeededSubject
{
    if (!_speedControlViewShowIfNeededSubject) {
        _speedControlViewShowIfNeededSubject = [RACSubject subject];
    }
    return _speedControlViewShowIfNeededSubject;
}

- (RACSignal *)speedControlViewShowIfNeededSignal
{
    return self.speedControlViewShowIfNeededSubject;
}

- (void)addShouldShowPrediacte:(BOOL(^)(void))predicate forHost:(id)host
{
    [self.predicates setObject:host forKey:predicate];
}

- (void)removeShouldShowPredicate:(ACCSpeedControlShouldShowPredicate)predicate
{
    [self.predicates removeObjectForKey:predicate];
}

- (NSEnumerator<ACCSpeedControlShouldShowPredicate> *)predicateEnumerator
{
    return self.predicates.keyEnumerator;
}

- (NSMapTable<ACCSpeedControlShouldShowPredicate,id> *)predicates
{
    if (_predicates == nil) {
        _predicates = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _predicates;
}

- (ACCGroupedPredicate *)barItemShowPredicate
{
    if (!_barItemShowPredicate) {
        _barItemShowPredicate = [[ACCGroupedPredicate alloc] init];
    }
    return _barItemShowPredicate;
}

@end
