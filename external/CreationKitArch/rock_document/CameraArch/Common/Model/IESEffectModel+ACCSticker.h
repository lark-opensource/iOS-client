//

#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <TTVideoEditor/IESMMBaseDefine.h>
#import <TTVideoEditor/HTSVideoData.h>
#import <Mantle/Mantle.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AWECommerceStickerType)
{
    AWECommerceStickerTypeUnknown,
    AWECommerceStickerTypeCommon,   // Commercial stickers supporting jump to landing page
};

typedef NS_ENUM(NSUInteger, ACCPropSelectionSource) {
    ACCPropSelectionSourceNone = 0,
    ACCPropSelectionSourceClassic,
    ACCPropSelectionSourceExposed
};

@interface ACCStickerMultiSegPropClipModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) CGFloat start;
@property (nonatomic, assign) CGFloat end;
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, copy) NSArray <NSNumber *>*xPoints;
@property (nonatomic, copy) NSArray <NSNumber *>*yPoints;

@end

@interface IESEffectModel (ACCSticker)

@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;
@property (nonatomic, copy) NSString *propSelectedFrom; // Prop source, used for burying point
@property (nonatomic, copy) NSString *localUnCompressPath;// Decompression path of built-in sound effects props
@property (nonatomic, copy) NSString *localVoiceEffectTag;// Tag with built-in sound effects
@property (nonatomic, copy) NSDictionary *recordTrackInfos;// for prop track
@property (nonatomic, assign) ACCPropSelectionSource selectionSource;
@property (nonatomic, copy) NSString *customStickerFilePath; // Custom sticker file path
@property (nonatomic, assign) BOOL useRemoveBg;// Remove Bg
@property (nonatomic, copy) NSArray *uploadFramePaths;// Path for upload frames

// Commercial sticker information
@property (nonatomic, copy, readonly) NSString *commerceWebURL;
@property (nonatomic, copy, readonly) NSString *commerceOpenURL;
@property (nonatomic, assign, readonly) AWECommerceStickerType commerceStickerType;
@property (nonatomic, copy, readonly) NSString *commerceBuyText;

// analyze extra and SDKExtra common
@property (nonatomic, copy, readonly) NSDictionary *acc_analyzeExtra;
@property (nonatomic, copy, readonly) NSDictionary *acc_analyzeSDKExtra;

// analyze type
- (BOOL)isTypeAR;
- (BOOL)isTypeARMatting;
- (BOOL)isTypeARKit;
- (BOOL)isTypeParticleJoint;
- (BOOL)isTypeTouchGes;
- (BOOL)isTypeStabilizationOff; // Turn off camera anti shake
- (BOOL)needKeepWhenEditing; // Do you need to cancel the application sticker when entering the edit page
- (BOOL)hasMakeupFeature;
- (BOOL)isTypeAdaptive; // Face scan sticker
- (BOOL)isTypeFaceReplace3D;
- (BOOL)isAnimatedDateSticker;

// analyze tag
- (BOOL)isTypeNewYear;  // New year stickers
- (BOOL)isTypeRecognition; // Identification sticker
- (BOOL)isTypeMute; // Silent sticker
- (BOOL)isTypeTimeInfo;
- (BOOL)isTypeMusicLyric;       // Lyrics stickers
- (BOOL)isTypeMagnifier; // Magnifying glass
- (BOOL)isTypeMultiScanBgVideo; // video control
- (BOOL)isUploadSticker;
- (BOOL)isDuetGreenScreen;
- (double)effectTimeLength;
- (NSString *)challengeID;
- (NSArray *)gestureRedPacketHandActionArray;// Is the sticker a gesture red envelope? Which gestures are included
- (NSArray<NSString *> *)dynamicIconURLs;
- (NSInteger)gestureRedPacketActivityType;// The activity type corresponding to the red envelope sticker
- (BOOL)isPreviewable;
- (BOOL)isLocked;
- (NSString *)activityId;
- (BOOL)isTypeVoiceRecognization; // Voice recognition stickers
- (BOOL)isTypeWeather;
- (BOOL)isTypeTime;
- (BOOL)isTypeDate;
- (BOOL)isTypeDairy;
- (BOOL)disableReshape;
- (BOOL)disableSmooth;
- (BOOL)disableBeautifyFilter;
- (BOOL)isStrongBeatSticker; // Is it a music stress sticker
- (BOOL)isTypeValantineStarSticker; // White Valentine's Day Star sticker
- (BOOL)isTypeInstrument; // Drum props
- (BOOL)needTransferTouch;
- (BOOL)isTypeCameraFront;
- (BOOL)isTypeCameraZoom;
- (BOOL)isTypeCameraBack;
- (BOOL)isType2DText;  // 2D text sticker
- (BOOL)canUseAmazingEngine; // Can I use a new rendering engine
- (BOOL)isDaily;

