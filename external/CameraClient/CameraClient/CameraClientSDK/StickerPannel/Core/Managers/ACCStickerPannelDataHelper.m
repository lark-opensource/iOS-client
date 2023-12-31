//
//  ACCStickerPannelDataHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/22.
//

#import "ACCStickerPannelDataHelper.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <EffectPlatformSDK/IESInfoStickerResponseModel.h>
#import <EffectPlatformSDK/IESInfoStickerListResponseModel.h>
#import <EffectPlatformSDK/EffectPlatform+InfoSticker.h>

@implementation ACCStickerPannelDataRequest

@end

@implementation ACCStickerPannelDataResponse

@end

@implementation ACCStickerPannelDataHelper

+ (void)downloadInfoSticker:(IESInfoStickerModel *)sticker trackParams:(NSDictionary *)trackParams progressBlock:(void(^)(CGFloat progress))progressBlock completion:(void(^)(NSError *, NSString *))completion
{
    if ([sticker downloaded]) {
        ACCBLOCK_INVOKE(completion, nil, sticker.filePath);
        return;
    }
    ACCBLOCK_INVOKE(progressBlock, 0.f);
    CFTimeInterval singleStickerStartTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform dowloadInfoStickerModel:sticker downloadQueuePriority:NSOperationQueuePriorityHigh downloadQualityOfService:NSQualityOfServiceDefault progress:progressBlock completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        NSInteger duration = (CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000;
        [ACCStickerPannelDataHelper p_logSingleStickerDownloaded:sticker trackParams:trackParams error:error filePath:filePath duration:duration];
        ACCBLOCK_INVOKE(completion, error, sticker.filePath);
    }];
}

+ (void)fetchInfoStickerPannelData:(ACCStickerPannelDataRequest *)params completion:(void(^)(BOOL, ACCStickerPannelDataResponse *response))completion
{
    NSDictionary *extraParams = @{
        @"image_uri" : params.uploadURI ? : @"",
        @"creation_id" : params.creationId ? : @"",
        @"source" : @1
    };
    
    __block IESInfoStickerResponseModel *recommendResult = nil;
    __block IESInfoStickerListResponseModel *lokiResult = nil;
    __block NSError *recommendError = nil;
    __block NSError *lokiError = nil;
    
    NSDictionary *configs = ACCConfigDict(kConfigDict_modern_sticker_panel_config);
    NSInteger pageCount = [configs btd_integerValueForKey:@"pageCount"] ? : 50;
    NSString *panel = @"infostickerv2";
    if (!ACC_isEmptyString(params.customPanelName)) {
        panel = params.customPanelName;
    }
    NSString *requestLoadTimeKey = @"modern_sticker_pannel_load_time";
    
    [ACCMonitor() startTimingForKey:requestLoadTimeKey];
    dispatch_group_t group = dispatch_group_create();
    if (params.uploadURI.length) {
        dispatch_group_enter(group);
        [EffectPlatform fetchInfoStickerRecommendListWithType:@"lab"
                                                    pageCount:pageCount
                                                       cursor:0
                                                    effectIDs:nil
                                              extraParameters:extraParams
                                                   completion:^(NSError * _Nullable error, IESInfoStickerResponseModel * _Nullable response) {
            if (!error) {
                recommendResult = response;
            }
            recommendError = error;
            AWELogToolError(AWELogToolTagEdit, @"modern sticker pannel recommend request error: %@", error);
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_enter(group);
    [EffectPlatform checkInfoStickerListUpdateWithPanel:panel completion:^(BOOL needUpdate) {
        IESInfoStickerListResponseModel *response = [EffectPlatform cachedInfoStickerListWithPanel:panel];
        if (needUpdate || (!response.stickerList.count && !response.categoryList.count)) {
            [EffectPlatform fetchInfoStickerListWithPanel:panel
                                     effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                                saveCache:YES
                                          extraParameters:extraParams
                                               completion:^(NSError *error, IESInfoStickerListResponseModel *response) {
                if (!error) {
                    lokiResult = response;
                }
                lokiError = error;
                AWELogToolError(AWELogToolTagEdit, @"modern sticker pannel loki request error: %@", error);
                dispatch_group_leave(group);
            }];
        } else {
            lokiResult = response;
            dispatch_group_leave(group);
        }
    }];
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSInteger errorStatus = 0;
        if (!lokiError && !recommendError) {
            ACCStickerPannelDataResponse *reponse = [ACCStickerPannelDataHelper merge:params recommendData:recommendResult pannelData:lokiResult];
            ACCBLOCK_INVOKE(completion, YES, reponse);
        } else {
            if (lokiError) { errorStatus += 1; }
            if (recommendError) { errorStatus += 2; }
            ACCBLOCK_INVOKE(completion, NO, nil);
        }
        [ACCMonitor() trackService:requestLoadTimeKey status:errorStatus extra:@{@"duration":@([ACCMonitor() timeIntervalForKey:requestLoadTimeKey])}];
        [ACCMonitor() cancelTimingForKey:requestLoadTimeKey];
    });
}

+ (ACCStickerPannelDataResponse *)merge:(ACCStickerPannelDataRequest *)request
                          recommendData:(IESInfoStickerResponseModel *)recommendModel
                             pannelData:(IESInfoStickerListResponseModel *)pannelModel
{
    ACCStickerPannelDataResponse *responseParams = [[ACCStickerPannelDataResponse alloc] init];
    
    // 推荐接口辅助数据
    NSMutableArray *recommendList = [[NSMutableArray alloc] init];
    NSMutableDictionary *recommendMap = [[NSMutableDictionary alloc] init];
    [recommendModel.stickerList enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sticker.stickerIdentifier &&
            ![ACCStickerPannelDataHelper p_shouldFilter:sticker tags:request.filterTags]) {
            [recommendMap btd_setObject:sticker forKey:sticker.stickerIdentifier];
            [recommendList btd_addObject:sticker];
        }
    }];

    // 面板接口辅助数据
    NSMutableArray *lokiList = pannelModel.categoryList.count ? nil : [[NSMutableArray alloc] init];// 有分类时不需要这个
    NSMutableDictionary *lokiMap = pannelModel.categoryList.count ? [[NSMutableDictionary alloc] init] : nil;// 无分类时不需要这个
    [pannelModel.stickerList enumerateObjectsUsingBlock:^(IESInfoStickerModel * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sticker.childrenIds.count) {
            [sticker updateChildrenStickersWithCollection:pannelModel.collectionStickerList];
        }
        if (sticker.stickerIdentifier &&
            ![recommendMap objectForKey:sticker.stickerIdentifier] &&
            ![ACCStickerPannelDataHelper p_shouldFilter:sticker tags:request.filterTags]) {
            [lokiMap btd_setObject:sticker forKey:sticker.stickerIdentifier];
            [lokiList btd_addObject:sticker];
        }
    }];

    // 构造拼接数据
    if (pannelModel.categoryList.count) {
        NSMutableArray<IESInfoStickerCategoryModel *> *categoryList = [[NSMutableArray alloc] init];
        NSString *recommendId = [ACCConfigDict(kConfigDict_modern_sticker_panel_config) btd_stringValueForKey:@"recommendId"] ? : @"6566";
        BOOL shouldUseRecommend = recommendList.count > 0;
        for (IESInfoStickerCategoryModel *category in pannelModel.categoryList) {
            // 放入推荐数据
            if (shouldUseRecommend && [category.categoryID isEqualToString:recommendId]) {
                [category replaceWithStickers:[recommendList copy]];
                shouldUseRecommend = NO;
            }
            // 放入面板数据
            if (category.infoStickerList.count) {
                [categoryList btd_addObject:category];
            } else {
                [category fillStickersWithStickersMap:lokiMap];
                [categoryList btd_addObject:category];
            }
        }
        responseParams.categories = [categoryList copy];
    } else {
        if (lokiList) {
            [recommendList addObjectsFromArray:lokiList];
        }
        responseParams.effects = [recommendList copy];
    }
    return responseParams;
}

