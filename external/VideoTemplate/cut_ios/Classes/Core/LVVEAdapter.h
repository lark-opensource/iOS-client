//
//  LVVEAdapter.h
//  VideoTemplate
//
//  Created by luochaojing on 2020/1/17.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESLVPlayer.h>
#include <iostream>
#include <TemplateConsumer/TemplateModel.h>
#include <cut/ComVEEditor.h>
#import "LVVEDataCache.h"
#import "LVPlayerDisableCache.h"
#import <KVOController/KVOController.h>
#include <cdom/ModelType.h>
#import "LVAIMattingManager.h"
#import "LVMediaAsset.h"
#import <TTVideoEditor/VEVideoStabAlg.h>
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

using namespace std;
using namespace cdom;

typedef void(^LVVESyncCompletion)(void);
typedef void(^LVGenerateImageBlock)(UIImage *_Nullable, NSError *_Nullable);
typedef void(^LVVESeekCompletion)(bool finished);

@protocol LVVEAdapterVideoAssetDataSource <NSObject>

- (AVAsset *)assetForVideoSegment:(NSString *)segmentID;
- (LVMediaAsset *)mediaAssetForVideoSegment:(NSString *)segmentID;
- (LVMediaAsset *)aiMattingAssetForVideoSegment:(NSString *)segmentID;
- (AVAsset *)assetForAudioSegment:(NSString *)segmentID;
- (NSString *)imagePathForVideoSegment:(NSString *)segmentID;
- (nullable IESMMCurveSource *)curveSpeedSourceForSegment:(NSString *)segmentID trackType:(LVMediaTrackType)trackType;
- (CGSize)cropSizeForVideoSegmnet:(NSString *)segmentID;
- (CGFloat)speedForVideoSegment:(NSString *)segmentID;
- (CGFloat)speedForAudioSegment:(NSString *)segmentID;
- (CGFloat)maxDurationForDraft;

- (NSString *)waterMarkPathWithSegmentID:(NSString *)segmentID;
- (NSString *)tailLeaderText;
- (NSString *)accountText;

@end

namespace cut {

class LVVEAdapter: public std::enable_shared_from_this<LVVEAdapter> {
    
public:
    IESLVPlayer *player;
    LVPlayerDisableCache *disableCache;
    LVVEDataCache *cache;
    HTSVideoData *videoData;
    __weak id<LVVEAdapterVideoAssetDataSource> videoAssetDataSource;
    LVVEBundleDataSourceProvider *bundleDataSource;

private:
    std::shared_ptr<CutSame::TemplateModel> project;
    CGSize canvasSize;
    __weak LVAIMattingManager *mattingManager;
    
public:
    LVVEAdapter();
    void setup(UIView *view, HTSVideoData *videoData);
//    LVVEAdapter(UIView *view, HTSVideoData *videoData);
    void setup(std::shared_ptr<CutSame::TemplateModel> project);
    
    ~LVVEAdapter();
    
    // MARK: -
    void seekToTimeAndRender(CMTime time, LVVESeekCompletion completion);
    void playWithinTimeRange(CMTimeRange range);
    
    // MARK: - VE 需要设置使用的算法
    void applyVEAlgorithmAsyn();
    
    // MARK: - 编辑的接口
    
    void updateVideoDataDuration(float maxTrackDuration);

    void startEditModeForSegment(std::string segmentID);
    
    void synchronize(LVVESyncCompletion _Nullable completion);
    
    bool reloadCanvasSize();
    
    CGSize getCanvasSize();
    
    // MARK: - Video
    
    void updateVideoCrop(string segmentID);
    
    void updateVideoCanvasSource(std::string segmentID);
    void updateVideoCanvasSourceScale(AVAsset *asset, double scale);
    void updateVideoCanvasSourceTranslation(AVAsset *asset, CGPoint translation);
    void updateVideoCanvasSourceFlip(AVAsset *asset, bool flipX, bool flipY);
    void updateVideoCanvasSourceRotation(AVAsset *asset, double rotation);
    void updateVideoCanvasSourceAlpha(AVAsset *asset, double alpha);


    void updateVideoOirginalSound();
    
    void updateSubVideosRenderIndex(vector<shared_ptr<CutSame::Segment>> &segments);
    
    void syncVideoAssets();
    
    void updateVideoAnimation(std::shared_ptr<CutSame::Segment> segment);
    void updateVideoMix(std::shared_ptr<CutSame::Segment> segment);
    
