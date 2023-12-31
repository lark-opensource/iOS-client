#import <Foundation/Foundation.h>

@class LVAutogenModel;
@class LVDependencyResource;
@class LVDraftEffectTemplatePayload;
@class LVKeyframe;
@class LVDraftPayload;
@class LVTailSegment;
@class LVMediaDraft;
@class LVCanvasConfig;
@class LVDraftConfig;
@class LVCover;
@class LVCoverDraft;
@class LVKeyframePool;
@class LVAdjustKeyframe;
@class LVAudioKeyframe;
@class LVFilterKeyframe;
@class LVStickerKeyframe;
@class LVPoint;
@class LVTextKeyframe;
@class LVVideoKeyframe;
@class LVVideoMaskConfig;
@class LVPayloadPool;
@class LVDraftAudioEffectPayload;
@class LVDraftAudioFadePayload;
@class LVDraftAudioPayload;
@class LVDraftBeatsPayload;
@class LVAIBeats;
@class LVDeleteBeats;
@class LVDraftCanvasPayload;
@class LVDraftChromaPayload;
@class LVDraftEffectPayload;
@class LVAdjustParamsInfo;
@class LVDraftImagePayload;
@class LVDraftVideoMaskPayload;
@class LVDraftAnimationPayload;
@class LVAnimationInfo;
@class LVDraftPlaceholderPayload;
@class LVRealtimeDenoises;
@class LVDraftSpeedPayload;
@class LVDraftCurveSpeedModel;
@class LVDraftStickerPayload;
@class LVDraftTailLeaderPayload;
@class LVDraftTextTemplatePayload;
@class LVEffectTemplateResource;
@class LVDraftTextPayload;
@class LVDraftTransitionPayload;
@class LVDraftVideoPayload;
@class LVVideoCropInfo;
@class LVGamePlay;
@class LVTypePathInfo;
@class LVStable;
@class LVMutableConfig;
@class LVMutablePayloadInfo;
@class LVPlatform;
@class LVRelationship;
@class LVMediaTrack;
@class LVMediaSegment;
@class LVSegmentClipInfo;
@class LVFlipClass;
@class LVTimerange;
@class LVCoverTemplate;
@class LVCoverFrameInfo;
@class LVCoverImageInfo;
@class LVCoverMaterials;
@class LVCoverText;
@class LVExtraInfo;
@class LVTrackInfo;
@class LVTutorialInfo;
@class LVTemplateParam;
@class LVTemplateText;
@class LVTextSegment;
@class LVTimeClipParam;
@class LVVeConfig;
@class LVVideoCompileParam;
@class LVVideoPreviewConfig;
@class LVVideoSegment;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Boxed enums

typedef NS_ENUM(NSUInteger,  LVPlatformEnum) {
    LVPlatformEnumAll,
    LVPlatformEnumAndroid,
    LVPlatformEnumIos,
};

typedef NS_ENUM(NSUInteger,  LVVideoCropRatio) {
    LVVideoCropRatio_Free,
    LVVideoCropRatio_r1_1,
    LVVideoCropRatio_r1125_2436,
    LVVideoCropRatio_r16_9,
    LVVideoCropRatio_r185_100,
    LVVideoCropRatio_r2_1,
    LVVideoCropRatio_r235_100,
    LVVideoCropRatio_r3_4,
    LVVideoCropRatio_r4_3,
    LVVideoCropRatio_r9_16,
};

typedef NS_ENUM(NSUInteger,  LVCoverType) {
    LVCoverTypeFrame,
    LVCoverTypeImage,
};

#pragma mark - Object interfaces

@interface LVAutogenModel : NSObject
@property (nonatomic, nullable, strong) LVDependencyResource *dependencyResource;
@property (nonatomic, nullable, strong) LVDraftEffectTemplatePayload *effectTemplate;
@property (nonatomic, nullable, strong) LVKeyframe *keyframe;
@property (nonatomic, nullable, strong) LVDraftPayload *material;
@property (nonatomic, nullable, strong) LVTailSegment *tailSegment;
@property (nonatomic, nullable, strong) LVMediaDraft *templateModel;
@property (nonatomic, nullable, strong) LVTemplateParam *templateParam;
@property (nonatomic, nullable, strong) LVTextSegment *textSegment;
@property (nonatomic, nullable, strong) LVTimeClipParam *timeClipParam;
@property (nonatomic, nullable, strong) LVVeConfig *veConfig;
@property (nonatomic, nullable, strong) LVVideoCompileParam *videoCompileParam;
@property (nonatomic, nullable, strong) LVVideoPreviewConfig *videoPreviewConfig;
@property (nonatomic, nullable, strong) LVVideoSegment *videoSegment;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVAutogenModel *)other;
@end

@interface LVDependencyResource : NSObject
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, nullable, copy) NSString *resourceID;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVDependencyResource *)other;
@end

@interface LVKeyframe : NSObject
@property (nonatomic, nullable, copy) NSString *identifier;
@property (nonatomic, assign)         NSInteger timeOffset;
@property (nonatomic, nullable, copy) NSString *typeString;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVKeyframe *)other;
@end

