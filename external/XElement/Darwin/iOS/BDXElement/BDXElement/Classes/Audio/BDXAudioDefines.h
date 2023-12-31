//
//  BDXAudioDefines.h
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXAudioPlayState) {
    BDXAudioPlayStatePlay = 0,
    BDXAudioPlayStateStop = 1,
    BDXAudioPlayStatePause = 2,
};

typedef NS_ENUM(NSUInteger, BDXAudioPlayerType) {
    BDXAudioPlayerTypeDefault,
    BDXAudioPlayerTypeLight,
    BDXAudioPlayerTypeShort
};

typedef NS_ENUM(NSInteger, BDXAudioErrorCode) {
    BDXAudioErrorCodePlayError = -1,
    BDXAudioErrorCodeDownloadError = -2,
    BDXAudioErrorCodeShortCreateError = -3,
    BDXAudioErrorCodePlayWithoutSrc = -4,
    BDXAudioErrorCodeJsonError = -5,
    BDXAudioErrorCodeOtherError = -999,
};

typedef NS_ENUM(NSUInteger, BDXAudioSrcLoadingState) {
  BDXAudioSrcLoadingStateInit = -1,
  BDXAudioSrcLoadingStateLoading = 0,
  BDXAudioSrcLoadingStateSuccess = 1,
  BDXAudioSrcLoadingStateFailed = 2,
};

typedef NS_ENUM(NSUInteger, BDXAudioAllErrorCode) {
  BDXAudioAllErrorCodeResLoaderSrcError = -1,
  BDXAudioAllErrorCodeResLoaderSrcJsonError = -2,
  BDXAudioAllErrorCodeResLoaderDownloadError = -3,
  BDXAudioAllErrorCodePlayerFinishedError = -4,
  BDXAudioAllErrorCodePlayerLoadingError = -5,
  BDXAudioAllErrorCodePlayerPlaybackError = -6,

};

typedef NSString * BDXAudioEvent;

FOUNDATION_EXPORT BDXAudioEvent const BDXAudioPlayEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioPauseEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioEndedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioErrorEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioErrorReportEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioStatusChangedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioTimeUpdateEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioCacheTimeUpdateEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioSeekEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioSourceChangedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioListChangedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioPreRemoteCommandEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioNextRemoteCommandEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioStopedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioFinishedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioReadyedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioPreparedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioPlaybackStateChangedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioLoadingStateChangedEvent;
FOUNDATION_EXPORT BDXAudioEvent const BDXAudioSrcLoadingStateChangedEvent;


NS_ASSUME_NONNULL_END
