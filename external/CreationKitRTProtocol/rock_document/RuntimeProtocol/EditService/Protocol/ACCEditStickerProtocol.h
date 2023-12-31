
//
//  ACCEditStickerProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//
@class RACSignal;
#import <Foundation/Foundation.h>
#import "ACCEditWrapper.h"
#import <TTVideoEditor/IESMMBaseDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class NLETrackSlot_OC;
@class NLEStickerBox;

@protocol ACCEditStickerProtocol <ACCEditWrapper>

@property (nonatomic, copy, readonly) NSArray<IESInfoSticker *> *infoStickers;
@property (nonatomic, copy) VEStickerImageBlock _Nullable captionStickerImageBlock;
@property (nonatomic, assign) NSInteger fixedTopInfoSticker; /// Set a sticker at the top and set ve stickerid

#pragma mark - Lyrics stickers

/// Add lyrics information
///@ param stickerid
///@ param SRT lyrics (JSON)
- (void)setSrtInfo:(NSInteger)stickerId srt:(NSString *)srt;

/// Set the font of the lyrics sticker
/// ID of @ param stickerid lyrics sticker
///@ param fontpath font resource package path
- (void)setSrtFont:(NSInteger)stickerId fontPath:(NSString *)fontPath;

/// Set the color of the lyrics sticker
/// ID of @ param stickerid lyrics sticker
/// @param r red 0.0~1.0
/// @param g green 0.0~1.0
/// @param b blue 0.0~1.0
/// @param a alpha 0.0~1.0
- (void)setSrtColor:(NSInteger)stickerId red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;

/// Set the editing status of lyrics stickers
///@ param stickerid lyrics sticker ID
///@ param state true indicates that the user is editing, and false indicates that the user has finished editing
- (void)setSrtManipulate:(NSInteger)stickerId state:(BOOL)state;

/// Set the clipping alignment of the music
/// ID of @ param stickerid lyrics sticker
/// The entry point of @ param seqinmusic in the video is temporarily 0
/// Start time of @ paramtrimin music
///@ param duration music duration
/// Is the @ param audiocycle music repeated
- (void)setSrtAudioInfo:(NSInteger)stickerId seqIn:(NSTimeInterval)seqIn trimIn:(NSTimeInterval)trimIn duration:(NSTimeInterval)duration audioCycle:(BOOL)audioCycle;

- (NSNumber *)filterMusicLyricStickerId;
- (NSString *)filterMusicLyricEffectId;
- (UIColor *)filterMusicLyricColor;

#pragma mark - auto-captioning
/// Add interface
- (NSInteger)addSubtitleSticker;
/// Update interface
- (void)updateSticker:(NSInteger)stickerId;

#pragma mark - Informative sticker Pin Pinning

/// Pin preparation
- (void)preparePin;

/// Apply pin sticker
///@ param stickerindex pin sticker ID
///@ param pinstarttime pin start time
///@ param duration pin duration
///@ param completion pin completes callback
- (void)startPin:(NSInteger)stickerIndex
    pinStartTime:(float)pinStartTime
     pinDuration:(float)duration
      completion:(nonnull void (^)(BOOL result, NSError *error))completion;

/// Cancel pin
///@ param stickerindex sticker ID
- (void)cancelPin:(NSInteger)stickerIndex;

/// Get pin status
///@ param stickerindex sticker ID
- (VEStickerPinStatus)getStickerPinStatus:(NSInteger)stickerIndex;

/// To set the pin sticker recovery mode, see < veeditorsession + effect. H > for details
///@ param mode information sticker pin status
- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode;

#pragma mark - Sticker

//###################################################
//################### READ ########################
- (BOOL)isAnimationSticker:(NSInteger)stickerID;
- (NSInteger)setStickerAnimationWithStckerID:(NSInteger)stickerID animationType:(NSInteger)animationType filePath:(NSString *)filePath duration:(CGFloat)duration;
- (CGSize)getInfoStickerSize:(NSInteger)stickerId;
- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId;
- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props;
- (CGRect)getstickerEditBoundBox:(NSInteger)stickerId;
- (CGFloat)getStickerRotation:(NSInteger)stickerIndex;
- (CGPoint)getStickerPosition:(NSInteger)stickerIndex;
- (BOOL)getStickerVisible:(NSInteger)stickerIndex;

//###################################################
//################### CREATE ########################
- (void)addStickerbyUIImage:(UIImage *)image letterInfo:(nullable NSString*)letterInfo duration:(CGFloat)duration;