@interface LVDraftPayload : NSObject
@property (nonatomic, copy)   NSString *payloadID;
@property (nonatomic, assign) LVPlatformEnum platform;
@property (nonatomic, copy)   NSString *type;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVDraftPayload *)other;
@end

@interface LVTailSegment : NSObject
@property (nonatomic, nullable, copy) NSString *materialID;
@property (nonatomic, assign)         NSInteger targetStartTime;
@property (nonatomic, nullable, copy) NSString *text;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTailSegment *)other;
@end

@interface LVMediaDraft : NSObject
@property (nonatomic, strong)           LVCanvasConfig *canvasConfig;
@property (nonatomic, strong)           LVDraftConfig *config;
@property (nonatomic, nullable, strong) LVCover *cover;
@property (nonatomic, assign)           NSTimeInterval createAt;
@property (nonatomic, assign)           NSInteger durationMilliSeconds;
@property (nonatomic, nullable, strong) LVExtraInfo *extraInfo;
@property (nonatomic, copy)             NSString *draftID;
@property (nonatomic, nullable, strong) LVKeyframePool *keyframes;
@property (nonatomic, strong)           LVPayloadPool *payloadPool;
@property (nonatomic, nullable, strong) LVMutableConfig *mutableConfigPrivate;
@property (nonatomic, copy)             NSString *name;
@property (nonatomic, copy)             NSString *draftVersion;
@property (nonatomic, strong)           LVPlatform *platform;
@property (nonatomic, nullable, copy)   NSArray<LVRelationship *> *relationships;
@property (nonatomic, copy)             NSArray<LVMediaTrack *> *tracks;
@property (nonatomic, assign)           NSTimeInterval updateAt;
@property (nonatomic, assign)           NSInteger version;
@property (nonatomic, copy)             NSString *rootPath;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVMediaDraft *)other;
@end

@interface LVCanvasConfig : NSObject
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, copy)   NSString *ratioString;
@property (nonatomic, assign) NSInteger width;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCanvasConfig *)other;
@end

@interface LVDraftConfig : NSObject
@property (nonatomic, assign)         NSInteger adjustMaxIndex;
@property (nonatomic, assign)         NSInteger extractAudioLastIndex;
@property (nonatomic, nullable, copy) NSString *lyricsRecognitionID;
@property (nonatomic, assign)         BOOL lyricsSync;
@property (nonatomic, assign)         NSInteger originalSoundLastIndex;
@property (nonatomic, assign)         NSInteger recordAudioLastIndex;
@property (nonatomic, assign)         NSInteger stickerMaxIndex;
@property (nonatomic, nullable, copy) NSString *subtitleRecognitionID;
@property (nonatomic, assign)         BOOL subtitleSync;
@property (nonatomic, assign)         BOOL videoMute;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVDraftConfig *)other;
@end

@interface LVCover : NSObject
@property (nonatomic, nullable, strong) LVCoverDraft *coverDraft;
@property (nonatomic, nullable, strong) LVCoverTemplate *coverTemplate;
@property (nonatomic, nullable, strong) LVCoverFrameInfo *frameInfo;
@property (nonatomic, nullable, strong) LVCoverImageInfo *imageInfo;
@property (nonatomic, strong)           LVCoverMaterials *materials;
@property (nonatomic, assign)           LVCoverType type;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCover *)other;
@end

@interface LVCoverDraft : NSObject
@property (nonatomic, nullable, strong) LVCanvasConfig *canvasConfig;
@property (nonatomic, nullable, strong) LVDraftConfig *config;
@property (nonatomic, assign)           NSInteger createAt;
@property (nonatomic, assign)           NSInteger durationMilliSeconds;
@property (nonatomic, nullable, copy)   NSString *draftID;
@property (nonatomic, nullable, strong) LVKeyframePool *keyframes;
@property (nonatomic, nullable, strong) LVPayloadPool *payloadPool;
@property (nonatomic, nullable, strong) LVMutableConfig *mutableConfigPrivate;
@property (nonatomic, nullable, copy)   NSString *name;
@property (nonatomic, nullable, copy)   NSString *draftVersion;
@property (nonatomic, nullable, strong) LVPlatform *platform;
@property (nonatomic, nullable, copy)   NSArray<LVRelationship *> *relationships;
@property (nonatomic, nullable, copy)   NSArray<LVMediaTrack *> *tracks;
@property (nonatomic, assign)           NSInteger updateAt;
@property (nonatomic, assign)           NSInteger version;
@property (nonatomic, nullable, copy)   NSString *rootPath;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverDraft *)other;
@end

@interface LVKeyframePool : NSObject
@property (nonatomic, nullable, copy) NSArray<LVAdjustKeyframe *> *adjusts;
@property (nonatomic, nullable, copy) NSArray<LVAudioKeyframe *> *audios;
@property (nonatomic, nullable, copy) NSArray<LVFilterKeyframe *> *filters;
@property (nonatomic, nullable, copy) NSArray<LVStickerKeyframe *> *stickers;
@property (nonatomic, nullable, copy) NSArray<LVTextKeyframe *> *texts;
@property (nonatomic, nullable, copy) NSArray<LVVideoKeyframe *> *videos;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVKeyframePool *)other;
@end

