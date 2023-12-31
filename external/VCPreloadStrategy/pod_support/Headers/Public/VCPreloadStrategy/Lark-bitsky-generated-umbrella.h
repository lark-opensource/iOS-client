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

#import "VCVodStrategyManager.h"
#import "vc_event_log_keys.h"
#import "vc_event_log_manager.h"
#import "vc_feature.h"
#import "vc_feature_define.h"
#import "vc_feature_produce.h"
#import "vc_feature_supplier.h"
#import "vc_feature_supplier_interface.h"
#import "vc_iportrait_supplier.h"
#import "vc_play_feature.h"
#import "vc_portrait_supplier.h"
#import "vc_vod_server_feature.h"

FOUNDATION_EXPORT double VCPreloadStrategyVersionNumber;
FOUNDATION_EXPORT const unsigned char VCPreloadStrategyVersionString[];
