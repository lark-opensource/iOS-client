//
//  AWEVideoPublishViewModel+PublishTitleHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/11/22.
//

#import "AWEVideoPublishViewModel+PublishTitleHandler.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCHashTagServiceProtocol.h"
#import "ACCRepoMissionModelProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CameraClientModel/ACCTextExtraType.h>

@implementation AWEVideoPublishViewModel (PublishTitleHandler)

- (void)syncMentionUserToTitleIfNeed
{
    if (self.repoDraft.isDraft) {
        return;
    }
    
    id<ACCRepoMissionModelProtocol> missionModel = [self extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    id<ACCTaskModelProtocol> task = [missionModel acc_mission] ?: self.repoChallenge.challenge.task;
    if (!task || !self.repoDuet.isDuet) {
        return;
    }
    
    NSMutableString *publishTitle = [self p_nonullMutableTitle];
    
    NSMutableArray<id<ACCTextExtraProtocol>> *textExtras = [self.repoPublishConfig.titleExtraInfo ?: @[] mutableCopy];
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
    
    self.repoPublishConfig.publishTitle = [publishTitle copy];
    self.repoPublishConfig.titleExtraInfo = [textExtras copy];
}

- (void)syncTitleChallengeInfosToTitleExtraInfo
{
    NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:self.repoPublishConfig.publishTitle ?:@""];
    NSMutableArray<id<ACCTextExtraProtocol>> *extraWithoutChallengeArray = [@[] mutableCopy];
    [self.repoPublishConfig.titleExtraInfo enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull acc_obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (acc_obj.accType != ACCTextExtraTypeChallenge) {
            [extraWithoutChallengeArray addObject:acc_obj];
        }
    }];
    self.repoPublishConfig.titleExtraInfo = [[extraWithoutChallengeArray arrayByAddingObjectsFromArray:resolvedHashtags] copy];
}

- (void)appendChallengesToTitleWithNames:(NSArray <NSString *> *)challengeNames
                       maxTitleLength:(NSInteger)publishMaxTitleLength
{
    if (ACC_isEmptyArray(challengeNames)) {
        return;
    }
    
    NSMutableString *publishTitle = [self p_nonullMutableTitle];
    
    NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:publishTitle];
    NSMutableArray *existHashTagArray = [NSMutableArray array];
    [resolvedHashtags enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.hashtagName.length) {
            [existHashTagArray addObject:obj.hashtagName];
        }
    }];
    
    for (NSUInteger i = 0; i < challengeNames.count; i++) {
        NSString *tag = challengeNames[i];
        NSString *tagInTitle = [NSString stringWithFormat:@"#%@ ", tag];
        if (![existHashTagArray containsObject:tag]) {
            if (publishTitle.length + tagInTitle.length <= publishMaxTitleLength) {
                if (publishTitle.length != 0 && ![publishTitle hasSuffix:@" "]) {
                    [publishTitle appendString:@" "];
                }
                [publishTitle appendString:tagInTitle];
            } else if (publishTitle.length + tagInTitle.length == publishMaxTitleLength + 1) {//把最后的空格删除后刚好够显示
                [publishTitle appendString:[NSString stringWithFormat:@"#%@", tag]];
            }
        }
    }
    if (publishTitle.length) {
        self.repoPublishConfig.publishTitle = [publishTitle copy];
    }
}

- (void)removeChallengesFromTitleWithNames:(NSArray <NSString *> *)challengeNames
{
    [challengeNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeChallengeFromTitleWithName:obj];
    }];
}

- (void)removeChallengeFromTitleWithName:(NSString *)challengeName
{
    if (ACC_isEmptyString(challengeName)) {
        return;
    }
    
    NSString *publishTitle = [self.repoPublishConfig.publishTitle copy] ?: @"";
    NSString *originalTitle = [self.repoPublishConfig.publishTitle copy];
    
    NSArray<id<ACCTextExtraProtocol>> *resolvedHashtags = [ACCHashTagService() resolveHashTagsWithText:publishTitle];

    id<ACCTextExtraProtocol> textExtraToRemove = nil;
    
    for (id<ACCTextExtraProtocol> textExtra in resolvedHashtags) {
        if (textExtra.accType == ACCTextExtraTypeChallenge && [textExtra.hashtagName isEqualToString:challengeName]) {
            textExtraToRemove = textExtra;
            break;
        }
    }
    
    if (textExtraToRemove && textExtraToRemove.start < publishTitle.length && textExtraToRemove.start + textExtraToRemove.length <= publishTitle.length) {
        publishTitle = [publishTitle stringByReplacingCharactersInRange:NSMakeRange(textExtraToRemove.start, textExtraToRemove.length) withString:@""];
    }
    
    if (![publishTitle isEqualToString:originalTitle]) {

        if (!ACC_isEmptyString(publishTitle)) {
            publishTitle = [publishTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (!ACC_isEmptyString(publishTitle)) {
                // 如果删除末尾绑定的字符串以后 末尾需要空格，之前有bug 后面加的会粘在一起
                publishTitle = [NSString stringWithFormat:@"%@ ", publishTitle];
            }
        }
        
        NSMutableArray *extraInfos = [NSMutableArray array];
        [self.repoPublishConfig.titleExtraInfo enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.accType != ACCTextExtraTypeChallenge && obj.end <= originalTitle.length) {
                NSString *extraString = [originalTitle substringWithRange:NSMakeRange(obj.start, obj.end - obj.start)];
                if (extraString.length > 0) {
                    NSRange newRange = [publishTitle rangeOfString:extraString];
                    if (newRange.length > 0) {
                        obj.start = newRange.location;
                        obj.end = newRange.location + newRange.length;
                        [extraInfos addObject:obj];
                    }
                }
            } else {
                [extraInfos addObject:obj];
            }
        }];
        self.repoPublishConfig.titleExtraInfo = [extraInfos copy];
        self.repoPublishConfig.publishTitle = publishTitle;
    }
}

- (NSMutableString *)p_nonullMutableTitle
{
    NSString *title = self.repoPublishConfig.publishTitle ?:@"";
    return [title mutableCopy];
}

@end