@interface LVAdjustKeyframe : LVKeyframe
@property (nonatomic, assign) float brightnessValue;
@property (nonatomic, assign) float contrastValue;
@property (nonatomic, assign) float fadeValue;
@property (nonatomic, assign) float highlightValue;
@property (nonatomic, assign) float lightSensationValue;
@property (nonatomic, assign) float particleValue;
@property (nonatomic, assign) float saturationValue;
@property (nonatomic, assign) float shadowValue;
@property (nonatomic, assign) float sharpenValue;
@property (nonatomic, assign) float temperatureValue;
@property (nonatomic, assign) float toneValue;
@property (nonatomic, assign) float vignettingValue;
- (void)copyCategoryToNewObject:(LVAdjustKeyframe *)other;
@end

@interface LVAudioKeyframe : LVKeyframe
@property (nonatomic, assign) CGFloat volume;
- (void)copyCategoryToNewObject:(LVAudioKeyframe *)other;
@end

@interface LVFilterKeyframe : LVKeyframe
@property (nonatomic, assign) float value;
- (void)copyCategoryToNewObject:(LVFilterKeyframe *)other;
@end

@interface LVStickerKeyframe : LVKeyframe
@property (nonatomic, nullable, strong) LVPoint *position;
@property (nonatomic, assign)           CGFloat rotation;
@property (nonatomic, nullable, strong) LVPoint *scale;
- (void)copyCategoryToNewObject:(LVStickerKeyframe *)other;
@end

@interface LVPoint : NSObject
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVPoint *)other;
@end

@interface LVTextKeyframe : LVKeyframe
@property (nonatomic, assign)           CGFloat backgroundAlpha;
@property (nonatomic, nullable, copy)   NSString *backgroundColor;
@property (nonatomic, nullable, copy)   NSString *borderColor;
@property (nonatomic, assign)           CGFloat borderWidth;
@property (nonatomic, nullable, strong) LVPoint *position;
@property (nonatomic, assign)           CGFloat rotation;
@property (nonatomic, nullable, strong) LVPoint *scale;
@property (nonatomic, assign)           CGFloat shadowAlpha;
@property (nonatomic, assign)           CGFloat shadowAngle;
@property (nonatomic, nullable, copy)   NSString *shadowColor;
@property (nonatomic, nullable, strong) LVPoint *shadowPoint;
@property (nonatomic, assign)           CGFloat shadowSmoothing;
@property (nonatomic, assign)           CGFloat textAlpha;
@property (nonatomic, nullable, copy)   NSString *textColor;
- (void)copyCategoryToNewObject:(LVTextKeyframe *)other;
@end

@interface LVVideoKeyframe : LVKeyframe
@property (nonatomic, assign)           CGFloat alpha;
@property (nonatomic, assign)           float brightnessValue;
@property (nonatomic, assign)           CGFloat chromaIntensity;
@property (nonatomic, assign)           CGFloat chromaShadow;
@property (nonatomic, assign)           float contrastValue;
@property (nonatomic, assign)           float fadeValue;
@property (nonatomic, assign)           float filterValue;
@property (nonatomic, assign)           float highlightValue;
@property (nonatomic, assign)           CGFloat lastVolume;
@property (nonatomic, assign)           float lightSensationValue;
@property (nonatomic, nullable, strong) LVVideoMaskConfig *maskConfig;
@property (nonatomic, assign)           float particleValue;
@property (nonatomic, nullable, strong) LVPoint *position;
@property (nonatomic, assign)           CGFloat rotation;
@property (nonatomic, assign)           float saturationValue;
@property (nonatomic, nullable, strong) LVPoint *scale;
@property (nonatomic, assign)           float shadowValue;
@property (nonatomic, assign)           float sharpenValue;
@property (nonatomic, assign)           float temperatureValue;
@property (nonatomic, assign)           float toneValue;
@property (nonatomic, assign)           float vignettingValue;
@property (nonatomic, assign)           CGFloat volume;
- (void)copyCategoryToNewObject:(LVVideoKeyframe *)other;
@end

@interface LVVideoMaskConfig : NSObject
@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat feather;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) BOOL invert;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat roundCorner;
@property (nonatomic, assign) CGFloat width;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVideoMaskConfig *)other;
@end

@interface LVPayloadPool : NSObject
@property (nonatomic, nullable, copy) NSArray<LVDraftAudioEffectPayload *> *audioEffectPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftAudioFadePayload *> *audioFadePayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftAudioPayload *> *audioPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftBeatsPayload *> *beatPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftCanvasPayload *> *canvasPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftChromaPayload *> *chromaPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftEffectPayload *> *effectPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftImagePayload *> *imagesPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftVideoMaskPayload *> *maskPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftAnimationPayload *> *animationPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftPlaceholderPayload *> *placeholderPayloads;
@property (nonatomic, nullable, copy) NSArray<LVRealtimeDenoises *> *realtimeDenoises;
@property (nonatomic, nullable, copy) NSArray<LVDraftSpeedPayload *> *speedPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftStickerPayload *> *stickerPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftTailLeaderPayload *> *tailLeaderPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftTextTemplatePayload *> *textTemplates;
@property (nonatomic, nullable, copy) NSArray<LVDraftTextPayload *> *textPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftTransitionPayload *> *transitionPayloads;
@property (nonatomic, nullable, copy) NSArray<LVDraftVideoPayload *> *videoPayloads;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVPayloadPool *)other;
@end

