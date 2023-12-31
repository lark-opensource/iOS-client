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

#import "BDAnimatedImagePlayer.h"
#import "BDImage.h"
#import "BDImageDecoder.h"
#import "BDImageDecoderConfig.h"
#import "BDImageDecoderFactory.h"
#import "BDImageDecoderImageIO.h"
#import "BDImageDecoderWebP.h"
#import "BDImageView.h"

FOUNDATION_EXPORT double BDWebImageVersionNumber;
FOUNDATION_EXPORT const unsigned char BDWebImageVersionString[];