+ (BOOL)p_shouldFilter:(IESInfoStickerModel *)sticker tags:(NSArray<NSString *> *)tags
{
    __block BOOL shouldFilter = NO;
    [sticker.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([tags containsObject:obj.lowercaseString]) {
            shouldFilter = YES;
            *stop = YES;
        }
    }];
    return shouldFilter;
}

+ (void)p_logSingleStickerDownloaded:(IESInfoStickerModel *)sticker
                         trackParams:(NSDictionary *)trackParams
                               error:(NSError *)error
                            filePath:(NSString *)filePath
                            duration:(CGFloat)duration
{
    NSArray *downloadURLs = sticker.sticker.url ? @[sticker.sticker.url] : sticker.fileDownloadURLs;
    NSString *composeStr = [downloadURLs componentsJoinedByString:@","];
    NSDictionary *extraInfo = @{
                                @"info_sticker_id" : sticker.stickerIdentifier ? : @"",
                                @"info_sticker_name" : sticker.effectName ? : @"",
                                @"download_urls" : composeStr ? : @""
    };
    
    if (error || ACC_isEmptyString(filePath)) {
        [ACCMonitor() trackService:@"aweme_info_sticker_modern_download_error"
                                 status:1
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                      @"errorCode" : @(error.code),
                                      @"errorDesc" : error.localizedDescription ?: @"",
                                      @"source_tag" : @(sticker.dataSource)
                                  }]];
    } else {
        [ACCMonitor() trackService:@"aweme_info_sticker_modern_download_error"
                                 status:0
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                      @"duration" : @(duration),
                                      @"source_tag" : @(sticker.dataSource)
                                  }]];
    }
    
    NSInteger success = !(error || ACC_isEmptyString(filePath));
    
    NSMutableDictionary *params = @{@"resource_type" : @"info_effect",
                                    @"resource_id" : sticker.stickerIdentifier ? : @"",
                                    @"duration" : @(duration),
                                    @"status" : @(success?0:1),
                                    @"error_domain":error.domain?:@"",
                                    @"error_code":@(error.code)}.mutableCopy;
    [params addEntriesFromDictionary:trackParams ? : @{}];
    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                      params:params.copy
             needStagingFlag:NO];
}

@end