@interface LVDraftAudioEffectPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *name;
- (void)copyCategoryToNewObject:(LVDraftAudioEffectPayload *)other;
@end

@interface LVDraftAudioFadePayload : LVDraftPayload
@property (nonatomic, assign) NSInteger fadeInDurationMilliSeconds;
@property (nonatomic, assign) NSInteger fadeOutDurationMilliSeconds;
- (void)copyCategoryToNewObject:(LVDraftAudioFadePayload *)other;
@end

@interface LVDraftAudioPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *categoryID;
@property (nonatomic, nullable, copy) NSString *categoryNamePrivate;
@property (nonatomic, assign)         NSInteger durationMilliSeconds;
@property (nonatomic, nullable, copy) NSString *effectID;
@property (nonatomic, nullable, copy) NSString *intensifiesPath;
@property (nonatomic, nullable, copy) NSString *musicID;
@property (nonatomic, copy)           NSString *name;
@property (nonatomic, copy)           NSString *relativePath;
@property (nonatomic, assign)         NSInteger sourcePlatform;
@property (nonatomic, nullable, copy) NSString *textID;
@property (nonatomic, nullable, copy) NSString *toneType;
- (void)copyCategoryToNewObject:(LVDraftAudioPayload *)other;
@end

@interface LVDraftBeatsPayload : LVDraftPayload
@property (nonatomic, nullable, strong) LVAIBeats *aiBeats;
@property (nonatomic, assign)           BOOL enableAiBeats;
@property (nonatomic, assign)           NSInteger gear;
@property (nonatomic, assign)           NSInteger modeInteger;
@property (nonatomic, nullable, copy)   NSArray<NSNumber *> *userBeatsPrivate;
@property (nonatomic, nullable, strong) LVDeleteBeats *userDeleteAIBeatsPrivate;
- (void)copyCategoryToNewObject:(LVDraftBeatsPayload *)other;
@end

@interface LVAIBeats : NSObject
@property (nonatomic, nullable, copy) NSString *beatsPath;
@property (nonatomic, nullable, copy) NSString *beatsUrl;
@property (nonatomic, nullable, copy) NSString *melodyPath;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *melodyPercents;
@property (nonatomic, nullable, copy) NSString *melodyUrl;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVAIBeats *)other;
@end

@interface LVDeleteBeats : NSObject
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *beat0Private;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *beat1Private;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *melody0Private;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVDeleteBeats *)other;
@end

@interface LVDraftCanvasPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *albumImage;
@property (nonatomic, assign)         CGFloat blur;
@property (nonatomic, nullable, copy) NSString *colorPrivate;
@property (nonatomic, nullable, copy) NSString *image;
@property (nonatomic, nullable, copy) NSString *imageID;
@property (nonatomic, nullable, copy) NSString *imageName;
- (void)copyCategoryToNewObject:(LVDraftCanvasPayload *)other;
@end

@interface LVDraftChromaPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *color;
@property (nonatomic, assign)         CGFloat intensityValue;
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, assign)         CGFloat shadowValue;
- (void)copyCategoryToNewObject:(LVDraftChromaPayload *)other;
@end

@interface LVDraftEffectPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSArray<LVAdjustParamsInfo *> *adjustParams;
@property (nonatomic, assign)         NSInteger applyTargetType;
@property (nonatomic, nullable, copy) NSString *categoryID;
@property (nonatomic, nullable, copy) NSString *categoryName;
@property (nonatomic, copy)           NSString *effectID;
@property (nonatomic, copy)           NSString *name;
@property (nonatomic, copy)           NSString *relativePath;
@property (nonatomic, copy)           NSString *resourceID;
@property (nonatomic, assign)         NSInteger sourcePlatform;
@property (nonatomic, assign)         float value;
@property (nonatomic, nullable, copy) NSString *version;
- (void)copyCategoryToNewObject:(LVDraftEffectPayload *)other;
@end

@interface LVAdjustParamsInfo : NSObject
@property (nonatomic, assign)         CGFloat defaultValue;
@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, assign)         CGFloat value;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVAdjustParamsInfo *)other;
@end

@interface LVDraftImagePayload : LVDraftPayload
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) CGFloat initialScale;
@property (nonatomic, copy)   NSString *path;
@property (nonatomic, assign) NSInteger width;
- (void)copyCategoryToNewObject:(LVDraftImagePayload *)other;
@end

