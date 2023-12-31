//
//  ACCSocialStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/9/7.
//

#import "AWERepoStickerModel.h"
#import "ACCSocialStickerComponent.h"

#import "ACCSocialStickerHandler.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCStickerPanelServiceProtocol.h"
#import "AWERecordInformationRepoModel.h"
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#import "ACCDraftResourceRecoverProtocol.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/ACCRepoBirthdayModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import "ACCEditStickerSelectTimeManager.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/ACCRepoChallengeBindModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCStickerHandler+SocialData.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCTextStickerSettingsConfig.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "AWEVideoFragmentInfo.h"
#import "ACCGrootStickerServiceProtocol.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCSocialStickerDataProvider.h"
#import <CameraClientModel/ACCTextExtraType.h>
#import <CameraClientModel/ACCTextExtraSubType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static const CGFloat kAutoAddedStickerViewVerticalSpacing = 16;
static const CGFloat kAutoAddedStickerViewH = 43;

@interface ACCSocialStickerComponent () <ACCStickerPannelObserver>

@property (nonatomic, strong) ACCSocialStickerHandler *socialStickerHandler;
@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) NSMutableArray<NSString *> *autoAddedHashtagArray;
@property (nonatomic, strong) NSMutableArray<id<ACCUserModelProtocol>> *autoAddedMentionUserArray;
@property (nonatomic, assign) CGFloat autoAddedStickerLastY;

@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;

@property (nonatomic, strong) ACCEditStickerSelectTimeManager *selectTimeManager;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCGrootStickerServiceProtocol> grootService;

@end

@implementation ACCSocialStickerComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, grootService, ACCGrootStickerServiceProtocol)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    [self.stickerService registStickerHandler:self.socialStickerHandler];
    [[self stickerPanelService] registObserver:self];
}

- (void)componentDidMount {

    if ([self shouldHandleAutoAddSocialInfoForRepository:self.repository]) {
        
        [self p_autoAddHashTagAndMentionStickers];
        self.repository.repoSticker.appliedAutoSocialStickerInAlbumMode = YES;
    }
    @weakify(self)
    [[[[self stickerPanelService] didDismissStickerPanelSignal] deliverOnMainThread] subscribeNext:^(ACCStickerSelectionContext * _Nullable x) {
        if (x.stickerType != ACCStickerTypeHashtagSticker && x.stickerType != ACCStickerTypeMentionSticker) {
            return ;
        }
        ACCSocialStickerType socialStickerType = ACCSocialStickerTypeHashTag;
        if (x.stickerType == ACCStickerTypeMentionSticker) {
            socialStickerType = ACCSocialStickerTypeMention;
        }
        @strongify(self)
        [self addSocialStickerWithStickerID:x.stickerModel.effectIdentifier stickerType:socialStickerType effectModelInfo:x.stickerModel];
    }];
    
    [[[[self grootService] sendAutoAddGrootHashtagSignal] deliverOnMainThread]  subscribeNext:^(NSString *  _Nullable x) {
        @strongify(self);
        if (x && [self enableAddSocialStickerType:ACCSocialStickerTypeHashTag]) {
            if ([self stickerService].infoStickerCount >= (ACCConfigInt(kConfigInt_info_sticker_max_count) + 1)) {
                [ACCToast() show:@"infosticker_maxsize_limit_toast"];
                return;
            }
            [self p_setupAutoAddHashtagSticker:x isManual:YES];
        }
    }];
}

