//
//  EffectPlatform+InfoSticker.h
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/1/6.
//

#import "EffectPlatform.h"
#import "IESInfoStickerResponseModel.h"
#import "IESInfoStickerListResponseModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^EffectPlatformFetchInfoStickerResponseCompletion) (NSError * _Nullable error, IESInfoStickerResponseModel * _Nullable reponseModel);
typedef void(^EffectPlatformFetchInfoStickerListResponseCompletion)(NSError * _Nullable error, IESInfoStickerListResponseModel * _Nullable responseModel);

@interface EffectPlatform (InfoSticker)

/**
 信息化贴纸列表的拉取
 @param panel 面板名称
 @param completion 下载回调
 */
+ (void)fetchInfoStickerListWithPanel:(NSString *)panel
                           completion:(EffectPlatformFetchInfoStickerListResponseCompletion _Nullable)completion;

/**
 信息化贴纸列表的拉取
 @param panel 面板名称
 @param statusType 测试状态分类，选填，默认返回全部
 @param completion 下载回调
 */
+ (void)fetchInfoStickerListWithPanel:(NSString *)panel
                 effectTestStatusType:(IESEffectModelTestStatusType)statusType
                            saveCache:(BOOL)saveCache
                      extraParameters:(NSDictionary * _Nullable)extraParameters
                           completion:(EffectPlatformFetchInfoStickerListResponseCompletion _Nullable)completion;

/**
 信息化贴纸列表检查更新
 @param panel 面板名称
 @param completion 返回YES or NO
 */
+ (void)checkInfoStickerListUpdateWithPanel:(NSString *)panel
                                 completion:(void (^)(BOOL))completion;

/**
 信息化贴纸搜索
 @param effectIDs 贴纸的id数组，必填
 @param completion 下载回调
 */
+ (void)fetchInfoStickerSearchListWithKeyWord:(NSString *)keyword
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion _Nullable)completion;


/**
 信息化贴纸搜索
 @param effectIDs 贴纸的id数组，必填
 @param keyword 关键词，选填
 @param type 类型，选填时为nil
 @param pagaCount 每页个数，选填时为NSNotFound
 @param cursor 当前页，选填时为NSNotFound
 @param extraParameters 额外的参数，例如@{@"image_url":@"", @"creation_id":@""}，选填时为nil
 @param completion 下载回调
 */
+ (void)fetchInfoStickerSearchListWithKeyWord:(NSString *)keyword
                                         type:(NSString * _Nullable)type
                                    pageCount:(NSInteger)pageCount
                                       cursor:(NSInteger)cursor
                                    effectIDs:(NSArray<NSString *> * _Nullable)effectIDs
                              extraParameters:(NSDictionary * _Nullable)extraParameters
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion _Nullable)completion;


/**
 信息化贴纸推荐
 @param effectIDs 贴纸的id数组，必填
 @param completion 下载回调
 */
+ (void)fetchInfoStickerRecommendListWithCompletion:(EffectPlatformFetchInfoStickerResponseCompletion _Nullable)completion;

/**
 信息化贴纸推荐
 @param effectIDs 贴纸的id数组，必填
 @param type 类型，选填
 @param pageCount 每页个数，选填
 @param cursor 当前页，选填
 @param extraParameters 额外的参数，例如@{@"image_url":@"", @"creation_id":@""}，选填
 @param completion 下载回调
 */
+ (void)fetchInfoStickerRecommendListWithType:(NSString * _Nullable)type
                                    pageCount:(NSInteger)pageCount
                                       cursor:(NSInteger)cursor
                                    effectIDs:(NSArray<NSString *> * _Nullable)effectIDs
                              extraParameters:(NSDictionary * _Nullable)extraParameters
                                   completion:(EffectPlatformFetchInfoStickerResponseCompletion _Nullable)completion;

/*
 根据panel获取信息化贴纸分类及列表的responseModel缓存
 */
+ (nullable IESInfoStickerListResponseModel *)cachedInfoStickerListWithPanel:(NSString *)panel;

/**
 下载信息化贴纸模型
 @param infoStickerModel
 @param completion
 */
+ (void)dowloadInfoStickerModel:(IESInfoStickerModel *)infoStickerModel
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;
/**
 下载信息化贴纸模型
 @param infoStickerModel
 @param priority&quality
 @param completion
 */
+ (void)dowloadInfoStickerModel:(IESInfoStickerModel *)infoStickerModel
          downloadQueuePriority:(NSOperationQueuePriority)queuePriority
       downloadQualityOfService:(NSQualityOfService)qualityOfService
                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                     completion:(EffectPlatformDownloadCompletionBlock _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
