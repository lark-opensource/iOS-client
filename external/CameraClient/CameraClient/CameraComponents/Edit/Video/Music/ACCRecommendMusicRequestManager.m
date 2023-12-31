//
//  ACCRecommendMusicRequestManager.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/8.
//

#import "ACCRecommendMusicRequestManager.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import "AWERepoMusicModel.h"
#import "ACCVideoMusicListResponse.h"
#import "ACCCommerceServiceProtocol.h"
#import "AWERepoContextModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWEAIMusicRecommendManager.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCConfigKeyDefines.h"
#import "ACCVideoEditMusicConfigProtocol.h"
#import "ACCVideoEditMusicViewModel.h"

@interface ACCRecommendMusicRequestManager ()

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) BOOL autoDegradeSelectHotMusic;

@property (nonatomic, assign) BOOL hotMusicIsProcessing;
@property (nonatomic, assign) BOOL hotMusicHasMore;
@property (nonatomic, assign) BOOL hotMusicFirstLoading;
@property (nonatomic, strong) NSNumber *hotMusicCursor;
@property (nonatomic, assign) BOOL usedHotMusicDefaultMusicList;


@property (nonatomic, assign) BOOL aiMusicIsProcessing;
@property (nonatomic, assign) BOOL aiMusicHasMore;
@property (nonatomic, assign) BOOL aiMusicFirstLoading;
@property (nonatomic, strong) NSNumber *aiMusicCursor;

@end

@implementation ACCRecommendMusicRequestManager

- (instancetype)initWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    self = [super init];
    if (self) {
        self.repository = publishViewModel;
        self.hotMusicFirstLoading = YES;
        self.aiMusicFirstLoading = YES;
        self.autoDegradeSelectHotMusic = NO;
        [self resetRequestParams];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self resetRequestParams];
        self.hotMusicFirstLoading = YES;
        self.aiMusicFirstLoading = YES;
        self.autoDegradeSelectHotMusic = NO;
    }
    return self;
}

- (void)resetRequestParams {
 
    _hotMusicHasMore = YES;
    _hotMusicCursor = @(0);
    
    _aiMusicHasMore = YES;
    _aiMusicCursor = @(0);
}

#pragma mark - public

- (BOOL)canUseLoadMore {
    if([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository]) {
        return YES;
    }
    
    if ([self shouldUseMusicDataFromHost]) {
        return NO;
    }
    
    if ([self usedNewClipForMultiUploadVideosFetchHotMusic]) {
        return NO;
    }
        
    BOOL musicPanelVertical = ACCConfigBool(kConfigBool_studio_music_panel_vertical);
    BOOL musicPanelCheckbox = ACCConfigBool(kConfigBool_studio_music_panel_checkbox);
    if (!musicPanelVertical && !musicPanelCheckbox) {
        return NO;
    }
    
    return YES;
}

- (BOOL)useHotMusic {
    // 可以抽帧则使用AI抽帧列表，拍摄器只能使用hot music
    if (![self shouldUseAIRecommendationMusic] || self.autoDegradeSelectHotMusic) {
        return YES;
    }
    return NO;
}

- (BOOL)usedNewClipForMultiUploadVideosFetchHotMusic {  // 新裁减多段视频音乐卡点使用hotmusic卡点音乐
    if ([self.repository.repoContext newClipForMultiUploadVideos] && !ACC_isEmptyArray(self.repository.repoMusic.musicList)) {
        return YES;
    }
    return NO;
}

- (BOOL)autoDegradedSelectHotMusicDataSourceSuccess:(BOOL)degradation {
    BOOL enableDegradedMusic = ACCConfigBool(kConfigBool_music_panel_request_with_current_state);
    if (enableDegradedMusic) { // 允许降级使用热门音乐
        self.autoDegradeSelectHotMusic = degradation;
    } else {
        self.autoDegradeSelectHotMusic = NO;
    }
    return self.autoDegradeSelectHotMusic;
}

- (BOOL)shouldUseAIRecommendationMusic {
    return [ACCVideoEditMusicViewModel shouldUploadBachOrFrameForRecommendation];
}