/// @todo @qiuhang这一坨老业务代码尽快迁移到sticker config
- (void)p_autoAddHashTagAndMentionStickers
{
    self.autoAddedHashtagArray = [@[] mutableCopy];
    self.autoAddedMentionUserArray = [@[] mutableCopy];

    if (self.repository.repoBirthday.isIMBirthdayPost && self.repository.repoBirthday.atUser) {
        [self.autoAddedMentionUserArray addObject:self.repository.repoBirthday.atUser];
    } else if (self.repository.repoQuickStory.newMention == 1) {
        CGFloat totalHeight = (([self p_totalAutoAddedStickerCount] - 1) * kAutoAddedStickerViewVerticalSpacing) + [self p_totalAutoAddedStickerCount] * 43;
        self.autoAddedStickerLastY = (self.socialStickerHandler.stickerContainerView.playerRect.size.height * 1.5 - totalHeight) / 2;
        if (self.autoAddedStickerLastY < 0) {
            self.autoAddedStickerLastY = 0;
        }
        
        id<ACCUserModelProtocol> user = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createUserModel];
        if (user) {
            ACCSocialStickerView *mentionSticker = [self p_setupAutoAddMentionSticker:user];
            [self.socialStickerHandler editTextStickerView:mentionSticker];
        }
        
        return;
    } else if ([self p_shouldAutoAddedHashTagStickers]) {
        [self.autoAddedMentionUserArray addObjectsFromArray:[self p_convertUserFromTextExtra]];
        
        if (self.autoAddedMentionUserArray.count > 0 && self.repository.repoDuet.isDuet) {
            [self.autoAddedHashtagArray addObject:ACCLocalizedString(@"duet", nil)];
        }
        [self.autoAddedHashtagArray addObjectsFromArray:self.repository.repoChallenge.allChallengeNameArray];
    } else if ([self p_shouldAddDuetHashTagStickers]) {
        // 合拍支持加hashtag,但会过滤掉[@原作者、#合拍]两个标签
        [self.autoAddedHashtagArray addObjectsFromArray:self.repository.repoChallenge.allChallengeNameArray];
    } else {
        for (AWEVideoFragmentInfo *fragmentInfo in self.repository.repoVideoInfo.fragmentInfo.copy) {
            if (fragmentInfo.needAddHashTagForStory && fragmentInfo.challengeInfos.count > 0) {
                for (AWEVideoPublishChallengeInfo *info in fragmentInfo.challengeInfos) {
                    if (info.challengeName.length > 0) {
                        [self.autoAddedHashtagArray addObject:info.challengeName];
                    }
                }
            }
        }
    }

    if ([self p_totalAutoAddedStickerCount] > 0) {
        CGFloat totalHeight = (([self p_totalAutoAddedStickerCount] - 1) * kAutoAddedStickerViewVerticalSpacing) + [self p_totalAutoAddedStickerCount] * 43;
        if (self.repository.repoQuickStory.isNewCityStory) {
            self.autoAddedStickerLastY = 0.8087 * ([UIScreen mainScreen].bounds.size.width / 9 * 16) - (totalHeight / 2) + 1.5 * ACC_IPHONE_X_BOTTOM_OFFSET;
        } else {
            self.autoAddedStickerLastY = (self.socialStickerHandler.stickerContainerView.playerRect.size.height * 1.5 - totalHeight) / 2;
        }
        if (self.autoAddedStickerLastY < 0) {
            self.autoAddedStickerLastY = 0;
        }
        
        [self.socialStickerHandler addAutoAddedStickerViewArray:[self p_autoAddHashtagStickers]];
        [self.socialStickerHandler addAutoAddedStickerViewArray:[self p_autoAddMentionStickers]];
        self.repository.repoSticker.assetCreationDate = nil;
    }
}

- (BOOL)p_shouldAutoAddedHashTagStickers
{
    if (self.repository.repoQuickStory.displayHashtagSticker == 1) {
        return YES;
    }
    ACCShootSameStickerModel *shootSameStickerModel = [self.repository.repoSticker.shootSameStickerModels acc_match:^BOOL(ACCShootSameStickerModel * _Nonnull item) {
        return item.stickerType = AWEInteractionStickerTypeComment;
    }];
    if (shootSameStickerModel != nil || self.repository.repoSticker.videoReplyCommentModel != nil) {
        return NO;
    }
    
    if (self.repository.repoChallengeBind.banAutoAddHashStickers) {
        return NO;
    }
    
    return ![self.repository.repoRecordInfo isCommerceStickerOrMV] && !self.repository.repoDuet.isDuet && (ACCConfigBool(kConfigBool_auto_add_sticker_on_edit_page) ||
        self.repository.repoQuickStory.isAvatarQuickStory ||
        self.repository.repoQuickStory.isNewCityStory);
}

