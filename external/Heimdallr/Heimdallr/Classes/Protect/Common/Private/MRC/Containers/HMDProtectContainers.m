//
//  HMDProtectContainers.m
//  HMDProtectProtector
//
//  Created by fengyadong on 2018/4/8.
//

#import <stdatomic.h>
#import <objc/runtime.h>
#import "pthread_extended.h"
#import "HMDProtectContainers.h"
#import "HMDProtect_Private.h"
#import "HMDProtectCapture.h"
#import "HMDProtectContainerProtocol.h"
#import "HMDALogProtocol.h"
#import "HMDSwizzle.h"
#import "HMDCompactUnwind.hpp"
#import "HMDAppleBacktracesLog.h"

#ifdef DEBUG
#import "hmd_crash_safe_tool.h"
#endif

#define NSArray_RANGE_STR(arrayObject)                                      \
({                                                                          \
NSString *result;                                                       \
NSUInteger count = arrayObject.count;                                   \
if(count == 0) result = @"for empty array";                             \
else result =                                                           \
[NSString stringWithFormat:@"[0 .. %lu]", (unsigned long)(count - 1)];  \
result;                                                                 \
})

#define SWIZZLE_METHOD_STRUCT(sel,imp) {.originSelectorName = #sel, \
.newSelector = @selector(HMDP_##sel), \
.newIMP = (IMP)(IMP_##imp), \
}

#define STORE_INCREASE 30

struct class_cluster {
    Class aClass;
    unsigned int size;
    unsigned int count;
    Class *subClasses;
};

struct swizzle_method {
    char *originSelectorName;
    SEL newSelector;
    IMP newIMP;
};

enum HMDPFoundationType {
    HMDPFoundationTypeNSNumber = 0,
    HMDPFoundationTypeNSString = 1,
    HMDPFoundationTypeNSMutableString = 2,
    HMDPFoundationTypeNSAttributeString = 3,
    HMDPFoundationTypeNSMutableAttributeString = 4,
    HMDPFoundationTypeNSArray = 5,
    HMDPFoundationTypeNSMutableArray = 6,
    HMDPFoundationTypeNSDictionary = 7,
    HMDPFoundationTypeNSMutableDictionary = 8,
    HMDPFoundationTypeNSSet = 9,
    HMDPFoundationTypeNSMutableSet = 10,
    HMDPFoundationTypeNSOrderedSet = 11,
    HMDPFoundationTypeNSMutableOrderedSet = 12,
    HMDPFoundationTypeNSURL = 13,
    HMDPFoundationTypeCALayer = 14,
};

typedef struct class_cluster cluster_t;
typedef struct swizzle_method swizzle_method_t;

static NSString *NSIndexSet_toString(NSIndexSet *set);

NS_INLINE BOOL HMDMaxRangeInvalid(NSRange range, NSUInteger length);
NS_INLINE BOOL HMDStrictMaxRangeInvalid(NSRange range, NSUInteger length);

static NSMutableSet<NSString *>* crashKeySet = nil;                                 /** 用来安全气垫去除重复的功能 */
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;                      /** 用来保护访问 _internal_container_captureBlock 的锁  */
static HMDProtectCaptureBlock _Nullable _internal_container_captureBlock;           /** 向上 protector 回调崩溃信息 */
static void HMD_Protect_Container_captureException(HMDProtectCapture *capture);     /** 各个NSString NSArray 等模块发生崩溃时向这里传入数据 */


static void SwizzlePreperation(void);       /** 在 Swizzle 开始前做准备操作，目前功能暂时为了标记特别需要注意的Class 数据 */
static void BatchSwizzleForStatic(void);    /** 开启实际 Swizzle 的模块, 会依次遍历需要 Swizzle 的 Class 然后进行 Swizzle */
#ifdef DEBUG
static void BatchSwizzleForDynamic(void);   /** 被废弃的功能，但是留着 */
#endif
#if RANGERSAPM
HMDProtectionArrayCreateMode HMD_Protect_Container_arrayCreateMode = HMDProtectionArrayCreateModeDefault;
#endif

#pragma mark - NSNumber

static NSComparisonResult IMP_numberCompare(NSString<HMDP_NSNumber> *thisSelf, SEL selector, NSNumber* otherNumber) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(compare:))) == 0);
        if (!(otherNumber && [otherNumber isKindOfClass:[NSNumber class]])) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ compare:%@]: ", NSStringFromClass(object_getClass(thisSelf)), otherNumber];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return NSOrderedDescending;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_compare:otherNumber];
}

static BOOL IMP_isEqualToNumber(NSString<HMDP_NSNumber> *thisSelf, SEL selector, NSNumber* number) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(isEqualToNumber:))) == 0);
        if (!(number && [number isKindOfClass:[NSNumber class]])) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ isEqualToNumber:%@]: ", NSStringFromClass(object_getClass(thisSelf)), number];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return NO;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_isEqualToNumber:number];
}

#pragma mark - NSString

static unichar IMP_characterAtIndex(NSString<HMDP_NSString> *thisSelf, SEL selector, NSUInteger index) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(characterAtIndex:))) == 0);
        if (index >= thisSelf.length) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ characterAtIndex:%lu]: Range or index out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return 0;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_characterAtIndex:index];
}

static NSString * IMP_substringFromIndex(NSString<HMDP_NSString> *thisSelf, SEL selector, NSUInteger from) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(substringFromIndex:))) == 0);
        // 注: from == length不会崩溃
        if (from > thisSelf.length) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ substringFromIndex:%lu]: Index %lu out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)from, (unsigned long)from, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_substringFromIndex:from];
};

static NSString *IMP_substringToIndex(NSString<HMDP_NSString> *thisSelf, SEL selector, NSUInteger to) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(substringToIndex:))) == 0);
        if (to > thisSelf.length) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ substringToIndex:%lu]: Index %lu out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)to, (unsigned long)to, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_substringToIndex:to];
}

static Class NSBigMutableStringClass = nil; // 注意是 MRC 环境
static Class NSTaggedPointerStringClass = nil;
static Class __NSCFStringClass = nil;
static BOOL  iOS17AndNewer = NO;

static BOOL needStrictRangeForStringClass(Class _Nullable stringClass) {
    
    if(stringClass == NSBigMutableStringClass)
        return YES;
    
    if(stringClass == NSTaggedPointerStringClass)
        return YES;
    
    // starting from iOS 17.0, __NSCFString will require strict range check
    if(iOS17AndNewer && stringClass == __NSCFStringClass)
        return YES;
    
    return NO;
}

static id IMP_substringWithRange(NSString<HMDP_NSString> *thisSelf, SEL selector, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(substringWithRange:))) == 0);
        /** 对于常见的 location or length -1 不会引起崩溃 除非是 NSBigMutableString */
        NSUInteger thisStringLength = thisSelf.length;
        
        if(needStrictRangeForStringClass(object_getClass(thisSelf)) ?
                HMDStrictMaxRangeInvalid(range, thisStringLength) :
                HMDMaxRangeInvalid(range, thisStringLength)) {
            
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ substringWithRange]:range {%lu, %lu} out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)range.location, (unsigned long)range.length, (unsigned long)thisStringLength];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_substringWithRange:range];
}

static NSString * IMP_stringByReplacingCharactersInRange_withString(NSString<HMDP_NSString> *thisSelf,
                                                                    SEL selector,
                                                                    NSRange range,
                                                                    NSString *replacement) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(stringByReplacingCharactersInRange:withString:))) == 0);
        if(replacement == nil || ![replacement isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ stringByReplacingCharactersInRange:%@ withString:%@]: invalid argument", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], replacement];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
        
        if(HMDMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ stringByReplacingCharactersInRange:%@ withString:%@]: Range or index out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], replacement, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_stringByReplacingCharactersInRange:range withString:replacement];
};

static NSString *IMP_stringByAppendingString(NSString<HMDP_NSString> *thisSelf, SEL selector, NSString *aString) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(stringByAppendingString:))) == 0);
        if (aString == nil || ![aString isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ stringByAppendingString:%@]: invalid argument", NSStringFromClass(object_getClass(thisSelf)), aString];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_stringByAppendingString:aString];
}

#pragma mark - NSMutableString

static void IMP_string_appendString(NSMutableString<HMDP_NSMutableString> *thisSelf,
                                    SEL selector,
                                    NSString *aString) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(appendString:))) == 0);
        if(aString == nil || ![aString isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ appendString:%@]: invalid argument", NSStringFromClass(object_getClass(thisSelf)), aString];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_appendString:aString];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_string_replaceCharactersInRange_withString(NSMutableString<HMDP_NSMutableString> *thisSelf,
                                                           SEL selector,
                                                           NSRange range,
                                                           NSString *aString) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceCharactersInRange:withString:))) == 0);
        if(aString == nil || ![aString isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceCharactersInRange:%@ withString:%@]: invalid argument", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], aString];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceCharactersInRange:%@ withString:%@]: Range or index out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], aString, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceCharactersInRange:range withString:aString];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_insertString_atIndex(NSMutableString<HMDP_NSMutableString> *thisSelf,
                                     SEL selector,
                                     NSString *aString,
                                     NSUInteger loc) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertString:atIndex:))) == 0);
        if(aString == nil || ![aString isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertString:%@ atIndex:%lu]: invalid argument", NSStringFromClass(object_getClass(thisSelf)), aString, (unsigned long)loc];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(loc > thisSelf.length) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertString:%@ atIndex:%lu]: Range or index out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), aString, (unsigned long)loc, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_insertString:aString atIndex:loc];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_string_deleteCharactersInRange(NSMutableString<HMDP_NSMutableString> *thisSelf,
                                               SEL selector,
                                               NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(deleteCharactersInRange:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ deleteCharactersInRange:%@]: Range or index out of bounds; string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_deleteCharactersInRange:range];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSAttributeString

static NSAttributedString * IMP_initWithString(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                               SEL selector,
                                               NSString *str) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initWithString:))) == 0);
        if (!(str && [str isKindOfClass:[NSString class]])) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initWithString:%@]", NSStringFromClass(object_getClass(thisSelf)), str];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initWithString:str];
}

static NSAttributedString * IMP_initWithString_attributes(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                          SEL selector,
                                                          NSString *str,
                                                          NSDictionary<NSAttributedStringKey,id> *attributes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initWithString:attributes:))) == 0);
        if (!(str && [str isKindOfClass:[NSString class]])) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initWithString:%@ attributes:%@]", NSStringFromClass(object_getClass(thisSelf)), str, attributes];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initWithString:str attributes:attributes];
}

