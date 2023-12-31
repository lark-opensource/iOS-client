//
//  GAIAEngine.h
//  Pods-Gaia
//
//  Created by 李琢鹏 on 2019/1/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef __FILE_NAME__
#define _STRRCHR_IMPL_COMMON(str, ch, offset) (str)[sizeof((str)) - 1 - (offset)] == (ch)? (str) + sizeof((str)) - (offset): sizeof((str)) <= (offset) + 1? (str)

#define _STRRCHR_IMPL_31(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 31): (str))
#define _STRRCHR_IMPL_30(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 30): _STRRCHR_IMPL_31(str, ch))
#define _STRRCHR_IMPL_29(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 29): _STRRCHR_IMPL_30(str, ch))
#define _STRRCHR_IMPL_28(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 28): _STRRCHR_IMPL_29(str, ch))
#define _STRRCHR_IMPL_27(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 27): _STRRCHR_IMPL_28(str, ch))
#define _STRRCHR_IMPL_26(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 26): _STRRCHR_IMPL_27(str, ch))
#define _STRRCHR_IMPL_25(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 25): _STRRCHR_IMPL_26(str, ch))
#define _STRRCHR_IMPL_24(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 24): _STRRCHR_IMPL_25(str, ch))
#define _STRRCHR_IMPL_23(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 23): _STRRCHR_IMPL_24(str, ch))
#define _STRRCHR_IMPL_22(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 22): _STRRCHR_IMPL_23(str, ch))
#define _STRRCHR_IMPL_21(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 21): _STRRCHR_IMPL_22(str, ch))
#define _STRRCHR_IMPL_20(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 20): _STRRCHR_IMPL_21(str, ch))
#define _STRRCHR_IMPL_19(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 19): _STRRCHR_IMPL_20(str, ch))
#define _STRRCHR_IMPL_18(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 18): _STRRCHR_IMPL_19(str, ch))
#define _STRRCHR_IMPL_17(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 17): _STRRCHR_IMPL_18(str, ch))
#define _STRRCHR_IMPL_16(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 16): _STRRCHR_IMPL_17(str, ch))
#define _STRRCHR_IMPL_15(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 15): _STRRCHR_IMPL_16(str, ch))
#define _STRRCHR_IMPL_14(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 14): _STRRCHR_IMPL_15(str, ch))
#define _STRRCHR_IMPL_13(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 13): _STRRCHR_IMPL_14(str, ch))
#define _STRRCHR_IMPL_12(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 12): _STRRCHR_IMPL_13(str, ch))
#define _STRRCHR_IMPL_11(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 11): _STRRCHR_IMPL_12(str, ch))
#define _STRRCHR_IMPL_10(str, ch) (_STRRCHR_IMPL_COMMON(str, ch, 10): _STRRCHR_IMPL_11(str, ch))
#define _STRRCHR_IMPL_9(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 9):  _STRRCHR_IMPL_10(str, ch))
#define _STRRCHR_IMPL_8(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 8):  _STRRCHR_IMPL_9(str, ch))
#define _STRRCHR_IMPL_7(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 7):  _STRRCHR_IMPL_8(str, ch))
#define _STRRCHR_IMPL_6(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 6):  _STRRCHR_IMPL_7(str, ch))
#define _STRRCHR_IMPL_5(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 5):  _STRRCHR_IMPL_6(str, ch))
#define _STRRCHR_IMPL_4(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 4):  _STRRCHR_IMPL_5(str, ch))
#define _STRRCHR_IMPL_3(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 3):  _STRRCHR_IMPL_4(str, ch))
#define _STRRCHR_IMPL_2(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 2):  _STRRCHR_IMPL_3(str, ch))
#define _STRRCHR_IMPL_1(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 1):  _STRRCHR_IMPL_2(str, ch))
#define _STRRCHR_IMPL_0(str, ch)  (_STRRCHR_IMPL_COMMON(str, ch, 0):  _STRRCHR_IMPL_1(str, ch))

// 宏版本的 strrchr, 第一个参数只能是字面量，并且在文件名超过 31 个字符时，会退化为原字符串
#define _STRRCHR(str, ch) (sizeof((str)) <= 1? (str): _STRRCHR_IMPL_0(str, ch))

// 当文件名长度超过 31 个字符时，退化为 __FILE__ 宏
#define __FILE_NAME__ _STRRCHR(__FILE__, '/')

#endif

#define _GAIA_CONCAT(A, B) A ## B

#define GAIASegmentName "__DATA"
#define GAIASectionName "__GAIA__SECTION"
#define GAIASectionSeperator ","
#define GAIASectionFullName GAIASegmentName GAIASectionSeperator GAIASectionName

#define GAIAIdentifier(COUNTER) _GAIA_CONCAT(__GAIA_ID__, COUNTER)
#define GAIAFunctionInfoIdentifier(COUNTER) _GAIA_CONCAT(__GAIA_F_I_ID__, COUNTER)

#define GAIAUniqueIdentifier GAIAIdentifier(__COUNTER__)

#define GAIADataDefine(KEY, REPEATABLE, TYPE, VALUE) __attribute__((used, no_sanitize_address, section(GAIASectionFullName))) static const GAIAData GAIAUniqueIdentifier = (GAIAData){TYPE, REPEATABLE, KEY, (void *)VALUE}

#define GAIA_EXPORT_OBJC_METHOD(KEY, REPEATABLE) GAIADataDefine(KEY, REPEATABLE, GAIATypeObjCMethod, __func__)

#define GAIA_METHOD(KEY) GAIA_EXPORT_OBJC_METHOD(KEY, false)
#define GAIA_REPEATABLE_METHOD(KEY) GAIA_EXPORT_OBJC_METHOD(KEY, true)

