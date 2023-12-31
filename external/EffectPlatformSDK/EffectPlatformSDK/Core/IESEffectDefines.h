//
//  IESEffectDefines.h
//  Pods
//
//  Created by Keliang Li on 2017/10/29.
//

#import <Foundation/Foundation.h>

#ifndef IESEffectDefines_h
#define IESEffectDefines_h

//weakify
#ifndef eff_keywordify
#if DEBUG
    #define eff_keywordify autoreleasepool {}
#else
    #define eff_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) eff_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) eff_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) eff_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) eff_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

typedef NS_ENUM(NSUInteger, IESEffectModelType) {
    IESEffectModelTypeProps = 0,
    IESEffectModelTypeFilter
};

// 特效类型
typedef NS_ENUM(NSInteger, IESEffectModelEffectType) {
    // 普通特效
    IESEffectModelEffectTypeNormal = 0,
    // 聚合特效
    IESEffectModelEffectTypeCollection,
    
    //schema
    IESEffectModelEffectTypeSchema,
};

// 特效测试状态
typedef NS_ENUM(NSInteger, IESEffectModelTestStatusType) {
    // 默认类型
    IESEffectModelTestStatusTypeDefault = 0,
    // 设计师自测
    IESEffectModelTestStatusTypeDesignerTest,
    // 待测试
    IESEffectModelTestStatusTypePendingTest,
    // 测试中
    IESEffectModelTestStatusTypeInTest,
    // 测试不通过
    IESEffectModelTestStatusTypeFailedTest,
    // 测试通过
    IESEffectModelTestStatusTypePassedTest
};

typedef NS_ENUM(NSUInteger, IESEffectModelEffectSource) {
    IESEffectModelEffectSourceInner,//内部上传
    IESEffectModelEffectSourceOriginal,//用户原创
};

typedef NS_ENUM(NSInteger, IESInfoStickerModelSource) {
    IESInfoStickerModelSourceLoki       = 1,
    IESInfoStickerModelSourceThirdParty = 2,
};

typedef NS_ENUM(NSUInteger, IESEffectErrorType) {
    IESEffectErrorUnknowError = 1, //未知错误
    IESEffectErrorNotLoggedIn = 8, //用户未登陆
    IESEffectErrorParametorError = 1000, //参数不合法（参数缺失或者错误）
    IESEffectErrorIllegalAccessKey = 1001, //access_key 不合法
    IESEffectErrorIllegalAppVersion = 1002, //app_version 不合法
    IESEffectErrorIllegalSDKVersion = 1003, //sdk_version 不合法
    IESEffectErrorIllegalDeviceId = 1004, //device_id 不合法
    IESEffectErrorIllegalDevicePlatform = 1005, //device_platform 不合法
    IESEffectErrorIllegalDeviceType = 1006, //device_type 不合法
    IESEffectErrorIllegalChannel = 1007, //channel 不合法
    IESEffectErrorIllegalAppChannel = 1008, //app_channel 不合法
    IESEffectErrorIllegalPanel = 1009, //panel不合法
    IESEffectErrorCurrentAppIsNotTestApp = 1100, //当前应用不是测试应用
    IESEffectErrorIllegalApp = 1100, //当前应用不是测试应用
    IESEffectErrorAccessKeyNotExists = 1101, //access_key 不存在
    IESEffectErrorMD5NotMatched = 2002, //md5 校验失败
    IESEffectErrorUnzipFailed = 2003, //解压缩失败
    IESEffectErrorFilePathNotFound = 2004, //下载回调没有path，但是error为空
    IESEffectErrorDownloadFailed = 2005,//
    IESEffectErrorDecryptFailed = 3001,
    IESEffectErrorOnlineModelNotFound = 3002,
    IESEffectErrorModelsDownloadFailed = 3003,
    IESEffectErrorModelInfosFetchFailed = 3004,
};

typedef NS_ENUM(NSInteger, IESCacheCleanStatus) {
    IESCacheCleanStatusDefault,
    IESCacheCleanStatusStart,
    IESCacheCleanStatusCancel,
    IESCacheCleanStatusFinished
};

FOUNDATION_EXTERN NSString * const IESEffectPlatformSDKVersion; // 版本号