static NSAttributedString * IMP_attributedSubstringFromRange(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                             SEL selector,
                                                             NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(attributedSubstringFromRange:))) == 0);
        if(HMDMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ attributedSubstringFromRange:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_attributedSubstringFromRange:range];
}

static void IMP_enumerateAttribute_inRange_options_usingBlock(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                              SEL selector,
                                                              NSAttributedStringKey attrName,
                                                              NSRange enumerationRange,
                                                              NSAttributedStringEnumerationOptions opts,
                                                              void (^block)(id value, NSRange range, BOOL *stop)) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(enumerateAttribute:inRange:options:usingBlock:))) == 0);
        if(block == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ enumerateAttribute:%@ inRange:%@ options:%lu usingBlock:(null)] nil argument", NSStringFromClass(object_getClass(thisSelf)), attrName, [NSValue valueWithRange:enumerationRange], (unsigned long)opts];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"EXC_BAD_ACCESS" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
        
        if(enumerationRange.length > 0
           && HMDMaxRangeInvalid(enumerationRange, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ enumerateAttribute:%@ inRange:%@ options:%lu usingBlock:] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), attrName, [NSValue valueWithRange:enumerationRange], (unsigned long)opts, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_enumerateAttribute:attrName inRange:enumerationRange options:opts usingBlock:block];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_enumerateAttributesInRange_options_usingBlock(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                              SEL selector,
                                                              NSRange enumerationRange,
                                                              NSAttributedStringEnumerationOptions opts,
                                                              void (^block)(NSDictionary<NSAttributedStringKey, id> *attrs,
                                                                            NSRange range,
                                                                            BOOL *stop)){
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(enumerateAttributesInRange:options:usingBlock:))) == 0);
        if(enumerationRange.length > 0
           && HMDMaxRangeInvalid(enumerationRange, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ enumerateAttributesInRange:%@ options:%lu usingBlock:] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:enumerationRange], (unsigned long)opts, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(block == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ enumerateAttributesInRange:%@ options:%lu usingBlock:(null)] nil argument", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:enumerationRange], (unsigned long)opts];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"EXC_BAD_ACCESS" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
    }
    
    [thisSelf HMDP_enumerateAttributesInRange:enumerationRange options:opts usingBlock:block];
    GCC_FORCE_NO_OPTIMIZATION
}

static NSData *IMP_dataFromRange_documentAttributes_error(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                          SEL selector,
                                                          NSRange range, NSDictionary<NSAttributedStringDocumentAttributeKey, id> * dict,
                                                          NSError * _Nullable * error) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(dataFromRange:documentAttributes:error:))) == 0);
        if(range.length > 0
           && HMDMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ dataFromRange:%@ documentAttributes:%@ error:%p] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], dict, error, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_dataFromRange:range documentAttributes:dict error:error];
}

static NSFileWrapper *IMP_fileWrapperFromRange_documentAttributes_error(NSAttributedString<HMDP_NSAttributedString> *thisSelf,
                                                                        SEL selector,
                                                                        NSRange range, NSDictionary<NSAttributedStringDocumentAttributeKey, id> *dict,
                                                                        NSError * _Nullable *error) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(fileWrapperFromRange:documentAttributes:error:))) == 0);
        if(range.length > 0
           && HMDMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ fileWrapperFromRange:%@ documentAttributes:%@ error:%p] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], dict, error, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_fileWrapperFromRange:range documentAttributes:dict error:error];
}

static BOOL IMP_containsAttachmentsInRange(NSAttributedString<HMDP_NSAttributedString> *thisSelf, SEL selector, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(containsAttachmentsInRange:))) == 0);
        if(range.length > 0
           && HMDMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ containsAttachmentsInRange:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return NO;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_containsAttachmentsInRange:range];
}

#pragma mark - NSMutableAttributedString

static void IMP_attributeString_replaceCharactersInRange_withString(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                                                    SEL selector,
                                                                    NSRange range,
                                                                    NSString *str) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceCharactersInRange:withString:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceCharactersInRange:%@ withString:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], str, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(str == nil || ![str isKindOfClass:[NSString class]]) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceCharactersInRange:%@ withString:%@] invalid argument", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], str];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceCharactersInRange:range withString:str];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_attributeString_deleteCharactersInRange(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                                        SEL selector,
                                                        NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(deleteCharactersInRange:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ deleteCharactersInRange:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_deleteCharactersInRange:range];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_setAttributes_range(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                    SEL selector,
                                    NSDictionary<NSAttributedStringKey, id> *attrs,
                                    NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setAttributes:range:))) == 0);
        if(range.length > 0
           && HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setAttributes:%@ range:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), attrs, [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_setAttributes:attrs range:range];
    GCC_FORCE_NO_OPTIMIZATION
}

// 该方法虽然在 NSAttributedString 实现, 但是只有 NSMutableAttributedString 会崩溃
static NSDictionary<NSAttributedStringKey, id> *IMP_attributesAtIndex_effectiveRange(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                                                                     SEL selector,
                                                                                     NSUInteger location,
                                                                                     NSRangePointer range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(attributesAtIndex:effectiveRange:))) == 0);
        
        if(thisSelf.length <= location) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString =
                [NSString stringWithFormat:@"-[%@ attributesAtIndex:%lu effectiveRange:%p] Out of bounds, string length %lu",
                 NSStringFromClass(object_getClass(thisSelf)), (unsigned long)location, range, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    GCC_FORCE_NO_OPTIMIZATION
    return [thisSelf HMDP_attributesAtIndex:location effectiveRange:range];
}

static void IMP_addAttribute_value_range(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                         SEL selector,
                                         NSAttributedStringKey name,
                                         id value,
                                         NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addAttribute:value:range:))) == 0);
        if(range.length > 0) {  // 只要 range.length == 0 一切都好说
            if(value == nil) {
                if(!hmd_upper_trycatch_effective(0)) {
                    NSString *reasonString = [NSString stringWithFormat:@"-[%@ addAttribute:%@ value:nil range:%@] nil value",
                                              NSStringFromClass(object_getClass(thisSelf)), name, [NSValue valueWithRange:range]];
                    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                    HMD_Protect_Container_captureException(capture);
                    return;
                }
            } else if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
                if(!hmd_upper_trycatch_effective(0)) {
                    NSString *reasonString = [NSString stringWithFormat:@"-[%@ addAttribute:%@ value:%@ range:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), name, value, [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                    HMD_Protect_Container_captureException(capture);
                    return;
                }
            }
        }
    }
    
    [thisSelf HMDP_addAttribute:name value:value range:range];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_addAttributes_range(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                    SEL selector,
                                    NSDictionary<NSAttributedStringKey, id> *attrs,
                                    NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addAttributes:range:))) == 0);
        if(range.length > 0
           && HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ addAttributes:%@ range:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), attrs, [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_addAttributes:attrs range:range];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_removeAttribute_range(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                      SEL selector,
                                      NSAttributedStringKey name,
                                      NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeAttribute:range:))) == 0);
        if(range.length > 0
           && HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeAttribute:%@ range:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), name, [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_removeAttribute:name range:range];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_insertAttributedString_atIndex(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                               SEL selector,
                                               NSAttributedString *attrString,
                                               NSUInteger loc) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertAttributedString:atIndex:))) == 0);
        if(attrString == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertAttributedString:%@ atIndex:%lu] invalid argument", NSStringFromClass(object_getClass(thisSelf)), attrString, (unsigned long)loc];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(loc > thisSelf.length) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertAttributedString:%@ atIndex:%lu] Range or index out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), attrString, (unsigned long)loc, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_insertAttributedString:attrString atIndex:loc];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_replaceCharactersInRange_withAttributedString(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                                              SEL selector,
                                                              NSRange range,
                                                              NSAttributedString *attrString) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceCharactersInRange:withAttributedString:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceCharactersInRange:%@ withAttributedString:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], attrString, (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceCharactersInRange:range withAttributedString:attrString];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_fixAttributesInRange(NSMutableAttributedString<HMDP_NSMutableAttributedString> *thisSelf,
                                     SEL selector,
                                     NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(fixAttributesInRange:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.length)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ fixAttributesInRange:%@] Out of bounds, string length %lu", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], (unsigned long)thisSelf.length];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_fixAttributesInRange:range];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSArray

static id IMP_arrayWithObjects_count(Class<HMDP_NSArray> thisClass,
                                     SEL selector,
                                     id _Nonnull const *objects,
                                     NSUInteger cnt) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(arrayWithObjects:count:))) == 0);
        if(objects == NULL && cnt > 0) {
            if(!hmd_upper_trycatch_effective(0)) {
                // It is safe to pass NULL and zero count to get empty array
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ arrayWithObjects:count:%lu] pointer to objects array is NULL but length is %lu", NSStringFromClass(thisClass), (unsigned long)cnt, (unsigned long)cnt];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
        if(cnt > 0) {
            BOOL errorFlag = NO;
            NSUInteger index;
            for(index = 0; index < cnt; index++) {
                if(objects[index] == nil) {
                    errorFlag = YES;
                    break;
                }
            }
            
            if(errorFlag) {
                if(!hmd_upper_trycatch_effective(0)) {
                    NSString *reasonString = [NSString stringWithFormat:@"-[%@ arrayWithObjects:count:%lu] attempt to insert nil to index %lu", NSStringFromClass(thisClass), (unsigned long)cnt, (unsigned long)index];
                    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                    HMD_Protect_Container_captureException(capture);
#if RANGERSAPM
                    if (HMDProtectionArrayCreateModeExcludeNil == HMD_Protect_Container_arrayCreateMode) {
                        id result = nil;
                        
                        id *nonnullObjectsArray;
                        if ((nonnullObjectsArray = malloc(sizeof(id) * cnt)) != NULL) {
                            NSUInteger currentSavedIndex = 0;
                            
                            for (NSUInteger index = 0; index < cnt; index++) {
                                if (objects[index] != nil) {
                                    nonnullObjectsArray[currentSavedIndex] = objects[index];
                                    currentSavedIndex++;
                                }
                            }
                            
                            if (currentSavedIndex != 0) {
                                result = [thisClass HMDP_arrayWithObjects:nonnullObjectsArray count:currentSavedIndex];
                            }
                            
                            free(nonnullObjectsArray);
                        } DEBUG_ELSE
                        
                        return result;
                    } else {
                        return nil;
                    }
#else
                    return nil;
#endif
                }
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisClass HMDP_arrayWithObjects:objects count:cnt];
}

static NSArray *IMP_objectsAtIndexes(NSArray<HMDP_NSArray> *thisSelf, SEL selector, NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(objectsAtIndexes:))) == 0);
        if(indexes == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ objectsAtIndexes:%@] index set cannot be nil", NSStringFromClass(object_getClass(thisSelf)), NSIndexSet_toString(indexes)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
        NSUInteger count = thisSelf.count;
        __block BOOL errorFlag = NO;
        __block NSUInteger errorIndex;
        [indexes enumerateIndexesUsingBlock:
         ^(NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx >= count) {
                *stop = YES;
                errorFlag = YES;
                errorIndex = idx;
            }
        }];
        
        if(errorFlag) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ objectsAtIndexes:%@] index %lu in index set beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), NSIndexSet_toString(indexes), (unsigned long)errorIndex, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_objectsAtIndexes:indexes];
}

