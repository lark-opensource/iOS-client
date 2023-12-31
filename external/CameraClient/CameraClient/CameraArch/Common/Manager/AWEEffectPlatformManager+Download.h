//
//  AWEEffectPlatformManager+Download.h
//  CameraClient
//
//  Created by geekxing on 2019/10/31.
//

#import <CameraClient/AWEEffectPlatformManager.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitArch/AWEEffectPlatformTrackModel.h>
#import <CreationKitArch/AWEEffectPlatformManageable.h>

NS_ASSUME_NONNULL_BEGIN
@class IESEffectModel;

@protocol AWEEffectPlatformManagerDelegate <NSObject>

- (BOOL)shouldFilterEffect:(IESEffectModel *)effect;

@end


/*!
     @class AWEEffectPlatformManager
     @abstract 对EffectPlatform道具资源包下载接口的封装，绑定端监控埋点
     @discussion trackModel传入AWEEffectPlatformTrackRequiredModel的实例，部分属性不能为空，否则不上报端监控，方法内部会copy，防止外部篡改数据
 */
@interface AWEEffectPlatformManager (Download)<AWEEffectPlatformManageable>

// 保存正在下载的effect的MD5,progress字典
- (NSDictionary<NSString *, NSNumber *> *)downloadingEffectsDict;

/// 根据stickerID下载道具
/// @param stickerID 道具ID
/// @param trackModel 埋点信息
/// @param progressBlock 进度条
/// @param completion 完成回调
- (void)downloadStickerWithStickerID:(NSString *)stickerID
                          trackModel:(AWEEffectPlatformTrackModel *)trackModel progress:(nullable EffectPlatformDownloadProgressBlock)progressBlock
                          completion:(nullable void(^)(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects))completion;

/// 根据stickerID下载道具
/// @param stickerID 道具ID
/// @param gradeKey 分级包标志
/// @param trackModel 埋点信息
/// @param progressBlock 进度条
/// @param completion 完成回调
- (void)downloadStickerWithStickerID:(NSString *)stickerID
                            gradeKey:(nullable NSString *)gradeKey
                          trackModel:(AWEEffectPlatformTrackModel *)trackModel
                            progress:(EffectPlatformDownloadProgressBlock)progressBlock
                          completion:(nullable void(^)(IESEffectModel *effect, NSError *error, IESEffectModel * _Nullable parentEffect, NSArray<IESEffectModel *> * _Nullable bindEffects))completion;

/// 获取道具列表并下载指定道具
/// @param stickersArray  道具ID数组
/// @param gradeKey 分级包标志
/// @param shouldApplySticker 是否应用道具
/// @param toDownloadEffect 是否下载父道具（聚合道具）
/// @param trackModel 埋点信息
/// @param progressBlock 进度条
/// @param whitelistOn 白名单
/// @param completion 完成回调
- (void)fetchStickerListWithStickerIDS:(NSArray *)stickersArray
                              gradeKey:(nullable NSString *)gradeKey
                    shouldApplySticker:(BOOL)shouldApplySticker
               toDownloadParentSticker:(nullable IESEffectModel *)toDownloadEffect
                         trackModel:(AWEEffectPlatformTrackModel *)trackModel
                              progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                            completion:(void(^_Nullable)(IESEffectModel *currentEffect, NSArray<IESEffectModel *> *allEffects, NSArray<IESEffectModel *> *_Nullable bindEffects, NSError *error))completion;

/// 获取道具列表,过滤列表并下载指定道具
/// @param stickersArray  道具ID数组
/// @param shouldApplySticker 是否应用道具
/// @param toDownloadEffect 是否下载父道具（聚合道具）
/// @param trackModel 埋点信息
/// @param progressBlock 进度条
/// @param stickerFilterBlock 过滤条件
/// @param completion 完成回调
- (void)fetchAndFilterStickerListWithStickerIDS:(NSArray *)stickersArray
                             shouldApplySticker:(BOOL)shouldApplySticker
                        toDownloadParentSticker:(IESEffectModel *_Nullable)toDownloadEffect
                                     trackModel:(AWEEffectPlatformTrackModel *)trackModel
                                       progress:(EffectPlatformDownloadProgressBlock _Nullable)progressBlock
                             stickerFilterBlock:(BOOL(^_Nullable)(IESEffectModel *sticker))stickerFilterBlock
                                     completion:(void(^_Nullable)(IESEffectModel *currentEffect, NSArray<IESEffectModel *> *allEffects, NSArray<IESEffectModel *> *_Nullable bindEffects, NSError *error))completion;

- (void)fetchEffectWith:(NSString *)effectID
               gradeKey:(nullable NSString *)gradeKey
             completion:(void(^_Nullable)(IESEffectModel * _Nullable effect,
                                          NSError * _Nullable error,
                                          IESEffectModel * _Nullable parentEffect,
                                          NSArray<IESEffectModel *> * _Nullable bindEffects))completion;

/// 下载道具资源包
/// @param effectModel 道具模型
/// @param trackModel 埋点信息
/// @param progressBlock 进度条
/// @param completion 回调
- (void)downloadEffect:(IESEffectModel *)effectModel
         trackModel:(AWEEffectPlatformTrackModel *)trackModel
              progress:(nullable EffectPlatformDownloadProgressBlock)progressBlock
            completion:(EffectPlatformDownloadCompletionBlock)completion;

/// 下载道具资源包
/// @param effectModel 道具模型
/// @param trackModel  埋点信息
/// @param queuePriority 队列优先级
/// @param qualityOfService QoS
/// @param progressBlock 进度条
/// @param completion  回调
- (void)downloadEffect:(IESEffectModel *)effectModel
         trackModel:(AWEEffectPlatformTrackModel *)trackModel
 downloadQueuePriority:(NSOperationQueuePriority)queuePriority
downloadQualityOfService:(NSQualityOfService)qualityOfService
              progress:(nullable EffectPlatformDownloadProgressBlock)progressBlock
            completion:(nullable EffectPlatformDownloadCompletionBlock)completion;


@end

NS_ASSUME_NONNULL_END
