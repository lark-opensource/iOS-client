//
//  AWEMusicStickerRecommendManager.m
//  CameraClient
//
//  Created by Liu Deping on 2019/10/15.
//

#import "AWEMusicStickerRecommendManager.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoMusicModel.h"
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCVideoMusicListResponse.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEEditAlgorithmManager.h>

@interface AWEMusicStickerRecommendManager ()

@property (nonatomic, copy, readwrite) NSArray<id<ACCMusicModelProtocol>> *recommendMusicList;
@property (nonatomic, copy) NSString *zipURI;

@end

@implementation AWEMusicStickerRecommendManager

+ (instancetype)sharedInstance
{
    static AWEMusicStickerRecommendManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWEMusicStickerRecommendManager alloc] init];
    });
    return instance;
}

- (void)fetchRecommendMusicWithRepository:(nullable AWEVideoPublishViewModel *)repository
                                 callback:(nullable AWEAIMusicRecommendFetchCompletion)completion
{
    if (!repository || repository.repoDuet.isDuet) {
        ACCBLOCK_INVOKE(completion,nil,[AWEAIMusicRecommendTask errorOfAIRecommend]);
        return;
    }
    BOOL useBach = [[AWEEditAlgorithmManager sharedManager] useBachToRecommend];
    NSString *uriToUse = useBach ? repository.repoMusic.binURI : repository.repoMusic.zipURI;
    if (ACC_isEmptyString(uriToUse)) {
        NSArray * tos_list = ACCConfigArray(kConfigArray_ai_recommend_music_list_default_url_lists);
        [[AWEAIMusicRecommendManager sharedInstance] fetchDefaultMusicListFromTOSWithURLGoup:tos_list callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
            ACCBLOCK_INVOKE(completion, musicList, error);
        }];
        return;
    }
    if ([self.zipURI isEqualToString:uriToUse] && self.recommendMusicList.count > 0) {
        ACCBLOCK_INVOKE(completion, self.recommendMusicList, nil);
        return;
    }
    self.recommendMusicList = [NSArray array];
    NSMutableDictionary *params = [@{@"scene" : @"aweme_sticker", @"video_duration" : @((int64_t)([repository.repoVideoInfo.video totalVideoDuration] * 1000))} mutableCopy];
    
    if ([uriToUse isKindOfClass:[NSString class]]) {
       if ([uriToUse length]) {
           if (useBach) {
               params[@"lab_extra"] = [@{@"embedding_uri" : uriToUse} acc_dictionaryToJson];
           } else {
               params[@"zip_uri"] = uriToUse;
           }
       }
    }
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestAIRecommendMusicListWithZipURI:repository.repoMusic.zipURI count:@50 otherParams:params completion:^(ACCVideoMusicListResponse *_Nullable response, NSError * _Nullable error) {
        @strongify(self);
        if (response.musicList.count > 0) {
            self.recommendMusicList = response.musicList;
            ACCBLOCK_INVOKE(completion, self.recommendMusicList, nil);
        } else {
            AWELogToolError2(@"recommendMusic", AWELogToolTagMusic, @"fetchRecommendMusic failed: %@", error);
            NSArray * tos_list = ACCConfigArray(kConfigArray_ai_recommend_music_list_default_url_lists);
            [[AWEAIMusicRecommendManager sharedInstance] fetchDefaultMusicListFromTOSWithURLGoup:tos_list callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
                ACCBLOCK_INVOKE(completion, musicList, error);
            }];
        }
    }];
}

@end