static id IMP_objectAtIndex(NSArray<HMDP_NSArray> *thisSelf, SEL selector, NSUInteger index) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(objectAtIndex:))) == 0);
        if(index >= thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ objectAtIndex:%lu]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_objectAtIndex:index];
}

static id IMP_objectAtIndexedSubscript(NSArray<HMDP_NSArray> *thisSelf, SEL selector, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(objectAtIndexedSubscript:))) == 0);
        if(idx >= thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ objectAtIndexedSubscript:%lu]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_objectAtIndexedSubscript:idx];
}

static id IMP_subarrayWithRange(NSArray<HMDP_NSArray> *thisSelf, SEL selector, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(subarrayWithRange:))) == 0);
        //for subarrayWithRange, location or length -1 will cause crash
        if(range.location > thisSelf.count || range.length > thisSelf.count || HMDMaxRangeInvalid(range, thisSelf.count)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ subarrayWithRange]:range {%lu, %lu} extends beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)range.location, (unsigned long)range.length, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_subarrayWithRange:range];
}

#pragma mark - NSMutableArray

static void IMP_removeObjectAtIndex(NSMutableArray<HMDP_NSMutableArray> *thisSelf, SEL selector, NSUInteger index) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectAtIndex:))) == 0);
        if(index >= thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeObjectAtIndex:%lu]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_removeObjectAtIndex:index];
}

static void IMP_removeObjectsInRange(NSMutableArray<HMDP_NSMutableArray> *thisSelf, SEL selector, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectsInRange:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.count)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeObjectsInRange:%@]: range %@ extends beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], [NSValue valueWithRange:range], NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_removeObjectsInRange:range];
}

static void IMP_removeObjectsAtIndexes(NSMutableArray<HMDP_NSMutableArray> *thisSelf, SEL selector, NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectsAtIndexes:))) == 0);
        if(indexes == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeObjectsAtIndexes:%@]: index set cannot be nil", NSStringFromClass(object_getClass(thisSelf)), indexes];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        NSUInteger count = thisSelf.count;
        __block BOOL errorFlag = NO;
        __block NSUInteger errorIndex;
        [indexes enumerateIndexesUsingBlock:
         ^(NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx >= count) {
                *stop = YES;
                errorFlag = YES;
                errorIndex = idx;
            }
        }];
        
        if(errorFlag) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeObjectsAtIndexes:%@]: index %lu in index set beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), indexes, (unsigned long)errorIndex, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_removeObjectsAtIndexes:indexes];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_insertObject_atIndex(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                     SEL selector,
                                     id anObject,
                                     NSUInteger index) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertObject:atIndex:))) == 0);
        if(anObject == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertObject:%@ atIndex:%lu]: object cannot be nil", NSStringFromClass(object_getClass(thisSelf)), anObject, (unsigned long)index];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(index > thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertObject:%@ atIndex:%lu]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), anObject, (unsigned long)index, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_insertObject:anObject atIndex:index];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_insertObjects_atIndexes(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                        SEL selector,
                                        NSArray *objects,
                                        NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertObjects:atIndexes:))) == 0);
        if(indexes == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertObjects:%@ atIndexes:%@]: index set cannot be nil", NSStringFromClass(object_getClass(thisSelf)), objects, indexes];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        BOOL errorFlag = NO;
        NSUInteger arrayCount = thisSelf.count;
        NSUInteger currentIndex = [indexes firstIndex];
        while(currentIndex != NSNotFound) {
            if(currentIndex > arrayCount) {
                errorFlag = YES;
                break;
            }
            else {
                arrayCount++;
                currentIndex = [indexes indexGreaterThanIndex:currentIndex];
            };
        }
        
        if(errorFlag) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertObjects:%@ atIndexes:%@]: index %lu in index set beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), objects, indexes, (unsigned long)currentIndex, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(objects.count != indexes.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ insertObjects:%@ atIndexes:%@]: count of array (%lu) differs from count of index set (%lu)", NSStringFromClass(object_getClass(thisSelf)), objects, indexes, (unsigned long)objects.count, (unsigned long)indexes.count];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_insertObjects:objects atIndexes:indexes];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_replaceObjectAtIndex_withObject(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                                SEL selector,
                                                NSUInteger index,
                                                id anObject) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectAtIndex:withObject:))) == 0);
        if(anObject == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectAtIndex:%lu withObject:%@]: object cannot be nil", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, anObject];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(index >= thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectAtIndex:%lu withObject:%@]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), (unsigned long)index, anObject, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceObjectAtIndex:index withObject:anObject];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_replaceObjectsAtIndexes_withObjects(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                                    SEL selector,
                                                    NSIndexSet *indexes,
                                                    NSArray *objects) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectsAtIndexes:withObjects:))) == 0);
        if(indexes == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsAtIndexes:%@ withObjects:%@]: index set cannot be nil", NSStringFromClass(object_getClass(thisSelf)), indexes, objects];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
        
        if(indexes.count != objects.count) {   // this include objects == nil
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsAtIndexes:%@ withObjects:%@]: count of array (%lu) differs from count of index set (%lu)", NSStringFromClass(object_getClass(thisSelf)), indexes, objects, (unsigned long)objects.count, (unsigned long)indexes.count];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        NSUInteger count = thisSelf.count;
        __block BOOL errorFlag = NO;
        __block NSUInteger errorIndex;
        [indexes enumerateIndexesUsingBlock:
         ^(NSUInteger idx, BOOL * _Nonnull stop) {
            if(idx >= count) {
                errorIndex = idx;
                errorFlag = YES;
                *stop = YES;
            }
        }];
        
        if(errorFlag) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsAtIndexes:%@ withObjects:%@]: index %lu in index set beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), indexes, objects, (unsigned long)errorIndex, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceObjectsAtIndexes:indexes withObjects:objects];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_replaceObjectsInRange_withObjectsFromArray(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                                           SEL selector,
                                                           NSRange range,
                                                           NSArray *otherArray) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectsInRange:withObjectsFromArray:))) == 0);
        if(HMDStrictMaxRangeInvalid(range, thisSelf.count)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsInRange:%@ withObjectsFromArray:%@]: range %@ extends beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], otherArray, [NSValue valueWithRange:range], NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceObjectsInRange:range withObjectsFromArray:otherArray];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_replaceObjectsInRange_withObjectsFromArray_range(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                                                 SEL selector,
                                                                 NSRange range,
                                                                 NSArray *otherArray,
                                                                 NSRange otherRange) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectsInRange:withObjectsFromArray:range:))) == 0);
        if(HMDStrictMaxRangeInvalid(otherRange, otherArray.count)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsInRange:%@ withObjectsFromArray:%@ range:%@]: range %@ extends beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], otherArray, [NSValue valueWithRange:otherRange], [NSValue valueWithRange:otherRange], NSArray_RANGE_STR(otherArray)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
        
        if(HMDStrictMaxRangeInvalid(range, thisSelf.count)) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ replaceObjectsInRange:%@ withObjectsFromArray:%@ range:%@]: range %@ extends beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), [NSValue valueWithRange:range], otherArray, [NSValue valueWithRange:otherRange], [NSValue valueWithRange:range], NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                return;
            }
        }
    }
    
    [thisSelf HMDP_replaceObjectsInRange:range withObjectsFromArray:otherArray range:otherRange];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_setObject_atIndexedSubscript(NSMutableArray<HMDP_NSMutableArray> *thisSelf,
                                             SEL selector,
                                             id anObject,
                                             NSUInteger index) {
    
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setObject:atIndexedSubscript:))) == 0);
        
        if(nil == anObject) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setObject:%@ atIndexedSubscript:%lu]: object cannot be nil", NSStringFromClass(object_getClass(thisSelf)), anObject, (unsigned long)index];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(index > thisSelf.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setObject:%@ atIndexedSubscript:%lu]: index %lu beyond bounds %@", NSStringFromClass(object_getClass(thisSelf)), anObject, (unsigned long)index, (unsigned long)index, NSArray_RANGE_STR(thisSelf)];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSRangeException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    [thisSelf HMDP_setObject:anObject atIndexedSubscript:index];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSDictionary

static id IMP_dictionaryWithObjects_forKeys(Class<HMDP_NSDictionary> thisClass,
                                            SEL selector,
                                            NSArray *objects,
                                            NSArray<id<NSCopying>> *keys) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(dictionaryWithObjects:forKeys:))) == 0);
        if(![objects isKindOfClass:[NSArray class]] ||
           ![keys isKindOfClass:[NSArray class]] ||
           objects.count != keys.count) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ dictionaryWithObjects:%@ forKeys:%@]: count of objects (%lu) differs from count of keys (%lu)", NSStringFromClass(thisClass), objects, keys, (unsigned long)objects.count, (unsigned long)keys.count];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisClass HMDP_dictionaryWithObjects:objects forKeys:keys];
}

