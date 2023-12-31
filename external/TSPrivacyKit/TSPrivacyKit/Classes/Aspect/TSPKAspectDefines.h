//
//  TSPKAspectDefines.h
//  iOS15PhotoDemo
//
//  Created by bytedance on 2021/11/2.
//

#ifndef TSPKAspectDefines_h
#define TSPKAspectDefines_h

#if __OBJC__
#import <Foundation/Foundation.h>
#endif

/**
 * Make global functions usable in C++
 */
#if defined(__cplusplus)
#define PNS_EXTERN extern "C" __attribute__((visibility("default")))
#define PNS_EXTERN_C_BEGIN extern "C" {
#define PNS_EXTERN_C_END }
#else
#define PNS_EXTERN extern __attribute__((visibility("default")))
#define PNS_EXTERN_C_BEGIN
#define PNS_EXTERN_C_END
#endif

#endif /* TSPKAspectDefines_h */