    // MARK: - AiMatting
    void setupAIMattingManager(LVAIMattingManager *manager);
    LVAIMattingManager *getAIMattingManager();
    void syncAIMattingAssets();
    void removeInvalidAIMattingAssets();
    
    // MARK: - Audio
    
    void syncAudioAsset();
    void removeAllAudioFilter();
    void removeAdditionalAudioFilter();
    
    // MARK: - Canvas
    void updateCanvas(std::string segmentID);
    
    // MARK: - Sticker
    void syncStickerAssets(std::vector<std::string> &segmentIDs, bool needLog, bool forceUpdate);
    void setStickerPreviewMode(std::string &segmentID, int32_t previewMode);
    void setStickerPreviewMode(NSInteger taskID, int32_t previewMode);
    void updateStickSegmentAnimation(std::shared_ptr<CutSame::Segment> segment);
    void disableStickerAnimation(std::string &segmentID);
    void updateStickerLayer(std::string &segmentID);
    void setInfoStickerToFront(std::string &segmentID);
    void updateTextContent(std::string segmentID);
    CGSize getStickerNormalizSize(std::string &segmentID);
    void setStickerFlipInfo(std::string &segmentID, bool flipX, bool flipY);
    
    // MARK: - GloabalEffect
    void syncGlobalEffect();
    void deleteGlobalEffectOfSegmentId(std::string &segmentId);
    void insertOrReplaceGlobalEffectResource(std::string &segmentID);
    void updateGlobalEffectValue(std::string &segmentID);
    void addGlobalEffect(std::string &segmentID);
    
    // MARK: - DisableFeature
    void syncDisableFeature();
    
    // MARK: - Effect
    void applyEffectIntensity(IESIndensityParam indensityParam, IESEffectType type, AVAsset *asset);
    void removeEffect(string taskID);
    void applyEffect(string path, IESEffectType type, AVAsset *asset);
    void syncBeautyAssets();
    void syncFilterAssets();
    void syncAdjustAssets();
    void syncChromaAssets();
    
    void setEffectRenderIndex(LVEffectRenderIndexBlock block);

    // MARK: - TailLeader
    void syncTailLeader();
    void updateTailLeaderContent(std::string &segmnetID);
    
    // MARK: - VideoEffect
    void syncVideoEffects();
    
    // MARK: -
    void syncTransitionAssets();
    
    // MARK: - Video Mask
    void syncVideoMaskAssets();
    
    bool isPlaying();
    
    // MARK: - Video Stabilization
    void syncVideoStab();
    
    void clearCache(NSString *cacheKey);
     
    BOOL isStabMatrixAvailable(std::shared_ptr<CutSame::Segment> segment);
    
    NSDictionary *_Nullable getStableData(std::shared_ptr<CutSame::Segment> segment);
    
    void applyStabFilter(std::shared_ptr<CutSame::Segment> segment, int stableLevel);
    
    void cancelStabFilter(std::shared_ptr<CutSame::Segment> segment);
    // MARK: - keyframes
    void syncKeyframes();
    void updateKeyframe(std::shared_ptr<CutSame::Keyframe> keyframe, std::shared_ptr<CutSame::Segment> segment);
    void insertKeyframe(std::shared_ptr<CutSame::Keyframe> keyframe, std::shared_ptr<CutSame::Segment> segment);
    void deleteKeyframe(std::shared_ptr<CutSame::Keyframe> keyframe, std::shared_ptr<CutSame::Segment> segment);
    void deleteAllKeyframes(std::shared_ptr<CutSame::Segment> segment);
    void processAllKeyframe(IESMMALLKeyFrames *allkeyFrame, NSUInteger pts);
    void reloadPropertiesEffectedByKeyframe(std::shared_ptr<CutSame::Segment> segment);
    void reloadKeyframes(std::shared_ptr<CutSame::Segment> segment);
    void updateKeyframes(std::shared_ptr<CutSame::Segment> segment);
    void syncChromaKeyframes(std::shared_ptr<CutSame::Segment> segment);
    
    // MARK: - TextTemplate
    void syncTextTemplates();
    void addTextTemplate(std::shared_ptr<CutSame::Segment> segment);
    void removeTextTemplate(std::string &segmentID);
    void updateTextTemplate(std::string &segmentID);
    NSString *getParmasOfTextTemplate(std::string &segmentID);
    void setTextTemplatePreviewMode(std::string &segmentID, int32_t previewMode);
    void setTextTemplateToFront(std::string &segmentID);
private:
    IESMMAudioFilter* __applySoundFilter(bool isVideo, IESAudioFilterType type, IESMMAudioEffectConfig *_Nullable config , AVAsset *asset);
    