@interface LVDraftVideoMaskPayload : LVDraftPayload
@property (nonatomic, strong) LVVideoMaskConfig *config;
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *path;
@property (nonatomic, copy)   NSString *resourceID;
@property (nonatomic, copy)   NSString *resourceTypePrivate;
- (void)copyCategoryToNewObject:(LVDraftVideoMaskPayload *)other;
@end

@interface LVDraftAnimationPayload : LVDraftPayload
@property (nonatomic, copy) NSArray<LVAnimationInfo *> *animations;
- (void)copyCategoryToNewObject:(LVDraftAnimationPayload *)other;
@end

@interface LVAnimationInfo : LVDraftPayload
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, copy)   NSString *animationName;
@property (nonatomic, copy)   NSString *relativePath;
@property (nonatomic, copy)   NSString *resourceID;
- (void)copyCategoryToNewObject:(LVAnimationInfo *)other;
@end

@interface LVDraftPlaceholderPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *name;
- (void)copyCategoryToNewObject:(LVDraftPlaceholderPayload *)other;
@end

@interface LVRealtimeDenoises : LVDraftPayload
@property (nonatomic, assign)         CGFloat denoiseMode;
@property (nonatomic, assign)         CGFloat denoiseRate;
@property (nonatomic, nullable, copy) NSString *identifier;
@property (nonatomic, assign)         BOOL isDenoise;
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, nullable, copy) NSString *type;
- (void)copyCategoryToNewObject:(LVRealtimeDenoises *)other;
@end

@interface LVDraftSpeedPayload : LVDraftPayload
@property (nonatomic, nullable, strong) LVDraftCurveSpeedModel *curveSpeed;
@property (nonatomic, assign)           NSInteger modePrivate;
@property (nonatomic, assign)           CGFloat speed;
- (void)copyCategoryToNewObject:(LVDraftSpeedPayload *)other;
@end

@interface LVDraftCurveSpeedModel : NSObject
@property (nonatomic, copy) NSString *resourceId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<LVPoint *> *speedPoints;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVDraftCurveSpeedModel *)other;
@end

@interface LVDraftStickerPayload : LVDraftPayload
@property (nonatomic, copy)           NSString *categoryID;
@property (nonatomic, copy)           NSString *categoryName;
@property (nonatomic, nullable, copy) NSString *iconUrl;
@property (nonatomic, copy)           NSString *name;
@property (nonatomic, copy)           NSString *path;
@property (nonatomic, nullable, copy) NSString *previewCoverUrl;
@property (nonatomic, copy)           NSString *resourceID;
@property (nonatomic, assign)         NSInteger sourcePlatform;
@property (nonatomic, copy)           NSString *stickerID;
@property (nonatomic, copy)           NSString *unicode;
- (void)copyCategoryToNewObject:(LVDraftStickerPayload *)other;
@end

@interface LVEffectTemplateResource : NSObject
@property (nonatomic, nullable, copy) NSString *panel;
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, nullable, copy) NSString *resourceID;
@property (nonatomic, assign)         NSInteger sourcePlatform;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVEffectTemplateResource *)other;
@end

@interface LVDraftTextPayload : LVDraftPayload
@property (nonatomic, assign)           NSInteger textAlignment;
@property (nonatomic, assign)           CGFloat backgroundAlpha;
@property (nonatomic, copy)             NSString *backgroundColor;
@property (nonatomic, assign)           CGFloat boldWidth;
@property (nonatomic, copy)             NSString *borderColor;
@property (nonatomic, assign)           CGFloat borderWidth;
@property (nonatomic, copy)             NSString *content;
@property (nonatomic, copy)             NSString *fallbackFontPath;
@property (nonatomic, copy)             NSString *fontEffectID;
@property (nonatomic, nullable, copy)   NSString *fontName;
@property (nonatomic, nullable, copy)   NSString *fontPath;
@property (nonatomic, copy)             NSString *fontResourceID;
@property (nonatomic, assign)           CGFloat fontSize;
@property (nonatomic, copy)             NSString *fontTitle;
@property (nonatomic, assign)           BOOL hasShadow;
@property (nonatomic, assign)           NSInteger italicDegree;
@property (nonatomic, nullable, copy)   NSString *ktvColor;
@property (nonatomic, assign)           NSInteger layerWeight;
@property (nonatomic, assign)           CGFloat letterSpacing;
@property (nonatomic, assign)           CGFloat lineSpacing;
@property (nonatomic, assign)           CGFloat shadowAlpha;
@property (nonatomic, assign)           CGFloat shadowAngle;
@property (nonatomic, nullable, copy)   NSString *shadowColor;
@property (nonatomic, assign)           CGFloat shadowDistance;
@property (nonatomic, nullable, strong) LVPoint *shadowPointInfo;
@property (nonatomic, assign)           CGFloat shadowSmoothing;
@property (nonatomic, assign)           BOOL shapeFlipX;
@property (nonatomic, assign)           BOOL shapeFlipY;
@property (nonatomic, nullable, copy)   NSString *styleName;
@property (nonatomic, assign)           NSInteger subType;
@property (nonatomic, assign)           CGFloat textAlpha;
@property (nonatomic, copy)             NSString *textColor;
@property (nonatomic, nullable, copy)   NSArray<NSString *> *textToAudioIds;
@property (nonatomic, assign)           NSInteger typesetting;
@property (nonatomic, assign)           BOOL underline;
@property (nonatomic, assign)           CGFloat underlineOffset;
@property (nonatomic, assign)           CGFloat underlineWidth;
@property (nonatomic, assign)           BOOL useEffectDefaultColor;
- (void)copyCategoryToNewObject:(LVDraftTextPayload *)other;
@end