// 对合拍视频是否能使用hashtag做前置判断
- (BOOL)p_shouldAddDuetHashTagStickers
{
    if (!self.repository.repoDuet.isDuet) {
        return NO;
    }
    if ([self.repository.repoRecordInfo shouldForbidCommerce]) {
        return NO;
    }
    if (!(ACCConfigBool(kConfigBool_auto_add_sticker_on_edit_page) ||
          self.repository.repoQuickStory.isAvatarQuickStory)) {
        return NO;
    }
    return self.repository.repoDuet.hasChallenge;
}

- (NSInteger)p_totalAutoAddedStickerCount
{
    return self.autoAddedHashtagArray.count + self.autoAddedMentionUserArray.count;
}

- (NSArray<ACCSocialStickerView *> *)p_autoAddHashtagStickers
{
    NSMutableArray<ACCSocialStickerView *> *stickerViewArray = [@[] mutableCopy];
    if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return [stickerViewArray copy];
    }
    if (self.autoAddedHashtagArray.count > 0) {
        [self.autoAddedHashtagArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [stickerViewArray acc_addObject:[self p_setupAutoAddHashtagSticker:obj isManual:NO]];
        }];
        
    }
    return [stickerViewArray copy];
}

- (ACCSocialStickerView *)p_setupAutoAddHashtagSticker:(NSString *)hashtagName isManual:(BOOL)isManual
{
    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:ACCSocialStickerTypeHashTag effectIdentifier:@"812897"];
    socialStickerModel.isAutoAdded =  !isManual;
    ACCSocialStickerView *stickerView = [self.socialStickerHandler addSocialStickerWithModel:socialStickerModel locationModel:[self p_autoAddedStickerLocationWithManual:isManual] constructorBlock:nil];
    ACCSocialStickeHashTagBindingModel *hashTagModel = [ACCSocialStickeHashTagBindingModel modelWithHashTagName:hashtagName];
    [stickerView bindingWithHashTagModel:hashTagModel];
    if (!isManual) {
        [ACCTracker() trackEvent:@"add_tag_prop" params:@{@"tag_name" : hashtagName ?: @"",
                                                          @"auto_tag" : @(1),
                                                          @"creation_id" : self.repository.repoContext.createId ?: @""}];
        
        // 分析师确认上面老的会被下掉，所以直接新增埋点
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:self.repository.repoTrack.referExtra?:@{}];
        [params addEntriesFromDictionary:stickerView.stickerModel.trackInfo?:@{}];
        params[@"enter_from"] = self.repository.repoTrack.enterFrom ?:@"video_edit_page";
        [ACCTracker() trackEvent:@"add_hashtag_at_sticker" params:[params copy]];
    } else {
        stickerView.hidden = YES;
        stickerView.alpha = 0;
        // groot贴纸自动添加话题贴纸消息，初始化位置会从左上角开始位移
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            stickerView.hidden = NO;
            stickerView.alpha = 1.0;
        });
    }

    return stickerView;
}

- (NSArray<ACCSocialStickerView *> *)p_autoAddMentionStickers
{
    NSMutableArray<ACCSocialStickerView *> *stickerViewArray = [@[] mutableCopy];
    if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return [stickerViewArray copy];
    }
    for (id<ACCUserModelProtocol> user in self.autoAddedMentionUserArray) {
        [stickerViewArray addObject:[self p_setupAutoAddMentionSticker:user]];
    }
    return [stickerViewArray copy];
}

- (NSArray<id<ACCUserModelProtocol>> *)p_convertUserFromTextExtra
{
    NSMutableArray<id<ACCUserModelProtocol>> *userModelArray = [@[] mutableCopy];
    NSArray<id<ACCTextExtraProtocol>> *textExtras = [self.repository.repoPublishConfig.titleExtraInfo ?: @[] copy];
    [textExtras enumerateObjectsUsingBlock:^(id<ACCTextExtraProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.accSubtype == ACCTextExtraSubtypeVideoReplyVideo) {
            return;
        }
        if (obj.accType == ACCTextExtraTypeUser) {
            id<ACCUserModelProtocol> user = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createUserModel];
            if (user) {
                user.followStatus = obj.followStatus;
                user.nickname = obj.nickname;
                user.secUserID = obj.secUserID;
                user.userID = obj.userId;
                [userModelArray addObject:user];
            }
        }
    }];
    return [userModelArray copy];
}

