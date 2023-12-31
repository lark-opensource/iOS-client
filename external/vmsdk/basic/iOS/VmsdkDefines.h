// Copyright 2019 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_CONCAT
#define VMSDK_CONCAT2(A, B) A##B
#define VMSDK_CONCAT(A, B) VMSDK_CONCAT2(A, B)
#endif

#if defined(__cplusplus)
#define VMSDK_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define VMSDK_EXTERN extern __attribute__((visibility("default")))
#endif

/**
 * This attribute is used for static analysis.
 */
#if !defined VMSDK_DYNAMIC
#if __has_attribute(objc_dynamic)
#define VMSDK_DYNAMIC __attribute__((objc_dynamic))
#else
#define VMSDK_DYNAMIC
#endif
#endif

#ifndef VMSDK_NOT_IMPLEMENTED
#define VMSDK_NOT_IMPLEMENTED(method)                                                          \
  method NS_UNAVAILABLE {                                                                      \
    NSString *msg = [NSString                                                                  \
        stringWithFormat:@"%s is not implemented in class %@", sel_getName(_cmd), self.class]; \
    @throw [NSException exceptionWithName:@"LxNotDesignatedInitializerException"               \
                                   reason:msg                                                  \
                                 userInfo:nil];                                                \
  }
#endif

#ifndef VmsdkMainThreadChecker
#define VmsdkMainThreadChecker()                              \
  NSAssert([NSThread currentThread] == [NSThread mainThread], \
           @"This method should be called on the main thread.")
#endif