FOUNDATION_EXTERN NSString * const IESEffectType2DSticker;
FOUNDATION_EXTERN NSString * const IESEffectTypeARPhotoFace;
FOUNDATION_EXTERN NSString * const IESEffectType3DStikcer;
FOUNDATION_EXTERN NSString * const IESEffectTypeMatting;
FOUNDATION_EXTERN NSString * const IESEffectTypeFaceDistortion;
FOUNDATION_EXTERN NSString * const IESEffectTypeFaceMakeup;
FOUNDATION_EXTERN NSString * const IESEffectTypeHairColor;
FOUNDATION_EXTERN NSString * const IESEffectTypeFilter;
FOUNDATION_EXTERN NSString * const IESEffectTypeFaceReshape;
FOUNDATION_EXTERN NSString * const IESEffectTypeBeauty;
FOUNDATION_EXTERN NSString * const IESEffectTypeBodyDance;
FOUNDATION_EXTERN NSString * const IESEffectTypeFacePick;
FOUNDATION_EXTERN NSString * const IESEffectTypeParticleJoint;
FOUNDATION_EXTERN NSString * const IESEffectTypeParticle;
FOUNDATION_EXTERN NSString * const IESEffectTypeAR;
FOUNDATION_EXTERN NSString * const IESEffectTypeCat;
FOUNDATION_EXTERN NSString * const IESEffectTypeGame2D;
FOUNDATION_EXTERN NSString * const IESEffectTypeARKit; // 相机模式为：IESMMCameraTypeAR
FOUNDATION_EXTERN NSString * const IESEffectTypeTouchGes; // 需要手势事件传递
FOUNDATION_EXTERN NSString * const IESEffectTypeFaceARKit; // 需要ARKit前置人脸
FOUNDATION_EXTERN NSString * const IESEffectTypeMakeup;
FOUNDATION_EXPORT NSString * const IESEffectTypeStabilizationOff; // 关闭摄像头防抖

FOUNDATION_EXTERN NSString * const IES_FOLDER_PATH;
FOUNDATION_EXTERN NSString * const IES_EFFECT_FOLDER_PATH;
FOUNDATION_EXTERN NSString * const IES_THIRDPARTY_FOLDER_PATH;
FOUNDATION_EXTERN NSString * const IES_EFFECT_UNCOMPRESS_FOLDER_PATH;
FOUNDATION_EXPORT NSString * const IES_EFFECT_ALGORITHM_FOLDER_PATH;
FOUNDATION_EXTERN NSString * const IES_COMPOSER_EFFECT_FOLDER_PATH;
FOUNDATION_EXTERN NSString * const IESEffectNetworkResponse;
FOUNDATION_EXTERN NSString * const IESEffectNetworkResponseStatus;
FOUNDATION_EXTERN NSString * const IESEffectNetworkResponseHeaderFields;
FOUNDATION_EXTERN NSString * const IESEffectErrorExtraInfoKey;

FOUNDATION_EXTERN NSString * const IESEffectPlatformSDKErrorDomain;
FOUNDATION_EXTERN NSString * const IESEffectPlatformSDKAlgorithmModelErrorDomain;
FOUNDATION_EXTERN NSString * IESEffectBookMarkPath(void);
FOUNDATION_EXTERN NSString * IESEffectListPathWithAccessKey(NSString *accessKey);
FOUNDATION_EXTERN NSString * IESMyEffectListPathWithAccessKey(NSString *accessKey);
FOUNDATION_EXTERN NSString * IESEffectListJsonPathWithAccessKey(NSString *accessKey);
FOUNDATION_EXTERN NSString * IESEffectPathWithIdentifier(NSString *identifier);
FOUNDATION_EXTERN NSString * IESThirdPartyModelPathWithIdentifier(NSString *identifier);
FOUNDATION_EXTERN NSString * IESEffectUncompressPathWithIdentifier(NSString *identifier);
FOUNDATION_EXTERN NSString * IESEffectSpeedTestPath(void);
FOUNDATION_EXTERN NSString * IESComposerResourceDir(void);
FOUNDATION_EXTERN NSString * IESComposerResourceZipDirWithMD5(NSString *md5);
FOUNDATION_EXTERN NSString * IESComposerResourceUncompressDirWithMD5(NSString *md5);
FOUNDATION_EXTERN NSDictionary * IESRequestLocationParametersProcessIfNeed(NSMutableDictionary *parameters);

static NSString * const kTrackingName = @"kTrackingName";

static inline NSError * EffectPlatformEmptyFilePathError() {
   return [NSError errorWithDomain:IESEffectPlatformSDKErrorDomain code:IESEffectErrorFilePathNotFound userInfo:@{NSLocalizedDescriptionKey : @"file path is empty"}];
}

#endif /* IESEffectDefines_h */