- (ACCSocialStickerView *)p_setupAutoAddMentionSticker:(id<ACCUserModelProtocol>)user
{
    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:ACCSocialStickerTypeMention effectIdentifier:@"812899"];
    socialStickerModel.isAutoAdded = YES;
    ACCSocialStickerView *stickerView =  [self.socialStickerHandler addSocialStickerWithModel:socialStickerModel locationModel:[self p_autoAddedStickerLocationWithManual:NO] constructorBlock:nil];
    //了解这块的同学为qiuhang 和 yangying.iris
    //首先，对于AWEUserModel而言：nickname == user account name，是用户的名称，socialName == 社交场景展示的名称（可能是备注名）
    //其次，mention承载的类是AWETextExtra，通过AWETextExtra是无法获取其socialName的，其只有nickname，对应的也是实际展示的名称，
    //它没有socialName，自然无法赋值给user，同时user中的socialName是readonly，也根本无法被赋值，
    //也就是说在这里通过AWETextExtra创建的user的socialName它一定为空，当前场景下，如果直接取socialName，拿到的就是空
    //因此这里新增了取nickName的逻辑，能够保证可以取到需要的值
    NSString *userName = user.socialName ?: user.nickname;
    ACCSocialStickeMentionBindingModel *mentionModel =  [ACCSocialStickeMentionBindingModel modelWithSecUserId:user.secUserID userId:user.userID userName:userName followStatus:user.followStatus];
    [stickerView bindingWithMentionModel:mentionModel];
    [ACCTracker() trackEvent:@"add_at_prop" params:@{@"to_user_id" : user.userID ?: @"",
                                                     @"auto_at" : @(1),
                                                     @"creation_id" : self.repository.repoContext.createId ?: @""}];
    // 分析师确认上面老的会被下掉，所以直接新增埋点
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:self.repository.repoTrack.referExtra?:@{}];
    [params addEntriesFromDictionary:stickerView.stickerModel.trackInfo?:@{}];
    params[@"enter_from"] = self.repository.repoTrack.enterFrom ?:@"video_edit_page";
    [ACCTracker() trackEvent:@"add_hashtag_at_sticker" params:[params copy]];
    return stickerView;
}

- (AWEInteractionStickerLocationModel *)p_autoAddedStickerLocationWithManual:(BOOL)isManual
{
    AWEInteractionStickerLocationModel *stickerLocation = [[AWEInteractionStickerLocationModel alloc] init];
    
    CGFloat offsetY = (self.autoAddedStickerLastY + kAutoAddedStickerViewH / 2) / self.socialStickerHandler.stickerContainerView.playerRect.size.height;
    CGFloat offsetX = 0.5;
    if (self.repository.repoQuickStory.isAvatarQuickStory && !ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish)) {
        offsetY = 0.75f;
        offsetX = 0.50f;
    }
    if ([self p_totalAutoAddedStickerCount] == 0) {
        offsetY = 0.75;
    }

    if (self.repository.repoBirthday.isIMBirthdayPost) {
        offsetX = 0.5;
        offsetY = 0.5 - (67.5 / 812);
    }
    
    if (isManual) {
        offsetX = 0.5f;
        offsetY = 0.5f;
    }
    
    self.autoAddedStickerLastY += kAutoAddedStickerViewH + kAutoAddedStickerViewVerticalSpacing;
    
    NSString *offsetXStr = [NSString stringWithFormat:@"%.4f", offsetX];
    NSString *offsetYStr = [NSString stringWithFormat:@"%.4f", offsetY];
    stickerLocation.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
    stickerLocation.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
    
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", self.socialStickerHandler.player.stickerInitialEndTime];
    stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    return stickerLocation;
}

