//
//  HMDTaggedPointerAnalyzer.m
//  iOS
//
//  Created by sunrunwang on 2022/11/16.
//

#pragma mark - Declaration

#pragma mark include and import

#include <dlfcn.h>
#include <stdint.h>
#include <stdbool.h>
#import <objc/objc.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "HMDMacro.h"
#import "HMDTaggedPointerAnalyzer.h"

#pragma mark imported macro

#if !__LP64__
#   define SUPPORT_TAGGED_POINTERS 0
#else
#   define SUPPORT_TAGGED_POINTERS 1
#endif

#if !SUPPORT_TAGGED_POINTERS  || ((TARGET_OS_OSX || TARGET_OS_MACCATALYST) && __x86_64__)
#   define SUPPORT_MSB_TAGGED_POINTERS 0
#else
#   define SUPPORT_MSB_TAGGED_POINTERS 1
#endif

#if (TARGET_OS_OSX || TARGET_OS_MACCATALYST) && __x86_64__
    // 64-bit Mac - tag bit is LSB
#   define OBJC_MSB_TAGGED_POINTERS 0
#else
    // Everything else - tag bit is MSB
#   define OBJC_MSB_TAGGED_POINTERS 1
#endif

#if __arm64__
// ARM64 uses a new tagged pointer scheme where normal tags are in
// the low bits, extended tags are in the high bits, and half of the
// extended tag space is reserved for unobfuscated payloads.
#   define OBJC_SPLIT_TAGGED_POINTERS 1
#else
#   define OBJC_SPLIT_TAGGED_POINTERS 0
#endif

#define _OBJC_TAG_INDEX_MASK 0x7UL

#if OBJC_SPLIT_TAGGED_POINTERS
#define _OBJC_TAG_SLOT_COUNT 8
#define _OBJC_TAG_SLOT_MASK 0x7UL
#else
// array slot includes the tag bit itself
#define _OBJC_TAG_SLOT_COUNT 16
#define _OBJC_TAG_SLOT_MASK 0xfUL
#endif

#define _OBJC_TAG_EXT_INDEX_MASK 0xff
// array slot has no extra bits
#define _OBJC_TAG_EXT_SLOT_COUNT 256
#define _OBJC_TAG_EXT_SLOT_MASK 0xff

#if OBJC_SPLIT_TAGGED_POINTERS
#   define _OBJC_TAG_MASK (1UL<<63)
#   define _OBJC_TAG_INDEX_SHIFT 0
#   define _OBJC_TAG_SLOT_SHIFT 0
#   define _OBJC_TAG_PAYLOAD_LSHIFT 1
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK (_OBJC_TAG_MASK | 0x7UL)
#   define _OBJC_TAG_NO_OBFUSCATION_MASK ((1UL<<62) | _OBJC_TAG_EXT_MASK)
#   define _OBJC_TAG_CONSTANT_POINTER_MASK \
        ~(_OBJC_TAG_EXT_MASK | ((uintptr_t)_OBJC_TAG_EXT_SLOT_MASK << _OBJC_TAG_EXT_SLOT_SHIFT))
#   define _OBJC_TAG_EXT_INDEX_SHIFT 55
#   define _OBJC_TAG_EXT_SLOT_SHIFT 55
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 9
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#elif OBJC_MSB_TAGGED_POINTERS
#   define _OBJC_TAG_MASK (1UL<<63)
#   define _OBJC_TAG_INDEX_SHIFT 60
#   define _OBJC_TAG_SLOT_SHIFT 60
#   define _OBJC_TAG_PAYLOAD_LSHIFT 4
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK (0xfUL<<60)
#   define _OBJC_TAG_EXT_INDEX_SHIFT 52
#   define _OBJC_TAG_EXT_SLOT_SHIFT 52
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 12
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#else
#   define _OBJC_TAG_MASK 1UL
#   define _OBJC_TAG_INDEX_SHIFT 1
#   define _OBJC_TAG_SLOT_SHIFT 0
#   define _OBJC_TAG_PAYLOAD_LSHIFT 0
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK 0xfUL
#   define _OBJC_TAG_EXT_INDEX_SHIFT 4
#   define _OBJC_TAG_EXT_SLOT_SHIFT 4
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 0
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#endif

