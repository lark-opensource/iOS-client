//
//  ACCRepoQuickStoryModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/11/30.
//

#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERecordInformationRepoModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

ACCLandingTabKey const ACCLandingTabKeyKaraoke = @"karaoke";

@interface AWEVideoPublishViewModel (RepoQuickStory) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoQuickStory)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoQuickStoryModel.class];
    return info;
}

- (ACCRepoQuickStoryModel *)repoQuickStory
{
    ACCRepoQuickStoryModel *quickStoryModel = [self extensionModelOfClass:ACCRepoQuickStoryModel.class];
    NSAssert(quickStoryModel, @"extension model should not be nil");
    return quickStoryModel;
}

@end

@interface ACCRepoQuickStoryModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@end

@implementation ACCRepoQuickStoryModel
@synthesize repository;

- (BOOL)shouldBuildQuickStoryPanel
{
    return ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone;
}

- (BOOL)shouldDisableQuickPublishActionSheet
{
    AWERecordInformationRepoModel *recordInfoModel = [self.repository extensionModelOfClass:AWERecordInformationRepoModel.class];
    if ([recordInfoModel shouldForbidCommerce]) {
        return YES;
    }
    // 快拍反转
    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return YES;
    }
    
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    // 个人主页相册tab
    if (contextModel.videoSource == AWEVideoSourceAlbum && [trackModel.referString isEqualToString:@"album_tab_upload"]) {
        return YES;
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoQuickStoryModel *model = [[[self class] alloc] init];
    model.isQuickShootChangeIcon = self.isQuickShootChangeIcon;
    model.newMention = self.newMention;
    model.displayHashtagSticker = self.displayHashtagSticker;
    model.isQuickStory = self.isQuickStory;
    model.hasPaint = self.hasPaint;
    model.videoCode = self.videoCode;
    model.saveStoryToLocal = self.saveStoryToLocal;
    model.beforeEditPublish = self.beforeEditPublish;
    model.friendsFeedPostPromotionType = self.friendsFeedPostPromotionType;
    return model;
}

- (BOOL)isNewcomersStory
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    return [trackModel.referString isEqualToString:@"bio_register"];
}

- (BOOL)isAvatarQuickStory
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    return [trackModel.referString isEqualToString:@"profile_photo"]
        || [trackModel.referString isEqualToString:@"sf_2022_task_edit_avatar_or_name"];
}

- (BOOL)isNewCityStory
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    return [trackModel.referString isEqualToString:@"city_story"];
}

- (BOOL)isProfileBgStory
{
    ACCRepoTrackModel *trackModel = [self.repository extensionModelOfClass:ACCRepoTrackModel.class];
    return [trackModel.referString isEqualToString:@"profile_cover"];
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    mutableParameter[@"is_story"] = @(self.isQuickStory ? 1 : 0);
    if (self.isQuickStory && ACCConfigInt(kConfigInt_story_visible_for_n_days) != 0) {
        mutableParameter[@"story_ttl"] = @(ACCConfigInt(kConfigInt_story_visible_for_n_days));
    }
    
    NSNumber *storySourceTypeValue = [self p_storySourceTypeValue];
    if (storySourceTypeValue != nil) {
        mutableParameter[@"story_source_type"] = storySourceTypeValue;
    }
    
    return mutableParameter.copy;
}

- (NSNumber *)p_storySourceTypeValue
{
    AWERepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    if (repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return @(1);
    }
    return nil;
}

@end