- (ACCSocialStickerHandler *)socialStickerHandler {
    
    if (!_socialStickerHandler) {
        ACCSocialStickerDataProvider *dataProvider = [[ACCSocialStickerDataProvider alloc] init];
        dataProvider.repository = self.repository;
        _socialStickerHandler = [[ACCSocialStickerHandler alloc] initWithDataProvider:dataProvider publishModel:self.repository];
        @weakify(self);
        [_socialStickerHandler setOnTimeSelect:^(ACCSocialStickerView * _Nonnull stickerView) {
            @strongify(self);
            [self selectTimeWithSocialStickerView:stickerView];
        }];
        _socialStickerHandler.editViewOnStartEdit = ^(ACCSocialStickerType type){
            @strongify(self);
            [self showEditView:NO animation:YES type:type];
        };
        _socialStickerHandler.editViewOnFinishEdit = ^(ACCSocialStickerType type){
            @strongify(self);
            [self showEditView:YES animation:YES type:type];
        };
    }
    
    return _socialStickerHandler;
}

- (void)addSocialStickerWithStickerID:(NSString *)stickerID stickerType:(ACCSocialStickerType)stickerType effectModelInfo:(IESEffectModel *)effectModel {
    if (![self enableAddSocialStickerType:stickerType]) {
        return;
    }
    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:stickerType effectIdentifier:stickerID];
    socialStickerModel.extraInfo = effectModel.extra;
    ACCSocialStickerView *stickerView =  [self.socialStickerHandler addSocialStickerWithModel:socialStickerModel locationModel:nil constructorBlock:nil];
    [self.socialStickerHandler editTextStickerView:stickerView];
}

- (BOOL)enableAddSocialStickerType:(ACCSocialStickerType)stickerType 
{
    NSInteger maxSocialBindCount = [ACCTextStickerSettingsConfig allStickerEachSociaMaxBindCount];
    
    if (stickerType == ACCSocialStickerTypeMention &&
        [self.socialStickerHandler allMentionCountInSticker] >= maxSocialBindCount) {
        
        [ACCToast() show:[NSString stringWithFormat:@"每条视频最多@%i个人", (int)maxSocialBindCount]];
        return NO;
    }
    
    if (stickerType == ACCSocialStickerTypeHashTag &&
        [self.socialStickerHandler allHashtahCountInSticker] >= maxSocialBindCount) {
        
        [ACCToast() show:[NSString stringWithFormat:@"每条视频最多添加%i个话题", (int)maxSocialBindCount]];
        return NO;
    }
    return YES;
}

- (void)showEditView:(BOOL)show animation:(BOOL)animation type:(ACCSocialStickerType)type
{
    CGFloat alpha = show ? 1 : 0;
    ACCStickerType stickerType = (type == ACCSocialStickerTypeMention) ? ACCStickerTypeMentionSticker : ACCStickerTypeHashtagSticker;
    if (show) {
        [[self stickerService] finishEditingStickerOfType:stickerType];
    } else {
        [[self stickerService] startEditingStickerOfType:stickerType];
    }
    
    if (animation) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.viewContainer.containerView.alpha = alpha;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.viewContainer.containerView.alpha = alpha;
    }
}

- (void)selectTimeWithSocialStickerView:(ACCSocialStickerView *)stickerView
{
    [self.selectTimeManager modernEditStickerDuration:[self.stickerService.stickerContainer stickerViewWithContentView:stickerView]];
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{    
    if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }

    { /* ························· socialStick process unit ··························· */

        NSNumber *matchingSocialStickType = acc_matchedSocialStickTypeWithEffectTagList(sticker.tags);
        // matched social stick
        if (matchingSocialStickType != nil) {
            ACCStickerType stickerType = ACCStickerTypeMentionSticker;
            if ([matchingSocialStickType integerValue] == ACCSocialStickerTypeHashTag) {
                stickerType = ACCStickerTypeHashtagSticker;
            }
            ACCBLOCK_INVOKE(willSelectHandle);
            ACCBLOCK_INVOKE(dismissPanelHandle, stickerType, NO);
            return YES;
        }
    }

    return NO;
}

- (ACCStickerPannelObserverPriority)stikerPriority {
    return ACCStickerPannelObserverPriorityNone;
}

