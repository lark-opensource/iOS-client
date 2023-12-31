//
//  cc.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/13.
//

#import "AWERepoAuthorityModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"
#import "AWERepoAuthorityContext.h"
#import "ACCFriendsServiceProtocol.h"
#import "ACCPublishPrivacySecurityManagerProtocol.h"
#import "ACCPrivacyPermissionDecouplingManagerProtocol.h"
#import "AWEPrivacyPermissionTypeDefines.h"

@implementation AWEVideoDraftExclusionModel

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:self.isHideSearch forKey:@"isHideSearch"];
    [coder encodeObject:self.exclusionSecUidList forKey:@"exclusionSecUidList"];
    [coder encodeObject:self.exclusionListJson forKey:@"exclusionListJson"];
    [coder encodeBool:self.isExclusionSelected forKey:@"isExclusionSelected"];
    [coder encodeBool:self.enablePublishExclusion forKey:@"enablePublishExclusion"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _isHideSearch = [coder decodeBoolForKey:@"isHideSearch"];
        _exclusionSecUidList = [coder decodeObjectForKey:@"exclusionSecUidList"];
        _exclusionListJson = [coder decodeObjectForKey:@"exclusionListJson"];
        _isExclusionSelected = [coder decodeBoolForKey:@"isExclusionSelected"];
        _enablePublishExclusion = [coder decodeBoolForKey:@"enablePublishExclusion"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEVideoDraftExclusionModel *model = [[AWEVideoDraftExclusionModel alloc] init];
    model.isHideSearch = self.isHideSearch;
    model.exclusionSecUidList = self.exclusionSecUidList.copy;
    model.exclusionListJson = self.exclusionListJson.copy;
    model.isExclusionSelected = self.isExclusionSelected;
    model.enablePublishExclusion = self.enablePublishExclusion;
    model.exclusionUserList = self.exclusionUserList.copy;
    
    return model;
}

- (BOOL)isEqualToObject:(AWEVideoDraftExclusionModel *)object
{
    if (![object isKindOfClass:[AWEVideoDraftExclusionModel class]]) {
        return NO;
    }
    
    if (self.isHideSearch != object.isHideSearch ||
        self.isExclusionSelected != object.isExclusionSelected ||
        self.enablePublishExclusion != object.enablePublishExclusion) {
        return NO;
    }
    
    if (self.exclusionListJson.length != object.exclusionListJson.length) {
        return NO;
    } else if (self.exclusionListJson.length) {
        if (![self.exclusionListJson isEqualToString:object.exclusionListJson]) {
            return NO;
        }
    }
    
    if (self.exclusionSecUidList.count != object.exclusionSecUidList.count) {
        return NO;
    } else if (self.exclusionSecUidList.count) {
        if (![self.exclusionSecUidList isEqualToArray:object.exclusionSecUidList]) {
            return NO;
        }
    }
    
    if (self.exclusionUserList.count != object.exclusionUserList.count) {
        return NO;
    } else if (self.exclusionUserList.count) {
        if (![self.exclusionUserList isEqualToArray:object.exclusionUserList]) {
            return NO;
        }
    }

    return YES;
}

@end

@interface AWEVideoPublishViewModel (AWERepoAuthority) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoAuthority)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoAuthorityModel.class];
	return info;
}

- (AWERepoAuthorityModel *)repoAuthority
{
    AWERepoAuthorityModel *authorityModel = [self extensionModelOfClass:AWERepoAuthorityModel.class];
    NSAssert(authorityModel, @"extension model should not be nil");
    return authorityModel;
}

@end

@interface AWERepoAuthorityModel()

@end

@implementation AWERepoAuthorityModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoAuthorityModel *model = [super copyWithZone:zone];
    model.itemComment = self.itemComment;
    model.itemDownload = self.itemDownload;
    model.itemDuet = self.itemDuet;
    model.itemShare = self.itemShare;
    model.itemReact = self.itemReact;
    model.exclusionModel = self.exclusionModel.copy;
    model.shouldShowGrant = self.shouldShowGrant;
    model.downloadType = self.downloadType;
    model.authorityContext = self.authorityContext.copy;
    return model;
}

- (BOOL)isEqualToObject:(AWERepoAuthorityModel *)object
{
    if (![object isKindOfClass:[AWERepoAuthorityModel class]]) {
        return NO;
    }
    
    if (self.itemComment != object.itemComment ||
        self.itemDownload != object.itemDownload ||
        !ACC_FLOAT_EQUAL_TO(self.itemDuet.floatValue, object.itemDuet.floatValue) ||
        !ACC_FLOAT_EQUAL_TO(self.itemReact.floatValue, object.itemReact.floatValue) ||
        self.privacyType != object.privacyType ||
        self.isPrivate != object.isPrivate) {
        return NO;
    }

    if (self.shouldShowGrant != object.shouldShowGrant ||
        !ACC_FLOAT_EQUAL_TO(self.downloadType.floatValue, object.downloadType.floatValue) ||
        !ACC_FLOAT_EQUAL_TO(self.itemShare.floatValue, object.itemShare.floatValue)) {
        return NO;
    }
    
    if (!self.exclusionModel && !object.exclusionModel) {
        return YES;
    }
    if (!self.exclusionModel || !object.exclusionModel) {
        return NO;
    }
    return [self.exclusionModel isEqualToObject:object.exclusionModel];
}

#pragma mark - Override
- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    [[IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) publishPrivacySecurityManager] resetAuthorityModelWithPrivacyCheck:publishViewModel];
    
    BOOL enablePrivacyDecoulpedFromVisibility = [[IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) AWEPrivacyPermissionDecouplingManagerClass] enablePrivacyDecoulpedFromVisibility];
    NSDictionary *accPublishRequestParams = [super acc_publishRequestParams:publishViewModel];
    NSMutableDictionary *awePublishRequestParams = accPublishRequestParams.mutableCopy;
    awePublishRequestParams[@"duet_ignore_visibility"] = enablePrivacyDecoulpedFromVisibility ? @(self.authorityContext.duetIgnoreVisibility) : @(NO);
    if (ACCConfigBool(kConfigBool_add_download_permission_before_publish)) {
        awePublishRequestParams[@"download_type"] = self.downloadType ?: @(AWEAuthorDownloadPermissionTypeAll);
        awePublishRequestParams[@"download_ignore_visibility"] = enablePrivacyDecoulpedFromVisibility ? @(self.authorityContext.downloadIgnoreVisibility) : @(NO);
    }
    
    if (ACCConfigBool(ACCConfigBOOL_enable_share_video_as_story) &&
        ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) &&
        ACCConfigBool(ACCConfigBOOL_social_enable_share_video_as_story_permission_optimation)) {
        awePublishRequestParams[@"item_share"] = self.itemShare ?: @(AWEAuthorStorySharePermissionTypeAll);
        awePublishRequestParams[@"share_ignore_visibility"] = enablePrivacyDecoulpedFromVisibility ? @(self.authorityContext.storyShareIgnoreVisibility) : @(NO);
    }
    
    return awePublishRequestParams.copy;
}

#pragma mark - Getter Method

- (AWERepoAuthorityContext *)authorityContext
{
    if (!_authorityContext) {
        _authorityContext = [[AWERepoAuthorityContext alloc] init];
    }
    return _authorityContext;
}

@synthesize repository;

@end