@interface LVDraftTransitionPayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *categoryID;
@property (nonatomic, nullable, copy) NSString *categoryName;
@property (nonatomic, assign)         NSInteger durationMilliSeconds;
@property (nonatomic, copy)           NSString *effectID;
@property (nonatomic, assign)         BOOL isOverlap;
@property (nonatomic, copy)           NSString *name;
@property (nonatomic, copy)           NSString *relativePath;
@property (nonatomic, copy)           NSString *resourceID;
- (void)copyCategoryToNewObject:(LVDraftTransitionPayload *)other;
@end

@interface LVDraftVideoPayload : LVDraftPayload
@property (nonatomic, assign)           NSInteger aiMatting;
@property (nonatomic, nullable, copy)   NSString *cartoonPath;
@property (nonatomic, nullable, copy)   NSString *categoryID;
@property (nonatomic, nullable, copy)   NSString *categoryName;
@property (nonatomic, strong)           LVVideoCropInfo *crop;
@property (nonatomic, assign)           LVVideoCropRatio cropRatio;
@property (nonatomic, assign)           CGFloat cropScale;
@property (nonatomic, assign)           NSInteger durationMilliSeconds;
@property (nonatomic, assign)           NSInteger extraTypeOption;
@property (nonatomic, nullable, strong) LVGamePlay *gameplay;
@property (nonatomic, nullable, copy)   NSString *gameplayAlgorithm;
@property (nonatomic, nullable, copy)   NSString *gameplayPath;
@property (nonatomic, assign)           NSInteger height;
@property (nonatomic, nullable, copy)   NSString *intensifiesAudioPath;
@property (nonatomic, nullable, copy)   NSString *intensifiesPath;
@property (nonatomic, nullable, copy)   NSString *materialID;
@property (nonatomic, nullable, copy)   NSString *materialName;
@property (nonatomic, nullable, copy)   NSString *materialUrl;
@property (nonatomic, copy)             NSString *relativePath;
@property (nonatomic, nullable, copy)   NSArray<LVTypePathInfo *> *paths;
@property (nonatomic, nullable, copy)   NSString *reverseIntensifiesPath;
@property (nonatomic, nullable, copy)   NSString *reversePath;
@property (nonatomic, nullable, strong) LVStable *stable;
@property (nonatomic, nullable, copy)   NSArray<NSNumber *> *typeOption;
@property (nonatomic, assign)           CGFloat volume;
@property (nonatomic, assign)           NSInteger width;
- (void)copyCategoryToNewObject:(LVDraftVideoPayload *)other;
@end

@interface LVVideoCropInfo : NSObject
@property (nonatomic, assign) CGFloat lowerLeftX;
@property (nonatomic, assign) CGFloat lowerLeftY;
@property (nonatomic, assign) CGFloat lowerRightX;
@property (nonatomic, assign) CGFloat lowerRightY;
@property (nonatomic, assign) CGFloat upperLeftX;
@property (nonatomic, assign) CGFloat upperLeftY;
@property (nonatomic, assign) CGFloat upperRightX;
@property (nonatomic, assign) CGFloat upperRightY;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVideoCropInfo *)other;
@end

@interface LVGamePlay : NSObject
@property (nonatomic, nullable, copy) NSString *algorithm;
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, assign)         BOOL reshape;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVGamePlay *)other;
@end

@interface LVTypePathInfo : NSObject
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *type;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTypePathInfo *)other;
@end

@interface LVStable : NSObject
@property (nonatomic, copy)   NSString *matrixPath;
@property (nonatomic, assign) NSInteger stableLevel;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVStable *)other;
@end

@interface LVMutableConfig : NSObject
@property (nonatomic, copy)           NSString *alignModeString;
@property (nonatomic, nullable, copy) NSArray<LVMutablePayloadInfo *> *mutableInfos;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVMutableConfig *)other;
@end

@interface LVMutablePayloadInfo : NSObject
@property (nonatomic, nullable, copy) NSString *coverPath;
@property (nonatomic, copy)           NSString *payloadID;
@property (nonatomic, assign)         LVPlatformEnum platform;
@property (nonatomic, nullable, copy) NSString *relationVideoGroup;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVMutablePayloadInfo *)other;
@end

@interface LVPlatform : NSObject
@property (nonatomic, copy) NSString *appVersion;
@property (nonatomic, copy) NSString *osName;
@property (nonatomic, copy) NSString *osVersion;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVPlatform *)other;
@end

@interface LVRelationship : NSObject
@property (nonatomic, nullable, copy) NSArray<NSString *> *idToID;
@property (nonatomic, nullable, copy) NSString *type;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVRelationship *)other;
@end

