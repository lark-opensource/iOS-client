//
//  LVVEDataCache.h
//  VideoTemplate
//
//  Created by ZhangYuanming on 2020/1/19.
//

//#ifndef LVVEDataCache_h
//#define LVVEDataCache_h

#import <Foundation/Foundation.h>
#include <TemplateConsumer/Segment.h>
#include <TemplateConsumer/MaterialEffect.h>
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/VideoSegment.h>
#import "LVVEBundleDataSource.h"
#import <TTVideoEditor/IESMMAudioFilter.h>
#import <TTVideoEditor/VEAmazingFeature.h>

NS_ASSUME_NONNULL_BEGIN

typedef int(^LVEffectRenderIndexBlock)(NSString *);

@interface LVVEAdjustDiffer : NSObject

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* added;

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* removed;

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* changed;

@end

@interface LVVEBaseDiffer : NSObject

@property (nonatomic, strong, nullable) VEAmazingFeature* added;

@property (nonatomic, strong, nullable) VEAmazingFeature* removed;

@property (nonatomic, strong, nullable) VEAmazingFeature* changed;

@end

@interface LVVEFigureDiffer: NSObject

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* added;

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* removed;

@property (nonatomic, copy, nullable) NSDictionary<NSString *,VEAmazingFeature*>* changed;

@end

@interface LVVEFilterDiffer : LVVEBaseDiffer
@end

@interface LVVEChromaDiffer : LVVEBaseDiffer
@end

@interface LVVEGlobalVideoEffectDiffer : LVVEBaseDiffer
@end

@interface LVVELocalVideoEffectDiffer : LVVEAdjustDiffer
@end

@interface LVVideoMaskDiffer : LVVEBaseDiffer
@end

@interface LVVEStickerCache : NSObject

@property (nonatomic, assign) NSInteger taskID;

- (instancetype)initWithTaskID:(NSInteger)taskID;

@end

@interface LVVEAudioFilterCache : NSObject

@property (nonatomic, strong) IESMMAudioFilter *filter;

@property (nonatomic, assign, getter=isVideo) BOOL video;

- (instancetype)initWithFilter:(IESMMAudioFilter *)filter forVideo:(BOOL)video;

@end

@interface LVVETailLeaderCache : NSObject

@property (nonatomic, assign) NSInteger contentStickerId;

@property (nonatomic, assign) NSInteger accountStickerID;

@end

@interface LVVEGlobalEffectDiffer : NSObject
/// {effectSegmentID:{featureID: VEAmazingFeature}}
@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSDictionary<NSString*, VEAmazingFeature *>*>* added;

@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSDictionary<NSString*, VEAmazingFeature *>*>* updated;

@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSDictionary<NSString*, VEAmazingFeature *>*>* removed;

@end


@interface LVVEDataCache : NSObject
- (instancetype)initWithBundleDataSource:(LVVEBundleDataSourceProvider *)bundleDataSource
                                 project:(std::shared_ptr<CutSame::TemplateModel> const &)project;

/**
 防抖参数缓存
 */
@property (nonatomic, strong) NSCache<NSString*, NSDictionary*>* videoStableCacheMap;
/**
 信息化贴纸应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*,LVVEStickerCache*>*stickerCacheMap;

///文字模版应用缓存
@property (nonatomic, strong) NSMutableDictionary<NSString*, LVVEStickerCache*> *textTemplateCacheMap;
 /**
 滤镜应用缓存
  */
@property (nonatomic, strong) NSMutableDictionary<NSString*, VEAmazingFeature*>*filterCacheMap;

/// 人像特效缓存
/// { segmentID: { resourceID: VEAmazingFeature }}
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableDictionary<NSString *, VEAmazingFeature *> *> *figureCacheMap;
/**
 色度抠图应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, VEAmazingFeature*>*chromaCacheMap;
/**
 主视频/画中画 画面特效应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableDictionary<NSString *, VEAmazingFeature*>*>*localVideoEffectCacheMap;

/**
全局 画面特效应用缓存
*/
@property (nonatomic, strong) NSMutableDictionary<NSString*, VEAmazingFeature*>*globalVideoEffectCacheMap;

/**
 特效调节应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSDictionary<NSString *, VEAmazingFeature*>*>*adjustCacheMap;
/**
 音效调节应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSArray<LVVEAudioFilterCache*>*>*audioFiltersCacheMap;
/**
 片尾应用缓存
 */
@property (nonatomic, strong, nullable) LVVETailLeaderCache *tailLeaderCache;

