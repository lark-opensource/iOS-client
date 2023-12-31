//
//  ACCPropRecommendMusicReponseModel.m
//  CameraClient
//
//  Created by xiaojuan on 2020/8/10.
//

#import "ACCPropRecommendMusicReponseModel.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEStickerMusicManager.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCPropRecommendMusicReponseModel

+ (void)fetchStickerRecommendMusicList:(IESEffectModel *)sticker
                              createId:(NSString *)createId
                     completionHandler:(nonnull void (^)(ACCPropRecommendMusicReponseModel * _Nullable, NSError * _Nullable))completionHandler
{
    if (sticker.effectIdentifier.length == 0) {
        if (completionHandler) {
            completionHandler(nil, nil);
        }
        return;
    }
    
    // 开始请求道具推荐音乐列表
    
    let musicNetService = IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol);
    
    dispatch_group_t group = dispatch_group_create();
    
    // 推荐音乐列表
    __block NSArray<id<ACCMusicModelProtocol>> *recommendMusicList = nil;
    __block NSString *bubbleTitle = nil;
    __block NSError *recommendError = nil;
    
    // 弱绑定音乐
    __block id<ACCMusicModelProtocol> weakBindMusic = nil;
    __block NSError *weakBindError = nil;
    
    CFTimeInterval start = CFAbsoluteTimeGetCurrent();

    if (sticker.musicIDs && !ACC_isEmptyArray(sticker.musicIDs)) {
        dispatch_group_enter(group);
        [musicNetService requestMusicItemWithID:sticker.musicIDs.firstObject completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
            if (model && !error) {
                weakBindMusic = model;
            } else {
                weakBindError = error;
                AWELogToolError(AWELogToolTagRecord, @"recommended music requestMusicItemWithID error: %@", error);
            }
            dispatch_group_leave(group);
        }];
    }
    
    //不仅带弱绑定音乐展示气泡
    if (ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) != ACCRecommendMusicByPropA) {
        dispatch_group_enter(group);
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
        params[@"effect_id"] = sticker.effectIdentifier ? : @"";
        params[@"creation_id"] = createId ? : @"";
        NSString *urlStr = [NSString stringWithFormat:@"%@/aweme/v1/music/recommend/effect/", [ACCNetService() defaultDomain]];
        [musicNetService fetchMusicListWithURL:urlStr params:params completion:^(ACCPropRecommendMusicReponseModel * _Nonnull model, NSError * _Nonnull error) {
            //这里需要加上请求的端监控
            if (!error && model) {
                recommendMusicList = model.recommendMusicList;
                bubbleTitle = model.bubbleTitle;
            } else {
                recommendError = error;
                AWELogToolError(AWELogToolTagRecord, @"recommended music fetchMusicListWithURL error: %@", error);
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        // type: 0-Only recommend, 1-Only weak bind music detail, 2-Both
        NSNumber *type = @(1); // Default : 1
        if (!weakBindMusic) {
            type = @(0);
        } else if(ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) > ACCRecommendMusicByPropA) {
            type = @(2);
        }
        NSDictionary *params = @{@"effectId" : sticker.effectIdentifier ? : @"",
                                 @"duration"  : @((CFAbsoluteTimeGetCurrent() - start) * 1000),
                                 @"errorCodeRecommend"  : @(recommendError.code),
                                 @"errorCodeWeak"  : @(weakBindError.code),
                                 @"type" : type};
        [ACCMonitor() trackService:@"effect_recommend_music_duration"
                            status:(recommendError || weakBindError) ? 1 : 0
                             extra:params];
        
        // 推荐列表和弱绑定音乐任意拉取成功
        if (recommendMusicList.count > 0 || weakBindMusic) {
            ACCPropRecommendMusicReponseModel *responseModel = [[ACCPropRecommendMusicReponseModel alloc] init];
            responseModel.recommendMusicList = recommendMusicList;
            responseModel.bubbleTitle = bubbleTitle;
            responseModel.weakBindMusic = weakBindMusic;
            
            if (completionHandler) {
                completionHandler(responseModel, nil);
            }
        } else {
            if (completionHandler) {
                completionHandler(nil, recommendError ?: weakBindError);
            }
        }
    });
}

+ (BOOL)shouldForbidRequestRecommendMusicInfoWithEffectModel:(IESEffectModel *)effect
{
    // Priority(AB test): Story record optimization > Prop music recommendation
    return ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) == ACCRecommendMusicByPropDefault ||
    [AWEStickerMusicManager musicIsForceBindStickerWithExtra:effect.extra] ||
    effect.isCommerce ||
    effect.isEffectControlGame;
}

@end
