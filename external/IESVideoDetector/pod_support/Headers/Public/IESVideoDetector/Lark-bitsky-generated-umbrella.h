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

#import "IESAVAsset.h"
#import "IESAVAssetAsynchronousLoader.h"
#import "IESAVAssetDefaultFormatter.h"
#import "IESAssetFormatterFunctions.h"
#import "IESCompositionInfoModel.h"
#import "IESMacros.h"
#import "IESUtils.h"
#import "IESVdetectAlogProtocol.h"
#import "IESVdetectMonitorProtocol.h"
#import "IESVdetectService.h"
#import "IESVideoDetectHelper.h"
#import "IESVideoDetectInputModel.h"
#import "IESVideoDetectInputModelProtocol.h"
#import "IESVideoDetectOutputModel.h"
#import "IESVideoDetector.h"
#import "IESVideoInfo.h"
#import "IESVideoInfoDefaultFormatter.h"
#import "IESVideoInfoProvider.h"
#import "IESVideoInspector.h"
#import "MTLJSONAdapter+IESValueTransformers.h"
#import "NSDictionary+IESAdditions.h"

FOUNDATION_EXPORT double IESVideoDetectorVersionNumber;
FOUNDATION_EXPORT const unsigned char IESVideoDetectorVersionString[];
