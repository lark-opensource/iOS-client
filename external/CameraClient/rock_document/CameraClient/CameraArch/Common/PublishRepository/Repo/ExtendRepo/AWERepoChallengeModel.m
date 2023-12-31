//
//  AWERepoChallengeModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/16.
//

#import "AWERepoChallengeModel.h"

#import <CreativeKit/ACCMacros.h>


#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import "ACCRepoChallengeBindModel.h"
#import "ACCRepoMissionModelProtocol.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "AWERepoMVModel.h"
#import "AWERecordInformationRepoModel.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoVoiceChangerModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoCutSameModel.h"
#import "ACCRepoSearchClueModelProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "AWERepoStickerModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoVideoInfoModel.h>

@interface AWEVideoPublishViewModel (AWERepoChallenge) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoChallenge)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoChallengeModel.class];
	return info;
}

- (AWERepoChallengeModel *)repoChallenge
{
    AWERepoChallengeModel *challengeModel = [self extensionModelOfClass:AWERepoChallengeModel.class];
    NSAssert(challengeModel, @"extension model should not be nil");
    return challengeModel;
}

@end

@interface AWERepoChallengeModel () <ACCRepositoryTrackContextProtocol>

@end

@implementation AWERepoChallengeModel

#pragma mark - public

- (NSArray <NSString *> *)allChallengeNameArray
{
    ACCRepoChallengeBindModel *repoChallengeBindModel = [self.repository extensionModelOfClass:ACCRepoChallengeBindModel.class];
    if (repoChallengeBindModel.didHandleChallengeBind) {
        return [[repoChallengeBindModel currentBindChallengeNames] copy];
    }
    
    /// 下面这些为了兼容很老的草稿所以暂时没删除，后续会删除
    /// @warning 所以新加的话题绑定不要写在这里了，写了没有任何效果 ！！
    /// @see ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler
    
    NSMutableArray *allChallengeNameArray = [NSMutableArray array];
    
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    NSString *lastChoosedChallengeName = [missionModel acc_mission].challengs.count != 0 ? [missionModel acc_mission].challengs.firstObject.challengeName : self.challenge.challengeName;
    if (lastChoosedChallengeName.length) {
        [allChallengeNameArray acc_addObject:lastChoosedChallengeName];
    }

    id<ACCRepoSearchClueModelProtocol> searchClueModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoSearchClueModelProtocol)];
    // 搜索灵感开拍多话题
    for (NSString *clueTagName in [searchClueModel.extraPublishTagNames copy]) {
        if (clueTagName && ![allChallengeNameArray containsObject:clueTagName]) {
            [allChallengeNameArray acc_addObject:clueTagName];
        }
    }
    
    ACCRepoVideoInfoModel *recordInfo = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    for (AWEVideoFragmentInfo *fragmentInfo in recordInfo.fragmentInfo.copy) {
        for (AWEVideoPublishChallengeInfo *challengeInfo in fragmentInfo.challengeInfos) {
            if (challengeInfo.challengeName.length > 0 && ![allChallengeNameArray containsObject:challengeInfo.challengeName]) {
                [allChallengeNameArray acc_addObject:challengeInfo.challengeName];
            }
        }
    }
    
    AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERecordInformationRepoModel.class];
    for (AWEVideoPublishChallengeInfo *challengeInfo in recordInfoModel.pictureToVideoInfo.challengeInfos) {
        NSString *challengeName = challengeInfo.challengeName;
        if (challengeName.length > 0 && ![allChallengeNameArray containsObject:challengeName]) {
            [allChallengeNameArray acc_addObject:challengeName];
        }
    }
    
    AWERepoMVModel *mv = [self.repository extensionModelOfClass:AWERepoMVModel.class];
    // mv挑战
    if (mv.mvChallengeName && ![allChallengeNameArray containsObject:mv.mvChallengeName]) {
        [allChallengeNameArray acc_addObject:mv.mvChallengeName];
    }
    
    // mv多话题
    for (NSString *mvChallengeName in [mv.mvChallengeNameArray copy]) {
        if (mvChallengeName && ![allChallengeNameArray containsObject:mvChallengeName]) {
            [allChallengeNameArray acc_addObject:mvChallengeName];
        }
    }
    
    // CutSame: Multiple Challenges
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    for (NSString *cutSameChallengeName in [cutSameModel.cutSameChallengeNames copy]) {
        if (!ACC_isEmptyString(cutSameChallengeName) && ![allChallengeNameArray containsObject:cutSameChallengeName]) {
            [allChallengeNameArray acc_addObject:cutSameChallengeName];
        }
    }
    
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    NSString *lastMusicChallengeName = musicModel.music.challenge.challengeName;
    if (lastMusicChallengeName.length && ![allChallengeNameArray containsObject:lastMusicChallengeName]) {
        [allChallengeNameArray acc_addObject:lastMusicChallengeName];
    }
    
    AWERepoStickerModel *sticker = [self.repository extensionModelOfClass:AWERepoStickerModel.class];
    [allChallengeNameArray addObjectsFromArray:[sticker infoStickerChallengeNames]];
    
    ACCRepoVoiceChangerModel *voiceChanger = [self.repository extensionModelOfClass:ACCRepoVoiceChangerModel.class];
    //Voice changer
    if (!ACC_isEmptyString(voiceChanger.voiceChangerChallengeName)) {
        [allChallengeNameArray acc_addObject:voiceChanger.voiceChangerChallengeName];
    }
    
    ACCRepoDuetModel *duet = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    [allChallengeNameArray addObjectsFromArray:[duet challengeNames]];
    
    /// 上面这些为了兼容很老的草稿所以暂时没删除，后续会删除
    /// @warning 所以新加的话题绑定不要写在这里了，写了没有任何效果 ！！
    /// @see ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler
    
    return allChallengeNameArray;
}

