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

#import "AvgFilterTracker.h"
#import "Blob.h"
#import "Blob.hpp"
#import "ImageTransform.h"
#import "ImageTransformNewAlign.h"
#import "ResParser.h"
#import "RfcnDetector.h"
#import "autovector.h"
#import "common_typedefs.h"
#import "gan_utils.hpp"
#import "mean_face.h"
#import "mm_detector.h"
#import "mm_multi_scale_proposal_layer.h"
#import "net_decode.h"
#import "openssl_aes.h"
#import "predictor.h"
#import "predictor_base.h"
#import "res_manager.h"
#import "seg_expval.h"
#import "seg_geometry.h"
#import "ssd_base.h"
#import "ssd_detector.h"
#import "ssd_detector_pytorch.h"
#import "ssd_multi_scale_proposal_layer.h"
#import "ssd_multi_scale_proposal_layer_pytorch.h"

FOUNDATION_EXPORT double smashVersionNumber;
FOUNDATION_EXPORT const unsigned char smashVersionString[];