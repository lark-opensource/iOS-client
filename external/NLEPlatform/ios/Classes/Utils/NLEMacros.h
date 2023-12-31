//
//  NLEMacros.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/5.
//

#ifndef NLEMacros_h
#define NLEMacros_h


#import <Foundation/Foundation.h>

typedef void(^NLEBaseBlock)(void);
#define NLEBaseBlockInvoke(block) if (block) block();

#define NLEBLOCK_INVOKE(block, ...) if (block) block(__VA_ARGS__);

//float
#define NLE_FLOAT_ZERO                      0.00001f
#define NLE_FLOAT_EQUAL_ZERO(a)             (fabs(a) <= NLE_FLOAT_ZERO)
#define NLE_FLOAT_GREATER_THAN(a, b)        ((a) - (b) >= NLE_FLOAT_ZERO)
#define NLE_FLOAT_EQUAL_TO(a, b)            NLE_FLOAT_EQUAL_ZERO((a) - (b))
#define NLE_FLOAT_LESS_THAN(a, b)           ((a) - (b) <= -NLE_FLOAT_ZERO)


#ifndef nle_keywordify
#if DEBUG
#define nle_keywordify autoreleasepool {}
#else
#define nle_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) nle_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) nle_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) nle_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) nle_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif


#if __has_include(<TTVideoEditor/IESMMBingoManager.h>)
    #define NLE_USE_NEW_VE 1
#else
    #define NLE_USE_NEW_VE 0
#endif


#endif /* NLEMacros_h */