- (void)fetchInfiniteHotMusic:(void (^)(void))fetchResultBlock {
    if (self.hotMusicIsProcessing) {
        return;
    }
    self.hotMusicIsProcessing = YES;
    @weakify(self);
    [self p_fetchMusicListFromLibWithCompletion:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSError * _Nullable error) {
        @strongify(self);
        if (!error && [musicList count]) {
            self.usedHotMusicDefaultMusicList = NO;
            self.hotMusicIsProcessing = NO;
            self.hotMusicFirstLoading = NO;
            self.hotMusicHasMore = hasMore.boolValue;
            self.hotMusicCursor = cursor ?: self.hotMusicCursor;
            if (self.repository.repoMusic.musicList != nil) {
                NSMutableArray<id<ACCMusicModelProtocol>> *musicAppendList = [self.repository.repoMusic.musicList mutableCopy];
                if ([self.hotMusicCursor isEqualToNumber:@(0)]) {  //已经存音乐列表，cousor为0时重置所有的音乐
                    musicAppendList = [@[] mutableCopy];
                }
                [musicAppendList addObjectsFromArray:musicList];
                self.repository.repoMusic.musicList = musicAppendList;
            } else {
                self.repository.repoMusic.musicList = musicList;
            }
            if (!self.autoDegradeSelectHotMusic) { // 降级使用热门音乐时不清除AI推荐兜底音乐
                [[AWEAIMusicRecommendManager sharedInstance] cleanRecommedMusicList];
            }
            ACCBLOCK_INVOKE(fetchResultBlock);
        } else {
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"fetchDefaultMusicListFromLib: %@", error);
            }
            
            if (![self.hotMusicCursor isEqualToNumber:@(0)]) {
                // cursour为0时才需要使用兜底的音乐
                self.hotMusicIsProcessing = NO;
                self.hotMusicFirstLoading = NO;
                ACCBLOCK_INVOKE(fetchResultBlock);
                return;
            }
            
            [self p_fetchDefaultMusicListWithCompletion:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
                @strongify(self);
                self.hotMusicIsProcessing = NO;
                self.hotMusicFirstLoading = NO;
                self.usedHotMusicDefaultMusicList = YES;
                if (musicList.count > 0) {
                    if ([self.repository.repoMusic.musicList count] == 0) {
                        NSMutableArray<id<ACCMusicModelProtocol>> *musicAppendList = [musicList mutableCopy];
                        self.repository.repoMusic.musicList = musicAppendList;
                    } else {
                        self.repository.repoMusic.musicList = musicList;
                    }
                    if (!self.autoDegradeSelectHotMusic) {
                        [[AWEAIMusicRecommendManager sharedInstance] cleanRecommedMusicList];
                    }
                    ACCBLOCK_INVOKE(fetchResultBlock);
                } else {
                    if (error) {
                        AWELogToolError(AWELogToolTagMusic, @"fetchDefaultMusicListFromDefault: %@", error);
                    }
                    ACCBLOCK_INVOKE(fetchResultBlock);
                }
            }];
        }
    }];
}

- (void)fetchInfiniteAIRecommendMusicWithURI:(NSString *)zipUri isCommercialScene:(BOOL)isCommercialScene fetchResultBlock:(void (^)(void))fetchResultBlock {
    if (self.aiMusicIsProcessing) {
        return;
    }
    self.aiMusicIsProcessing = YES;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"cursor"] = self.aiMusicCursor;
    if (![self canUseLoadMore]) {
        // 不支持loadMore则重置游标为0进行列表刷新
        self.aiMusicCursor = @0;
        self.aiMusicHasMore = NO;
        params[@"cursor"] = self.aiMusicCursor;
    }
    
    if (isCommercialScene) {
        params[@"scene"] = @2;
    }
    
    @weakify(self);
    [[AWEAIMusicRecommendManager sharedInstance] fetchAIRecommendMusicWithURI:zipUri otherParam:params laodMoreCallback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber * _Nonnull hasMore, NSNumber * _Nonnull cursor, NSError * _Nullable error) {
        @strongify(self);
        self.aiMusicFirstLoading = NO;
        self.aiMusicIsProcessing = NO;
        if (!error && [musicList count]) {
            if ([self canUseLoadMore]) {
                self.aiMusicHasMore = hasMore.boolValue;
                self.aiMusicCursor = cursor ?: self.aiMusicCursor;
            } else {
                self.aiMusicHasMore = NO;
                self.aiMusicCursor = @0;
            }
            self.repository.repoMusic.musicList = musicList;
            ACCBLOCK_INVOKE(fetchResultBlock);
        } else {
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"fetchAIRecommendMusicWithURI: %@", error);
            }
            
            if (![self.aiMusicCursor isEqualToNumber:@(0)]) {
                // cursour为0时才需要使用兜底的音乐
                ACCBLOCK_INVOKE(fetchResultBlock);
                return;
            }
            
            if (musicList.count > 0) {
                self.repository.repoMusic.musicList = musicList;
            }
            ACCBLOCK_INVOKE(fetchResultBlock);
        }
    }];
}

