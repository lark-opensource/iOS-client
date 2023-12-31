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

#import "Gaia/Math/AMGColor.h"
#import "Gaia/Math/AMGColorSpaceConversion.h"
#import "Gaia/Math/AMGCurve.h"
#import "Gaia/Math/AMGDynamicBitset.h"
#import "Gaia/Math/AMGFloatConversion.h"
#import "Gaia/Math/AMGHashFunction.h"
#import "Gaia/Math/AMGMatrix3x3.h"
#import "Gaia/Math/AMGMatrix4x4.h"
#import "Gaia/Math/AMGPerlinNoise.h"
#import "Gaia/Math/AMGPolynomials.h"
#import "Gaia/Math/AMGQuaternion.h"
#import "Gaia/Math/AMGRect.h"
#import "Gaia/Math/AMGSphericalHarmonics.h"
#import "Gaia/Math/AMGVector2.h"
#import "Gaia/Math/AMGVector2i.h"
#import "Gaia/Math/AMGVector3.h"
#import "Gaia/Math/AMGVector3i.h"
#import "Gaia/Math/AMGVector4.h"
#import "Gaia/Math/Random/AMGRandom.h"
#import "Gaia/Math/Random/amg_rand.h"

FOUNDATION_EXPORT double gaia_lib_publishVersionNumber;
FOUNDATION_EXPORT const unsigned char gaia_lib_publishVersionString[];