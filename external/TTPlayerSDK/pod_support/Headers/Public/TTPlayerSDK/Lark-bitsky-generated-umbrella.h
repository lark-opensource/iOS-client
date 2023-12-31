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

#import "ByteCrypto.h"
#import "MediaDecrypter.h"
#import "TTAVPlayer.h"
#import "TTAVPlayerItem.h"
#import "TTAVPlayerItemProtocol.h"
#import "TTAVPlayerKit.h"
#import "TTAVPlayerLoadControlInterface.h"
#import "TTAVPlayerMaskInfoInterface.h"
#import "TTAVPlayerOpenGLActivity.h"
#import "TTAVPlayerProtocol.h"
#import "TTAVPlayerSubInfoInterface.h"
#import "TTPlayerDef.h"
#import "TTPlayerView.h"
#import "TTPlayerViewProtocol.h"
#import "av_base.h"
#import "av_config.h"
#import "av_error.h"
#import "av_namespace.h"
#import "ttvideodec.h"
#import "ttvideoenc.h"

FOUNDATION_EXPORT double TTPlayerSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char TTPlayerSDKVersionString[];