    void __applyGlobalEffectSegment(std::shared_ptr<CutSame::Segment> &effectSegment, std::shared_ptr<CutSame::Segment> &videoSegment, std::shared_ptr<CutSame::MaterialEffect> &effectPayload);
    
    void __syncVolumFilter(bool isVideo, std::shared_ptr<CutSame::Segment> segment, AVAsset *asset);
    
    void __syncPitchFilter(bool isVideo, std::shared_ptr<CutSame::Segment> segment, AVAsset *asset);
    
    void __createSegment(std::shared_ptr<CutSame::Segment> segment, AVAsset *asset, shared_ptr<CutSame::MaterialVideo> material, bool isInMainTrack);

    void __reloadVideoConfig(std::shared_ptr<CutSame::Segment> segment, AVAsset *asset, shared_ptr<CutSame::MaterialVideo> material);
    
    bool __applyVideoAnimation(std::shared_ptr<CutSame::Segment> segment);
    
    // MARK: - Keyframe
    void syncKeyframes(std::shared_ptr<CutSame::Segment> segment, KeyframeType keyframeType);
    void syncChromaKeyframes(std::shared_ptr<CutSame::Segment> segment, VEAmazingFeature *feature);
    void syncMaskKeyframes(std::shared_ptr<CutSame::Segment> segment, VEAmazingFeature *feature);
    
    // MARK: - VideoEffects
    void __syncMainVideoEffects();
    void __syncSubVideoEffects();
    void __syncGlobalVideoEffects();
    
    // 全局滤镜features
    NSArray<VEAmazingFeature *> *__getGlobalFilterFeatures(NSString *segmentID);
    // 全局调节featureMaps
    NSArray<NSDictionary *> *__getGlobalAdjustFeatureMaps(NSString *segmentID);
    // 全局调节值
    NSNumber *__getGlobalAdjustValue(std::shared_ptr<CutSame::AdjustKeyframe> keyframe, MaterialType type);
    
    void __reloadGlobbalFilterPropertiesEffectedByKeyframe(NSString *segmentID);
    void __reloadGlobbalAdjustPropertiesEffectedByKeyframe(NSString *segmentID);
    
    // MARK: - Sticker
    long __addEmojiSticker(NSString *emoji);
    long __addInfoSticker(NSString *path);
    void __updateSticker(long taskID, CutSame::Segment &segment);
    void __updateSticker(long taskID, std::shared_ptr<CutSame::Segment> segment);
    void __setStickerAnimation(long taskID, int32_t animationType, NSString *path, NSTimeInterval duration);
    void __setStickerTimeRange(long taskID, int64_t startTimeMs, int64_t durationTimeMs);
    void __setStickerAlpha(long taskID, float alpha);
    void __setStickerClipInfo(long taskID, std::shared_ptr<CutSame::Segment> segment);
    
    // MARK: - DisableFeature
    void __disableFeatureFlipX();
    void __disableFeatureFlipY();
    void __disableFeatureBeauty();
    void __disableFeatureChroma();
    void __disableFeatureSeparatedSound();

    // MARK: - TailLeader
    void __updateTailLeaderText(shared_ptr<CutSame::Segment> segment, shared_ptr<CutSame::MaterialTailLeader> tailLeaderMaterial);
    void __updateAccountInfo(shared_ptr<CutSame::Segment> segment, shared_ptr<CutSame::MaterialTailLeader> tailLeaderMaterial);

    // MARK: - Delegate
    AVAsset *__assetForVideoSegment(std::string segmentID);
    LVMediaAsset *__mediaAssetForVideoSegment(const std::string &segmentID);
    LVMediaAsset *__aiMattingAssetForVideoSegment(const std::string &segmentID);
    AVAsset *__assetForAudioSegment(std::string segmentID);
    IESMMCurveSource *__curveSpeedSourceForSegment(std::string segmentID, LVMediaTrackType trackType);
    CGSize __videCropSizeForVideoSegment(std::string segmentID);
    CGFloat __speedForVideoSegment(std::string segmentID);
    CGFloat __speedForAudioSegment(std::string segmentID);
    CGFloat __maxDurationForDraft();
};

};



NS_ASSUME_NONNULL_END