// analyze extra
- (BOOL)isTypePhotoSensitive;
- (BOOL)isTypeMusicBeat; // Music Prop
- (BOOL)isMultiSegProp; // Is it a multi stage prop
- (NSArray <ACCStickerMultiSegPropClipModel *>*)clipsArray;

- (BOOL)hasCommerceEnter; // Is there a commercial trial sticker entrance
- (IESMMEffectStickerInfo *)effectStickerInfo;
- (ACCGameType)gameType;

- (nullable NSString *)welfareActivityID;
- (NSInteger)guideVideoThresholdCount;
- (BOOL)infoStickerBlockStory;

@end

#pragma mark - EffectControlGame

@interface IESEffectModel (EffectControlGame)

- (BOOL)isEffectControlGame;// The game directly controlled by effect is judged by the SDK extra field, which is different from the old small game

@end

#pragma mark - Pixaloop

@interface IESEffectModel (Pixaloop)

@property (nonatomic, copy, readonly) NSDictionary *pixaloopExtra;
@property (nonatomic, copy, readonly) NSDictionary *pixaloopSDKExtra;

- (BOOL)isPixaloopSticker;
- (BOOL)isMultiAssetsPixaloopProp;
- (BOOL)isVideoBGPixaloopSticker;

@end

@interface NSDictionary (Pixaloop)

/**
 * In the sdkExtra field
 * Image to video sticker recognition type: face, sky, etc.
 */
// for pixaloop?
- (NSString *)acc_effectAlgorithmHint;
- (NSInteger)acc_albumFilterNumber:(NSString *)key;

- (NSString *)acc_illegalPhotoHint;
- (NSString *)acc_mvResolutionLimitedToast;
- (NSInteger)acc_mvResolutionLimitedWidth;
- (NSInteger)acc_mvResolutionLimitedHeight;
- (NSString *)acc_savePhotoHint;
- (NSString *)acc_algorithmArrNeedSavePhoto;
- (BOOL)acc_enableMVOriginAudio;

- (NSArray<NSString *> *)acc_pixaloopAlg:(NSString*)key; // Recognition algorithm
- (NSString *)acc_pixaloopImgK:(NSString*)key; // Rendering mode
- (NSString *)acc_pixaloopRelation:(NSString*)key; // Algorithm relation and / or
- (BOOL)acc_pixaloopLoading:(NSString*)key; // Display loading view
- (NSString *)acc_pixaloopResourcePath:(NSString*)key; // Relative path of resources in sticker
/**
 * In the extra field
 * pixaloop pop-ups are used
 * Prompt text, stills and lead videos
 */
- (NSString *)acc_pixaloopText;
- (NSString *)acc_pixaloopVideoCover;
- (NSString *)acc_pixaloopPictureCover;
- (NSInteger)acc_maxAssetsSelectionCount;
- (NSInteger)acc_minAssetsSelectionCount;
- (NSInteger)acc_defaultAssetsSelectionCount;

@end

#pragma mark - ACCARConfiguration

@interface IESEffectModel (ACCARConfiguration)

- (NSDictionary *)acc_ARConfigurationDictionary;

@end

#pragma mark - BindingMusic

@interface IESEffectModel (BindingMusic)
- (BOOL)acc_isForceBindingMusic; // Strong binding of music props
@end

#pragma mark - SlowMotion

@interface IESEffectModel (SlowMotion)

- (BOOL)acc_isCannotCancelMusic;
- (BOOL)acc_useEffectRecordRate;
- (BOOL)acc_forbidSpeedBarSelection;
- (BOOL)acc_isTypeSlowMotion;

@end

#pragma mark - Audio Graph

@interface IESEffectModel (AudioGraph)

/** Audio graph prop has the `audio_graph` key presented in extra.json, structured as:
 * {
 *   "audio_graph" : {
        "sources" : ["mic", "music"],
 *      "use_output" : true/false
 *    }
 * }
 * Detailed explanation: https://bytedance.feishu.cn/docs/doccnanBxNO2qOd3qacFN6351oe
 */
- (BOOL)isTypeAudioGraph;
- (BOOL)audioGraphMicSource; // `audio_graph.sources` contains `mic`.
- (BOOL)audioGraphMusicSource; // `audio_graph.sources` contains `music`.
- (BOOL)audioGraphUseOutput; // `audio_graph.use_output`.

@end

NS_ASSUME_NONNULL_END
