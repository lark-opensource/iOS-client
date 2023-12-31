//
//  VENativeWrapper.h
//  Pods
//
//  Created by bytedance on 2020/12/3.
//

#ifndef VENativeWrapper_h
#define VENativeWrapper_h

#import "NLEDiffCalculator_OC.h"
#include <string>
#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEEditorSession.h>
#import <TTVideoEditor/HTSVideoData.h>
#import "NLEEditor.h"
#import "NLEResourceFinderProtocol.h"
#import "NLENativeDefine.h"
#import "NLEVEDataCache.h"
#import "NLEVECallBackProtocol.h"
#import "NLEMacros.h"

@class NLEEditor_OC, NLEVideoDataUpdateInfo;

NS_ASSUME_NONNULL_BEGIN

typedef void (^_StickerSegmentRecoverFactoryBlock)(NSDictionary * __autoreleasing *userInfo,  std::shared_ptr<cut::model::NLETrackSlot> &slot);

@interface VENativeWrapper : NSObject

@property (nonatomic, assign, readonly) std::shared_ptr<const cut::model::NLEModel> pStageModel;
@property (nonatomic, assign, readonly) std::shared_ptr<const cut::model::NLEModel> prevStageModel;
@property (nonatomic, assign) BOOL                                   bCompleteCommit;   // 特效有长按场景，由于VE接口的调用顺序问题，在长按开始时会调用start接口，松手时需要再调一次start接口然后才是end接口,所以设置这个标志位作区分
@property (nonatomic, copy) NSArray<UIView *>*                       arrViews;
@property (nonatomic, strong) NSMutableSet<NLEVideoDataUpdateInfo *> *videoDataUpdateInfos;
@property (nonatomic, strong) id<NLEResourceFinderProtocol> resourceFinder;
@property (nonatomic, strong, readonly) VEEditorSession*       veEditor;
@property (nonatomic, strong, readonly) HTSVideoData *veVideoData; // 透传给业务，后续可移除
@property (nonatomic, assign) BOOL disableAutoUpdateCanvasSize;
@property (nonatomic, copy) _StickerSegmentRecoverFactoryBlock nleConvertUserInfoBlock;
@property (nonatomic, assign) NLEVideoDurationMode videoDurationMode;
@property (nonatomic, assign) BOOL isPlay;
@property (nonatomic, strong) NLEVEDataCache* dataCache;
@property (nonatomic, weak) id<NLEVECallBackProtocol> listener;
@property (nonatomic, strong, nullable) NSError *renderError; // commit操作失败错误
@property (nonatomic, copy, nullable) void (^stickerChangeEvent)(NSInteger newId, NSInteger oldId);
@property (nonatomic, copy) ALLKeyFramesCallBack keyFrameJsonBlock;

- (std::shared_ptr<cut::model::NLEEditor>)pCurNLEEditor;
- (void)setNLEEditor:(NLEEditor_OC *)editor;

- (void)setVEEditorSession:(VEEditorSession*)editor videoData:(HTSVideoData*)videodata;

/**
 * 重置player依赖的view
 */
- (void)resetPlayerWithViews:(nullable NSArray<UIView *> *)views;

- (void)ResetPreModel;

- (void)setVEOperateCallback:(id<NLEVECallBackProtocol> _Nullable)listener;

- (AVURLAsset * _Nullable)assetFromSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (nullable NSString *)getAbsolutePathWithResource:(const std::shared_ptr<const cut::model::NLEResourceNode>)resource;

#pragma mark - render hook

@property (nonatomic, copy, nullable) void(^beforeRender)(void);
@property (nonatomic, copy, nullable) void(^afterUpdateVideoData)(void);

/// 添加更新类型，此方法不会立刻updateVideoData
/// @param updateType VEVideoDataUpdateType
/// @param tag NSString *用来标识来源，DEBUG时用
- (void)addForceUpdateWithType:(VEVideoDataUpdateType)updateType
                           tag:(NSString *)tag;

/// 最长时长，不同的模式下，计算方式不一样
/// @param model std::shared_ptr<const cut::model::NLEModel>
- (CGFloat)totalVideoDuration:(std::shared_ptr<const cut::model::NLEModel>)model;

- (void)updateVideoData:(HTSVideoData *)videoData
             updateType:(VEVideoDataUpdateType)updateType
             completion:(void (^)(NSError *updateError))completion;

- (void)updateVideoData:(HTSVideoData *)videoData
             updateType:(VEVideoDataUpdateType)updateType
                  forMV:(BOOL)forMV
             completion:(void (^)(NSError *updateError))completion;

- (void)removeAssetFromSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)incrementBuildWithChangeTracks:(std::vector<NodeChangeInfo>&)changeTracks
                             prevModel:(std::shared_ptr<const cut::model::NLEModel>)prevModel
                              curModel:(std::shared_ptr<const cut::model::NLEModel>)curModel
                              isMVMode:(BOOL)isMVMode
                            completion:(NLEBaseBlock)completion;

- (void)updateVideoDataIfNeedWithPreModel:(std::shared_ptr<const cut::model::NLEModel>)preModel
                                 curModel:(std::shared_ptr<const cut::model::NLEModel>)curModel
                               completion:(void (^)(NSError *))completion;

@end

NS_ASSUME_NONNULL_END

#endif /* VENativeWrapper_h */