/// Add information stickers
///@ param path image path
///@ param effectinfo special effect information
///@ param userinfo custom fields
- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(nullable NSArray *)effectInfo userInfo:(NSDictionary *)userInfo;

/// Add a text information sticker
///@ param userinfo to stickerinfo's userinfo
- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo;

//###################################################
//################### UPDATE ########################

/// Set up sticker transform
///@ param stickerid sticker ID
///@ param offsetx center offset x
///@ param offsety center offset y
///@ param angle (- 180) °-- one hundred and eighty °）
///@ param scale relative scaling factor
- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale;

/// batch set up sticker transform and move to front
///@ param stickerids sticker IDs
///@ param offsetx center offset x
///@ param offsety center offset y
///@ param angle (- 180) °-- one hundred and eighty °）
///@ param scale relative scaling factor
- (void)setStickersAbove:(NSArray<NSNumber *> *)stickerIds
                 offsetX:(CGFloat)offsetX
                 offsetY:(CGFloat)offsetY
                   angle:(CGFloat)angle
                   scale:(CGFloat)scale;

/// Set sticker offset
///@ param stickerid sticker ID
///@ param offsetx center offset x
///@ param offsety center offset y
- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY;

/// Set the rotation angle of the sticker
///@ param stickerid sticker ID
///@ param angle (- 180) °-- one hundred and eighty °）
- (void)setStickerAngle:(NSInteger)stickerId angle:(CGFloat)angle;

/// Set sticker transparency
///@ param stickerid sticker ID
///@ param alpha transparency (0 -- 1)
- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha;

/// batch set sticker transparency and move to front
///@ param stickerid sticker ID
///@ param alpha transparency (0 -- 1)
- (void)setStickerAlphas:(NSArray<NSNumber *> *)stickerIds
                   alpha:(CGFloat)alpha
                   above:(BOOL)above;

/// Set sticker effective time
///@ param stickerid sticker ID
///@ param starttime start time (s)
///@ param duration (s), - 1 is the maximum
- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration;
- (void)setTextStickerTextParams:(NSInteger)stickerId textParams:(NSString *)textParams;

/// Set the level of stickers, do not affect other stickers
///@ param stickerid sticker ID
///@ param layer level
- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer;

/// Set the absolute scale of the sticker
///@ param stickerid sticker ID
///@ param scale absolute scale
- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale;

/// batch set the absolute scale of the sticker
///@ param stickerids sticker IDs
///@ param scale absolute scale
- (void)setStickersScale:(NSArray<NSNumber *> *)stickerIds
                   scale:(CGFloat)scale;

/// Set the top-level display of the stickers. This method will change the rest of the information-based sticker levels to be arranged according to the subscript of the sticker array stored in VE
///@ param stickerid sticker ID
- (void)setStickerAbove:(NSInteger)stickerId;

/// Set the top display of the sticker, but always under the top sticker
/// @discussion  If setabove for info sticker, use this method
///@ param stickerid sticker ID
- (void)setStickerAboveForInfoSticker:(NSInteger)stickerId;

- (void)startChangeStickerDuration:(NSInteger)stickerId;
- (void)stopChangeStickerDuration:(NSInteger)stickerId;

//###################################################
//################### DELETE ########################

/// Remove informational stickers
///@ param stickerid sticker ID
- (void)removeInfoSticker:(NSInteger)stickerId;
- (void)removeAllInfoStickers;
- (void)removeAll2DStickers;

@optional

@property (nonatomic, readonly) RACSignal *stickerRegenerateSignal;

/// Atlas publishing mode only
- (NSInteger)addInfoSticker:(NSString *)path
             withEffectInfo:(nullable NSArray *)effectInfo
                   userInfo:(NSDictionary *)userInfo
           imageEditorIndex:(NSInteger)imageEditorIndex;

- (void)beginCurrentImageEditorBatchUpdate;

- (void)endCurrentImageEditorBatchUpdate;

/// This method doesn't have much to do with the timing of the sticker, but the sticker is reused and the current framework can't get mix wrap, so it is put in the sticker wrap first
/// Get the image size and ve rendering size of the text sticker in the atlas
- (CGFloat)getImageEditorTextStickerVEScaleWithImage:(UIImage *)image imagePath:(NSString *)path userInfo:(NSDictionary *)userInfo;

#pragma mark - Sticker Animation

- (void)disableStickerAnimation:(nullable NLETrackSlot_OC *)slot disable:(BOOL)disable;

- (nullable NLEStickerBox *)stickerBoxWithSlot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
