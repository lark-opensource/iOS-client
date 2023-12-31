//  HMDOOMLockingDetector.h
//
//  some like that
//


#ifndef HMDOOMLockingDetector_h
#define HMDOOMLockingDetector_h

#include <stdbool.h>
#include "HMDMacro.h"

HMD_EXTERN bool HMDOOMLockingDetector_isOOMLocking(void);

HMD_TYPEDEF_EXTERN typedef bool (*HMDOOMLockingDetector_OOMLockingFunction_t)(void);

HMD_EXTERN void HMDOOMLockingDetector_registerOOMLockingFunction(HMDOOMLockingDetector_OOMLockingFunction_t _Nonnull function);

#endif /* HMDOOMLockingDetector_h */

