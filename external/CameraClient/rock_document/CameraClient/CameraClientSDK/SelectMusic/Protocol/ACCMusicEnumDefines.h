//
//  ACCMusicEnumDefines.h
//  CameraClient
//
//  Created by Zhihao Zhang on 2021/2/26.
//

#ifndef ACCMusicEnumDefines_h
#define ACCMusicEnumDefines_h

typedef NS_ENUM(NSInteger, ACCMusicServicePlayStatus) {
    ACCMusicServicePlayStatusStopped,
    ACCMusicServicePlayStatusPlaying,
    ACCMusicServicePlayStatusPaused,
    ACCMusicServicePlayStatusLoading,
    ACCMusicServicePlayStatusError
};

typedef NS_ENUM(NSUInteger, ACCMusicCommonSearchBarType) {
    ACCMusicCommonSearchBarTypeRightButtonAuto,
    ACCMusicCommonSearchBarTypeRightButtonShow,
    ACCMusicCommonSearchBarTypeRightButtonHidden,
};

typedef NS_ENUM(NSUInteger, ACCSearchTabType) {
    ACCSearchTabMusicCreate,
    ACCSearchTabMusicKaraoke,
};


typedef NS_ENUM(NSUInteger, AWEStudioMusicCollectionType) {
    AWEStudioMusicCollectionTypeCancelCollection,
    AWEStudioMusicCollectionTypeCollection,
};

typedef NS_ENUM(NSUInteger, ACCImageGearType) {
    ACCImageGearTypeMusic,
    ACCMusicBannerImageGearType
};

typedef NS_ENUM(NSUInteger, ACCASSSearchMusicEnterSourceType) {
    ACCASSSearchMusicEnterSourceNormalType,
    ACCASSSearchMusicEnterSourceMusicStickerType,
    ACCASSSearchMusicEnterSourceCommerce,
    ACCASSSearchMusicEnterSourceKaraokeType,
};

#endif /* ACCMusicEnumDefines_h */
