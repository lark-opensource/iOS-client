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

#import "ACCEditAudioEffectProtocol.h"
#import "ACCEditBeautyProtocol.h"
#import "ACCEditCanvasProtocol.h"
#import "ACCEditCaptureFrameProtocol.h"
#import "ACCEditEffectProtocol.h"
#import "ACCEditFilterProtocol.h"
#import "ACCEditHDRProtocol.h"
#import "ACCEditImageAlbumMixedProtocol.h"
#import "ACCEditMultiTrackProtocol.h"
#import "ACCEditPreviewProtocol.h"
#import "ACCEditServiceProtocol.h"
#import "ACCEditSessionBuilderProtocol.h"
#import "ACCEditSessionLifeCircleEvent.h"
#import "ACCEditSessionWrapper.h"
#import "ACCEditStickerProtocol.h"
#import "ACCEditWrapper.h"
#import "ACCImageEditHDRProtocol.h"
#import "ACCMediaContainerViewProtocol.h"

FOUNDATION_EXPORT double CreationKitRTProtocolVersionNumber;
FOUNDATION_EXPORT const unsigned char CreationKitRTProtocolVersionString[];