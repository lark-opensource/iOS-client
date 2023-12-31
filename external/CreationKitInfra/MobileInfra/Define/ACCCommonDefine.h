//
//  ACCCommonDefine.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/12.
//

#ifndef ACCCommonDefine_h
#define ACCCommonDefine_h

typedef NS_ENUM(NSUInteger, ACCSelectAlbumAOrMusicEnterFromPage) {
    ACCSelectAlbumAOrMusicEnterFromPageDefault,
    ACCSelectAlbumAOrMusicEnterFromPageRecord,  // Shooting
    ACCSelectAlbumAOrMusicEnterFromPageEdit,    // Editor
};

typedef NS_ENUM(NSInteger, AWEStuioPageType) {
    AWEStuioPageVideoRecord,
    AWEStuioPageVideoEdit,
    AWEStuioPageVideoEffectChoose,
    AWEStuioPageVideoPublish,
};

typedef NS_ENUM(NSInteger, AWEStudioPermessionCheckAction) {
    AWEStudioPermessionCheckActionDefault = 0,
    AWEStudioPermessionCheckActionDuet = 1,
    AWEStudioPermessionCheckActionStitch = 2,
    AWEStudioPermessionCheckActionMusic = 3,
};

typedef NS_ENUM(NSInteger, AWEStudioPermessionIdType) {
    AWEStudioPermessionIdTypeDefault = 0,
    AWEStudioPermessionIdTypeItemId = 1,
    AWEStudioPermessionIdTypeUserId = 2,
    AWEStudioPermessionIdTypeMusicId = 3,
};

typedef NS_ENUM(NSInteger, AWEStudioPermessionCheckStatus) {
    AWEStudioPermessionCheckStatusUnknown = 0,  // Unkonwn status, means the request failed due to network issue;
    AWEStudioPermessionCheckStatusSuccess = 1,  // Success, able to perform action
    AWEStudioPermessionCheckStatusFail = 2,     // Fail, unable to perform action
};

typedef NS_OPTIONS(NSUInteger, AWELogToolTag) {
    AWELogToolTagNone = 0,
    // The business-level tags are mutually exclusive to each other, but are bitwise or-able with the other-level tags.
    // Combining tags from the same grouping will result in an NSInvalidArgumentException.
    AWELogToolTagRecord = 1 << 0,  // Recording
    AWELogToolTagImport = 1 << 1,  // Local import
    AWELogToolTagEdit = 1 << 2,    // Editor
    AWELogToolTagPublish = 1 << 3, // Release
    AWELogToolTagDraft = 1 << 4,   // Draft
    AWELogToolTagMusic = 1 << 5,   // Music
    AWELogToolTagCloudAlbum = 1 << 6,   // CloudAlbum
    AWELogToolTagBusinessReserved = 1 << 10, // do not use
    // Likewise, the functional-level tags are mutually exclusive to each other.
    AWELogToolTagMV = 1 << 11,
    AWELogToolTagAIClip = 1 << 12,
    AWELogToolTagCompose = 1 << 13,
    AWELogToolTagUpload = 1 << 14,
    AWELogToolTagVideoEditor = 1 << 15,  // VESDK
    AWELogToolTagEffectPlatform = 1 << 16, // EffectPlatformSDK
    AWELogToolTagMonitor = 1 << 17,
    AWELogToolTagTracker = 1 << 18,
    AWELogToolTagMoment = 1 << 19, // Smart template (time album + one click XXX + more ways to play)
    AWELogToolTagSecurity = 1 << 20,
    AWELogToolTagKaraoke = 1 << 21,
    AWELogToolTagCommercialCheck = 1 << 22,
    AWELogToolTagFunctionalReserved = 1U << 31, // do not use
};

typedef NS_ENUM(NSInteger, AWEDraftMusicDeleteCauseType) {
    AWEDraftMusicDeleteCauseTypeUGC = 0,  // draft UGC music private / friend only / deleted by creator
    AWEDraftMusicDeleteCauseTypePGC = 1,  // draft PGC offline
    AWEDraftMusicDeleteCauseTypeBA = 2,     // draft long video and current user business account
    AWEDraftMusicDeleteCauseTypeNoPermision = 3, // draft long video and current user hasn't  choose long video music permission
};

typedef NS_ENUM(NSInteger, AWEPublishMusicRemoveAlertType) {
    AWEPublishMusicRemoveAlertTypeNone = 0,
    AWEPublishMusicRemoveAlertTypeUnavailableMusic = 1,  // alert caused by unavailable UGC / PGC music
    AWEPublishMusicRemoveAlertTypeLongVideo = 2,  // alert caused by long video
};

#endif /* ACCCommonDefine_h */