typedef uint16_t objc_tag_index_t;
enum {
    // 60-bit payloads
    OBJC_TAG_NSAtom            = 0,
    OBJC_TAG_1                 = 1,
    OBJC_TAG_NSString          = 2,
    OBJC_TAG_NSNumber          = 3,
    OBJC_TAG_NSIndexPath       = 4,
    OBJC_TAG_NSManagedObjectID = 5,
    OBJC_TAG_NSDate            = 6,

    // 60-bit reserved
    OBJC_TAG_RESERVED_7        = 7,

    // 52-bit payloads
    OBJC_TAG_Photos_1          = 8,
    OBJC_TAG_Photos_2          = 9,
    OBJC_TAG_Photos_3          = 10,
    OBJC_TAG_Photos_4          = 11,
    OBJC_TAG_XPC_1             = 12,
    OBJC_TAG_XPC_2             = 13,
    OBJC_TAG_XPC_3             = 14,
    OBJC_TAG_XPC_4             = 15,
    OBJC_TAG_NSColor           = 16,
    OBJC_TAG_UIColor           = 17,
    OBJC_TAG_CGColor           = 18,
    OBJC_TAG_NSIndexSet        = 19,
    OBJC_TAG_NSMethodSignature = 20,
    OBJC_TAG_UTTypeRecord      = 21,

    // When using the split tagged pointer representation
    // (OBJC_SPLIT_TAGGED_POINTERS), this is the first tag where
    // the tag and payload are unobfuscated. All tags from here to
    // OBJC_TAG_Last52BitPayload are unobfuscated. The shared cache
    // builder is able to construct these as long as the low bit is
    // not set (i.e. even-numbered tags).
    OBJC_TAG_FirstUnobfuscatedSplitTag = 136, // 128 + 8, first ext tag with high bit set

    OBJC_TAG_Constant_CFString = 136,

    OBJC_TAG_First60BitPayload = 0,
    OBJC_TAG_Last60BitPayload  = 6,
    OBJC_TAG_First52BitPayload = 8,
    OBJC_TAG_Last52BitPayload  = 263,

    OBJC_TAG_RESERVED_264      = 264
};

#define objc_tag_classes objc_debug_taggedpointer_classes
#define objc_tag_ext_classes objc_debug_taggedpointer_ext_classes

#pragma mark macro definition

#if !__has_feature(objc_arc)
#error HMDTaggedPointerAnalyzer must be compiled in ARC
#endif

#define _HMD_OBJC_DEBUG_TAG60_PERMUTATIONS_COUNT 8

#define HMDTaggedPointerAnalyzerNotDecided ((void *)(0x0))
#define HMDTaggedPointerAnalyzerNotExist   ((void *)(0x1))

#if OBJC_SPLIT_TAGGED_POINTERS
#define try_fetch_objc_debug_tag60_permutations_if_needed() fetch_objc_debug_tag60_permutations()
#else
#define try_fetch_objc_debug_tag60_permutations_if_needed() HMDTPAStatusFetched
#endif

#pragma mark type definition

typedef enum : uint8_t {
    HMDTPAStatusUnknown,
    HMDTPAStatusNotExist,
    HMDTPAStatusFetched,
    
    HMDTPAStatusImpossible
} HMDTPAStatus;

#pragma mark static function declaration

#if !HMD_APPSTORE_REVIEW_FIXUP
static void * _Nullable openObjcDylib(void);
static NSString * _Nullable objcDylibPath(void);
#endif
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
static void * _Nullable addressFetch(NSString *symbolName);
static NSString * _Nullable decodeBase64String(NSString * _Nonnull encodedDomain);

static HMDTPAStatus fetch_objc_debug_taggedpointer_mask(void);
static NSString * _Nullable symbol_objc_debug_taggedpointer_mask(void);

static HMDTPAStatus fetch_objc_debug_taggedpointer_obfuscator(void);
static NSString * _Nullable symbol_objc_debug_taggedpointer_obfuscator(void);

#if OBJC_SPLIT_TAGGED_POINTERS
static HMDTPAStatus fetch_objc_debug_tag60_permutations(void);
static NSString * _Nullable symbol_objc_debug_tag60_permutations(void);
#endif

static HMDTPAStatus fetch_objc_debug_taggedpointer_classes(void);
static NSString * _Nullable symbol_objc_debug_taggedpointer_classes(void);

static HMDTPAStatus fetch_objc_debug_taggedpointer_ext_classes(void);
static NSString * _Nullable symbol_objc_debug_taggedpointer_ext_classes(void);