@interface LVMediaTrack : NSObject
@property (nonatomic, assign) NSInteger flagInteger;
@property (nonatomic, copy)   NSString *trackID;
@property (nonatomic, copy)   NSArray<LVMediaSegment *> *segments;
@property (nonatomic, copy)   NSString *typeString;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVMediaTrack *)other;
@end

@interface LVMediaSegment : NSObject
@property (nonatomic, assign)           CGFloat avgSpeed;
@property (nonatomic, assign)           BOOL cartoon;
@property (nonatomic, nullable, strong) LVSegmentClipInfo *clipInfoPrivate;
@property (nonatomic, nullable, copy)   NSArray<NSString *> *extraMaterialRefs;
@property (nonatomic, nullable, copy)   NSArray<LVDraftPayload *> *relatedPayloadsPrivate;
@property (nonatomic, copy)             NSString *segmentID;
@property (nonatomic, assign)           BOOL intensifiesAudio;
@property (nonatomic, assign)           BOOL isToneModify;
@property (nonatomic, nullable, copy)   NSArray<NSString *> *keyframeRefs;
@property (nonatomic, nullable, copy)   NSArray<LVKeyframe *> *keyframesPrivate;
@property (nonatomic, assign)           CGFloat lastNonzeroVolumePrivate;
@property (nonatomic, nullable, strong) LVDraftPayload *payloadPrivate;
@property (nonatomic, copy)             NSString *materialID;
@property (nonatomic, assign)           BOOL mirror;
@property (nonatomic, assign)           NSInteger renderIndex;
@property (nonatomic, assign)           BOOL reverse;
@property (nonatomic, strong)           LVTimerange *sourceTimeRangeInfo;
@property (nonatomic, assign)           CGFloat speed;
@property (nonatomic, strong)           LVTimerange *targetTimeRangeInfo;
@property (nonatomic, assign)           NSInteger targetTimeOffset;
@property (nonatomic, assign)           CGFloat volumePrivate;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVMediaSegment *)other;
@end

@interface LVSegmentClipInfo : NSObject
@property (nonatomic, assign)           CGFloat alpha;
@property (nonatomic, nullable, strong) LVFlipClass *flipInfo;
@property (nonatomic, assign)           CGFloat rotation;
@property (nonatomic, nullable, strong) LVPoint *scaleInfo;
@property (nonatomic, nullable, strong) LVPoint *transform;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVSegmentClipInfo *)other;
@end

@interface LVFlipClass : NSObject
@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) BOOL vertical;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVFlipClass *)other;
@end

@interface LVTimerange : NSObject
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger start;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTimerange *)other;
@end

@interface LVCoverTemplate : NSObject
@property (nonatomic, nullable, copy) NSString *coverTemplateCategory;
@property (nonatomic, nullable, copy) NSString *coverTemplateCategoryID;
@property (nonatomic, nullable, copy) NSString *coverTemplateID;
@property (nonatomic, nullable, copy) NSArray<NSString *> *coverTemplateMaterialIds;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverTemplate *)other;
@end

@interface LVCoverFrameInfo : NSObject
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, copy)   NSString *segmentID;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverFrameInfo *)other;
@end

@interface LVCoverImageInfo : NSObject
@property (nonatomic, strong) LVVideoCropInfo *crop;
@property (nonatomic, copy)   NSString *path;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverImageInfo *)other;
@end

@interface LVCoverMaterials : NSObject
@property (nonatomic, copy) NSArray<LVCoverText *> *coverTexts;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverMaterials *)other;
@end

@interface LVCoverText : NSObject
@property (nonatomic, strong)           LVSegmentClipInfo *clip;
@property (nonatomic, strong)           LVDraftTextPayload *text;
@property (nonatomic, nullable, strong) LVDraftEffectPayload *textEffect;
@property (nonatomic, nullable, strong) LVDraftEffectPayload *textShape;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVCoverText *)other;
@end

@interface LVExtraInfo : NSObject
@property (nonatomic, nullable, strong) LVTrackInfo *trackInfo;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVExtraInfo *)other;
@end

@interface LVTrackInfo : NSObject
@property (nonatomic, nullable, copy)   NSString *templateID;
@property (nonatomic, nullable, copy)   NSArray<NSString *> *transferPaths;
@property (nonatomic, nullable, strong) LVTutorialInfo *tutorialInfo;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTrackInfo *)other;
@end

@interface LVTutorialInfo : NSObject
@property (nonatomic, nullable, copy) NSString *editMethod;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTutorialInfo *)other;
@end

@interface LVTemplateParam : NSObject
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *boundingBox;
@property (nonatomic, assign)         CGFloat duration;
@property (nonatomic, nullable, copy) NSArray<NSString *> *fallbackFontList;
@property (nonatomic, assign)         NSInteger orderInLayer;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *position;
@property (nonatomic, assign)         CGFloat rotation;
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *scale;
@property (nonatomic, assign)         CGFloat startTime;
@property (nonatomic, nullable, copy) NSArray<LVTemplateText *> *textList;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTemplateParam *)other;
@end

