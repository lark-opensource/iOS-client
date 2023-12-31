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

#import "AVAsset+DVE.h"
#import "CGRectUtil.h"
#import "CMTime+DVE.h"
#import "DVEButton.h"
#import "DVEColorMacro.h"
#import "DVECommonDefine.h"
#import "DVEConfig.h"
#import "DVECustomResourceProvider.h"
#import "DVEFileUtils.h"
#import "DVEFontMacro.h"
#import "DVEGCDUtils.h"
#import "DVEImageMacro.h"
#import "DVEMacros.h"
#import "DVEPadUIAdapter.h"
#import "DVEPlaceholderTextView.h"
#import "DVEResourceManagerProtocol.h"
#import "DVEScreenAdaptUtils.h"
#import "DVEStringMacro.h"
#import "DVETargetIndex.h"
#import "DVEUIHelper.h"
#import "DVEUILayoutConfig.h"
#import "NLEModel_OC+DVE.h"
#import "NLENode_OC+DVE.h"
#import "NLEResourceAV_OC+DVE.h"
#import "NLEResourceNode_OC+DVE.h"
#import "NLESegmentAudio_OC+DVE.h"
#import "NLESegmentTransition_OC+DVE.h"
#import "NLESegment_OC+DVE.h"
#import "NLETimeSpaceNode_OC+DVE.h"
#import "NLETrackSlot_OC+DVE.h"
#import "NLETrack_OC+DVE.h"
#import "NLEVideoAnimation_OC+DVE.h"
#import "NLEVideoFrameModel_OC+DVE.h"
#import "NSArray+DVE.h"
#import "NSBundleUtil.h"
#import "NSData+DVE.h"
#import "NSDictionary+DVE.h"
#import "NSString+DVE.h"
#import "UIBezierPath+DVE.h"
#import "UIColor+DVE.h"
#import "UIFont+DVE.h"
#import "UIImage+DVE.h"
#import "UIView+DVE.h"
#import "UIViewController+Private.h"

FOUNDATION_EXPORT double DVEFoundationKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DVEFoundationKitVersionString[];