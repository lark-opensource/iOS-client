//
//  ACCSmartMovieDefines.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/19.
//

#ifndef ACCSmartMovieDefines_h
#define ACCSmartMovieDefines_h

// music request params
#define ACCSmartMovieRequestMusicCount 20

// 决定图片压缩质量的数量临界点（PM要求）
static NSInteger const ACCSmartMovieCriticalAmount = 30;

// 在一次创作流程中是否已经展示相册页引导气泡
static NSString *const ACCSmartMovieAlbumGuideBubbleHasShownKey = @"ACCSmartMovieAlbumGuideBubbleHasShownKey";

// 编辑页云端处理提示框Key
static NSString *const ACCSmartMovieUploadRemindToastHasShownKey = @"ACCSmartMovieUploadRemindToastHasShownKey";

// 用户手动取消加载框的消息
static NSString *const ACCSmartMovieExportCancelByUserKey = @"ACCSmartMovieExportCancelByUserKey";

typedef NS_ENUM(NSUInteger, ACCSmartMovieError) {
    ACCSmartMovieErrorUnknown = 0,
    ACCSmartMovieErrorDownloadPhotoError,
    ACCSmartMovieErrorSavePhotoError,
    ACCSmartMovieErrorUploadMaterialFail,
    ACCSmartMovieErrorNLEModelDownloadFail,
    ACCSmartMovieErrorProcessVideoFail,
};

typedef NS_ENUM(NSInteger, ACCSmartMovieBarItemState) {
    ACCSmartMovieBarItemStateNone = 0,
    ACCSmartMovieBarItemStateOn,
    ACCSmartMovieBarItemStateOff,
    ACCSmartMovieBarItemStateReverse
};

typedef NS_ENUM(NSInteger, ACCSmartMovieSceneMode) {
    ACCSmartMovieSceneModeNone = 0,
    ACCSmartMovieSceneModeMVVideo,
    ACCSmartMovieSceneModeSmartMovie,
    ACCSmartMovieSceneModeImageAlbum
};

#define SM_LOG(fmt, ...) AWEMacroLogToolInfo2(@"smartmovie", (AWELogToolTag)(1 << 22), fmt, ##__VA_ARGS__);
#define SM_ERR(fmt, ...) AWEMacroLogToolError2(@"smartmovie", (AWELogToolTag)(1 << 22), fmt, ##__VA_ARGS__);

inline static NSError *acc_customExportSmartMovieError()
{
    NSError *error = [NSError errorWithDomain:@"com.bytedance.exportSmartMovieError" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"网络不给力，请稍后重试"}];
    return error;
}

#endif /* ACCSmartMovieDefines_h */
