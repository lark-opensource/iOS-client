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

#import "ACCBeautyComponentConfigProtocol.h"
#import "ACCBeautyConfigKeyDefines.h"
#import "ACCBeautyDataHandler.h"
#import "ACCBeautyFeatureComponent+BeautyDelegate.h"
#import "ACCBeautyFeatureComponent+Private.h"
#import "ACCBeautyFeatureComponent.h"
#import "ACCBeautyFeatureComponentView.h"
#import "ACCBeautyManager.h"
#import "ACCBeautyPanel.h"
#import "ACCBeautyPanelViewModel.h"
#import "ACCBeautyTrackSenderProtocol.h"
#import "ACCBeautyTrackerSender.h"
#import "AWEComposerBeautyViewController+ACCPanelViewProtocol.h"

FOUNDATION_EXPORT double CreationKitComponentsVersionNumber;
FOUNDATION_EXPORT const unsigned char CreationKitComponentsVersionString[];