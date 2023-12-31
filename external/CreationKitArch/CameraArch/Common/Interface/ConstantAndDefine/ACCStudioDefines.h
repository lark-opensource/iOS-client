//
//  ACCStudioDefines.h
//  AWEStudio
//
//  Created by lixingdong on 2018/6/15.
//  Copyright  ©  Byedance. All rights reserved, 2018
//


#ifndef ACCStudioDefines_h
#define ACCStudioDefines_h

typedef NS_ENUM(NSUInteger, AWESegClipMode) {
    AWESegClipModeSingle,           // Single clip
    AWESegClipModeMulti,            // Multiterminal clipping
    AWESegClipModeMultiToSingle,    // Multi terminal variable single segment clipping
};

typedef NS_ENUM(NSUInteger, AWESegEditMode) {
    AWESegEditModeTotal,        // Whole cut
    AWESegEditModeSingle,       // Segmented clipping
};

typedef NS_ENUM(NSUInteger, AWEVideoClipMode) {
    AWEVideoClipModeNormal,     // Common cutting
    AWEVideoClipModeAI,         // Intelligent cutting
};

typedef NS_ENUM(NSUInteger, AWEClipCollectionType) {
    AWEClipCollectionTypeFrame = 0,        // Frame collectonview
    AWEClipCollectionTypeVideo             // Video list collectionview
};

typedef NS_ENUM(NSInteger, AWEVideoRouterDownloadStickerErrorCode) {
    AWEVideoRouterDownloadStickerErrorCodeNoStickerID    = -1,
    AWEVideoRouterDownloadStickerErrorCodeEmptyEffects   = -2,
    AWEVideoRouterDownloadStickerErrorCodeDownloadFail   = -3,
    
    AWEVideoRouterDownloadStickerErrorCodeOffline        = 2002,
    AWEVideoRouterDownloadStickerErrorCodeNonsupport     = 2003,
    AWEVideoRouterDownloadStickerErrorCodeNonexistence   = 2004,
    AWEVideoRouterDownloadStickerErrorCodeOutOfAllowList = 2005,
    AWEVideoRouterDownloadStickerErrorCodeVersionLower   = 2006,
    
    
    AWEVideoRouterDownloadStickerErrorCodeNeedUnlockByQRCode = 10000, // The local error code is used to handle the pop-up prompt logic of commercial stickers that need to be scanned and unlocked
};

typedef NS_ENUM(NSInteger, AWEVideoRouterReuseStickerErrorCode) {
    AWEVideoRouterReuseStickerErrorCodeNotStrictFirstSticker    = -1,
};

typedef NS_ENUM(NSInteger, AWEComposerFaceDetectStatus) {
    AWEComposerFaceDetectBegin        = 1,
    AWEComposerFaceDetecting          = 2,
    AWEComposerFaceDetectNoFace       = 3,
    AWEComposerFaceDetectMutiFaces    = 4,
    AWEComposerFaceDetectNoFitFace    = 5,
    AWEComposerFaceDetectFaceChange   = 6,
    AWEComposerFaceDetectComplete     = 7,
    AWEComposerFaceDetectError        = 8,
    AWEComposerFaceDetectEffectLoaded = 9,
};

// The source of choice for shooting page music
typedef NS_ENUM(NSInteger, AWERecordMusicSelectSource) {
    AWERecordMusicSelectSourceUnSelected = 0,
    AWERecordMusicSelectSourceMusicSelectPage = 1,  // Music is manually selected from the music selection page
    AWERecordMusicSelectSourceStickerForceBind = 2,  // Music from props strong binding automatically applied to the shooting page
    AWERecordMusicSelectSourceOriginalVideo = 3,    // From the original video music
    AWERecordMusicSelectSourceMusicDetail = 4,   // From music details page
    AWERecordMusicSelectSourceChallengeStrongBinded = 5, // Challenge music
    AWERecordMusicSelectSourceTaskStrongBinded = 6, // Task Force music
    AWERecordMusicSelectSourcePhotoToVideoList = 7, // from photo to video default music list
    AWERecordMusicSelectSourceImageAlbumEditSwitched = 8, // From picture editing to video sharing
    AWERecordMusicSelectSourceRecommendAutoApply = 9,   // Automatic application of weak binding music in shooting page
    AWERecordMusicSelectSourceRemoteResourceBind = 10,   // Automatic application of music from remote resource
};

typedef NS_ENUM(NSInteger, AWEForceBindMusicBubbleStatus) {
    AWEForceBindMusicBubbleStatusDefault = 0, // The music bubble has been displayed
    AWEForceBindMusicBubbleStatusFailed = 1, // Loading failed
    AWEForceBindMusicBubbleStatusSuccess = 2 // Loaded successfully
};

