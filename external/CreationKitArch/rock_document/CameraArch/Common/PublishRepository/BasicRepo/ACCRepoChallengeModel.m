//
//  ACCRepoChallengeModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/16.
//

#import "ACCRepoChallengeModel.h"

#import <IESInject/IESInject.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>

@interface AWEVideoPublishViewModel (RepoChallenge) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoChallenge)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoChallengeModel.class];
    return info;
}

- (ACCRepoChallengeModel *)repoChallenge
{
    ACCRepoChallengeModel *challengeModel = [self extensionModelOfClass:ACCRepoChallengeModel.class];
    NSAssert(challengeModel, @"extension model should not be nil");
    return challengeModel;
}

@end

@interface ACCRepoChallengeModel ()

@end

@implementation ACCRepoChallengeModel

#pragma mark - public

- (NSArray <NSString *> *)allChallengeNameArray
{
    ASSERT_IN_SUB_CLASS
    return @[];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoChallengeModel *copyModel = [[[self class] alloc] init];
    copyModel.challenge = [self.challenge copyWithZone:zone];
    return copyModel;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *params = @{}.mutableCopy;
    ACCRepoPublishConfigModel *publishConfigModel = [self.repository extensionModelOfClass:ACCRepoPublishConfigModel.class];
    if (self.challenge.itemID && !publishConfigModel.isHashTag) {
        NSArray *challengItems = @[self.challenge.itemID];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:challengItems options:0 error:&error];
        params[@"challenge_list"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (error) {
            AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
        }
    }
    return params;
}

@end
