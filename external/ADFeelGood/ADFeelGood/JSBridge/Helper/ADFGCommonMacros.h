//
//  ADFeelGoodCommonDefine.h
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/26.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADFGBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const _Nonnull ADFGSDKVersion;

/***** VALID CHECK *****/
#define ADFGCheckValidString(__string)               (__string && [__string isKindOfClass:[NSString class]] && [__string length])
#define ADFGCheckValidNumber(__aNumber)              (__aNumber && [__aNumber isKindOfClass:[NSNumber class]])
#define ADFGCheckValidArray(__aArray)                (__aArray && [__aArray isKindOfClass:[NSArray class]] && [__aArray count])
#define ADFGCheckValidDictionary(__aDictionary)      (__aDictionary && [__aDictionary isKindOfClass:[NSDictionary class]] && [__aDictionary count])

/***** 强弱引用转换*****/
#ifndef adfg_weakify
#if __has_feature(objc_arc)
#define adfg_weakify(object) __weak __typeof__(object) weak##object = object;
#else
#define adfg_weakify(object) __block __typeof__(object) block##object = object;
#endif
#endif
#ifndef adfg_strongify
#if __has_feature(objc_arc)
#define adfg_strongify(object) __typeof__(object) object = weak##object;
#else
#define adfg_strongify(object) __typeof__(object) object = block##object;
#endif
#endif


@interface ADFGCommonMacros : NSObject

@end

NS_ASSUME_NONNULL_END
