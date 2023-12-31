//
//  LVCutSameConsumer.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "LVDraftModels.h"
#import "LVMediaDefinition.h"
#import "LVCutSameVideoMaterial.h"
#import "LVCutSameTextMaterial.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameConsumer : NSObject

// 给NLEModel添加个剪同款模板，0表示成功
+ (int32_t)addCutSame:(LVMediaDraft *)draft toNLE:(NLEModel_OC *)nleModel;

// 移除NLEModel中的所有跟剪同款有关的属性，0表示成功
+ (int32_t)removeCutSame:(NLEModel_OC *)nleModel;

+ (void)updateRelativeSizeWhileGlobalCanvasChanged:(NLEModel_OC *)nleModel
                             prevGlobalCanvasRatio:(CGFloat)prevCanvasRatio
                                 globalCanvasRatio:(CGFloat)canvasRatio;

+ (BOOL)replaceVideoAssetWithResourceID:(NSString *)resourceID
                              PayloadID:(NSString *)payloadId
                                   path:(NSString *)path
                              nleFolder:(NSString *)nleFolder
                        sourceTimeRange:(CMTimeRange)sourceTimeRange
                       fromCutSameDraft:(LVMediaDraft *)draft
                                  toNLE:(NLEModel_OC *)nleModel;

+ (BOOL)replaceImagePathWithResourceID:(NSString *)resourceID
                             payloadID:(NSString *)payloadId
                             nleFolder:(NSString *)nleFolder
                             imagePath:(NSString *)imagePath
                             imageSize:(CGSize)imageSize
                       sourceTimeRange:(CMTimeRange)sourceTimeRange
                      fromCutSameDraft:(LVMediaDraft *)draft
                                 toNLE:(NLEModel_OC *)nleModel;

+ (BOOL)replaceSourceTimeRange:(CMTimeRange)sourceTimeRange
                     payloadID:(NSString *)payloadId
              fromCutSameDraft:(LVMediaDraft *)draft
                         toNLE:(NLEModel_OC *)nleModel;

+ (BOOL)replaceVideoCrops:(NSArray<NSValue *> *)crops
                payloadID:(NSString *)payloadId
         fromCutSameDraft:(LVMediaDraft *)draft
                    toNLE:(NLEModel_OC *)nleModel;

+ (BOOL)replaceTextWithPayloadID:(NSString *)payloadId
                            text:(NSString *)text
                fromCutSameDraft:(LVMediaDraft *)draft
                           toNLE:(NLEModel_OC *)nleModel;

+ (nullable NLETrackSlot_OC *)getTrackSlotForPayloadId:(NSString *)payloadId
                                              forTrack:(LVMediaTrackType)trackType
                                      fromCutSameDraft:(LVMediaDraft *)draft
                                                 toNLE:(NLEModel_OC *)nleModel;


/// 获取所有可替换的文字素材
/// @param nleModel NLEModel_OC
+ (NSArray<LVCutSameTextMaterial *> *)getMutableTextMaterials:(NLEModel_OC *)nleModel;

+ (NSArray<LVCutSameVideoMaterial *> *)getVideoMaterials:(NLEModel_OC *)nleModel;

/// 替换文本
/// @param textMaterial LVCutSameTextMaterial
/// @param nleModel NLEModel_OC
+ (void)replaceText:(LVCutSameTextMaterial *)textMaterial
              toNLE:(NLEModel_OC *)nleModel;


/// 替换视频素材：包括素材资源、裁剪、放大缩小、播放区间
/// @param videoMaterial LVCutSameVideoMaterial
/// @param nleModel NLEModel_OC
+ (void)replaceVideoMaterial:(LVCutSameVideoMaterial *)videoMaterial
                       toNLE:(NLEModel_OC *)nleModel;

/// 获得画布比例
+ (float)getRatio:(LVMediaDraft *)draft;

@end

NS_ASSUME_NONNULL_END
