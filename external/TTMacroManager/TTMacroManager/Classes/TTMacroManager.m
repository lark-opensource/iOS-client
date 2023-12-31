//
//  TTMacroManager.m
//  TTMacroManager
//
//  Created by Bob on 2018/11/21.
//

#import "TTMacroManager.h"

@implementation TTMacroManager
+ (BOOL)isDebug {
#if DEBUG
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isRelease {
#if Release
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isInHouse {
#if INHOUSE == 1
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isAddressSanitizer {
#if __has_feature(address_sanitizer)
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)isThreadSanitizer {
#if __has_feature(thread_sanitizer)
    return YES;
#else
    return NO;
#endif
}

@end