@interface LVTemplateText : NSObject
@property (nonatomic, nullable, copy) NSArray<NSNumber *> *boundingBox;
@property (nonatomic, assign)         CGFloat duration;
@property (nonatomic, assign)         NSInteger index;
@property (nonatomic, assign)         CGFloat startTime;
@property (nonatomic, nullable, copy) NSString *value;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTemplateText *)other;
@end

@interface LVTextSegment : NSObject
@property (nonatomic, assign)         NSInteger duration;
@property (nonatomic, assign)         BOOL isMutable;
@property (nonatomic, nullable, copy) NSString *materialID;
@property (nonatomic, assign)         CGFloat rotation;
@property (nonatomic, assign)         NSInteger targetStartTime;
@property (nonatomic, nullable, copy) NSString *text;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTextSegment *)other;
@end

@interface LVTimeClipParam : NSObject
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) NSInteger trimIn;
@property (nonatomic, assign) NSInteger trimOut;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVTimeClipParam *)other;
@end

@interface LVVeConfig : NSObject
@property (nonatomic, assign) BOOL autoPrepare;
@property (nonatomic, assign) BOOL veCtrlSurface;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVeConfig *)other;
@end

@interface LVVideoCompileParam : NSObject
@property (nonatomic, nullable, copy) NSString *audioFilePath;
@property (nonatomic, assign)         NSInteger bps;
@property (nonatomic, nullable, copy) NSString *compileJsonStr;
@property (nonatomic, nullable, copy) NSString *encodeProfile;
@property (nonatomic, assign)         NSInteger fps;
@property (nonatomic, assign)         NSInteger gopSize;
@property (nonatomic, assign)         NSInteger height;
@property (nonatomic, assign)         BOOL isAudioOnly;
@property (nonatomic, assign)         BOOL supportHwEncoder;
@property (nonatomic, assign)         NSInteger width;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVideoCompileParam *)other;
@end

@interface LVVideoPreviewConfig : NSObject
@property (nonatomic, assign) BOOL loop;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVideoPreviewConfig *)other;
@end

@interface LVVideoSegment : NSObject
@property (nonatomic, assign)           NSInteger aiMatting;
@property (nonatomic, nullable, copy)   NSString *alignMode;
@property (nonatomic, nullable, copy)   NSString *blendPath;
@property (nonatomic, assign)           NSInteger cartoonType;
@property (nonatomic, nullable, strong) LVSegmentClipInfo *clip;
@property (nonatomic, nullable, strong) LVVideoCropInfo *crop;
@property (nonatomic, assign)           CGFloat cropScale;
@property (nonatomic, assign)           NSInteger duration;
@property (nonatomic, nullable, copy)   NSArray<NSString *> *frames;
@property (nonatomic, nullable, copy)   NSString *gameplayAlgorithm;
@property (nonatomic, assign)           NSInteger height;
@property (nonatomic, nullable, copy)   NSString *identifier;
@property (nonatomic, assign)           BOOL isCartoon;
@property (nonatomic, assign)           BOOL isMutable;
@property (nonatomic, assign)           BOOL isReverse;
@property (nonatomic, assign)           BOOL isSubVideo;
@property (nonatomic, nullable, copy)   NSString *materialID;
@property (nonatomic, nullable, copy)   NSString *originPath;
@property (nonatomic, nullable, copy)   NSString *path;
@property (nonatomic, nullable, copy)   NSString *relationVideoGroup;
@property (nonatomic, assign)           NSInteger sourceStartTime;
@property (nonatomic, assign)           NSInteger targetStartTime;
@property (nonatomic, nullable, copy)   NSString *type;
@property (nonatomic, assign)           CGFloat volume;
@property (nonatomic, assign)           NSInteger width;
- (id)copyToNewObject;
- (void)copyCategoryToNewObject:(LVVideoSegment *)other;
@end

@interface LVDraftEffectTemplatePayload : LVDraftPayload
@property (nonatomic, nullable, copy) NSString *categoryID;
@property (nonatomic, nullable, copy) NSString *categoryName;
@property (nonatomic, nullable, copy) NSString *effectID;
@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *path;
@property (nonatomic, nullable, copy) NSString *resourceID;
- (void)copyCategoryToNewObject:(LVDraftEffectTemplatePayload *)other;
@end

@interface LVDraftTailLeaderPayload : LVDraftVideoPayload
@property (nonatomic, nullable, copy) NSString *textPrivate;
- (void)copyCategoryToNewObject:(LVDraftTailLeaderPayload *)other;
@end

@interface LVDraftTextTemplatePayload : LVDraftEffectTemplatePayload
@property (nonatomic, nullable, copy) NSString *fallbackFontPath;
@property (nonatomic, nullable, copy) NSArray<LVEffectTemplateResource *> *resources;
@property (nonatomic, assign)         NSInteger sourcePlatform;
- (void)copyCategoryToNewObject:(LVDraftTextTemplatePayload *)other;
@end

NS_ASSUME_NONNULL_END