static id IMP_dictionaryWithObjects_forKeys_count(Class<HMDP_NSDictionary> thisClass,
                                                  SEL selector,
                                                  id _Nonnull * _Nullable objects,
                                                  id<NSCopying> _Nonnull const * _Nullable keys,
                                                  NSUInteger cnt) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(dictionaryWithObjects:forKeys:count:))) == 0);
        if(unlikely((objects == NULL || keys == NULL) && cnt > 0)) {
            if(likely(!hmd_upper_trycatch_effective(0))) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ dictionaryWithObjects:forKeys:count:%lu]: pointer to objects array is NULL but length is %lu", NSStringFromClass(thisClass), (unsigned long)cnt, (unsigned long)cnt];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
        // 如果 BAD_ACCESS CRASH 在这里 可不是 安全气垫的问题
        BOOL errorFlag = NO;
        NSUInteger index = 0;
        for(index = 0; index < cnt; index++) {
            if(objects[index] == nil || keys[index] == nil) {
                errorFlag = YES;
                break;
            }
        }
        
        if(unlikely(errorFlag)) {
            if(likely(!hmd_upper_trycatch_effective(0))) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ dictionaryWithObjects:forKeys:count:%lu]: attempt to insert (object:%@ key:%@) to index %lu",
                                          NSStringFromClass(thisClass), (unsigned long)cnt, objects[index], keys[index], (unsigned long)index];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                
                id *nonnullObjectArray;
                id *nonnullKeyArray;
                
                id returnValue = nil;
                
                if((nonnullObjectArray = malloc(sizeof(id) * cnt)) != NULL) {
                    if((nonnullKeyArray = malloc(sizeof(id) * cnt)) != NULL) {
                        
                        NSUInteger currentSaveIndex = 0;
                        
                        for(NSUInteger index = 0; index < cnt; index++) {
                            if(objects[index] != nil && keys[index] != nil) {
                                nonnullObjectArray[currentSaveIndex] = objects[index];
                                nonnullKeyArray[currentSaveIndex] = keys[index];
                                currentSaveIndex++;
                            }
                        }
                        
                        if(currentSaveIndex != 0)
                            returnValue = [thisClass HMDP_dictionaryWithObjects:nonnullObjectArray forKeys:nonnullKeyArray count:currentSaveIndex];
                        
                        free(nonnullKeyArray);
                    } DEBUG_ELSE
                    free(nonnullObjectArray);
                } DEBUG_ELSE
                
                return returnValue;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisClass HMDP_dictionaryWithObjects:objects forKeys:keys count:cnt];
}

#pragma mark - NSMutableDictionary

static void IMP_setObject_forKey(NSMutableDictionary<HMDP_NSMutableDictionary> *thisSelf,
                                 SEL selector,
                                 id anObject,
                                 id<NSCopying> aKey) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setObject:forKey:))) == 0);
        if(aKey == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setObject:%@ forKey:%@]: key cannot be nil", NSStringFromClass(object_getClass(thisSelf)), anObject, aKey];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
        
        if(anObject == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setObject:%@ forKey:%@]: object cannot be nil (key: %@)", NSStringFromClass(object_getClass(thisSelf)), anObject, aKey, aKey];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_setObject:anObject forKey:aKey];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_setValue_forKey(NSMutableDictionary<HMDP_NSMutableDictionary> *thisSelf,
                                SEL selector,
                                id value,
                                NSString *key) {
    if(_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setValue:forKey:))) == 0);
        if (key == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setValue:%@ forKey:%@]: key cannot be nil", NSStringFromClass(object_getClass(thisSelf)), value, key];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_setValue:value forKey:key];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_removeObjectForKey(NSMutableDictionary<HMDP_NSMutableDictionary> *thisSelf,
                                   SEL selector,
                                   id aKey) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectForKey:))) == 0);
        if(aKey == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ removeObjectForKey:%@]: key cannot be nil", NSStringFromClass(object_getClass(thisSelf)), aKey];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_removeObjectForKey:aKey];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_setObject_forKeyedSubscript(NSMutableDictionary<HMDP_NSMutableDictionary> *thisSelf,
                                            SEL selector,
                                            id obj,
                                            id<NSCopying> key ) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setObject:forKeyedSubscript:))) == 0);
        if(key == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ setObject:%@ forKeyedSubscript:%@]: key cannot be nil", NSStringFromClass(object_getClass(thisSelf)), obj, key];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    [thisSelf HMDP_setObject:obj forKeyedSubscript:key];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSSet

static BOOL IMP_intersectsSet(NSSet<HMDP_NSSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(intersectsSet:))) == 0);
        BOOL rst = NO;
        @try {
            rst = [thisSelf HMDP_intersectsSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return rst;
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_intersectsSet:otherSet];
}

static BOOL IMP_isEqualToSet(NSSet<HMDP_NSSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(isEqualToSet:))) == 0);
        BOOL rst = NO;
        @try {
            rst = [thisSelf HMDP_isEqualToSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return rst;
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_isEqualToSet:otherSet];
}

static BOOL IMP_isSubsetOfSet(NSSet<HMDP_NSSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(isSubsetOfSet:))) == 0);
        BOOL rst = NO;
        @try {
            rst = [thisSelf HMDP_isSubsetOfSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return rst;
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_isSubsetOfSet:otherSet];
}

#pragma mark - NSMutableSet

static void IMP_addObject(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSObject* object) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addObject:))) == 0);
        @try {
            [thisSelf HMDP_addObject:object];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_addObject:object];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_removeObject(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSObject* object) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObject:))) == 0);
        @try {
            [thisSelf HMDP_removeObject:object];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObject:object];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_addObjectsFromArray(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSArray* array) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addObjectsFromArray:))) == 0);
        @try {
            [thisSelf HMDP_addObjectsFromArray:array];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_addObjectsFromArray:array];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_unionSet(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(unionSet:))) == 0);
        @try {
            [thisSelf HMDP_unionSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_unionSet:otherSet];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_intersectSet(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(intersectSet:))) == 0);
        @try {
            [thisSelf HMDP_intersectSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_intersectSet:otherSet];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_minusSet(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(minusSet:))) == 0);
        @try {
            [thisSelf HMDP_minusSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_minusSet:otherSet];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_setSet(NSMutableSet<HMDP_NSMutableSet> *thisSelf, SEL selector, NSSet* otherSet) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setSet:))) == 0);
        @try {
            [thisSelf HMDP_setSet:otherSet];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_setSet:otherSet];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSOrderedSet

static id IMP_orderedSet_objectAtIndex(NSOrderedSet<HMDP_NSOrderedSet> *thisSelf, SEL selector, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(objectAtIndex:))) == 0);
        id rst = nil;
        @try {
            rst = [thisSelf HMDP_objectAtIndex:idx];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return rst;
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_objectAtIndex:idx];
}

static NSArray<id> *IMP_orderedSet_objectsAtIndexes(NSOrderedSet<HMDP_NSOrderedSet> *thisSelf, SEL selector, NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(objectsAtIndexes:))) == 0);
        id rst = nil;
        @try {
            rst = [thisSelf HMDP_objectsAtIndexes:indexes];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return rst;
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_objectsAtIndexes:indexes];
}

static void IMP_orderedSet_getObjects_range(NSOrderedSet<HMDP_NSOrderedSet> *thisSelf, SEL selector, id *objects, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(getObjects:range:))) == 0);
        @try {
            [thisSelf HMDP_getObjects:objects range:range];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_getObjects:objects range:range];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSMutableOrderedSet

static void IMP_orderedSet_setObject_atIndex(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, id obj, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setObject:atIndex:))) == 0);
        @try {
            [thisSelf HMDP_setObject:obj atIndex:idx];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_setObject:obj atIndex:idx];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_addObject(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, id object) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addObject:))) == 0);
        @try {
            [thisSelf HMDP_addObject:object];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_addObject:object];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_addObjects_count(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, id *objects, NSUInteger count) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(addObjects:count:))) == 0);
        @try {
            [thisSelf HMDP_addObjects:objects count:count];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_addObjects:objects count:count];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_insertObject_atIndex(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, id object, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertObject:atIndex:))) == 0);
        @try {
            [thisSelf HMDP_insertObject:object atIndex:idx];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_insertObject:object atIndex:idx];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_insertObjects_atIndexes(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSArray<id> *objects, NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(insertObjects:atIndexes:))) == 0);
        @try {
            [thisSelf HMDP_insertObjects:objects atIndexes:indexes];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_insertObjects:objects atIndexes:indexes];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_exchangeObjectAtIndex_withObjectAtIndex(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSUInteger idx1, NSUInteger idx2) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(exchangeObjectAtIndex:withObjectAtIndex:))) == 0);
        @try {
            [thisSelf HMDP_exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_moveObjectsAtIndexes_toIndex(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSIndexSet *indexes, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(moveObjectsAtIndexes:toIndex:))) == 0);
        @try {
            [thisSelf HMDP_moveObjectsAtIndexes:indexes toIndex:idx];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_moveObjectsAtIndexes:indexes toIndex:idx];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_replaceObjectAtIndex_withObject(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSUInteger idx, id object) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectAtIndex:withObject:))) == 0);
        @try {
            [thisSelf HMDP_replaceObjectAtIndex:idx withObject:object];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_replaceObjectAtIndex:idx withObject:object];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_replaceObjectsInRange_withObjects_count(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSRange range, const id *objects, NSUInteger count) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectsInRange:withObjects:count:))) == 0);
        @try {
            [thisSelf HMDP_replaceObjectsInRange:range withObjects:objects count:count];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_replaceObjectsInRange:range withObjects:objects count:count];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_replaceObjectsAtIndexes_withObjects(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSIndexSet *indexes, NSArray<id> * objects) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(replaceObjectsAtIndexes:withObjects:))) == 0);
        @try {
            [thisSelf HMDP_replaceObjectsAtIndexes:indexes withObjects:objects];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_replaceObjectsAtIndexes:indexes withObjects:objects];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_removeObjectAtIndex(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSUInteger idx) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectAtIndex:))) == 0);
        @try {
            [thisSelf HMDP_removeObjectAtIndex:idx];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObjectAtIndex:idx];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_removeObject(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, id object) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObject:))) == 0);
        @try {
            [thisSelf HMDP_removeObject:object];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObject:object];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_removeObjectsInRange(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSRange range) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectsInRange:))) == 0);
        @try {
            [thisSelf HMDP_removeObjectsInRange:range];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObjectsInRange:range];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_removeObjectsAtIndexes(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSIndexSet *indexes) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectsAtIndexes:))) == 0);
        @try {
            [thisSelf HMDP_removeObjectsAtIndexes:indexes];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObjectsAtIndexes:indexes];
    GCC_FORCE_NO_OPTIMIZATION
}

static void IMP_orderedSet_removeObjectsInArray(NSMutableOrderedSet<HMDP_NSMutableOrderedSet> *thisSelf, SEL selector, NSArray<id> *array) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(removeObjectsInArray:))) == 0);
        @try {
            [thisSelf HMDP_removeObjectsInArray:array];
        } @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception];
                HMD_Protect_Container_captureException(capture);
            }
        }
        
        return;
    }
    
    [thisSelf HMDP_removeObjectsInArray:array];
    GCC_FORCE_NO_OPTIMIZATION
}