//#define _GAIA_EXPORT_FUNCTION(KEY, REPEATABLE, COUNTER) \
//__attribute__((used)) static void GAIAIdentifier(COUNTER)(void); \
//GAIADataDefine(KEY, REPEATABLE, GAIATypeFunction, GAIAIdentifier(COUNTER)); \
//__attribute__((used no_sanitize_address)) static void GAIAIdentifier(COUNTER)

#define _GAIA_EXPORT_FUNCTION(KEY, REPEATABLE, COUNTER) \
__attribute__((used)) static void GAIAIdentifier(COUNTER)(void); \
static const GAIAFunctionInfo GAIAFunctionInfoIdentifier(COUNTER) = (GAIAFunctionInfo){(void *)GAIAIdentifier(COUNTER), __FILE_NAME__, __LINE__}; \
GAIADataDefine(KEY, REPEATABLE, GAIATypeFunctionInfo, &(GAIAFunctionInfoIdentifier(COUNTER))); \
__attribute__((used, no_sanitize_address)) static void GAIAIdentifier(COUNTER)

#define GAIA_EXPORT_FUNCTION(KEY, REPEATABLE) _GAIA_EXPORT_FUNCTION(KEY, REPEATABLE, __COUNTER__)

#define GAIA_FUNCTION(KEY) GAIA_EXPORT_FUNCTION(KEY, false)
#define GAIA_REPEATABLE_FUNCTION(KEY) GAIA_EXPORT_FUNCTION(KEY, true)

#define _GAIA_EXPORT_FUNCTION_WITH_OBJECT(KEY, REPEATABLE, COUNTER) \
__attribute__((used)) static void GAIAIdentifier(COUNTER)(id); \
static const GAIAFunctionInfo GAIAFunctionInfoIdentifier(COUNTER) = (GAIAFunctionInfo){(void *)GAIAIdentifier(COUNTER), __FILE_NAME__, __LINE__}; \
GAIADataDefine(KEY, REPEATABLE, GAIATypeFunctionInfo, &(GAIAFunctionInfoIdentifier(COUNTER))); \
__attribute__((used, no_sanitize_address)) static void GAIAIdentifier(COUNTER)

#define GAIA_EXPORT_FUNCTION_WITH_OBJECT(KEY, REPEATABLE) _GAIA_EXPORT_FUNCTION_WITH_OBJECT(KEY, REPEATABLE, __COUNTER__)

#define GAIA_FUNCTION_WITH_OBJECT(KEY) GAIA_EXPORT_FUNCTION_WITH_OBJECT(KEY, false)
#define GAIA_REPEATABLE_FUNCTION_WITH_OBJECT(KEY) GAIA_EXPORT_FUNCTION_WITH_OBJECT(KEY, true)



typedef enum : NSUInteger {
    GAIATypeFunction = 1,
    GAIATypeObjCMethod = 2,
    GAIATypeFunctionInfo = 3,// 和 function 的区别是，这种类型会携带 function 的文件信息
} GAIAType;

typedef struct _GAIAData {
    const GAIAType type;
    const bool repeatable;
    const char *key;
    const void *value;
} GAIAData;

typedef struct _GAIAFunctionInfo {
    const void *function;
    const char *fileName;
    const int line;
} GAIAFunctionInfo;

@interface GAIATask : NSObject

@property (nonatomic, assign, readonly) BOOL repeatable;

- (void)start;
- (void)startWithObject:(id)object;

@end

@interface _GAIAFunction : GAIATask

@end

typedef _GAIAFunction GAIAFunctionTask;

@interface _GAIAFunctionInfoData : GAIATask

@property(nonatomic, assign, readonly) GAIAFunctionInfo functionInfo;

@end

typedef _GAIAFunctionInfoData GAIAFunctionInfoTask;


@interface _GAIAObjCMethod : GAIATask

@property(nonatomic, readonly) Class classOfMethod;
@property(nonatomic, readonly) SEL selector;

@end

typedef _GAIAObjCMethod GAIAObjCMethodTask;


@protocol GAIAEngineObserver <NSObject>

@optional
+ (void)gaiaTasksWillStartForKey:(NSString *)key;
+ (void)gaiaTasksDidStartForKey:(NSString *)key;
+ (void)gaiaTaskWillExecute:(__kindof GAIATask *)task forKey:(NSString *)key;
+ (void)gaiaTaskDidExecute:(__kindof GAIATask *)task forKey:(NSString *)key;

@end

@interface GAIAEngine : NSObject


/// 根据 key 获取对应的 task array, 如果已经对 unrepeatable 的 task 执行过 startTasksForKey: 方法，此方法无法再次获取到该 task
/// @param key Gaia key
+ (nullable NSArray<GAIATask *> *)tasksForKey:(NSString *)key;


/// 根据 key 获取对应的 task array 并调用 start, 如果 task 为 unrepeatable, 执行完成后会移除并无法再次执行
/// @param key Gaia key
+ (void)startTasksForKey:(NSString *)key;
+ (void)startSwiftTasksForKey:(NSString *)key;


/**
 注意，同一个 key 不支持既有带参数的函数/方法，又有不带参数的函数/方法，否则可能出现不可预料的 crash

 @param object task 接收的参数，只支持一个参数
 */
+ (void)startTasksForKey:(NSString *)key withObject:(id)object;

+ (void)addGaiaObserver:(id<GAIAEngineObserver>)observer;
+ (void)removeGaiaObserver:(id<GAIAEngineObserver>)observer;

@end

NS_ASSUME_NONNULL_END
