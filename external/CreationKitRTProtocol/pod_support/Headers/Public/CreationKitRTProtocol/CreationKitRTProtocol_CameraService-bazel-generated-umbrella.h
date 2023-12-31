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

#import "ACCAlgorithmEvent.h"
#import "ACCAlgorithmProtocol.h"
#import "ACCBeautyProtocol.h"
#import "ACCCameraControlEvent.h"
#import "ACCCameraControlProtocol.h"
#import "ACCCameraDefine.h"
#import "ACCCameraLifeCircleEvent.h"
#import "ACCCameraService.h"
#import "ACCCameraSubscription.h"
#import "ACCCameraWrapper.h"
#import "ACCEffectEvent.h"
#import "ACCEffectProtocol.h"
#import "ACCFilterProtocol.h"
#import "ACCKaraokeProtocol.h"
#import "ACCMessageProtocol.h"
#import "ACCRecorderProtocol.h"
#import "AWEComposerEffectProtocol.h"

FOUNDATION_EXPORT double CreationKitRTProtocolVersionNumber;
FOUNDATION_EXPORT const unsigned char CreationKitRTProtocolVersionString[];