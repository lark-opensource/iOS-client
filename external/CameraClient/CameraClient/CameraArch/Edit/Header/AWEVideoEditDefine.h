//
//  AWEVideoEditDefine.h
//  Pods
//
//  Created by lxp on 2019/9/29.
//

#ifndef AWEVideoEditDefine_h
#define AWEVideoEditDefine_h

typedef NS_ENUM(NSInteger, AWEStudioEditFunctionType) {
    AWEStudioEditFunctionMusic          = 1,    // 音乐
    AWEStudioEditFunctionEffect         = 2,    // 特效
    AWEStudioEditFunctionSticker        = 3,    // 贴纸
    AWEStudioEditFunctionChangeVoice    = 4,    // 变声
    AWEStudioEditFunctionVideoEnhance   = 5,    // 画质增强
    AWEStudioEditFunctionText           = 7,    // 文字
    AWEStudioEditFunctionLyrics         = 9,    // lyrics is subtype of AWEStudioEditFunctionSticker
    AWEStudioEditFunctionCustomSticker  = 10,    // CustomSticker is subtype of AWEStudioEditFunctionSticker
    AWEStudioEditFunctionLiveSticker    = 11,
    // 11 was deleted, for quick publish button
    // -----------------above is top right bar item bubble -----------------------
    AWEStudioEditFunctionTopSelectMusic = 12,    // top select button guidance
    AWEStudioEditFunctionPublishButton  = 13,    // publish Button guidance
    AWEStudioEditFunctionKaraokeVolume  = 14,
    AWEStudioEditFunctionKaraokeAudioBG = 15,
    AWEStudioEditFunctionGrootSticker = 16,
    AWEStudioEditFunctionSmartMovie = 17,
    AWEStudioEditFunctionTags = 18,
    AWEStudioEditFunctionClipAtShareToStoryScene = 19,  // 分享到日常剪裁
    AWEStudioEditFunctionWishModule  = 20,
    AWEStudioEditFunctionWishText  = 21,
    AWEStudioEditFunctionFlowerRedPacket = 22,
    AWEStudioEditFunctionImageAlbumCrop = 23,  // 图文图片裁切
};

typedef NS_ENUM(NSInteger, AWEAudioClipRangeChangeType) {
    AWEAudioClipRangeChangeTypeUnknown = 0,
    AWEAudioClipRangeChangeTypeShowView = 1,
    AWEAudioClipRangeChangeTypeChange = 2,
    AWEAudioClipRangeChangeTypeHideView = 3,
};

typedef NS_ENUM(NSInteger, ACCMusicPanelLyricsStickerButtonChangeType) {
    ACCMusicPanelLyricsStickerButtonChangeTypeReset = 0,
    ACCMusicPanelLyricsStickerButtonChangeTypeEnable,
    ACCMusicPanelLyricsStickerButtonChangeTypeUnenable,
};

static NSString *const ACCEffectRequestDomain = @"https://effect.snssdk.com";

FOUNDATION_EXPORT void * const ACCEditChangeVoicePanelContext;

FOUNDATION_EXPORT void * const ACCVideoEditMusicContext;

#endif /* AWEVideoEditDefine_h */
