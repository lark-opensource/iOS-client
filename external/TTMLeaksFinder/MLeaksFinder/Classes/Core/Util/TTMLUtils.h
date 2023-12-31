//
//  TTMLUtils.h
//  TTMLeaksFinder-Pods-Aweme
//
//  Created by maruipu on 2020/11/11.
//

#ifndef TTMLUtils_h
#define TTMLUtils_h

#import <Foundation/Foundation.h>
#import "TTMLCommon.h"

NS_ASSUME_NONNULL_BEGIN

TTML_EXTERN_C_BEGIN

extern Class _Nullable object_getClass(id _Nullable obj);

extern NSString *TTMLMD5String(NSString *);

BOOL ttml_checkIsSystemClass(Class clazz);

static inline BOOL ttml_checkObjectIsSystemClass(id object) {
    return ttml_checkIsSystemClass(object_getClass(object));
}

extern uint64_t TTMLCurrentMachTime(void);
extern double TTMLMachTimeToSecs(uint64_t time);

TTML_EXTERN_C_END

@interface TTMLUtil : NSObject

+ (BOOL)objectIsSystemClass:(id)object;
+ (BOOL)isSystemClass:(Class)clazz;

+ (void)tt_swizzleClass:(Class)cls SEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL;

@end

NS_ASSUME_NONNULL_END

#endif /* TTMLUtils_h */