#pragma mark - NSURL

static id IMP_url_initFileURLWithPath(NSURL<HMDP_NSURL> *thisSelf, SEL selector, NSString *path) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initFileURLWithPath:))) == 0);
        if (path == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initFileURLWithPath:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initFileURLWithPath:path];
}

static id IMP_url_initFileURLWithPath_isDirectory_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                                                SEL selector, NSString *path,
                                                                BOOL isDir,
                                                                NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initFileURLWithPath:isDirectory:relativeToURL:))) == 0);
        if (path == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initFileURLWithPath:isDirectory:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initFileURLWithPath:path isDirectory:isDir relativeToURL:baseURL];
}

static id IMP_url_initFileURLWithPath_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                                    SEL selector, NSString *path,
                                                    NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initFileURLWithPath:relativeToURL:))) == 0);
        if (path == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initFileURLWithPath:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initFileURLWithPath:path relativeToURL:baseURL];
}

static id IMP_url_initFileURLWithPath_isDirectory(NSURL<HMDP_NSURL> *thisSelf,
                                                  SEL selector,
                                                  NSString *path,
                                                  BOOL isDir) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initFileURLWithPath:isDirectory:))) == 0);
        if (path == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initFileURLWithPath:isDirectory:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initFileURLWithPath:path isDirectory:isDir];
}

static id IMP_url_initFileURLWithFileSystemRepresentation_isDirectory_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                                                                    SEL selector,
                                                                                    const char *path,
                                                                                    BOOL isDir,
                                                                                    NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initFileURLWithFileSystemRepresentation:isDirectory:relativeToURL:))) == 0);
        if (path == NULL) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initFileURLWithFileSystemRepresentationh:isDirectory:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initFileURLWithFileSystemRepresentation:path isDirectory:isDir relativeToURL:baseURL];
}

static id IMP_url_initWithString(NSURL<HMDP_NSURL> *thisSelf, SEL selector, NSString *URLString) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initWithString:))) == 0);
        if (URLString == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initWithString:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initWithString:URLString];
}

static id IMP_url_initWithString_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                               SEL selector,
                                               NSString *URLString,
                                               NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initWithString:relativeToURL:))) == 0);
        if (URLString == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initWithString:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initWithString:URLString relativeToURL:baseURL];
}

static id IMP_url_initAbsoluteURLWithDataRepresentation_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                                                      SEL selector,
                                                                      NSData *data,
                                                                      NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initAbsoluteURLWithDataRepresentation:relativeToURL:))) == 0);
        if (data == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initAbsoluteURLWithDataRepresentation:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initAbsoluteURLWithDataRepresentation:data relativeToURL:baseURL];
}

static id IMP_url_initWithDataRepresentation_relativeToURL(NSURL<HMDP_NSURL> *thisSelf,
                                                           SEL selector,
                                                           NSData *data,
                                                           NSURL *baseURL) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(initWithDataRepresentation:relativeToURL:))) == 0);
        if (data == nil) {
            if(!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"-[%@ initWithDataRepresentation:relativeToURL:]: nil string parameter", NSStringFromClass(object_getClass(thisSelf))];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return nil;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION return [thisSelf HMDP_initWithDataRepresentation:data relativeToURL:baseURL];
}

#pragma mark - CALayer

static void IMP_calayer_setPosition(CALayer<HMDP_CALayer> *thisSelf, SEL selector, CGPoint position) {
    if (_internal_container_captureBlock) {
        DEBUG_ASSERT(strcmp(sel_getName(selector), sel_getName(@selector(setPosition:))) == 0);
        if (isnan(position.x) || isnan(position.y)) {
            //CA::Layer::presentation_layer has internal try catch protect
            if (!hmd_upper_trycatch_effective(0)) {
                NSString *reasonString = [NSString stringWithFormat:@"CALayer position contains NaN: [%f %f]. Layer: %@", position.x, position.y, thisSelf];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"CALayerInvalidGeometry" reason:reasonString];
                HMD_Protect_Container_captureException(capture);
                return;
            }
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION [thisSelf HMDP_setPosition:position];
}

#pragma mark - Foundation

void HMD_Protect_toggle_Container_protection(HMDProtectCaptureBlock _Nullable handle) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    Block_release(_internal_container_captureBlock);
    _internal_container_captureBlock = Block_copy(handle);
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        SwizzlePreperation();
        BatchSwizzleForStatic();
    }
}

static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_Container_captureException(HMDProtectCapture *capture) {
    if (!capture) {
        return;
    }
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] Container exception");
    HMDProtectCaptureBlock captureBlock = nil;
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    captureBlock = Block_copy(_internal_container_captureBlock);
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    if(captureBlock) {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:2 suspend:NO];
        if (bt) {
            capture.backtraces = @[bt];
            capture.crashKeySet = (NSMutableSet<id>*)crashKeySet;
            capture.filterWithTopStack = YES;
            captureBlock(capture);
        }
        
        Block_release(captureBlock);
    }
    
    GCC_FORCE_NO_OPTIMIZATION
}

static NSString *NSIndexSet_toString(NSIndexSet *set) {
    NSMutableString *allIndexString = [NSMutableString string];
    __block BOOL isFirst = YES;
    [allIndexString appendString:@"{"];
    [set enumerateIndexesUsingBlock:
     ^(NSUInteger idx, BOOL * _Nonnull stop) {
        if(isFirst) isFirst = NO;
        else [allIndexString appendString:@", "];
        [allIndexString appendFormat:@"%lu", (unsigned long)idx];
    }];
    [allIndexString appendString:@"}"];
    return allIndexString;
}

NS_INLINE BOOL HMDMaxRangeInvalid(NSRange range, NSUInteger length) {
    return NSMaxRange(range) > length;
}

NS_INLINE BOOL HMDStrictMaxRangeInvalid(NSRange range, NSUInteger length) {
    // 如果需要包括整个 range 内的数据, 那么该 array 的 length 至少需要 satisifyLength 长度
    NSUInteger satisifyLength;
    return __builtin_add_overflow(range.location, range.length, &satisifyLength) || satisifyLength > length;
}

#pragma mark - Swizzle

static void swizzleClassMethod(cluster_t *cluster, swizzle_method_t *swizzleMethods, int count) {
    Class aClass = nil;
    for(int classIndex = 0; classIndex <= cluster->count; classIndex++) {
        if (classIndex == cluster->count) {
            aClass = object_getClass(cluster->aClass);
        }
        else {
            aClass = object_getClass(cluster->subClasses[classIndex]);
        }
        
        Method *methodList;
        unsigned int methodCount;
        methodList = class_copyMethodList(aClass, &methodCount);
        if (!methodList) continue;
        for (int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            Method originMethod = methodList[methodIndex];
            SEL originSelector = method_getName(originMethod);
            const char *originSelectorName = sel_getName(originSelector);
            for (int i=0; i<count; i++) {
                if (strcmp(originSelectorName, swizzleMethods[i].originSelectorName) == 0) {
                    const char *type = method_getTypeEncoding(originMethod);
                    IMP originImp = method_getImplementation(originMethod);
                    if(class_addMethod(aClass, swizzleMethods[i].newSelector, originImp, type)) {
                        class_replaceMethod(aClass, originSelector, swizzleMethods[i].newIMP, type);
                    } DEBUG_ELSE
                    break;
                }
            }
        }
        
        free(methodList);
    }
}

static void swizzleInstanceMethod(cluster_t *cluster, swizzle_method_t *swizzleMethods, int count) {
    Class aClass = nil;
    for(int classIndex = 0; classIndex <= cluster->count; classIndex++) {
        if (classIndex == cluster->count) {
            aClass = cluster->aClass;
        }
        else {
            aClass = cluster->subClasses[classIndex];
        }
        
        Method *methodList;
        unsigned int methodCount;
        methodList = class_copyMethodList(aClass, &methodCount);
        if (!methodList) continue;
        for (int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            Method originMethod = methodList[methodIndex];
            SEL originSelector = method_getName(originMethod);
            const char *originSelectorName = sel_getName(originSelector);
            for (int i = 0; i < count; i++) {
                if (strcmp(originSelectorName, swizzleMethods[i].originSelectorName) == 0) {
                    const char *type = method_getTypeEncoding(originMethod);
                    IMP originImp = method_getImplementation(originMethod);
                    if (class_addMethod(aClass, swizzleMethods[i].newSelector, originImp, type)) {
                        class_replaceMethod(aClass, originSelector, swizzleMethods[i].newIMP, type);
                    } DEBUG_ELSE
                    break;
                }
            }
        }
        
        free(methodList);
    }
}

static void SwizzlePreperation(void) {
    NSBigMutableStringClass = objc_lookUpClass("NSBigMutableString");
    NSTaggedPointerStringClass = objc_lookUpClass("NSTaggedPointerString");
    if (@available(iOS 17.0, *)) {
        iOS17AndNewer = YES;
        __NSCFStringClass = objc_lookUpClass("__NSCFString");
    }
}