static uintptr_t _objc_decodeTaggedPointer(const void * _Nullable ptr);
static uintptr_t _objc_decodeTaggedPointer_noPermute(const void * _Nullable ptr);
static HMDUnsafeClass _Nullable * _Nullable classSlotForTagIndex(objc_tag_index_t tag);
static HMDUnsafeClass _Nullable * _Nullable classSlotForBasicTagIndex(objc_tag_index_t tag);
static HMDUnsafeClass _Nullable _objc_getClassForTag(objc_tag_index_t tag);
static objc_tag_index_t _objc_getTaggedPointerTag(const void * _Nullable ptr);

#if OBJC_SPLIT_TAGGED_POINTERS
static uintptr_t _objc_obfuscatedTagToBasicTag(uintptr_t tag);
static uintptr_t _objc_basicTagToObfuscatedTag(uintptr_t tag);
#endif
CLANG_DIAGNOSTIC_POP

#pragma mark static variable
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE
static HMDTPAStatus analyzerInitializationStatus = HMDTPAStatusUnknown;

static HMDTPAStatus status_objc_debug_taggedpointer_mask = HMDTPAStatusUnknown;
static uintptr_t objc_debug_taggedpointer_mask;

static HMDTPAStatus status_objc_debug_taggedpointer_obfuscator = HMDTPAStatusUnknown;
static uintptr_t objc_debug_taggedpointer_obfuscator;

#if OBJC_SPLIT_TAGGED_POINTERS
static HMDTPAStatus status_objc_debug_tag60_permutations = HMDTPAStatusUnknown;
static uint8_t objc_debug_tag60_permutations[_HMD_OBJC_DEBUG_TAG60_PERMUTATIONS_COUNT];
#endif

static HMDTPAStatus status_objc_debug_taggedpointer_classes = HMDTPAStatusUnknown;
static HMDUnsafeClass _Nullable objc_debug_taggedpointer_classes[_OBJC_TAG_SLOT_COUNT];

static HMDTPAStatus status_objc_debug_taggedpointer_ext_classes = HMDTPAStatusUnknown;
static HMDUnsafeClass _Nullable objc_debug_taggedpointer_ext_classes[_OBJC_TAG_EXT_SLOT_COUNT];
CLANG_DIAGNOSTIC_POP

#if HMD_APPSTORE_REVIEW_FIXUP
#pragma mark - Public Interface (HMD_APPSTORE_REVIEW_FIXUP)

bool HMDTaggedPointerAnalyzer_initialization(void) {
    return true;
}

bool HMDTaggedPointerAnalyzer_isInitialized(void) {
    return true;
}

