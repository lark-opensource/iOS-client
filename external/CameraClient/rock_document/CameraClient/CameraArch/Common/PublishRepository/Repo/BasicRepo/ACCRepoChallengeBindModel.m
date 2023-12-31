//
//  ACCRepoChallengeBindModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/11/17.
//

#import "ACCRepoChallengeBindModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreativeKit/ACCMacros.h>

NSString * const ACCRepoChallengeBindInfoIdKey = @"itemID";
NSString * const ACCRepoChallengeBindInfoNameKey = @"challengeName";
NSString * const ACCRepoChallengeBindInfoModuleKey = @"moduleKey";
NSString * const ACCRepoChallengeBindInfoOrderIndexKey = @"orderIndex";

#pragma mark - ACCRepositoryElementRegisterCategoryProtocol
@interface AWEVideoPublishViewModel (RepoChallengeBind) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoChallengeBind)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoChallengeBindModel.class];
    return info;
}

- (ACCRepoChallengeBindModel *)repoChallengeBind
{
    ACCRepoChallengeBindModel *repoChallengeBind = [self extensionModelOfClass:[ACCRepoChallengeBindModel class]];
    NSParameterAssert(repoChallengeBind != nil);
    return repoChallengeBind;
}

@end

#pragma mark - ACCRepoChallengeBindModel
@interface ACCRepoChallengeBindModel() <NSCopying>

@end

@implementation ACCRepoChallengeBindModel

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoChallengeBindModel *model = [[[self class] alloc] init];
    model.currentBindChallengeInfos = self.currentBindChallengeInfos;
    model.didHandleChallengeBind = self.didHandleChallengeBind;
    model.needRemoveWhenReRecordChallenges = self.needRemoveWhenReRecordChallenges;
    model.challengeIDsFromSchema = self.challengeIDsFromSchema;
    model.banAutoAddHashStickers = self.banAutoAddHashStickers;
    return model;
}

#pragma mark - getter
- (NSArray<NSString *> *)currentBindChallengeNames
{
    NSMutableArray <NSString *> *ret = [NSMutableArray array];
    [self.currentBindChallengeInfos enumerateObjectsUsingBlock:^(NSDictionary<NSString *, NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *challengeName = obj[ACCRepoChallengeBindInfoNameKey];
        if (!ACC_isEmptyString(challengeName) && ![ret containsObject:challengeName]) {
            [ret addObject:challengeName];
        }
    }];
    return [ret copy];
}

- (NSArray<NSString *> *)currentBindChallengeIds
{
    NSMutableArray <NSString *> *ret = [NSMutableArray array];
    [self.currentBindChallengeInfos enumerateObjectsUsingBlock:^(NSDictionary<NSString *, NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *challengeId = obj[ACCRepoChallengeBindInfoIdKey];
        if (!ACC_isEmptyString(challengeId) && ![ret containsObject:challengeId]) {
            [ret addObject:challengeId];
        }
    }];
    return [ret copy];
}

- (void)markNeedRemoveWhenReRecord
{
    self.needRemoveWhenReRecordChallenges = [self currentBindChallengeNames];
    self.currentBindChallengeInfos = nil;
}

@end