typedef NS_ENUM(NSUInteger, AWEAIVideoClipFooterViewPanelType) {
    AWEAIVideoClipFooterViewPanelTypeRequestFailed, // Request failed
    AWEAIVideoClipFooterViewPanelTypeMusic, // Music choice
    AWEAIVideoClipFooterViewPanelTypeVideoSegments, // Multi video adjustment
    AWEAIVideoClipFooterViewPanelTypeOneVideoClip, // Single paragraph editing

};

typedef NS_ENUM(NSInteger, ACCButtonDirection) {
    ACCButtonDirectionLeft,
    ACCButtonDirectionRight
};


typedef NS_ENUM(NSInteger, AWEDelayRecordMode) {
    AWEDelayRecordModeDefault = 0,
    AWEDelayRecordMode3S = 3,
    AWEDelayRecordMode10S = 10
};

typedef NS_ENUM(NSInteger, AWEVideoUploadType) {
    AWEVideoUploadTypeNormal = 0,
    AWEVideoUploadTypeProp = 1,
    AWEVideoUploadTypeMV = 2,
    AWEVideoUploadTypeGreenScreenDuet = 3
};

typedef NS_ENUM(NSInteger, AWEAlbumFaceCacheCleanStatus) {
    AWEAlbumFaceCacheCleanStatusDefault,
    AWEAlbumFaceCacheCleanStatusStart,
    AWEAlbumFaceCacheCleanStatusCancel,
    AWEAlbumFaceCacheCleanStatusFinished
};

#ifndef kAWEStudioReuseSticker
#define kAWEStudioReuseSticker @"prop_reuse"
#endif

#ifndef kAWEStoryPublishXBannerClosed
#define kAWEStoryPublishXBannerClosed @"kAWEStoryPublishXBannerClosed"
#endif

#ifndef kAWEStudioDraftRecordSavedModififedVideo
#define kAWEStudioDraftRecordSavedModififedVideo @"AWEStudioDraftRecordSavedModififedVideo"
#endif

#ifndef kAWEStudioPublishRetryDraftIDKey
#define kAWEStudioPublishRetryDraftIDKey @"kAWEStudioPublishRetryDraftIDKey"
#endif

#ifndef kAWEStudioAllowShowFunctionToastKey
#define kAWEStudioAllowShowFunctionToastKey @"kAWEStudioAllowShowFunctionToastKey"
#endif

#ifndef kAWEStudioEditFunctionToastShowedValuesKey
#define kAWEStudioEditFunctionToastShowedValuesKey @"kAWEStudioEditFunctionToastShowedValuesKey"
#endif

#ifndef kAWEStudioEditSoundsToastFirstShowedValuesKey
#define kAWEStudioEditSoundsToastFirstShowedValuesKey @"kAWEStudioEditSoundsToastFirstShowedValuesKey"
#endif

#define AWEStudioSafeString(__string__) __string__ ?: @""

typedef void(^AWEStudioUserListDataBlock)(NSArray *userList, NSArray *shieldList, NSError *error);

static const NSUInteger AWEStudioTaskFlowPresentingVCTag = 1000;
static const NSUInteger AWEStudioSingleClipPresentingVCTag = 1001;
static const NSUInteger AWEStudioRecordDraftPresentingVCTag = 1002;

#define AWEStudioIsValidViewFrame(__frame__) (AWEStudioIsValidViewOrigin(__frame__.origin) && AWEStudioIsValidViewSize(__frame__.size))

#define AWEStudioIsValidViewOriginDimension(__number__) (!isnan(__number__) && isfinite(__number__))
#define AWEStudioIsValidViewOrigin(__origin__) (AWEStudioIsValidViewOriginDimension(__origin__.x) && AWEStudioIsValidViewOriginDimension(__origin__.y))

#define AWEStudioIsValidVideoSizeDimension(__number__) (!isnan(__number__) && __number__ > 0 && isfinite(__number__))
#define AWEStudioIsValidVideoSize(__size__) (AWEStudioIsValidVideoSizeDimension(__size__.width) && AWEStudioIsValidVideoSizeDimension(__size__.height))

#define AWEStudioIsValidViewSizeDimension(__number__) (!isnan(__number__) && __number__ >= 0 && isfinite(__number__))
#define AWEStudioIsValidViewSize(__size__) (AWEStudioIsValidViewSizeDimension(__size__.width) && AWEStudioIsValidViewSizeDimension(__size__.height))

#endif /* AWEStudioDefines_h */
