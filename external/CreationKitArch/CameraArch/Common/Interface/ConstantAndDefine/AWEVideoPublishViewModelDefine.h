//
//  AWEVideoPublishViewModelDefine.h
//  Pods
//
//  Created by songxiangwu on 2019/8/23.
//

#ifndef AWEVideoPublishViewModelDefine_h
#define AWEVideoPublishViewModelDefine_h

typedef struct __attribute__((objc_boxable)) _HTSAudioRange {
    CGFloat location;
    CGFloat length;
} HTSAudioRange;

typedef NS_ENUM(NSInteger,AWEVideoSource) {
    AWEVideoSourceUnknown = -1,
    AWEVideoSourceAlbum = 0,
    AWEVideoSourceCapture = 1,
    AWEVideoSourceRemoteResource = 2,
};

typedef NS_ENUM(NSInteger,AWEShoutoutsContextStep) {
    AWEShoutoutsContextStepPost = 0,
    AWEShoutoutsContextStepIntro = 1,
    AWEShoutoutsContextStepEdit = 2,
    AWEShoutoutsContextStepSend = 3,
};

typedef NS_ENUM(NSInteger,AWEVideoType) {
    AWEVideoTypeUnknown = -1,
    AWEVideoTypeNormal = 0,         // Music Video
    AWEVideoTypeStory = 1,          // Story Video
    AWEVideoType360 = 2,            // Panoramic video
    AWEVideoTypeAR = 3,             // Ar video
    AWEVideoTypePicture = 5,        // Picture
    AWEVideoTypePhotoMovie = 6,     // Photo film
    AWEVideoType2DGame = 7,         // 2D game video
    AWEVideoTypeStoryPicture = 8,   // Story picture (static sticker)
    AWEVideoTypeStoryPicVideo = 9,  // Story picture (dynamic sticker)
    AWEVideoTypeMV = 10,            // MV theme template
    AWEVideoTypeStatus = 11,        // Status create video
    AWEVideoTypeLivePlayback = 12,     // Live playback
    AWEVideoTypeLiveHignLight = 13,    // Live highlights
    AWEVideoTypeLiveScreenShot = 14,   // Live recording screen
    AWEVideoTypeStitch = 15,        // stitch
    AWEVideoTypeGreenScreen = 16,   // Greenscreen video
    AWEVideoTypePhotoToVideo = 17, // photo to video using mv templates
    AWEVideoTypeMoments = 18,       // moments
    AWEVideoTypeReplaceMusicVideo = 19, // illegal video to replace music
    AWEVideoTypeLiveBackRecord = 20,   // live back recording screen
    AWEVideoTypeQuickStoryPicture = 21,// Quick Story picture, logic basically with Story pictures, but don't take the old Storyvc, take the main shooter process 
    AWEVideoTypeOneClickFilming = 22,  // One-button 
    AWEVideoTypeSmartMV = 23, // One-click MV 
    AWEVideoTypeImageAlbum = 25, // Atlas publishing mode, actually this is no longer video editing, defined or according to this definition
    AWEVideoTypeMediumVideoReward = 26, // Xigua medium-length video promotin plan
    AWEVideoTypeKaraoke = 27, // Karaoke
    AWEVideoTypeLivePhoto = 28,
    AWEVideoTypeLiteTheme = 29, // aweme lite, theme mode
    AWEVideoTypeStoryTT = 40, // TT story, include video and image
    AWEVideoTypeNewYearWish = 41
};

typedef NS_ENUM(NSInteger,AWEVideoRecordType) {
    AWEVideoRecordTypeUnknown = -1,
    AWEVideoRecordTypeNormal = 0,           // Normal video
    AWEVideoRecordTypeBoomerang = 1,        // Ghost animal video
};

typedef NS_ENUM(NSInteger, AWEPublishFlowStep) {
    AWEPublishFlowStepInvalid = -1,     // Invalid
    AWEPublishFlowStepUnknown = 0,
    AWEPublishFlowStepCapture = 10,
    AWEPublishFlowStepEdit = 20,
    AWEPublishFlowStepAdvancedEdit = 25,
    AWEPublishFlowStepPublish = 30,
};

typedef NS_ENUM(NSInteger, AWECameraType) {
    AWECameraTypeOld = 0, // Consistent with the default values of the old draft
    AWECameraTypeLocal = 1,
    AWECameraTypeAuto = 3,
};

typedef enum : NSUInteger {
    AWEAssetModelMediaTypeUnknow,
    AWEAssetModelMediaTypePhoto,
    AWEAssetModelMediaTypeVideo,
    AWEAssetModelMediaTypeAudio,
} AWEAssetModelMediaType;

typedef enum : NSUInteger {
    AWEAssetModelMediaSubTypeUnknow = 0,
    // Video
    AWEAssetModelMediaSubTypeVideoHighFrameRate = 1,
    // Picture
    AWEAssetModelMediaSubTypePhotoGif,
    AWEAssetModelMediaSubTypePhotoLive,
} AWEAssetModelMediaSubType;

typedef NS_ENUM(NSInteger, AWEVideoRecordButtonType);

typedef NS_ENUM(NSUInteger, AWEVideoCoShootingType) {
    AWEVideoCoShootingTypeNone,             // Out of step type
    AWEVideoCoShootingTypeDuet,             // Duet
    AWEVideoCoShootingTypeReact,            // React
};

typedef NS_ENUM(NSInteger, ACCRecordLengthMode) {
    ACCRecordLengthModeUnknown = 0,
    ACCRecordLengthModeStandard,
    ACCRecordLengthModeLong,
    ACCRecordLengthMode60Seconds,
    ACCRecordLengthMode3Minutes,
};

typedef NS_ENUM(NSInteger, AWERecordSourceFrom) {
    AWERecordSourceFromUnknown = 0,
    AWERecordSourceFromIM,
    AWERecordSourceFromIMGreet,
};

typedef NS_ENUM(NSInteger, AWEVideoPublishSourceType) {
    AWEVideoPublishSourceTypeFaceU,
};

typedef NS_ENUM(NSInteger, AWEStatusBackgroundImageType) {
    AWEStatusBackgroundImageTypeTemplate = 0,  // The template has its own background
    AWEStatusBackgroundImageTypeBgTemplate = 1, // Background template
    AWEStatusBackgroundImageTypeWallpaper = 2,  // Background template wallpaper
    AWEStatusBackgroundImageTypePhoto = 3,      // Photo album pictures
};

typedef NS_ENUM(NSUInteger, AWEAIVideoClipSourceType) {
    AWEAIVideoClipSourceUndefined,
    AWEAIVideoClipSourceVideos,
    AWEAIVideoClipSourceVideoAndPhoto,
    AWEAIVideoClipSourcePhotos,
};


#endif /* AWEPublishViewModelDefine_h */
