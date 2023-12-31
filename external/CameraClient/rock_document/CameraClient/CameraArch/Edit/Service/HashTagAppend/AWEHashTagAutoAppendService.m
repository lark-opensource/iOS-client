//
//  AWEHashTagAutoAppendService.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEHashTagAutoAppendService.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/ACCHashTagServiceProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCRepoMissionModelProtocol.h"
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <objc/runtime.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClientModel/ACCTextExtraType.h>

// ************************************************************************
// ***** IM STORY 模式在用 请勿再加任何代码，后面清理IM STORY的时候回一并清理掉 *****
// ************************************************************************

@interface AWEHashTagAutoAppendService ()
@property (nonatomic, strong) id<ACCVideoConfigProtocol> config;
@end


@implementation AWEHashTagAutoAppendService
IESAutoInject(ACCBaseServiceProvider(), config, ACCVideoConfigProtocol)

#pragma mark - 处理视频编辑页的hashtag

- (void)appendHashTagIfNeededWithAppendPublishTitle:(NSMutableString *)publishTitle
{
    // story里面有迷之逻辑 先保留着调用吧，后面删代码的时候统一删
    if (![self.publishModel isStory]) {
        NSAssert(NO, @"Don't use this class anymore");
        return;
    }
    
    [self updatePublishTitleIfShouldMentionUserAutomatically:publishTitle];
    //首先和之前使用的挑战的id进行比较,得出新增的(只要之前不包括,就是新增)
    NSArray *lastAllChallengeNameArray = [self.publishModel.repoDraft.originalModel.repoChallenge allChallengeNameArray];
    if (self.publishModel.repoDraft.originalModel && !self.publishModel.repoDraft.originalDraft) {
        //如果是备份,标题肯定是我们自己拼上去了
        lastAllChallengeNameArray = nil;
    }
        
    NSArray *currentAllChallengeNameArray = [self.publishModel.repoChallenge allChallengeNameArray];
    NSMutableArray *addedChallengeNameArray = [@[] mutableCopy];
    [currentAllChallengeNameArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull challengeName, NSUInteger idx, BOOL * _Nonnull stop) {
        if (challengeName.length && ![lastAllChallengeNameArray containsObject:challengeName]) {
            [addedChallengeNameArray addObject:challengeName];
        }
    }];
    [self updatePublishTitleWithHashTagArray:addedChallengeNameArray appendingPublishTitle:publishTitle];
}

//如果currentHashTagArray.count == 0就保持publishModel.repoPublishConfig.publishTitle的原状.
//和之前使用的挑战进行比较,得出新增的(只要之前不包括,就是新增)
- (void)updatePublishTitleWithHashTagArray:(NSArray *)currentHashTagArray appendingPublishTitle:(NSMutableString *)publishTitle
{
    // story里面有迷之逻辑 先保留着调用吧，后面删代码的时候统一删
    if (![self.publishModel isStory]) {
        NSAssert(NO, @"Don't use this class anymore");
        return;
    }
    
    if (currentHashTagArray.count) {
        NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:publishTitle];
        NSMutableArray *existHashTagArray = [NSMutableArray array];
        [resolvedHashtags enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.hashtagName.length) {
                [existHashTagArray addObject:obj.hashtagName];
            }
        }];
        
        for (NSUInteger i = 0; i < currentHashTagArray.count; i++) {
            NSString *tag = currentHashTagArray[i];
            NSString *tagInTitle = [NSString stringWithFormat:@"#%@ ", tag];
            if (![existHashTagArray containsObject:tag]) {
                if (publishTitle.length + tagInTitle.length <= [self.config publishMaxTitleLength]) {
                    if (publishTitle.length != 0 && ![publishTitle hasSuffix:@" "]) {
                        [publishTitle appendString:@" "];
                    }
                    [publishTitle appendString:tagInTitle];
                } else if (publishTitle.length + tagInTitle.length == [self.config publishMaxTitleLength] + 1) {//把最后的空格删除后刚好够显示
                    [publishTitle appendString:[NSString stringWithFormat:@"#%@", tag]];
                }
            }
        }
        if (publishTitle.length) {
            self.publishModel.repoPublishConfig.publishTitle = publishTitle;
        }
    }
}

- (void)saveHashTagToTitleExtraInfo
{
    // story里面有迷之逻辑 先保留着调用吧，后面删代码的时候统一删
    if (![self.publishModel isStory]) {
        NSAssert(NO, @"Don't use this class anymore");
        return;
    }
    
    NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:self.publishModel.repoPublishConfig.publishTitle.mutableCopy ?: @"".mutableCopy];
    NSMutableArray *extraWithoutChallengeArray = [@[] mutableCopy];
    [self.publishModel.repoPublishConfig.titleExtraInfo enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accType != ACCTextExtraTypeChallenge) {
            [extraWithoutChallengeArray addObject:obj];
        }
    }];
    self.publishModel.repoPublishConfig.titleExtraInfo = [extraWithoutChallengeArray arrayByAddingObjectsFromArray:resolvedHashtags];
}

/*
 TODO: hongcheng
 创建专门的 @ service
 */
