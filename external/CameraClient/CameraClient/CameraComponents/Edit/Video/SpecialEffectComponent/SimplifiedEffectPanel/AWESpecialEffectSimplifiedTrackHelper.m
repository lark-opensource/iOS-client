//
//  AWESpecialEffectSimplifiedTrackHelper.m
//  Indexer
//
//  Created by Daniel on 2021/11/23.
//

#import "AWESpecialEffectSimplifiedTrackHelper.h"

#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@implementation AWESpecialEffectSimplifiedTrackHelper

+ (void)trackClickEffectEntrance:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *attributes = [publishModel.repoTrack.referExtra mutableCopy];
    if (publishModel.repoContext.videoType == AWEVideoTypeAR) {
        attributes[@"type"] = @"ar";
    }
    [ACCTracker() trackEvent:@"add_effect"
                       label:@"mid_page"
                       value:nil
                       extra:nil
                  attributes:attributes];
    [attributes addEntriesFromDictionary:(publishModel.repoTrack.mediaCountInfo ?: @{})];
    id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    [attributes addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
    [ACCTracker() trackEvent:@"click_effect_entrance" params:attributes needStagingFlag:NO];
}

+ (void)trackClickEffect:(AWEVideoPublishViewModel *)publishModel effectModel:(IESEffectModel *)effectModel
{
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:publishModel.repoTrack.referExtra];
    referExtra[@"effect_id"] = effectModel.effectIdentifier ?: @"";
    referExtra[@"effect_name"] = effectModel.effectName ?: @"";
    [ACCTracker() trackEvent:@"effect_click" params:referExtra needStagingFlag:NO];
}

+ (void)trackClearEffects
{
    NSDictionary *params = @{
        @"enter_from" : @"video_edit_page",
    };
    [ACCTracker() trackEvent:@"delete_effect" params:params];
}

@end