#pragma mark - getter
- (BOOL)shouldHandleAutoAddSocialInfoForRepository:(AWEVideoPublishViewModel *)repository
{
    if (repository.repoDraft.isDraft ||
        repository.repoDraft.isBackUp ||
        repository.repoImageAlbumInfo.isImageAlbumEdit ||
        (repository.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode && self.repository.repoSticker.appliedAutoSocialStickerInAlbumMode) ||
        repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        
        return NO;
    }
    
    return YES;
}

- (ACCEditStickerSelectTimeManager *)selectTimeManager
{
    if (!_selectTimeManager) {
        _selectTimeManager = [[ACCEditStickerSelectTimeManager alloc] initWithEditService:self.editService repository:self.repository player:self.stickerService.compoundHandler.player stickerContainer:self.stickerService.stickerContainer transitionService:self.transitionService];
    }
    return _selectTimeManager;
}


#pragma mark - ACCDraftResourceRecoverProtocol
+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return @[];
}

+ (void)regenerateTheNecessaryResourcesForPublishViewModel:(AWEVideoPublishViewModel *)publishModel completion:(nonnull ACCDraftRecoverCompletion)completion
{
    // recover image source
    __block NSUInteger socialStickerIndex = -1;
    [publishModel.repoVideoInfo.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sticker.acc_stickerType == ACCEditEmbeddedStickerTypeSocial) {
            socialStickerIndex++;
            if (ACC_isEmptyString(sticker.resourcePath)) {
                NSString *iosResourcePath = [sticker.userinfo acc_stringValueForKey:ACCCrossPlatformiOSResourcePathKey];
                if (ACC_isEmptyString(iosResourcePath)) {
                    if (sticker.resourcePath == nil || sticker.resourcePath.length == 0) {
                        NSString *socialStickerUniqueId = [sticker.userinfo acc_stringValueForKey:kSocialStickerUserInfoUniqueIdKey];
                        if (ACC_isEmptyString(socialStickerUniqueId)) {
                            return;
                        }
                        
                        AWEInteractionStickerModel *interactionStickerModel = [publishModel.repoSticker.interactionStickers acc_match:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
                            return item.trackInfo
                            && (item.type == AWEInteractionStickerTypeHashtag || item.type == AWEInteractionStickerTypeMention)
                            && [item.localStickerUniqueId isEqualToString:socialStickerUniqueId];
                        }];
                        if (interactionStickerModel == nil) {
                            return;
                        }
                        
                        NSNumber *matchedSocialStickerType = acc_convertSocialStickerTypeFromInteractionStickerType(interactionStickerModel.type);
                        if (matchedSocialStickerType == nil) {
                            return;
                        }
                        NSString *draftJsonString = [sticker.userinfo acc_stringValueForKey:kSocialStickerUserInfoDraftJsonDataKey];
                        if (ACC_isEmptyString(draftJsonString)) {
                            return;
                        }
                        ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:matchedSocialStickerType.integerValue
                                                                                                      effectIdentifier:interactionStickerModel.stickerID];
                        [socialStickerModel recoverDataFromDraftJsonString:draftJsonString];
                        
                        ACCSocialStickerView *stickerView = [[ACCSocialStickerView alloc] initWithStickerModel:socialStickerModel socialStickerUniqueId:socialStickerUniqueId];
                        UIImage *socialImage = [stickerView acc_imageWithViewOnScale:1.8];
                        NSData *imageData = UIImagePNGRepresentation(socialImage);
                        if (imageData && imageData.length > 0) {
                            NSString *imagePath = [AWEDraftUtils generateModernSocialPathFromTaskId:publishModel.repoDraft.taskID index:socialStickerIndex];
                            BOOL saveRst = [imageData acc_writeToFile:imagePath atomically:YES];
                            if (saveRst) {
                                sticker.resourcePath = imagePath;
                            }
                        }
                    }
                } else {
                    if ([iosResourcePath hasPrefix:@"./"]) {
                        iosResourcePath = [iosResourcePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
                    }
                    sticker.resourcePath = [AWEDraftUtils generatePathFromTaskId:publishModel.repoDraft.taskID name:iosResourcePath];
                }
            }
        }
    }];
    
    ACCBLOCK_INVOKE(completion, nil, NO);
}

@end
