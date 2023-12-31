//
//  ModelType.h
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/13.
//

#ifndef ModelType_h
#define ModelType_h

namespace cdom {
    enum MaterialType {
        MaterialTypeNone = 0,
        MaterialTypeVideo = 1,
        MaterialTypePhoto,
        MaterialTypeMusic,
        MaterialTypeExtractMusic,
        MaterialTypeSound,
        MaterialTypeRecord,
        MaterialTypeImage,

        MaterialTypeText,
        MaterialTypeSubtitle,
        MaterialTypeSticker,
        MaterialTypeFilter,
        MaterialTypeReshape,
        MaterialTypeBeauty,
        MaterialTypeVideoEffect,

        MaterialTypeBrightness,
        MaterialTypeContrast,
        MaterialTypeSaturation,
        MaterialTypeSharpen,
        MaterialTypeHighlight,
        MaterialTypeShadow,
        MaterialTypeTemperature,
        MaterialTypeTone,
        MaterialTypeFade,
        MaterialTypeLightSensation,
        MaterialTypeVignetting,
        MaterialTypeParticle,

        MaterialTypeSegmentCanvas,
        MaterialTypeCanvasColor,
        MaterialTypeCanvasImage,
        MaterialTypeCanvasBlur,
        MaterialTypeTransition,
        MaterialTypeAudioEffect,
        MaterialTypeAudioFade,
        MaterialTypeBeats,
        MaterialTypeTailLeader,

        MaterialTypeAnimation,

        MaterialTypeTextEffect,
        MaterialTypeTextShape,

        MaterialTypeVideoAnimation,
        MaterialTypeTextToAudio,
        MaterialTypeVideoMix,
        MaterialTypeLyrics,
        MaterialTypeAdjust,
        MaterialTypeMask,
        MaterialTypeSpeed,
        MaterialTypeChroma,
        MaterialTypeTextTemplate,
        MaterialTypeGif,
        MaterialTypeVideoOriginalSound,
        MaterialTypeStretchLeg,
        MaterialTypeRealTimeDenoise,
        MaterialTypeFigure,
        MaterialTypeFaceEffect,

    };

    enum KeyframeType  {
        KeyframeTypeNone = 0,
        KeyframeTypeVideo = 1,
        KeyframeTypeAudio,
        KeyframeTypeText,
        KeyframeTypeSticker,
        KeyframeTypeFilter,
        KeyframeTypeAdjust,
    };

    enum TrackType {
        TrackTypeVideo = 0,
        TrackTypeAudio,
        TrackTypeSticker,
        TrackTypeVideoEffect,
        TrackTypeFilter,
        TrackTypeArticleVideo,
        TrackTypeNone,
    };

    enum EffectSourcePlatformType {
        EffectSourcePlatformTypeLoki = 0,
        EffectSourcePlatformTypeArtist
    };
}


#endif /* ModelType_h */
