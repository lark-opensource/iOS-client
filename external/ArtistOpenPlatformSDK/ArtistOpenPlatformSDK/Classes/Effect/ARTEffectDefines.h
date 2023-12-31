//
//  ARTEffectDefines.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/21.
//

#ifndef ARTEffectDefines_h
#define ARTEffectDefines_h

typedef NS_ENUM(NSUInteger, ARTEffectErrorType) {
    ARTEffectErrorUnknowError = 0, //未知错误
    ARTEffectErrorNotFound = 2004, //找不到
};

// Download progress callback block definition.
typedef void(^art_effect_download_progress_block_t)(CGFloat progress);

// Download completion callback block definition.
typedef void(^art_effect_download_completion_block_t)(BOOL success, NSError * _Nullable error);


FOUNDATION_EXTERN NSString * _Nonnull const ArtistOpenPlatformSDKEffectErrorDomain;

#endif /* ARTEffectDefines_h */