- (BOOL)usedDefaultMusicList { // 音乐面板音乐列表数据源，判定是否正在使用兜底音乐列表
    if ([self usedNewClipForMultiUploadVideosFetchHotMusic]) {
        return NO;
    }
    if ([self useHotMusic]) {
        return self.usedHotMusicDefaultMusicList;
    } else {
        return [AWEAIMusicRecommendManager sharedInstance].usedAIRecommendDefaultMusicList;
    }
}

#pragma mark - private

/**
 * 从曲库拉取推荐的音乐列表。
 */
- (void)p_fetchMusicListFromLibWithCompletion:(void(^)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSError * _Nullable error))completion {
    // 拉取曲库推荐的音乐列表
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"creation_id"] = self.repository.repoContext.createId;
    params[@"video_duration"] = @((int64_t)([self.repository.repoVideoInfo.video totalVideoDuration] * 1000)); // 单位毫秒
    
    NSNumber *count = @(20);
    params[@"cursor"] = self.hotMusicCursor;
    if (![self canUseLoadMore]) {
        self.hotMusicCursor = @0;
        self.hotMusicHasMore = NO;
        params[@"cursor"] = self.hotMusicCursor;
    }
    
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestAIRecommendMusicListWithZipURI:nil count:count otherParams:params loadMoreCompletion:^(ACCVideoMusicListResponse * _Nullable response, NSNumber * _Nonnull hasMore, NSNumber * _Nonnull cursor, NSError * _Nullable error) {
        NSNumber *hotHasMore = response.hasMore;
        NSNumber *hotCursor = response.cursor;
        if (![self canUseLoadMore]) {
            hotHasMore = @(NO);
            hotCursor = @0;
        }
        ACCBLOCK_INVOKE(completion, response.musicList, hotHasMore, hotCursor, error);
    }];
}

/**
 * 拉取默认的音乐列表。
 */
- (void)p_fetchDefaultMusicListWithCompletion:(void(^)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error))completion
{
    // 拉取默认的兜底音乐列表
    //read cache
    NSString *cached_uri = [ACCCache() objectForKey:kAWEAIMusicRecommendCacheURIKey];
    NSString *settings_music_uri = ACCConfigString(kConfigString_ai_recommend_music_list_default_uri);
    if (cached_uri && settings_music_uri && [cached_uri isEqualToString:settings_music_uri]) {
        NSArray<id<ACCMusicModelProtocol>> * cachedList = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicListWithCacheKey:kAWEAIMusicRecommendDefaultMusicCacheKey];
        if ([cachedList count]) {
            ACCBLOCK_INVOKE(completion, cachedList, nil);
            return;
        }
    }
    
    //save cache
    if ([settings_music_uri length]) {
        [ACCCache() setObject:settings_music_uri forKey:kAWEAIMusicRecommendCacheURIKey];
    }
    
    //fetch default music list from tos
    NSArray *tos_list = ACCConfigArray(kConfigArray_ai_recommend_music_list_default_url_lists);
    if (![tos_list count]) {
        ACCBLOCK_INVOKE(completion, nil, nil);
        return;
    }
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchDefaultMusicListWithURLGoup:tos_list callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
        ACCBLOCK_INVOKE(completion, musicList, error);
    }];
}

#pragma mark - 使用宿主提供的音乐数据(此数据源供外部业务方调用，抖音不适用 owner:张志豪)

- (BOOL)shouldUseMusicDataFromHost
{
    let editMusicConfig = IESOptionalInline(ACCBaseServiceProvider(), ACCVideoEditMusicConfigProtocol);
    if ([editMusicConfig respondsToSelector:@selector(enableUseMusicFromHost)]) {
        return [editMusicConfig enableUseMusicFromHost];
    }
    return NO;
}

@end
