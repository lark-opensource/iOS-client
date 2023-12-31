//
//  ACCEffectTrackViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/12/14.
//

#import "ACCEffectTrackViewModel.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/AWEVideoFragmentInfo.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@interface ACCEffectTrackViewModel ()

@property (nonatomic, strong) AWEVideoFragmentInfo *currentFragment;

// 每一段开拍前收到的埋点数据
@property (nonatomic, copy) NSArray<ACCEffectTrackParams *> *effectTrackParams;

@end

@implementation ACCEffectTrackViewModel

- (void)trackRecordWithEvent:(NSString *)event params:(NSDictionary *)params
{
    // 插入通用参数
    NSString *propId = nil;
    if (self.currentStickerHandler) {
        propId = self.currentStickerHandler();
    }
    NSMutableDictionary *mutableDictionary = [params mutableCopy];
    mutableDictionary[@"prop_id"] = propId ?: @"";
    mutableDictionary[@"shoot_way"] =  self.inputData.publishModel.repoTrack.referString ?: @"";
    mutableDictionary[@"creation_id"] = self.inputData.publishModel.repoContext.createId ?: @"";
    mutableDictionary[@"draft_id"] = @(self.inputData.publishModel.repoDraft.editFrequency).stringValue ?: @"";
    AWELogToolInfo(AWELogToolTagNone, @"trackRecordWithEvent|event=%@|params=%@", event, mutableDictionary);
    [ACCTracker() trackEvent:event params:mutableDictionary.copy];
}

- (void)updateEffectTrackModelWithParams:(NSDictionary *)params type:(ACCTrackMessageType)type
{
    NSAssert(params, @"params is invalid!!!");
    if (!params) {
        return;
    }
    
    ACCEffectTrackParams *paramModel = [[ACCEffectTrackParams alloc] init];
    paramModel.params = params;
    paramModel.needTrackInEdit = (type & ACCTrackMessageTypeEdit) != 0;
    paramModel.needTrackInPublish = (type & ACCTrackMessageTypePublish) != 0;
    
    @synchronized (self) {
        if (!self.currentFragment) {
            NSMutableArray *mutableEffectTrackParams = self.effectTrackParams ? self.effectTrackParams.mutableCopy : [NSMutableArray array];
            [mutableEffectTrackParams addObject:paramModel];
            self.effectTrackParams = [mutableEffectTrackParams copy];
        } else {
            NSArray<ACCEffectTrackParams*> *paramsArray = self.currentFragment.effectTrackParams ?: @[];
            NSMutableArray<ACCEffectTrackParams*> *mutableParamsArray = [paramsArray mutableCopy];
            [mutableParamsArray addObject:paramModel];
            self.currentFragment.effectTrackParams = [mutableParamsArray copy];
        }
    }
}

- (void)addFragment:(AWEVideoFragmentInfo *)fragment
{
    @synchronized (self) {
        self.currentFragment = fragment;
        self.currentFragment.effectTrackParams = self.effectTrackParams;
        self.effectTrackParams = nil;
    }
}

- (void)clearTrackParamsCache
{
    @synchronized (self) {
        self.effectTrackParams = nil;
        self.currentFragment = nil;
    }
}

@end
