//
//  ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/11/22.
//

#import "AWERepoCutSameModel.h"
#import "AWERepoMVModel.h"
#import "AWERepoStickerModel.h"
#import "AWERecordInformationRepoModel.h"
#import "ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler.h"
#import "ACCRepoMissionModelProtocol.h"
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCRepoSearchClueModelProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import "ACCRepoChallengeBindModel.h"
#import <CreativeKit/ACCServiceLocator.h>
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>

static const NSInteger kMaxCarryChallengeCountFromSchema = 4;

@implementation ACCVideoEditChallengeBindViewModel (ACCExtraModuleHandler)

/* 编辑页外没有模块负责的统一处理下 后续也可以移到对应的模块里... */

- (void)updateExtraModulesChallengeIfNeed
{
    [self p_updateMissionChallenges];
    [self p_updatePropsChallenges];
    [self p_updateSearchClueChallenges];
    [self p_updateMVChallenges];
    [self p_updateCutsameChallenges];
    [self p_updateCommerceDuetChallenges];
    [self p_updateDeeplinkCarryChallenges];
}

#pragma Mark - modules

// 全民任务
- (void)p_updateMissionChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    
    id<ACCRepoMissionModelProtocol> missionModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    id<ACCChallengeModelProtocol> challenge = [missionModel acc_mission].challengs.firstObject;
    if (ACC_isEmptyString(challenge.itemID) && ACC_isEmptyString(challenge.challengeName)) {
        challenge = publishModel.repoChallenge.challenge;
    }
    if (challenge) {
        [challenges addObject:challenge];
    }
    [self updateExtraModulesChallenges: [challenges copy] moduleKey:@"mission"];
}

// Props
- (void)p_updatePropsChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    
    // video fragment
    for (AWEVideoFragmentInfo *fragmentInfo in [publishModel.repoVideoInfo.fragmentInfo copy]) {
        
        for (AWEVideoPublishChallengeInfo *challengeInfo in fragmentInfo.challengeInfos) {
            NSString *challengeID = challengeInfo.challengeId;
            NSString *challengeName = challengeInfo.challengeName;
            if (!ACC_isEmptyString(challengeID) || !ACC_isEmptyString(challengeName)) {
                id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeID challengeName:challengeName];
                  [challenges acc_addObject:model];
            }
        }
        
        [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"props" ];
    }
    
    // picture to video fragmet
    if (publishModel.repoRecordInfo.pictureToVideoInfo) {
        AWEPictureToVideoInfo  *pictureToVideoInfo = publishModel.repoRecordInfo.pictureToVideoInfo;
        for (AWEVideoPublishChallengeInfo *challengeInfo in pictureToVideoInfo.challengeInfos) {
            NSString *challengeID = challengeInfo.challengeId;
            NSString *challengeName = challengeInfo.challengeName;
            if (!ACC_isEmptyString(challengeID) || !ACC_isEmptyString(challengeName)) {
                id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeID challengeName:challengeName];
                [challenges acc_addObject:model];
            }
        }
        
        [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"props" ];
    }
    
    
}

// 搜索多话题
- (void)p_updateSearchClueChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    id<ACCRepoSearchClueModelProtocol> searchClueModel = [publishModel extensionModelOfProtocol:@protocol(ACCRepoSearchClueModelProtocol)];
    for (NSString *clueTagName in [searchClueModel.extraPublishTagNames copy]) {
        id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:nil challengeName:clueTagName];
        [challenges acc_addObject:model];
    }
    [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"searchClueChallenge"];
}

// MV挑战
- (void)p_updateMVChallenges
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    if (!ACC_isEmptyString(publishModel.repoMV.mvChallengeName)) {
        id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:nil challengeName:publishModel.repoMV.mvChallengeName];
        [challenges addObject:model];
    }
    // mv多话题
    for (NSString *mvChallengeName in [publishModel.repoMV.mvChallengeNameArray copy]) {
        if (!ACC_isEmptyString(mvChallengeName)) {
            id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:nil challengeName:mvChallengeName];
            [challenges acc_addObject:model];
        }
    }
    [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"mvChallenge"];
}

// CutSame
- (void)p_updateCutsameChallenges
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    for (NSString *cutSameChallengeID in [publishModel.repoCutSame.cutSameChallengeIDs copy]) {
        if (!ACC_isEmptyString(cutSameChallengeID)) {
            id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:cutSameChallengeID challengeName:nil];
            [challenges acc_addObject:model];
        }
    }
    [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"cutsameChallenge"];
}

// 商业化挑战
- (void)p_updateCommerceDuetChallenges
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCModuleConfigProtocol);
    if ([config allowCommerceChallenge]) {
        // 合拍带上商业化挑战
        if (publishModel.repoDuet.isDuet) {
            for (id<ACCChallengeModelProtocol> challenge in [publishModel.repoDuet.duetSource.challengeList copy]) {
                if (challenge.isCommerce) {
                    [challenges addObject:challenge];
                }
            }
        }
    }
    [self updateExtraModulesChallenges:[challenges copy] moduleKey:@"commerceDuet"];
}

// schema携带的多话题
- (void)p_updateDeeplinkCarryChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = [NSMutableArray array];
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    
    NSArray<NSString *> *challengesIDsArray = [publishModel.repoChallengeBind.challengeIDsFromSchema componentsSeparatedByString:@","];
    if (!ACC_isEmptyArray(challengesIDsArray)) {
        if (challengesIDsArray.count > kMaxCarryChallengeCountFromSchema) {
            challengesIDsArray = [challengesIDsArray subarrayWithRange:NSMakeRange(0, kMaxCarryChallengeCountFromSchema)];
        }
        for (NSString *challengeID in challengesIDsArray) {
            if (!ACC_isEmptyString(challengeID)) {
                id<ACCChallengeModelProtocol> model = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeID challengeName:nil];
                [challenges acc_addObject:model];
            }
        }
    }
    [self updateExtraModulesChallenges: [challenges copy] moduleKey:@"deeplinkCarry"];
}

@end