bool HMDTaggedPointerAnalyzer_isTaggedPointer(const HMDUnsafeObject _Nullable object) {
    return ((uintptr_t)object & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

HMDUnsafeClass _Nullable HMDTaggedPointerAnalyzer_taggedPointerGetClass(const HMDUnsafeObject _Nullable object) {
    return NULL;
}

#else /* HMD_APPSTORE_REVIEW_FIXUP */
#pragma mark - Public Interface

//bool HMDTaggedPointerAnalyzer_initialization(void) {
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&analyzerInitializationStatus, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        if(fetch_objc_debug_taggedpointer_mask() == HMDTPAStatusFetched) {
//            if(fetch_objc_debug_taggedpointer_obfuscator() == HMDTPAStatusFetched) {
//                if(try_fetch_objc_debug_tag60_permutations_if_needed() == HMDTPAStatusFetched) {
//                    if(fetch_objc_debug_taggedpointer_classes() == HMDTPAStatusFetched) {
//                        if(fetch_objc_debug_taggedpointer_ext_classes() == HMDTPAStatusFetched) {
//                            currentStatus = HMDTPAStatusFetched;
//                        } DEBUG_ELSE
//                    } DEBUG_ELSE
//                } DEBUG_ELSE
//            } DEBUG_ELSE
//        } DEBUG_ELSE
//
//        if(currentStatus != HMDTPAStatusFetched)
//           currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&analyzerInitializationStatus, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//
//    return currentStatus == HMDTPAStatusFetched;
//}
//
//bool HMDTaggedPointerAnalyzer_isInitialized(void) {
//    return __atomic_load_n(&analyzerInitializationStatus, __ATOMIC_ACQUIRE) == HMDTPAStatusFetched;
//}
//
//bool HMDTaggedPointerAnalyzer_isTaggedPointer(const HMDUnsafeObject _Nullable object) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    if(object == NULL) return false;
//    uintptr_t rawPointer = (uintptr_t)object;
//
//    return (rawPointer & objc_debug_taggedpointer_mask) != 0;
//}
//
//HMDUnsafeClass _Nullable HMDTaggedPointerAnalyzer_taggedPointerGetClass(const HMDUnsafeObject _Nullable object) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    if(HMDTaggedPointerAnalyzer_isTaggedPointer(object)) {
//        objc_tag_index_t tag = _objc_getTaggedPointerTag(object);
//        return _objc_getClassForTag(tag);
//    }
//    return NULL;
//}
#endif /* HMD_APPSTORE_REVIEW_FIXUP */

#pragma mark - Private Method

//static HMDUnsafeClass _Nullable _objc_getClassForTag(objc_tag_index_t tag) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    HMDUnsafeClass * _Nullable slot = classSlotForTagIndex(tag);
//    if (slot != NULL) return slot[0];
//    else return NULL;
//}
//
//static HMDUnsafeClass _Nullable * _Nullable classSlotForTagIndex(objc_tag_index_t tag) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    if (tag >= OBJC_TAG_First60BitPayload && tag <= OBJC_TAG_Last60BitPayload) {
//        return classSlotForBasicTagIndex(tag);
//    }
//
//    if (tag >= OBJC_TAG_First52BitPayload && tag <= OBJC_TAG_Last52BitPayload) {
//        COMPILE_ASSERT(OBJC_TAG_Last52BitPayload > OBJC_TAG_First52BitPayload);
//        COMPILE_ASSERT(OBJC_TAG_Last52BitPayload - OBJC_TAG_First52BitPayload < _OBJC_TAG_EXT_SLOT_COUNT);
//
//        int index = tag - OBJC_TAG_First52BitPayload;
//#if OBJC_SPLIT_TAGGED_POINTERS
//        if (tag >= OBJC_TAG_FirstUnobfuscatedSplitTag)
//            return &objc_tag_ext_classes[index];
//#endif
//        uintptr_t tagObfuscator = ((objc_debug_taggedpointer_obfuscator
//                                    >> _OBJC_TAG_EXT_INDEX_SHIFT)
//                                   & _OBJC_TAG_EXT_INDEX_MASK);
//
//        COMPILE_ASSERT(_OBJC_TAG_EXT_INDEX_MASK < _OBJC_TAG_EXT_SLOT_COUNT);
//
//        return &objc_tag_ext_classes[index ^ tagObfuscator];
//    }
//
//    return NULL;
//}
//
//static HMDUnsafeClass _Nullable * _Nullable classSlotForBasicTagIndex(objc_tag_index_t tag) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    if(tag >= _OBJC_TAG_SLOT_COUNT) DEBUG_RETURN(NULL);
//
//#if OBJC_SPLIT_TAGGED_POINTERS
//    uintptr_t obfuscatedTag = _objc_basicTagToObfuscatedTag(tag);
//    if(obfuscatedTag < _OBJC_TAG_SLOT_COUNT) {
//        return &objc_tag_classes[obfuscatedTag];
//    } ELSE_DEBUG_RETURN(NULL);
//#else
//    uintptr_t tagObfuscator = ((objc_debug_taggedpointer_obfuscator
//                                >> _OBJC_TAG_INDEX_SHIFT)
//                               & _OBJC_TAG_INDEX_MASK);
//
//    COMPILE_ASSERT(_OBJC_TAG_INDEX_MASK < _OBJC_TAG_SLOT_COUNT);
//    COMPILE_ASSERT(0xF < _OBJC_TAG_SLOT_COUNT);
//    COMPILE_ASSERT(0x8 < _OBJC_TAG_SLOT_COUNT);
//
//    uintptr_t obfuscatedTag = tag ^ tagObfuscator;
//
//    // Array index in objc_tag_classes includes the tagged bit itself
//#   if SUPPORT_MSB_TAGGED_POINTERS
//    uintptr_t index = 0x8 | obfuscatedTag;
//#   else
//    uintptr_t index = (obfuscatedTag << 1) | 1;
//#   endif
//    return &objc_tag_classes[index];
//#endif
//}
//
//#if OBJC_SPLIT_TAGGED_POINTERS
//static uintptr_t _objc_basicTagToObfuscatedTag(uintptr_t tag) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//    if(tag >= _HMD_OBJC_DEBUG_TAG60_PERMUTATIONS_COUNT) DEBUG_RETURN(0);
//
//    uintptr_t result = objc_debug_tag60_permutations[tag];
//    DEBUG_ASSERT(result < _OBJC_TAG_SLOT_COUNT);
//
//    return result;
//}
//#endif
//
//// should be called if objc_debug_tag60_permutations fetched
//#if OBJC_SPLIT_TAGGED_POINTERS
//static uintptr_t _objc_obfuscatedTagToBasicTag(uintptr_t tag) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    DEBUG_ASSERT(fetch_objc_debug_tag60_permutations() == HMDTPAStatusFetched);
//    for (unsigned i = 0; i < 7; i++)
//        if (objc_debug_tag60_permutations[i] == tag)
//            return i;
//    return 7;
//}
//#endif
//
//static objc_tag_index_t _objc_getTaggedPointerTag(const void * _Nullable ptr) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isTaggedPointer((const HMDUnsafeObject _Nullable)ptr));
//
//    uintptr_t value = _objc_decodeTaggedPointer(ptr);
//    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
//    uintptr_t extTag =   (value >> _OBJC_TAG_EXT_INDEX_SHIFT) & _OBJC_TAG_EXT_INDEX_MASK;
//    if (basicTag == _OBJC_TAG_INDEX_MASK) {
//        return (objc_tag_index_t)(extTag + OBJC_TAG_First52BitPayload);
//    } else {
//        return (objc_tag_index_t)basicTag;
//    }
//}
//
//static uintptr_t _objc_decodeTaggedPointer(const void * _Nullable ptr) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    uintptr_t value = _objc_decodeTaggedPointer_noPermute(ptr);
//#if OBJC_SPLIT_TAGGED_POINTERS
//    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
//    value &= ~(_OBJC_TAG_INDEX_MASK << _OBJC_TAG_INDEX_SHIFT);
//    value |= _objc_obfuscatedTagToBasicTag(basicTag) << _OBJC_TAG_INDEX_SHIFT;
//#endif
//    return value;
//}
//
//static uintptr_t _objc_decodeTaggedPointer_noPermute(const void * _Nullable ptr) {
//    DEBUG_ASSERT(HMDTaggedPointerAnalyzer_isInitialized());
//
//    uintptr_t value = (uintptr_t)ptr;
//#if OBJC_SPLIT_TAGGED_POINTERS
//    if ((value & _OBJC_TAG_NO_OBFUSCATION_MASK) == _OBJC_TAG_NO_OBFUSCATION_MASK)
//        return value;
//#endif
//    return value ^ objc_debug_taggedpointer_obfuscator;
//}
//
//#pragma mark - Address Fetch
//
//#pragma mark for each address
//
//static HMDTPAStatus fetch_objc_debug_taggedpointer_obfuscator(void) {
//
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&status_objc_debug_taggedpointer_obfuscator, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        void * _Nullable symbolAddress = NULL;
//
//        NSString *symbolName;
//        if((symbolName = symbol_objc_debug_taggedpointer_obfuscator()) != nil) {
//            symbolAddress = addressFetch(symbolName);
//        } DEBUG_ELSE
//
//        if(symbolAddress != NULL) {
//
//            currentStatus = HMDTPAStatusFetched;
//            uintptr_t * _Nonnull address_objc_debug_taggedpointer_obfuscator = symbolAddress;
//            objc_debug_taggedpointer_obfuscator = address_objc_debug_taggedpointer_obfuscator[0];
//
//        } else currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&status_objc_debug_taggedpointer_obfuscator, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//    return currentStatus;
//}
//
//static HMDTPAStatus fetch_objc_debug_taggedpointer_mask(void) {
//
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&status_objc_debug_taggedpointer_mask, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        void * _Nullable symbolAddress = NULL;
//
//        NSString *symbolName;
//        if((symbolName = symbol_objc_debug_taggedpointer_mask()) != nil) {
//            symbolAddress = addressFetch(symbolName);
//        } DEBUG_ELSE
//
//        if(symbolAddress != NULL) {
//
//            currentStatus = HMDTPAStatusFetched;
//            uintptr_t * _Nonnull address_objc_debug_taggedpointer_mask = symbolAddress;
//            objc_debug_taggedpointer_mask = address_objc_debug_taggedpointer_mask[0];
//
//        } else currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&status_objc_debug_taggedpointer_mask, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//    return currentStatus;
//}
//
//#if OBJC_SPLIT_TAGGED_POINTERS
//static HMDTPAStatus fetch_objc_debug_tag60_permutations(void) {
//
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&status_objc_debug_tag60_permutations, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        void * _Nullable symbolAddress = NULL;
//
//        NSString *symbolName;
//        if((symbolName = symbol_objc_debug_tag60_permutations()) != nil) {
//            symbolAddress = addressFetch(symbolName);
//        } DEBUG_ELSE
//
//        if(symbolAddress != NULL) {
//
//            currentStatus = HMDTPAStatusFetched;
//            uint8_t * _Nonnull address_objc_debug_tag60_permutations = symbolAddress;
//
//            for(NSUInteger index = 0; index < _HMD_OBJC_DEBUG_TAG60_PERMUTATIONS_COUNT; index++)
//                objc_debug_tag60_permutations[index] = address_objc_debug_tag60_permutations[index];
//
//        } else currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&status_objc_debug_tag60_permutations, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//    return currentStatus;
//}
//#endif
//
//static HMDTPAStatus fetch_objc_debug_taggedpointer_classes(void) {
//
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&status_objc_debug_taggedpointer_classes, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        void * _Nullable symbolAddress = NULL;
//
//        NSString *symbolName;
//        if((symbolName = symbol_objc_debug_taggedpointer_classes()) != nil) {
//            symbolAddress = addressFetch(symbolName);
//        } DEBUG_ELSE
//
//        if(symbolAddress != NULL) {
//
//            currentStatus = HMDTPAStatusFetched;
//            void * _Nullable * _Nonnull address_objc_debug_taggedpointer_classes = symbolAddress;
//
//            for(NSUInteger index = 0; index < _OBJC_TAG_SLOT_COUNT; index++)
//                objc_debug_taggedpointer_classes[index] = address_objc_debug_taggedpointer_classes[index];
//
//        } else currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&status_objc_debug_taggedpointer_classes, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//    return currentStatus;
//}
//
//static HMDTPAStatus fetch_objc_debug_taggedpointer_ext_classes(void) {
//
//    HMDTPAStatus currentStatus;
//    if((currentStatus = __atomic_load_n(&status_objc_debug_taggedpointer_ext_classes, __ATOMIC_ACQUIRE)) == HMDTPAStatusUnknown) {
//
//        void * _Nullable symbolAddress = NULL;
//
//        NSString *symbolName;
//        if((symbolName = symbol_objc_debug_taggedpointer_ext_classes()) != nil) {
//            symbolAddress = addressFetch(symbolName);
//        } DEBUG_ELSE
//
//        if(symbolAddress != NULL) {
//
//            currentStatus = HMDTPAStatusFetched;
//            void * _Nullable * _Nonnull address_objc_debug_taggedpointer_ext_classes = symbolAddress;
//
//            for(NSUInteger index = 0; index < _OBJC_TAG_EXT_SLOT_COUNT; index++)
//                objc_debug_taggedpointer_ext_classes[index] = address_objc_debug_taggedpointer_ext_classes[index];
//
//        } else currentStatus = HMDTPAStatusNotExist;
//
//        __atomic_store_n(&status_objc_debug_taggedpointer_ext_classes, currentStatus, __ATOMIC_RELEASE);
//    }
//
//    DEBUG_ASSERT(currentStatus < HMDTPAStatusImpossible);
//    DEBUG_ASSERT(currentStatus != HMDTPAStatusUnknown);
//    return currentStatus;
//}
//
//#pragma mark shared fetch
//
//static void * _Nullable addressFetch(NSString *symbolName) {
//    const char * rawSymbolName = symbolName.UTF8String;
//    if(rawSymbolName == NULL) DEBUG_RETURN(NULL);
//
//    void * _Nullable lib;
//    void * _Nullable address = NULL;
//
//
//#if HMD_APPSTORE_REVIEW_FIXUP
//    lib = RTLD_NEXT;
//#else
//    lib = openObjcDylib();
//    if(lib == NULL) DEBUG_RETURN(NULL);
//#endif
//
//    address = dlsym(lib, rawSymbolName);
//
//    DEBUG_ASSERT(address != NULL);
//    return address;
//}
//
//#pragma mark - Symbol Name base64 encoded
//
//static NSString * _Nullable symbol_objc_debug_taggedpointer_mask(void) {
//    NSString * _Nonnull result = decodeBase64String(@"b2JqY19kZWJ1Z190YWdnZWRwb2ludGVyX21hc2s=");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "objc_debug_taggedpointer_mask") == 0);
//    return result;
//}
//
//static NSString * _Nullable symbol_objc_debug_taggedpointer_obfuscator(void) {
//    NSString * _Nonnull result = decodeBase64String(@"b2JqY19kZWJ1Z190YWdnZWRwb2ludGVyX29iZnVzY2F0b3I=");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "objc_debug_taggedpointer_obfuscator") == 0);
//    return result;
//}
//
//#if OBJC_SPLIT_TAGGED_POINTERS
//static NSString * _Nullable symbol_objc_debug_tag60_permutations(void) {
//    NSString * _Nonnull result = decodeBase64String(@"b2JqY19kZWJ1Z190YWc2MF9wZXJtdXRhdGlvbnM=");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "objc_debug_tag60_permutations") == 0);
//    return result;
//}
//#endif
//
//static NSString * _Nullable symbol_objc_debug_taggedpointer_classes(void) {
//    NSString * _Nonnull result = decodeBase64String(@"b2JqY19kZWJ1Z190YWdnZWRwb2ludGVyX2NsYXNzZXM=");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "objc_debug_taggedpointer_classes") == 0);
//    return result;
//}
//
//static NSString * _Nullable symbol_objc_debug_taggedpointer_ext_classes(void) {
//    NSString * _Nonnull result = decodeBase64String(@"b2JqY19kZWJ1Z190YWdnZWRwb2ludGVyX2V4dF9jbGFzc2Vz");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "objc_debug_taggedpointer_ext_classes") == 0);
//    return result;
//}
//
//#if !HMD_APPSTORE_REVIEW_FIXUP
//static NSString * _Nullable objcDylibPath(void) {
//    NSString * _Nonnull result = decodeBase64String(@"L3Vzci9saWIvbGlib2JqYy5BLmR5bGli");
//    DEBUG_ASSERT(strcmp(result.UTF8String, "/usr/lib/libobjc.A.dylib") == 0);
//    return result;
//}
//#endif
//
//#pragma mark - objc.A.dylib support
//
//#if !HMD_APPSTORE_REVIEW_FIXUP
//static void * _Nullable openObjcDylib(void) {
//
//    static void * _Nullable sharedObjcDylib = HMDTaggedPointerAnalyzerNotDecided;
//
//    void * _Nullable currentObjcDylib;
//    if((currentObjcDylib = __atomic_load_n(&sharedObjcDylib, __ATOMIC_ACQUIRE)) == HMDTaggedPointerAnalyzerNotDecided) {
//
//        NSString * _Nullable queryObjcDylibPath = objcDylibPath();
//        if(queryObjcDylibPath != nil) {
//
//            /* 我知道开一个动态库, 还需要配对的 dclose 关闭
//               但是这个是 libobjc.A.dylib 无所谓咯 (摊) */
//
//            void *queryObjcDylib = dlopen(queryObjcDylibPath.UTF8String, RTLD_LAZY | RTLD_NOLOAD);
//            DEBUG_ASSERT(queryObjcDylib != NULL);
//
//            if(queryObjcDylib == NULL)
//                 currentObjcDylib = HMDTaggedPointerAnalyzerNotExist;
//            else currentObjcDylib = queryObjcDylib;
//
//            __atomic_store_n(&sharedObjcDylib, currentObjcDylib, __ATOMIC_RELEASE);
//        } DEBUG_ELSE
//    }
//
//    DEBUG_ASSERT(currentObjcDylib != HMDTaggedPointerAnalyzerNotDecided);
//    DEBUG_ASSERT(__atomic_load_n(&sharedObjcDylib, __ATOMIC_ACQUIRE) != HMDTaggedPointerAnalyzerNotDecided);
//
//    if(currentObjcDylib == HMDTaggedPointerAnalyzerNotExist) return NULL;
//
//    return currentObjcDylib;
//}
//#endif
//
//static NSString * _Nullable decodeBase64String(NSString * _Nonnull encodedDomain) {
//    DEBUG_ASSERT(encodedDomain != nil);
//    if(encodedDomain == nil) DEBUG_RETURN(nil);
//
//    NSData *data = [[NSData alloc] initWithBase64EncodedString:encodedDomain
//                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    NSString *domainString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    DEBUG_ASSERT(domainString != nil);
//    return domainString;
//}