- (NSArray <NSString *> *)allChallengeIdArray
{
    
    ACCRepoChallengeBindModel *repoChallengeBindModel = [self.repository extensionModelOfClass:ACCRepoChallengeBindModel.class];
    if (repoChallengeBindModel.didHandleChallengeBind) {
        return [repoChallengeBindModel.currentBindChallengeIds copy];
    }
    
    /// 下面这些为了兼容很老的草稿所以暂时没删除，后续会删除
    /// @warning 所以新加的话题绑定不要写在这里了，写了没有任何效果 ！！
    /// @see ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler
     
    NSMutableArray *allChallengeIDArray = [NSMutableArray array];
    
    //全民任务 ID
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    NSString *lastChoosedChallengeID = [missionModel acc_mission].challengs.count != 0 ? [missionModel acc_mission].challengs.firstObject.itemID : self.challenge.itemID;
    if (lastChoosedChallengeID.length) {
        [allChallengeIDArray acc_addObject:lastChoosedChallengeID];
    }
    
    ACCRepoVideoInfoModel *recordInfo = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    for (AWEVideoFragmentInfo *fragmentInfo in recordInfo.fragmentInfo.copy) {
        for (AWEVideoPublishChallengeInfo *challengeInfo in fragmentInfo.challengeInfos) {
            if (challengeInfo.challengeId.length > 0 && ![allChallengeIDArray containsObject:challengeInfo.challengeId]) {
                [allChallengeIDArray acc_addObject:challengeInfo.challengeId];
            }
        }
    }
    
    AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERecordInformationRepoModel.class];
    for (AWEVideoPublishChallengeInfo *challengeInfo in recordInfoModel.pictureToVideoInfo.challengeInfos) {
        NSString *challengeID = challengeInfo.challengeId;
        if (challengeID.length > 0 && ![allChallengeIDArray containsObject:challengeID]) {
            [allChallengeIDArray acc_addObject:challengeID];
        }
    }
    
    // CutSame: Multiple Challenges
    AWERepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:AWERepoCutSameModel.class];
    for (NSString *cutSameChallengeID in [cutSameModel.cutSameChallengeIDs copy]) {
        if (!ACC_isEmptyString(cutSameChallengeID) && ![allChallengeIDArray containsObject:cutSameChallengeID]) {
            [allChallengeIDArray acc_addObject:cutSameChallengeID];
        }
    }
    
    //Music challenge
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    NSString *lastMusicChallengeID = musicModel.music.challenge.itemID;
    if (lastMusicChallengeID.length && ![allChallengeIDArray containsObject:lastMusicChallengeID]) {
        [allChallengeIDArray acc_addObject:lastMusicChallengeID];
    }
    
    // Sticker challenge
    AWERepoStickerModel *sticker = [self.repository extensionModelOfClass:AWERepoStickerModel.class];
    [allChallengeIDArray addObjectsFromArray:[sticker infoStickerChallengeIDs]];
    
    // Voice changer
    ACCRepoVoiceChangerModel *voiceChanger = [self.repository extensionModelOfClass:ACCRepoVoiceChangerModel.class];
    if (!ACC_isEmptyString(voiceChanger.voiceChangerChallengeID)) {
        [allChallengeIDArray acc_addObject:voiceChanger.voiceChangerChallengeID];
    }
    
    // Commerce challenge
    ACCRepoDuetModel *duet = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    [allChallengeIDArray addObjectsFromArray:[duet challengeIDs]];
    
    /// 上面这些为了兼容很老的草稿所以暂时没删除，后续会删除
    /// @warning 所以新加的话题绑定不要写在这里了，写了没有任何效果 ！！
    /// @see ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler
     
    return allChallengeIDArray;
}
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoChallengeModel *copyModel = [super copyWithZone:zone];
    copyModel.challengeJson = self.challengeJson;
    return copyModel;
}
@end