- (void)updatePublishTitleIfShouldMentionUserAutomatically:(NSMutableString *)publishTitle;
{
    // story里面有调用吧，后面删代码的时候统一删
    if (![self.publishModel isStory]) {
        NSAssert(NO, @"Don't use this class anymore");
        return;
    }
    
    if (self.publishModel.repoDraft.isDraft) {
        return;
    }
    id<ACCRepoMissionModelProtocol> missionModel = [self.publishModel extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    id<ACCTaskModelProtocol> task = [missionModel acc_mission] ?: self.publishModel.repoChallenge.challenge.task;
    if (!task || !self.publishModel.repoDuet.isDuet) {
        return;
    }
    NSMutableArray<id<ACCTextExtraProtocol>> *textExtras = [self.publishModel.repoPublishConfig.titleExtraInfo ?: @[] mutableCopy];
    NSArray<id<ACCUserModelProtocol>> *users = task.usersShouldBeMentioned;
    for (id<ACCUserModelProtocol> user in users) {
        if (user.socialName.length == 0 || (user.userID.length == 0 && user.secUserID.length == 0)) {
            continue;
        }
        NSUInteger index = [textExtras indexOfObjectPassingTest:^BOOL(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return obj.accType == ACCTextExtraTypeUser && ([obj.userId isEqualToString:user.userID] || [obj.secUserID isEqualToString:user.secUserID]) && obj.awemeId == nil;
        }];
        if (index != NSNotFound) {
            continue;
        }
        NSString *mentionString = [NSString stringWithFormat:@"@%@", user.socialName];
        [publishTitle appendString:@" "];
        [publishTitle appendString:mentionString];
        
        id<ACCTextExtraProtocol> textExtra = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createTextExtra:ACCTextExtraTypeUser];
        if (textExtra) {
            textExtra.userId = user.userID;
            textExtra.secUserID = user.secUserID;
            textExtra.start = publishTitle.length - mentionString.length;
            textExtra.end = publishTitle.length;
            [textExtras addObject:textExtra];
        }
    }
    
    self.publishModel.repoPublishConfig.publishTitle = publishTitle;
    self.publishModel.repoPublishConfig.titleExtraInfo = textExtras;
}

//
- (NSMutableString *)appendingPublishTitle
{
    NSMutableString *publishTitle = @"".mutableCopy;//备份
    if (self.publishModel.repoDraft.originalDraft) {//如果是草稿
        publishTitle = (self.publishModel.repoPublishConfig.publishTitle == nil) ? @"".mutableCopy : self.publishModel.repoPublishConfig.publishTitle.mutableCopy;
    } else if (!self.publishModel.repoDraft.originalModel) { //不是草稿，也不是备份
        if (self.defaultTitleFromVideoRouter.length) {
            [publishTitle appendString:self.defaultTitleFromVideoRouter];
        }
    }
    
    return publishTitle;
}

//由于音乐可能带有挑战信息,所以在选择音乐后,把挑战信息拼接到之前的publishTitle的尾部.(只增不减)
- (NSMutableString *)appendingPublishTitleForSelectMusic
{
    NSMutableString *publishTitle = self.publishModel.repoPublishConfig.publishTitle.length ? self.publishModel.repoPublishConfig.publishTitle.mutableCopy : @"".mutableCopy;
    
    return publishTitle;
}

// 根据传入的 challengeNameArray 更新 publishTitle
// 其中 challengeNameArray 的元素没有在 publishTitle 中没有出现
// 则拼接到 publishTitle 尾部
- (NSString *)generatepublishTitleWithChallengeNames:(NSArray<NSString *> *)challengeNameArray publishTItle:(NSString *)publishTItle
{
    if (challengeNameArray.count == 0) {
        return publishTItle;
    }
    
    // 需要新增到 publishTitle 中的话题
    NSMutableArray<NSString *> *updateChallengeNameArray = [NSMutableArray array];
    NSMutableArray<NSString *> *existChallengeNamesArray = [NSMutableArray array];
    NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:self.publishModel.repoPublishConfig.publishTitle];
    for (id<ACCTextExtraProtocol> hashTag in resolvedHashtags) {
        if (hashTag.hashtagName.length > 0) {
            [existChallengeNamesArray addObject:hashTag.hashtagName];
        }
    }
    
    for (NSString *challengeName in challengeNameArray) {
        if ([existChallengeNamesArray containsObject:challengeName] == NO) {
            [updateChallengeNameArray addObject:challengeName];
        }
    }
    
    NSString *res = publishTItle ?: @"";
    if (res.length > 0) {
        NSString *lastChar = [res substringFromIndex:res.length - 1];
        if (![lastChar isEqualToString:@" "]) {
            res = [res stringByAppendingString:@" "];
        }
    }
    for (NSString *challengeName in updateChallengeNameArray) {
        NSString *hashTagString = [NSString stringWithFormat:@"#%@ ", challengeName];
        if (res.length + hashTagString.length <= [self.config publishMaxTitleLength]) {
            res = [res stringByAppendingString:hashTagString];
        } else if (res.length + hashTagString.length == [self.config publishMaxTitleLength] + 1) {
            res = [res stringByAppendingString:[NSString stringWithFormat:@"#%@", challengeName]];
        }
    }
        
    return res;
}

@end
