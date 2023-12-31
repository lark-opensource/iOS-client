//
//  ACCRepoKaraokeModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/22.
//

#import "ACCMusicModelProtocolD.h"
#import <Mantle/MTLJSONAdapter.h>

#import "ACCKaraokeTimeSlice.h"

typedef NS_ENUM(NSInteger, ACCKaraokeRecordMode) {
    ACCKaraokeRecordModeVideo = 0,
    ACCKaraokeRecordModeAudio = 1,
};

@class AWEAssetModel, ACCEditMVModel;

@protocol ACCKaraokeEditModelProtocol <MTLJSONSerializing>

@property (nonatomic, copy) NSArray<ACCKaraokeTimeSlice *> *originalSongTimeList;// 不持久化
@property (nonatomic, copy) NSArray<ACCKaraokeTimeSlice *> *accompanyTimeList;// 不持久化
@property (nonatomic, assign) CGFloat vocalVolume;// 人声音量
@property (nonatomic, assign) CGFloat bgmVolume;// 伴奏或者原唱音量
@property (nonatomic, assign) CGFloat vocalAlign;// 人声对齐
@property (nonatomic, assign) BOOL useRecommendVolume;// 是否使用推荐音量
@property (nonatomic, assign) BOOL useOriginalSong;// 是否开启原唱
@property (nonatomic, assign) NSUInteger accompanyIndex;
@property (nonatomic, assign) NSUInteger originalSongIndex;
@property (nonatomic, copy, nullable) NSString *lyricStyleId;// 歌词样式id
@property (nonatomic, copy, nullable) NSString *lyricInfoStyleId;// 歌词信息样式id
@property (nonatomic, copy, nullable) NSString *lyricFontId;// 歌词字体id
@property (nonatomic, copy, nullable) NSString *soundEffectId;// 混响id
@property (nonatomic, copy, nullable) NSString *audioBGVideoId;// 音频模式视频背景id
@property (nonatomic, copy, nullable) NSString *preloadVideoBGID;// 预加载视频背景id
@property (nonatomic, copy, nullable) NSArray<NSString *> *audioBGImages;// 音频模式图片背景相对路径
@property (nonatomic, copy, nullable) NSString *audioBGImagesPickerId;// 每次选取操作的标记，不持久化
@property (nonatomic, copy, nullable) NSArray<AWEAssetModel *> *audioBGAssetModels;// 音频模式图片背景asset，不持久化

- (void)reset;

@end

@protocol ACCRepoKaraokeModelProtocol <NSObject>

#pragma mark - Entrance
/**
 * @note Set in `VideoRouterKaraokeSevice`, read in following steps.
 */

/**
 * @brief If has music, enter recorder directly.
 */
@property (nonatomic, assign) BOOL enterWithMusic;

#pragma mark - Record
/**
 * @note In most situations, set in RecorderVC, read in following steps. In the case of recovering backup or draft, the data flows in the reverse direction.
 */

@property (nonatomic, copy) NSString *karaokeID;
@property (nonatomic, copy) NSString *karaokeMusicID;
@property (nonatomic, assign) ACCKaraokeRecordMode recordMode;
@property (nonatomic, strong) ACCEditMVModel *mvModel;
@property (nonatomic, strong) id<ACCMusicKaraokeAudioModelProtocol> originalSongTrack;
@property (nonatomic, strong) id<ACCMusicKaraokeAudioModelProtocol> accompanyTrack;
@property (nonatomic, strong) id<ACCMusicModelProtocolD> musicModel;
@property (nonatomic, assign) BOOL lightningStyleKaraoke; // enter edit page immediately when the user stops.
/**
 * Whether the builtin microphone is used for audio capturing in recording page.
 */
@property (nonatomic, assign) BOOL recordWithBuiltinMic;

#pragma mark - Edit
/**
 * @note In most situations, set in EditVC, read in following steps. In the case of recovering backup or draft, the data flows in the reverse direction.
 */
@property (nonatomic, assign) BOOL fromRecordExport;
@property (nonatomic, strong) id<ACCKaraokeEditModelProtocol> editModel;

- (NSString *)lyricJsonString;

#pragma mark - Track
/**
 * @note Different creation steps will set different tracking parameters as listed in https://bytedance.feishu.cn/docs/doccnQ5Pw5BOUa8C00VJs0wiBWc#
 */
@property (nonatomic, copy, readonly) NSDictionary *trackParams;
- (void)addTrackParamsFromDictionary:(nullable NSDictionary *)dictionary;
- (void)setTrackParam:(nullable NSString *)param forKey:(nonnull NSString *)paramKey;

@end