/**
 蒙版应用缓存
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, VEAmazingFeature*>*maskCacheMap;
/**
全局滤镜、调节应用缓存
 {videoSegmentID:{effectSegmentID:{featureID: VEAmazingFeature}}}
*/
@property (nonatomic, strong) NSMutableDictionary<AVAsset*, NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, VEAmazingFeature*>*>*>*globalEffectCacheMap;

@property (nonatomic, copy) LVEffectRenderIndexBlock effectRenderIndexBlock;

- (BOOL)isStickerExistedWithTaskID:(NSInteger)taskID;

- (nullable LVVEAudioFilterCache *)audioFilterWithSegmentID:(NSString *)segmentID type:(IESAudioFilterType)type;

- (void)addAdjustMap:(NSDictionary<NSString *, VEAmazingFeature*> *)adjustMap forKey:(NSString *)key;

- (void)removeAdjustMap:(NSDictionary<NSString *, VEAmazingFeature*> *)adjustMap forKey:(NSString *)key;

- (LVVEAdjustDiffer *)diffWithAdjusts:(const std::vector<std::shared_ptr<CutSame::MaterialEffect>>&)adjusts videoSegment:(std::shared_ptr<CutSame::Segment> &)videoSegment;

- (void)addAudioFilter:(IESMMAudioFilter *)filter video:(BOOL)isVideo forKey:(NSString *)key;

- (void)addStickerTaskID:(NSInteger)taskID forKey:(NSString *)key;

- (LVVEFilterDiffer *)diffWithFilter:(const std::shared_ptr<CutSame::MaterialEffect>&)filterPayload segment:(const std::shared_ptr<CutSame::Segment>&)segment;

- (LVVEFigureDiffer *)diffWithFigures:(const std::vector<std::shared_ptr<CutSame::MaterialEffect>>&)figures
                             rootPath:(NSString *)rootPath
                              segment:(const std::shared_ptr<CutSame::Segment>&)segment;

- (LVVEChromaDiffer *)diffWithChroma:(const std::shared_ptr<CutSame::MaterialChroma>&)chromaPayload segment:(const std::shared_ptr<CutSame::Segment> &)segment;

- (LVVideoMaskDiffer *)diffVideoMask:(std::shared_ptr<CutSame::MaterialMask>)videoMaskPayload
                             segment:(std::shared_ptr<CutSame::Segment>)segment
                            rootPath:(NSString *)rootPath
                       videoCropSize:(CGSize)videoCropSize;

- (BOOL)isGlobalEffectExistedWithVideoAsset:(AVAsset *)asset
                              effectSegment:(std::shared_ptr<CutSame::Segment> &)effectSegment;

- (void)addGlobalEffectWithVideoAsset:(AVAsset *)asset
                      effectSegmentID:(NSString *)effectSegmentID
                            featureID:(NSString *)featureID
                              feature:(VEAmazingFeature *)feature;

- (void)deleteGlobalEffectWithVideoAsset:(AVAsset *)asset
                         effectSegmentID:(NSString *)effectSegmentID;

- (void)deleteGlobalEffectWithVideoAsset:(AVAsset *)asset;

- (void)updateGlobalEffectWithVideoAsset:(AVAsset *)asset
                         effectSegmentID:(NSString *)effectSegmentID
                               featureID:(NSString *)featureID
                                 feature:(VEAmazingFeature *)feature;

- (LVVEGlobalEffectDiffer *)diffGlobalEffectNeededUpdateWithSegment:(std::shared_ptr<CutSame::Segment> &)segment
                                                     effectSegments:(std::vector<std::shared_ptr<CutSame::Segment>> &)effectSegments
                                                         videoAsset:(AVAsset *)videoAsset;

- (LVVEGlobalVideoEffectDiffer *)diffGlobalVideoEffect:(const std::shared_ptr<CutSame::MaterialEffect> &)effectPayload
                                         effectSegment:(std::shared_ptr<CutSame::Segment> &)effectSegment;

- (LVVELocalVideoEffectDiffer *)diffsubVideoEffectsWithVideoSegment:(std::shared_ptr<CutSame::Segment> &)videoSegment
                                                   effectSegments:(std::vector<std::shared_ptr<CutSame::Segment>> &)effectSegments;

- (LVVELocalVideoEffectDiffer *)diffMainVidoeEffectWithVideoSegment:(std::shared_ptr<CutSame::Segment> &)videoSegment
                                                     effectSegments:(std::vector<std::shared_ptr<CutSame::Segment>> &)effectSegments;

@end

NS_ASSUME_NONNULL_END

//#endif /* LVVEDataCache_h */
