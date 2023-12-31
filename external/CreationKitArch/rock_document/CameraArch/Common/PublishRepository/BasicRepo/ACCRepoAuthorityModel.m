//
//  cc.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/13.
//

#import "ACCRepoAuthorityModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoAuthority) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoAuthority)

- (ACCRepoAuthorityModel *)repoAuthority {
    ACCRepoAuthorityModel *authorityModel = [self extensionModelOfClass:ACCRepoAuthorityModel.class];
    NSAssert(authorityModel, @"extension model should not be nil");
    return authorityModel;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [ACCRepositoryRegisterInfo new];
    info.classInfo = ACCRepoAuthorityModel.class;
    return info;
}

@end

@interface ACCRepoAuthorityModel()

@end

@implementation ACCRepoAuthorityModel

+ (NSDictionary *)privacyTraceMap
{
    return @{
        @(ACCPrivacyTypePublic) : @"public",
        @(ACCPrivacyTypePrivate) : @"private",
        @(ACCPrivacyTypeFriendVisible) : @"friend",
    };
}

- (BOOL)isPrivate
{
    return self.privacyType != ACCPrivacyTypePublic;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoAuthorityModel *model = [[[self class] alloc] init];
    model.privacyType = self.privacyType;
    return model;
}


#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSDictionary *privacyTraceMap = [self.class privacyTraceMap];
    return @{
        @"item_comment" : @(self.itemComment),
        @"item_download" : @(self.itemDownload),
        @"item_duet" : self.itemDuet ?: @(0),
        @"item_react" : self.itemReact ?: @(0),
        @"initial_privacy_status" : privacyTraceMap[@(self.privacyType)],
        @"is_private" : @(self.privacyType),
    };
}

@end