static void BatchSwizzleForStatic(void) {
    cluster_t clusters[] = {
        [HMDPFoundationTypeNSNumber] = {.aClass = NSNumber.class, .subClasses = NULL },
        [HMDPFoundationTypeNSString] = {.aClass = NSString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableString] = {.aClass = NSMutableString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSAttributeString] = {.aClass = NSAttributedString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableAttributeString] = {.aClass = NSMutableAttributedString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSArray] = {.aClass = NSArray.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableArray] = {.aClass = NSMutableArray.class, .subClasses = NULL },
        [HMDPFoundationTypeNSDictionary] = {.aClass = NSDictionary.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableDictionary] = {.aClass = NSMutableDictionary.class, .subClasses = NULL },
        [HMDPFoundationTypeNSSet] = {.aClass = NSSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableSet] = {.aClass = NSMutableSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSOrderedSet] = {.aClass = NSOrderedSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableOrderedSet] = {.aClass = NSMutableOrderedSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSURL] = {.aClass = NSURL.class, .subClasses = NULL },
        [HMDPFoundationTypeCALayer] = {.aClass = CALayer.class, .subClasses = NULL },
    };
    
    char *class_name_list[] = {
        //NSNumber(10)
        "NSConstantDoubleNumber",
        "NSConstantFloatNumber",
        "NSConstantIntegerNumber",
        "NSDecimalNumber",
        "NSDecimalNumberPlaceholder",
        "NSPlaceholderNumber",
        "NSPlaceholderValue",
        "_NSStatic_NSDecimalNumber",
        "__NSCFBoolean",
        "__NSCFNumber",
        //NSString(19)
        "NSBigMutableString",
        "NSCheapMutableString",
        "NSConstantString",
        "NSLocalizableString",
        "NSMutableString",
        "NSMutableStringProxyForMutableAttributedString",
        "NSPathStore2",
        "NSPinyinString",
        "NSPlaceholderMutableString",
        "NSPlaceholderString",
        "NSSimpleCString",
        "NSTaggedPointerString",
        "_NSClStr",
        "_NSStringProxyForContext",
        "__NSCFConstantString",
        "__NSCFString",
        "__NSLocalizedString",
        "__NSVariableWidthString",
        //NSAttributedString(5)
        "NSCFAttributedString",
        "NSConcreteAttributedString",
        "NSConcreteMutableAttributedString",
        "NSMutableAttributedString",
        "__NSCFAttributedString",
        //NSArray(26)
        "NSArrayChanges",
        "NSCFArray",
        "NSConcreteArrayChanges",
        "NSConstantArray",
        "NSKeyValueArray",
        "NSKeyValueFastMutableArray",
        "NSKeyValueFastMutableArray1",
        "NSKeyValueFastMutableArray2",
        "NSKeyValueIvarMutableArray",
        "NSKeyValueMutableArray",
        "NSKeyValueNotifyingMutableArray",
        "NSKeyValueSlowMutableArray",
        "NSMutableArray",
        "_NSCallStackArray",
        "_NSMetadataQueryResultArray",
        "_NSMetadataQueryResultGroupArray",
        "__NSArray0",
        "__NSArrayI",
        "__NSArrayI_Transfer",
        "__NSArrayM",
        "__NSArrayReversed",
        "__NSCFArray",
        "__NSFrozenArrayM",
        "__NSOrderedSetArrayProxy",
        "__NSPlaceholderArray",
        "__NSSingleObjectArrayI",
        //NSDictionary(18)
        "NSCFDictionary",
        "NSConstantDictionary",
        "NSDirInfo",
        "NSFileAttributes",
        "NSKeyValueChangeDictionary",
        "NSMutableDictionary",
        "NSOwnedDictionaryProxy",
        "NSRTFD",
        "NSSharedKeyDictionary",
        "NSSimpleAttributeDictionary",
        "_NSNestedDictionary",
        "__NSCFDictionary",
        "__NSDictionary0",
        "__NSDictionaryI",
        "__NSDictionaryM",
        "__NSFrozenDictionaryM",
        "__NSPlaceholderDictionary",
        "__NSSingleEntryDictionaryI",
        //NSSet(19)
        "NSConcreteSetChanges",
        "NSCountedSet",
        "NSKeyValueFastMutableSet",
        "NSKeyValueFastMutableSet1",
        "NSKeyValueFastMutableSet2",
        "NSKeyValueIvarMutableSet",
        "NSKeyValueMutableSet",
        "NSKeyValueNotifyingMutableSet",
        "NSKeyValueSet",
        "NSKeyValueSlowMutableSet",
        "NSMutableSet",
        "NSSetChanges",
        "__NSCFSet",
        "__NSFrozenSetM",
        "__NSOrderedSetSetProxy",
        "__NSPlaceholderSet",
        "__NSSetI",
        "__NSSetM",
        "__NSSingleObjectSetI",
        // nsorderedset(15)
        "NSKeyValueOrderedSet",
        "__NSOrderedSetReversed",
        "__NSOrderedSetI",
        "NSMutableOrderedSet",
        "NSKeyValueMutableOrderedSet",
        "NSKeyValueIvarMutableOrderedSet",
        "NSKeyValueFastMutableOrderedSet",
        "NSKeyValueFastMutableOrderedSet1",
        "NSKeyValueFastMutableOrderedSet2",
        "NSKeyValueSlowMutableOrderedSet",
        "NSKeyValueMutableOrderedSet",
        "__NSOrderedSetM",
        "__NSPlaceholderOrderedSet",
        "NSKeyValueNotifyingMutableOrderedSet",
        "_NSFaultingMutableOrderedSet",
        // NSURL(0)
        // CALayer(0)
    };
    
    unsigned int clustersCount = (sizeof(clusters) / sizeof(cluster_t));
    unsigned int totalClassCount = (sizeof(class_name_list)/sizeof(char *));
    for (int classIndex = 0; classIndex < totalClassCount; classIndex++) {
        @autoreleasepool {
            const char *class_name = class_name_list[classIndex];
            Class aClass = objc_lookUpClass(class_name);
            Class superClass = aClass;
            // 找子类
            // 不能用isKindOfClass，因为__NSMessageBuilder等类不继承NSObject协议
            while((superClass = class_getSuperclass(superClass)) != NULL) {
                for(unsigned int clusterIndex = 0; clusterIndex < clustersCount; clusterIndex++) {
                    cluster_t *cluster = clusters + clusterIndex;
                    if(cluster->aClass == superClass) {
                        if(cluster->count >= cluster->size) {
                            cluster->subClasses = (Class *)realloc(cluster->subClasses, sizeof(Class) * (cluster->size + STORE_INCREASE));
                            if(cluster->subClasses != NULL) {
                                cluster->size += STORE_INCREASE;
                            }
                            else {
                                goto swizzle_finish;
                            }
                        }
                        cluster->subClasses[cluster->count++] = aClass;
                    }
                }
            }
        }
    }
    
    // NSNumber
    swizzle_method_t numberSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(compare:, numberCompare),
        SWIZZLE_METHOD_STRUCT(isEqualToNumber:, isEqualToNumber),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSNumber], numberSwizzleMethods, sizeof(numberSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSString
    swizzle_method_t stringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(characterAtIndex:, characterAtIndex),
        SWIZZLE_METHOD_STRUCT(substringFromIndex:, substringFromIndex),
        SWIZZLE_METHOD_STRUCT(substringToIndex:, substringToIndex),
        SWIZZLE_METHOD_STRUCT(substringWithRange:, substringWithRange),
        SWIZZLE_METHOD_STRUCT(stringByReplacingCharactersInRange:withString:, stringByReplacingCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(stringByAppendingString:, stringByAppendingString),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSString], stringSwizzleMethods, sizeof(stringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableString
    swizzle_method_t mutableStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(appendString:, string_appendString),
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withString:, string_replaceCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(insertString:atIndex:, insertString_atIndex),
        SWIZZLE_METHOD_STRUCT(deleteCharactersInRange:, string_deleteCharactersInRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableString], mutableStringSwizzleMethods, sizeof(mutableStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSAttributeString
    swizzle_method_t attributeStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(initWithString:, initWithString),
        SWIZZLE_METHOD_STRUCT(initWithString:attributes:, initWithString_attributes),
        SWIZZLE_METHOD_STRUCT(attributedSubstringFromRange:, attributedSubstringFromRange),
        SWIZZLE_METHOD_STRUCT(enumerateAttribute:inRange:options:usingBlock:, enumerateAttribute_inRange_options_usingBlock),
        SWIZZLE_METHOD_STRUCT(enumerateAttributesInRange:options:usingBlock:, enumerateAttributesInRange_options_usingBlock),
        SWIZZLE_METHOD_STRUCT(dataFromRange:documentAttributes:error:, dataFromRange_documentAttributes_error),
        SWIZZLE_METHOD_STRUCT(fileWrapperFromRange:documentAttributes:error:, fileWrapperFromRange_documentAttributes_error),
        SWIZZLE_METHOD_STRUCT(containsAttachmentsInRange:, containsAttachmentsInRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSAttributeString], attributeStringSwizzleMethods, sizeof(attributeStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableAttributeString
    swizzle_method_t mutableAttributeStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withString:, attributeString_replaceCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(deleteCharactersInRange:, attributeString_deleteCharactersInRange),
        SWIZZLE_METHOD_STRUCT(setAttributes:range:, setAttributes_range),
        SWIZZLE_METHOD_STRUCT(addAttribute:value:range:, addAttribute_value_range),
        SWIZZLE_METHOD_STRUCT(addAttributes:range:, addAttributes_range),
        SWIZZLE_METHOD_STRUCT(removeAttribute:range:, removeAttribute_range),
        SWIZZLE_METHOD_STRUCT(insertAttributedString:atIndex:, insertAttributedString_atIndex),
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withAttributedString:, replaceCharactersInRange_withAttributedString),
        SWIZZLE_METHOD_STRUCT(fixAttributesInRange:, fixAttributesInRange),
        
        // 这是一个 NSAttributeString 的实现的方法
        // 但是如果在 NSMutableAttributeString 中调用会需要严格判断
        SWIZZLE_METHOD_STRUCT(attributesAtIndex:effectiveRange:, attributesAtIndex_effectiveRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableAttributeString], mutableAttributeStringSwizzleMethods, sizeof(mutableAttributeStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSArray
    swizzle_method_t arrayClassSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(arrayWithObjects:count:, arrayWithObjects_count),
    };
    swizzleClassMethod(&clusters[HMDPFoundationTypeNSArray], arrayClassSwizzleMethods, sizeof(arrayClassSwizzleMethods) / sizeof(swizzle_method_t));
    
    swizzle_method_t arraySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(objectsAtIndexes:, objectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(objectAtIndex:, objectAtIndex),
        SWIZZLE_METHOD_STRUCT(objectAtIndexedSubscript:, objectAtIndexedSubscript),
        SWIZZLE_METHOD_STRUCT(subarrayWithRange:, subarrayWithRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSArray], arraySwizzleMethods, sizeof(arraySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableArray
    swizzle_method_t mutableArraySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(removeObjectAtIndex:, removeObjectAtIndex),
        SWIZZLE_METHOD_STRUCT(removeObjectsInRange:, removeObjectsInRange),
        SWIZZLE_METHOD_STRUCT(removeObjectsAtIndexes:, removeObjectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(insertObject:atIndex:, insertObject_atIndex),
        SWIZZLE_METHOD_STRUCT(insertObjects:atIndexes:, insertObjects_atIndexes),
        SWIZZLE_METHOD_STRUCT(replaceObjectAtIndex:withObject:, replaceObjectAtIndex_withObject),
        SWIZZLE_METHOD_STRUCT(replaceObjectsAtIndexes:withObjects:, replaceObjectsAtIndexes_withObjects),
        SWIZZLE_METHOD_STRUCT(replaceObjectsInRange:withObjectsFromArray:, replaceObjectsInRange_withObjectsFromArray),
        SWIZZLE_METHOD_STRUCT(replaceObjectsInRange:withObjectsFromArray:range:, replaceObjectsInRange_withObjectsFromArray_range),
        SWIZZLE_METHOD_STRUCT(setObject:atIndexedSubscript:, setObject_atIndexedSubscript),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableArray], mutableArraySwizzleMethods, sizeof(mutableArraySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSDictionary
    swizzle_method_t dictionayClassSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(dictionaryWithObjects:forKeys:, dictionaryWithObjects_forKeys),
        SWIZZLE_METHOD_STRUCT(dictionaryWithObjects:forKeys:count:, dictionaryWithObjects_forKeys_count),
    };
    swizzleClassMethod(&clusters[HMDPFoundationTypeNSDictionary], dictionayClassSwizzleMethods, sizeof(dictionayClassSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableDictionary
    swizzle_method_t mutableDictionaySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(setObject:forKey:, setObject_forKey),
        SWIZZLE_METHOD_STRUCT(setValue:forKey:, setValue_forKey),
        SWIZZLE_METHOD_STRUCT(removeObjectForKey:, removeObjectForKey),
        SWIZZLE_METHOD_STRUCT(setObject:forKeyedSubscript:, setObject_forKeyedSubscript),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableDictionary], mutableDictionaySwizzleMethods, sizeof(mutableDictionaySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSSet
    swizzle_method_t setSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(intersectsSet:, intersectsSet),
        SWIZZLE_METHOD_STRUCT(isEqualToSet:, isEqualToSet),
        SWIZZLE_METHOD_STRUCT(isSubsetOfSet:, isSubsetOfSet),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSSet], setSwizzleMethods, sizeof(setSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableSet
    swizzle_method_t mutableSetSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(addObject:, addObject),
        SWIZZLE_METHOD_STRUCT(removeObject:, removeObject),
        SWIZZLE_METHOD_STRUCT(addObjectsFromArray:, addObjectsFromArray),
        SWIZZLE_METHOD_STRUCT(unionSet:, unionSet),
        SWIZZLE_METHOD_STRUCT(intersectSet:, intersectSet),
        SWIZZLE_METHOD_STRUCT(minusSet:, minusSet),
        SWIZZLE_METHOD_STRUCT(setSet:, setSet),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableSet], mutableSetSwizzleMethods, sizeof(mutableSetSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSOrderedSet
    swizzle_method_t orderedSetSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(objectAtIndex:, orderedSet_objectAtIndex),
        SWIZZLE_METHOD_STRUCT(objectsAtIndexes:, orderedSet_objectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(getObjects:range:, orderedSet_getObjects_range),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSOrderedSet], orderedSetSwizzleMethods, sizeof(orderedSetSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableOrderedSet
    swizzle_method_t mutableOrderedSetSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(setObject:atIndex:, orderedSet_setObject_atIndex),
        SWIZZLE_METHOD_STRUCT(addObject:, orderedSet_addObject),
        SWIZZLE_METHOD_STRUCT(addObjects:count:, orderedSet_addObjects_count),
        SWIZZLE_METHOD_STRUCT(insertObject:atIndex:, orderedSet_insertObject_atIndex),
        SWIZZLE_METHOD_STRUCT(insertObjects:atIndexes:, orderedSet_insertObjects_atIndexes),
        SWIZZLE_METHOD_STRUCT(exchangeObjectAtIndex:withObjectAtIndex:, orderedSet_exchangeObjectAtIndex_withObjectAtIndex),
        SWIZZLE_METHOD_STRUCT(moveObjectsAtIndexes:toIndex:, orderedSet_moveObjectsAtIndexes_toIndex),
        SWIZZLE_METHOD_STRUCT(replaceObjectAtIndex:withObject:, orderedSet_replaceObjectAtIndex_withObject),
        SWIZZLE_METHOD_STRUCT(replaceObjectsInRange:withObjects:count:, orderedSet_replaceObjectsInRange_withObjects_count),
        SWIZZLE_METHOD_STRUCT(replaceObjectsAtIndexes:withObjects:, orderedSet_replaceObjectsAtIndexes_withObjects),
        SWIZZLE_METHOD_STRUCT(removeObjectAtIndex:, orderedSet_removeObjectAtIndex),
        SWIZZLE_METHOD_STRUCT(removeObject:, orderedSet_removeObject),
        SWIZZLE_METHOD_STRUCT(removeObjectsInRange:, orderedSet_removeObjectsInRange),
        SWIZZLE_METHOD_STRUCT(removeObjectsAtIndexes:, orderedSet_removeObjectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(removeObjectsInArray:, orderedSet_removeObjectsInArray),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableOrderedSet], mutableOrderedSetSwizzleMethods, sizeof(mutableOrderedSetSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSURL
    swizzle_method_t urlSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(initFileURLWithPath:, url_initFileURLWithPath),
        SWIZZLE_METHOD_STRUCT(initFileURLWithPath:isDirectory:relativeToURL:, url_initFileURLWithPath_isDirectory_relativeToURL),
        SWIZZLE_METHOD_STRUCT(initFileURLWithPath:relativeToURL:, url_initFileURLWithPath_relativeToURL),
        SWIZZLE_METHOD_STRUCT(initFileURLWithPath:isDirectory:, url_initFileURLWithPath_isDirectory),
        SWIZZLE_METHOD_STRUCT(initFileURLWithFileSystemRepresentation:isDirectory:relativeToURL:, url_initFileURLWithFileSystemRepresentation_isDirectory_relativeToURL),
        SWIZZLE_METHOD_STRUCT(initWithString:, url_initWithString),
        SWIZZLE_METHOD_STRUCT(initWithString:relativeToURL:, url_initWithString_relativeToURL),
        SWIZZLE_METHOD_STRUCT(initWithDataRepresentation:relativeToURL:, url_initWithDataRepresentation_relativeToURL),
        SWIZZLE_METHOD_STRUCT(initAbsoluteURLWithDataRepresentation:relativeToURL:, url_initAbsoluteURLWithDataRepresentation_relativeToURL),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSURL], urlSwizzleMethods, sizeof(urlSwizzleMethods) / sizeof(swizzle_method_t));
    
    // CALayer
    swizzle_method_t calayerSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(setPosition:, calayer_setPosition),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeCALayer], calayerSwizzleMethods, sizeof(calayerSwizzleMethods) / sizeof(swizzle_method_t));
    
swizzle_finish:
    for(NSUInteger index = 0; index < clustersCount; index++) {
        if(clusters[index].subClasses != NULL) {
            free(clusters[index].subClasses);
        }
    }
}

#ifdef DEBUG // 暂时不更新咯，但是思路留在这里
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
static void BatchSwizzleForDynamic(void) {
    
    cluster_t clusters[] = {
        [HMDPFoundationTypeNSNumber] = {.aClass = NSNumber.class, .subClasses = NULL },
        [HMDPFoundationTypeNSString] = {.aClass = NSString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableString] = {.aClass = NSMutableString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSAttributeString] = {.aClass = NSAttributedString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableAttributeString] = {.aClass = NSMutableAttributedString.class, .subClasses = NULL },
        [HMDPFoundationTypeNSArray] = {.aClass = NSArray.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableArray] = {.aClass = NSMutableArray.class, .subClasses = NULL },
        [HMDPFoundationTypeNSDictionary] = {.aClass = NSDictionary.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableDictionary] = {.aClass = NSMutableDictionary.class, .subClasses = NULL },
        [HMDPFoundationTypeNSSet] = {.aClass = NSSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableSet] = {.aClass = NSMutableSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSOrderedSet] = {.aClass = NSOrderedSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSMutableOrderedSet] = {.aClass = NSMutableOrderedSet.class, .subClasses = NULL },
        [HMDPFoundationTypeNSURL] = {.aClass = NSURL.class, .subClasses = NULL },
        [HMDPFoundationTypeCALayer] = {.aClass = CALayer.class, .subClasses = NULL },
    };
    
    unsigned int class_count = (sizeof(clusters) / sizeof(cluster_t));
    unsigned int totalClassCount = 0;
    
    //    // 方式1：获取所有匹配的类
    //    Class *class_list = objc_copyClassList(&totalClassCount);
    //    if (totalClassCount == 0 || class_list == NULL) {
    //        return;
    //    }
    //
    //    for (int i = 0; i < totalClassCount; i++) {
    //        Class aClass = class_list[i];
    //        Class superClass = aClass;
    //        // 找子类
    //        // 不能用isKindOfClass，因为__NSMessageBuilder等类不继承NSObject协议
    //        while((superClass = class_getSuperclass(superClass)) != NULL) {
    //            for(unsigned int index = 0; index < class_count; index++) {
    //                cluster_t *cluster = &clusters[index];
    //                if(cluster->aClass == superClass) {
    //                    if(cluster->count >= cluster->size) {
    //                        cluster->subClasses = (Class *)realloc(cluster->subClasses, sizeof(Class) * (cluster->size + STORE_INCREASE));
    //                        if(cluster->subClasses != NULL) {
    //                            cluster->size += STORE_INCREASE;
    //                        }
    //                        else {
    //                            goto swizzle_finish;
    //                        }
    //                    }
    //
    //                    cluster->subClasses[cluster->count++] = aClass;
    //                }
    //            }
    //        }
    //    }
    //
    //    free(class_list);
    //    class_list = NULL;
    //    // 方式1：结束
    
    
    // 方式2：获取Fondation、CoreFoundation中所有的匹配类
    unsigned int foudationClsCount = 0;
    unsigned int coreFoundationClsCount = 0;
    __block const char *foundationImage = NULL;
    __block const char *coreFoundationImage = NULL;
    hmd_enumerate_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        if (image == NULL) {
            return;
        }
        
        if (foundationImage == NULL && hmd_reliable_has_suffix(image->macho_image.name, "Foundation.framework/Foundation")) {
            foundationImage = image->macho_image.name;
        }
        else if (coreFoundationImage == NULL && hmd_reliable_has_suffix(image->macho_image.name, "CoreFoundation.framework/CoreFoundation")) {
            coreFoundationImage = image->macho_image.name;
        }
        
        if (foundationImage != NULL && coreFoundationImage != NULL) {
            *stop = YES;
        }
    });
    
    const char * _Nonnull * _Nullable foundationClsNames = NULL;
    const char * _Nonnull * _Nullable coreFoundationClsNames = NULL;
    if (foundationImage != NULL) {
        foundationClsNames = objc_copyClassNamesForImage(foundationImage, &foudationClsCount);
    } DEBUG_ELSE
    
    if (coreFoundationImage != NULL) {
        coreFoundationClsNames = objc_copyClassNamesForImage(coreFoundationImage, &coreFoundationClsCount);
    } DEBUG_ELSE
    
    totalClassCount = foudationClsCount + coreFoundationClsCount;
    for (int i = 0; i < totalClassCount; i++) {
        const char *className = (i<foudationClsCount) ? foundationClsNames[i] : coreFoundationClsNames[i-foudationClsCount];
        if (className != NULL) {
            Class aClass = objc_lookUpClass(className);
            if (aClass == NULL) {
                continue;
            }
            
            Class superClass = aClass;
            // 找子类
            // 不能用isKindOfClass，因为__NSMessageBuilder等类不继承NSObject协议
            while((superClass = class_getSuperclass(superClass)) != NULL) {
                for(unsigned int index = 0; index < class_count; index++) {
                    cluster_t *cluster = &clusters[index];
                    if(cluster->aClass == superClass) {
                        if(cluster->count >= cluster->size) {
                            cluster->subClasses = (Class *)realloc(cluster->subClasses, sizeof(Class) * (cluster->size + STORE_INCREASE));
                            if(cluster->subClasses != NULL) {
                                cluster->size += STORE_INCREASE;
                            }
                            else {
                                goto swizzle_finish;
                            }
                        }
                        
                        cluster->subClasses[cluster->count++] = aClass;
                    }
                }
            }
        }
    }
    
    free(foundationClsNames);
    free(coreFoundationClsNames);
    
    // 打印所有匹配的类信息
    
    for (int i=0; i<class_count; i++) {
        cluster_t t = clusters[i];
        Class mainClass = t.aClass;
        NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:t.count];
        for (int j=0; j<t.count; j++) {
            [tmpArray addObject:t.subClasses[j]];
        }
        
        NSString *mainStrName = NSStringFromClass(mainClass);
        // Mutable类型包含在不可变类型中，只打印不可变类型即可
        if ([[mainStrName lowercaseString] containsString:@"mutable"]) {
            continue;
        }
        
        [tmpArray sortUsingComparator:^NSComparisonResult(Class  _Nonnull obj1, Class  _Nonnull obj2) {
            return [NSStringFromClass(obj1) compare:NSStringFromClass(obj2)];
        }];
        
        printf("//%s(%d)\n", mainStrName.UTF8String, t.count);
        for (Class subClass in tmpArray) {
            NSString *subClassName = NSStringFromClass(subClass);
            printf("\"%s\",\n", subClassName.UTF8String);
        }
        
        [tmpArray release];
    }
    
    // NSNumber
    swizzle_method_t numberSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(compare:, numberCompare),
        SWIZZLE_METHOD_STRUCT(isEqualToNumber:, isEqualToNumber),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSNumber], numberSwizzleMethods, sizeof(numberSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSString
    swizzle_method_t stringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(characterAtIndex:, characterAtIndex),
        SWIZZLE_METHOD_STRUCT(substringFromIndex:, substringFromIndex),
        SWIZZLE_METHOD_STRUCT(substringToIndex:, substringToIndex),
        SWIZZLE_METHOD_STRUCT(substringWithRange:, substringWithRange),
        SWIZZLE_METHOD_STRUCT(stringByReplacingCharactersInRange:withString:, stringByReplacingCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(stringByAppendingString:, stringByAppendingString),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSString], stringSwizzleMethods, sizeof(stringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableString
    swizzle_method_t mutableStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(appendString:, string_appendString),
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withString:, string_replaceCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(insertString:atIndex:, insertString_atIndex),
        SWIZZLE_METHOD_STRUCT(deleteCharactersInRange:, string_deleteCharactersInRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableString], mutableStringSwizzleMethods, sizeof(mutableStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSAttributeString
    swizzle_method_t attributeStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(initWithString:, initWithString),
        SWIZZLE_METHOD_STRUCT(initWithString:attributes:, initWithString_attributes),
        SWIZZLE_METHOD_STRUCT(attributedSubstringFromRange:, attributedSubstringFromRange),
        SWIZZLE_METHOD_STRUCT(enumerateAttribute:inRange:options:usingBlock:, enumerateAttribute_inRange_options_usingBlock),
        SWIZZLE_METHOD_STRUCT(enumerateAttributesInRange:options:usingBlock:, enumerateAttributesInRange_options_usingBlock),
        SWIZZLE_METHOD_STRUCT(dataFromRange:documentAttributes:error:, dataFromRange_documentAttributes_error),
        SWIZZLE_METHOD_STRUCT(fileWrapperFromRange:documentAttributes:error:, fileWrapperFromRange_documentAttributes_error),
        SWIZZLE_METHOD_STRUCT(containsAttachmentsInRange:, containsAttachmentsInRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSAttributeString], attributeStringSwizzleMethods, sizeof(attributeStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableAttributeString
    swizzle_method_t mutableAttributeStringSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withString:, attributeString_replaceCharactersInRange_withString),
        SWIZZLE_METHOD_STRUCT(deleteCharactersInRange:, attributeString_deleteCharactersInRange),
        SWIZZLE_METHOD_STRUCT(setAttributes:range:, setAttributes_range),
        SWIZZLE_METHOD_STRUCT(addAttribute:value:range:, addAttribute_value_range),
        SWIZZLE_METHOD_STRUCT(addAttributes:range:, addAttributes_range),
        SWIZZLE_METHOD_STRUCT(removeAttribute:range:, removeAttribute_range),
        SWIZZLE_METHOD_STRUCT(insertAttributedString:atIndex:, insertAttributedString_atIndex),
        SWIZZLE_METHOD_STRUCT(replaceCharactersInRange:withAttributedString:, replaceCharactersInRange_withAttributedString),
        SWIZZLE_METHOD_STRUCT(fixAttributesInRange:, fixAttributesInRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableAttributeString], mutableAttributeStringSwizzleMethods, sizeof(mutableAttributeStringSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSArray
    swizzle_method_t arrayClassSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(arrayWithObjects:count:, arrayWithObjects_count),
    };
    swizzleClassMethod(&clusters[HMDPFoundationTypeNSArray], arrayClassSwizzleMethods, sizeof(arrayClassSwizzleMethods) / sizeof(swizzle_method_t));
    
    swizzle_method_t arraySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(objectsAtIndexes:, objectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(objectAtIndex:, objectAtIndex),
        SWIZZLE_METHOD_STRUCT(objectAtIndexedSubscript:, objectAtIndexedSubscript),
        SWIZZLE_METHOD_STRUCT(subarrayWithRange:, subarrayWithRange),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSArray], arraySwizzleMethods, sizeof(arraySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableArray
    swizzle_method_t mutableArraySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(removeObjectAtIndex:, removeObjectAtIndex),
        SWIZZLE_METHOD_STRUCT(removeObjectsInRange:, removeObjectsInRange),
        SWIZZLE_METHOD_STRUCT(removeObjectsAtIndexes:, removeObjectsAtIndexes),
        SWIZZLE_METHOD_STRUCT(insertObject:atIndex:, insertObject_atIndex),
        SWIZZLE_METHOD_STRUCT(insertObjects:atIndexes:, insertObjects_atIndexes),
        SWIZZLE_METHOD_STRUCT(replaceObjectAtIndex:withObject:, replaceObjectAtIndex_withObject),
        SWIZZLE_METHOD_STRUCT(replaceObjectsAtIndexes:withObjects:, replaceObjectsAtIndexes_withObjects),
        SWIZZLE_METHOD_STRUCT(replaceObjectsInRange:withObjectsFromArray:, replaceObjectsInRange_withObjectsFromArray),
        SWIZZLE_METHOD_STRUCT(replaceObjectsInRange:withObjectsFromArray:range:, replaceObjectsInRange_withObjectsFromArray_range),
        SWIZZLE_METHOD_STRUCT(setObject:atIndexedSubscript:, setObject_atIndexedSubscript),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableArray], mutableArraySwizzleMethods, sizeof(mutableArraySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSDictionary
    swizzle_method_t dictionayClassSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(dictionaryWithObjects:forKeys:, dictionaryWithObjects_forKeys),
        SWIZZLE_METHOD_STRUCT(dictionaryWithObjects:forKeys:count:, dictionaryWithObjects_forKeys_count),
    };
    swizzleClassMethod(&clusters[HMDPFoundationTypeNSDictionary], dictionayClassSwizzleMethods, sizeof(dictionayClassSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableDictionary
    swizzle_method_t mutableDictionaySwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(setObject:forKey:, setObject_forKey),
        SWIZZLE_METHOD_STRUCT(setValue:forKey:, setValue_forKey),
        SWIZZLE_METHOD_STRUCT(removeObjectForKey:, removeObjectForKey),
        SWIZZLE_METHOD_STRUCT(setObject:forKeyedSubscript:, setObject_forKeyedSubscript),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableDictionary], mutableDictionaySwizzleMethods, sizeof(mutableDictionaySwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSSet
    swizzle_method_t setSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(intersectsSet:, intersectsSet),
        SWIZZLE_METHOD_STRUCT(isEqualToSet:, isEqualToSet),
        SWIZZLE_METHOD_STRUCT(isSubsetOfSet:, isSubsetOfSet),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSSet], setSwizzleMethods, sizeof(setSwizzleMethods) / sizeof(swizzle_method_t));
    
    // NSMutableSet
    swizzle_method_t mutableSetSwizzleMethods[] = {
        SWIZZLE_METHOD_STRUCT(addObject:, addObject),
        SWIZZLE_METHOD_STRUCT(removeObject:, removeObject),
        SWIZZLE_METHOD_STRUCT(addObjectsFromArray:, addObjectsFromArray),
        SWIZZLE_METHOD_STRUCT(unionSet:, unionSet),
        SWIZZLE_METHOD_STRUCT(intersectSet:, intersectSet),
        SWIZZLE_METHOD_STRUCT(minusSet:, minusSet),
        SWIZZLE_METHOD_STRUCT(setSet:, setSet),
    };
    swizzleInstanceMethod(&clusters[HMDPFoundationTypeNSMutableSet], mutableSetSwizzleMethods, sizeof(mutableSetSwizzleMethods) / sizeof(swizzle_method_t));
    
swizzle_finish:
    for(NSUInteger index = 0; index < class_count; index++) {
        if(clusters[index].subClasses != NULL) {
            free(clusters[index].subClasses);
        }
    }
}
CLANG_DIAGNOSTIC_POP
#endif
