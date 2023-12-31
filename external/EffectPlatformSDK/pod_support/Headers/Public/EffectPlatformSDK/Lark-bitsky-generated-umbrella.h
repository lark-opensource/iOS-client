#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "EffectPlatform+Additions.h"
#import "EffectPlatform+InfoSticker.h"
#import "EffectPlatform+Inspire.h"
#import "EffectPlatform+PreLoad.h"
#import "EffectPlatform+Search.h"
#import "EffectPlatform.h"
#import "EffectPlatformBookMark.h"
#import "EffectPlatformCache.h"
#import "EffectPlatformJsonCache.h"
#import "IESCategoryEffectsModel.h"
#import "IESCategoryModel.h"
#import "IESCategorySampleEffectModel.h"
#import "IESCategoryVideoEffectsModel.h"
#import "IESDelegateFileDownloadTask.h"
#import "IESEffectAlgorithmModel.h"
#import "IESEffectConfig.h"
#import "IESEffectDefines.h"
#import "IESEffectListManager.h"
#import "IESEffectLogger.h"
#import "IESEffectManager.h"
#import "IESEffectModel.h"
#import "IESEffectPlatformNewResponseModel.h"
#import "IESEffectPlatformPostSerializer.h"
#import "IESEffectPlatformRequestManager.h"
#import "IESEffectPlatformResponseModel.h"
#import "IESEffectResourceModel.h"
#import "IESEffectResourceResponseModel.h"
#import "IESEffectSampleVideoModel.h"
#import "IESEffectTopListResponseModel.h"
#import "IESEffectURLModel.h"
#import "IESFileDownloadTask.h"
#import "IESFileDownloader.h"
#import "IESInfoStickerCategoryModel.h"
#import "IESInfoStickerListResponseModel.h"
#import "IESInfoStickerModel.h"
#import "IESInfoStickerResponseModel.h"
#import "IESMyEffectModel.h"
#import "IESPlatformPanelModel.h"
#import "IESSearchEffectsModel.h"
#import "IESSimpleVideoModel.h"
#import "IESThirdPartyResponseModel.h"
#import "IESThirdPartyStickerInfoModel.h"
#import "IESThirdPartyStickerModel.h"
#import "IESUserUsedStickerResponseModel.h"
#import "IESVideoEffectWrapperModel.h"
#import "NSArray+EffectPlatformUtils.h"
#import "NSData+Crypto.h"
#import "NSDictionary+EffectPlatfromUtils.h"
#import "NSString+Crypto.h"
#import "NSString+EffectPlatformUtils.h"
#import "EffectPlatform+AlgorithmModel.h"

FOUNDATION_EXPORT double EffectPlatformSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char EffectPlatformSDKVersionString[];
