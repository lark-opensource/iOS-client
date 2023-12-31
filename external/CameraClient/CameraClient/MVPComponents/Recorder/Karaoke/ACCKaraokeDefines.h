//
//  ACCKaraokeDefines.h
//  Aweme
//
//  Created by xiafeiyu on 2021/10/27.
//

#ifndef ACCKaraokeDefines_h
#define ACCKaraokeDefines_h

/**
 * @discussion K歌选择页的 tab id
 */
FOUNDATION_EXPORT NSString * const kAWEKaraokeCollectionIDDuetSing; // 合唱 tab
FOUNDATION_EXPORT NSString * const kAWEKaraokeCollectionIDRecommend; // 推荐 tab
FOUNDATION_EXPORT NSString * const kAWEKaraokeCollectionIDSelectedSong;// 已点 tab

FOUNDATION_EXPORT NSString * const kAWEKaraokeCollectionIDSearch; // 搜索结果list，客户端本地定义


typedef NS_ENUM(NSUInteger, ACCKaraokeMusicSource) {
    ACCKaraokeMusicSourceInvalid = 0,
    ACCKaraokeMusicSourceKaraokeSelectMusic = 1,
    ACCKaraokeMusicSourceMusicDetail = 2,
    ACCKaraokeMusicSourceRecordSelectMusic = 3,
    ACCKaraokeMusicSourceBackupOrDraft = 4,
};

typedef NS_ENUM(NSUInteger, ACCKaraokeActionType) {
    ACCKaraokeActionTypeInvalid = 0,
    ACCKaraokeActionTypeMusic = 1, // 物料类型是音乐，用于唱歌。
    ACCKaraokeActionTypeAweme = 2  // 物料类型是Aweme视频，用于合拍类型的合唱。
};

FOUNDATION_EXPORT NSString * const kAWEKaraokeDefaultRecordMode;

typedef NSString * ACCKaraokeWorkflowParam;
/**
 * @discussion Required. The karaoke music (AWEMusicModel), must has its `karaoke` property to be non-nil;
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowMusic;
/**
 * @discussion Required. An enum integer of ACCKaraokeMusicSource.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowMusicSource;
/**
 * @discussion Not Required. Integer, either ACCKaraokeRecordModeVideo or ACCKaraokeRecordModeAudio. If not provided, will use previous karaoke record mode. If is the first time to use karaoke, will use AB configuration.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowRecordMode;
/**
 * @discussion Not Required. Bool, either open original sound or not when enter PrepareToRecord state. Default is NO. If it's recovering backup/draft, `originalSoundOpened` will be set to the draft's saved value, ignoring this parameter.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowUseOriginalSound;
/**
 * @discussion Not Required. Bool, if YES, stops immediately upon stopping. Default is NO.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowUseLightning;
/**
 * @discussion Not Required. If provided, this block will be invoked after exiting karaoke mode.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowReturnBlock;
/**
 * @discussion Not Required. If provided, will use this materials (its `validated` property must be true) to start karaoke work flow. If not provided, will download karaoke materials with the music given by `kAWEKaraokeWorkflowMusic`.
 */
FOUNDATION_EXPORT ACCKaraokeWorkflowParam const kAWEKaraokeWorkflowMaterials;


#endif /* ACCKaraokeDefines_h */
