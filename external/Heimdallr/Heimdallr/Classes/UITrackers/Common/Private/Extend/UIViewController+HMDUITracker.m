//
//  UIViewController+HMDUITracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/20.
//

#include <stdatomic.h>
#import "UIViewController+HMDUITracker.h"
#import <objc/runtime.h>
#import "HMDUITrackableContext.h"
#import "HMDSwizzle.h"
#import "HMDUITrackableContext.h"
#import "HMDUITracker.h"
#import "UIViewController+HMDControllerMonitor.h"
#import "HMDMacro.h"
#import "HMDTimeSepc.h"
#import "UIViewController+HMDUITracker+Macro.h"
#include "HMDISAHookOptimization.h"
#include "pthread_extended.h"

#pragma mark - Heimdallr toB 代码兼容

/** [ Heimdallr ToB 代码兼容 ]
    背景      toB 的业务方代码中, 存在 isa swizzle, 会将我们已经 isa swizzle 的 class 再进行 isa swizzle
          并且再额外添加自己的 method，但是由于我们重写了 +-[ XXViewController_hmd_subfix_ class] 方法
          导致他们的 respondToSelector 判断失效 ( 再备注：toB 业务方是交了钱的, 虽然有点苦, 但也得顺着他们的逻辑 )
 
    ISA        为什么要再重写 class 方法, 第一点是隐藏我们中间层 hook 代码的逻辑, 第二点是参考 KVO 实现
          系统的 KVO 实现提供了 isa hook 方案的指导, 重写 class 方法可以防止 self.class == XXViewController.class 这样的判断失效
          并且如果不重写, 存在无可预估的问题

          这个问题的核心在于：isa swizzle 只能用于拦截已有的实现方案，不应当作为添加方案的存在 ( ⚠️ 重点 )
          但是：我们要兼容 toB 业务方的问题, 因为他们交了钱 ( 是的, 苦了点, 但是为了商业化, 坚持吧 )
 
    方案      我们采取定制化, 提供不进行 class 方法重写的选择：提供一个对外的接口, 是否 UITracker 的 hook 需要 hook class 方法
 
    备注      RANGERSAPM 是 Heimdallr toB 专用的宏定义
 */
#ifdef RANGERSAPM
/** 如果该是 true 那么 isa swizzle 不添加 class 方法的替换 */
static atomic_bool isa_swizzle_dont_add_class_implementation = false;

void HMDUITracker_viewController_isa_swizzle(bool forbiddenClassImplementation) {
    isa_swizzle_dont_add_class_implementation = forbiddenClassImplementation;
}
#endif

#pragma mark - 校验 typeEncoding 没有问题 (下方有说明)

#ifdef DEBUG
static void HMD_validateTypeEncoding(Class aClass, BOOL isClassMethod, SEL selector, const char * _Nonnull typeEncoding);
#define validateTypeEncoding(aClass, isClassMethod, selector, typeEncoding) \
        HMD_validateTypeEncoding((aClass), (isClassMethod), (selector), (typeEncoding))
#else
#define validateTypeEncoding(aClass, isClassMethod, selector, typeEncoding)
#endif

static inline void HMD_addLoadViewIMP(Class originClass, Class newClass);
static inline void HMD_addViewDidLoadIMP(Class originClass, Class newClass);
static inline void HMD_addViewWillAppearIMP(Class originClass, Class newClass);
static inline void HMD_addViewDidAppearIMP(Class originClass, Class newClass);
static inline void HMD_addClassIMP(Class statedClass, Class newClass, Class newMetaClass);
static inline void HMD_addInitializeIMP(Class newClass, Class newMetaClass);

#pragma mark - 保留 UIViewController 原有的 IMP (注意该处数据可能已经被其他HOOK库替换过了)

static void (*IMP_origin_presentViewController)(UIViewController __kindof *, SEL, UIViewController *, BOOL, void (^)(void));
static void (*IMP_origin_dismissViewController)(UIViewController __kindof *, SEL, BOOL, void (^)(void));
static void (*IMP_origin_viewWillDisappear)(UIViewController __kindof *, SEL, BOOL);
static void (*IMP_origin_viewDidDisappear)(UIViewController __kindof *, SEL, BOOL);
static UIViewController __kindof * (*IMP_origin_initWithNibName)(UIViewController __kindof *, SEL, NSString *, NSBundle *);
static UIViewController __kindof * (*IMP_origin_initWithCoder)(UIViewController __kindof *, SEL, NSCoder *);

#pragma mark - 替换 UIViewController 原有的 IMP (此处方法进行调用原来的实现的逻辑)

static void HMD_presentViewController(UIViewController __kindof *thisSelf, SEL selector, UIViewController *viewControllerToPresent, BOOL flag, void (^completion)(void));
static void HMD_dismissViewController(UIViewController __kindof *thisSelf, SEL selector, BOOL flag, void (^completion)(void));
static void HMD_viewWillDisappear(UIViewController __kindof *thisSelf, SEL selector, BOOL animated);
static void HMD_viewDidDisappear(UIViewController __kindof *thisSelf, SEL selector, BOOL animated);
static UIViewController __kindof *HMD_initWithNibName(UIViewController __kindof *thisSelf, SEL selector, NSString *nibNameOrNil, NSBundle *nibBundleOrNil);
static UIViewController __kindof *HMD_initWithCoder(UIViewController __kindof *thisSelf, SEL selector, NSCoder *aDecoder);

#pragma mark - ISA Swizzle Optimization

static BOOL enable_ISA_swizzle_optimization = NO;

#pragma mark - UIViewController (HMDUITracker) 实际实现

#pragma mark Swizzle 启动

@implementation UIViewController (HMDUITracker)

+ (void)hmd_startSwizzle
{
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        
        Class UIViewControllerClass = UIViewController.class;
        
        /* https://www.jianshu.com/p/d5c3c2f236b8
           这部分改动兼容 forwardInvocation 并且兼容基于 SEL 实现的逻辑
           通过直接 IMP 替换, 并且调用回原方法实现
           原有的逻辑只能兼容 Aspects 库 */
        
        /* [第一步] 当前需要替换 IMP 的 SEL */
        SEL SEL_presentViewController = @selector(presentViewController:animated:completion:);
        SEL SEL_dismissViewController = @selector(dismissViewControllerAnimated:completion:);
        SEL SEL_viewWillDisappear     = @selector(viewWillDisappear:);
        SEL SEL_viewDidDisappear      = @selector(viewDidDisappear:);
        SEL SEL_initWithNibName       = @selector(initWithNibName:bundle:);
        SEL SEL_initWithCoder         = @selector(initWithCoder:);
        
        /* [第二步] 获取当前 UIViewController 所有的需要替换的方法 */
        Method method_presentViewController = class_getInstanceMethod(UIViewControllerClass, @selector(presentViewController:animated:completion:));
        Method method_dismissViewController = class_getInstanceMethod(UIViewControllerClass, @selector(dismissViewControllerAnimated:completion:));
        Method method_viewWillDisappear     = class_getInstanceMethod(UIViewControllerClass, @selector(viewWillDisappear:));
        Method method_viewDidDisappear      = class_getInstanceMethod(UIViewControllerClass, @selector(viewDidDisappear:));
        Method method_initWithNibName       = class_getInstanceMethod(UIViewControllerClass, @selector(initWithNibName:bundle:));
        Method method_initWithCoder         = class_getInstanceMethod(UIViewControllerClass, @selector(initWithCoder:));
        
        /* 判断获取的数据不为 NULL */
        if(method_presentViewController == NULL ||
           method_dismissViewController == NULL ||
           method_viewWillDisappear     == NULL ||
           method_viewDidDisappear      == NULL ||
           method_initWithNibName       == NULL ||
           method_initWithCoder         == NULL) {
            DEBUG_RETURN_NONE;
        };
        
        /* [第三步] 获取当前 UIViewController 原来的 IMP并且保存 (注意这部分 IMP 可能已经被各种 Swizzle 库给替换掉了) */
           IMP_origin_presentViewController = (__typeof(IMP_origin_presentViewController))method_getImplementation(method_presentViewController);
           IMP_origin_dismissViewController = (__typeof(IMP_origin_dismissViewController))method_getImplementation(method_dismissViewController);
           IMP_origin_viewWillDisappear     = (__typeof(IMP_origin_viewWillDisappear))    method_getImplementation(method_viewWillDisappear);
           IMP_origin_viewDidDisappear      = (__typeof(IMP_origin_viewDidDisappear))     method_getImplementation(method_viewDidDisappear);
           IMP_origin_initWithNibName       = (__typeof(IMP_origin_initWithNibName))      method_getImplementation(method_initWithNibName);
           IMP_origin_initWithCoder         = (__typeof(IMP_origin_initWithCoder))        method_getImplementation(method_initWithCoder);
        
        /* 判断获取的数据不为 NULL */
        if(IMP_origin_presentViewController == NULL ||
           IMP_origin_dismissViewController == NULL ||
           IMP_origin_viewWillDisappear     == NULL ||
           IMP_origin_viewDidDisappear      == NULL ||
           IMP_origin_initWithNibName       == NULL ||
           IMP_origin_initWithCoder         == NULL) {
            DEBUG_RETURN_NONE;
        };
        
        /* [第四步] 获取 typeEncoding ( 是NULL也不会崩溃, 不判断了 ) */
        const char *typeEncoding_presentViewController = method_getTypeEncoding(method_presentViewController);
        const char *typeEncoding_dismissViewController = method_getTypeEncoding(method_dismissViewController);
        const char *typeEncoding_viewWillDisappear     = method_getTypeEncoding(method_viewWillDisappear);
        const char *typeEncoding_viewDidDisappear      = method_getTypeEncoding(method_viewDidDisappear);
        const char *typeEncoding_initWithNibName       = method_getTypeEncoding(method_initWithNibName);
        const char *typeEncoding_initWithCoder         = method_getTypeEncoding(method_initWithCoder);
        
        /* [第五步] 替换方法实现 */
        class_replaceMethod(UIViewControllerClass, SEL_presentViewController, (IMP)HMD_presentViewController, typeEncoding_presentViewController);
        class_replaceMethod(UIViewControllerClass, SEL_dismissViewController, (IMP)HMD_dismissViewController, typeEncoding_dismissViewController);
        class_replaceMethod(UIViewControllerClass, SEL_viewWillDisappear,     (IMP)HMD_viewWillDisappear,     typeEncoding_viewWillDisappear);
        class_replaceMethod(UIViewControllerClass, SEL_viewDidDisappear,      (IMP)HMD_viewDidDisappear,      typeEncoding_viewDidDisappear);
        class_replaceMethod(UIViewControllerClass, SEL_initWithNibName,       (IMP)HMD_initWithNibName,       typeEncoding_initWithNibName);
        class_replaceMethod(UIViewControllerClass, SEL_initWithCoder,         (IMP)HMD_initWithCoder,         typeEncoding_initWithCoder);
    }
}

#pragma mark HMDUITrackable protocol

- (BOOL)hmd_trackEnabled
{
    if ([self isKindOfClass:[UINavigationController class]] ||
        [self isKindOfClass:[UITabBarController class]]) {
        return NO;
    }
    return YES;
}

#pragma mark isa hook linked array

/*!@define HMDISA_hookArrayCount
 * @abstract ISA HOOK Linked Array 单个最大的保存数量
 */
#define HMDISA_hookArrayCount 64

/*!@typedef HMDISA_hookPair
 * @abstract @p fromClass 是原始的 ViewController 类别
 *           @p toClass 是 Heimdallr ISA HOOK 之后的 ViewController 类别
 *           @p class_getSuperClass(toClass)==fromClass
 */
typedef struct {
    Class fromClass;
    Class toClass;
} HMDISA_hookPair;

/*!@typedef HMDISA_hookLinkedArrayRef
 * @abstract HMDISA_hookLinkedArray 类型的指针
 */
typedef struct HMDISA_hookLinkedArray *HMDISA_hookLinkedArrayRef;

/*!@typedef HMDISA_hookLinkedArray
 * @name count 当前保存在 @p pairs 内的有效数量
 * @name @p pairs 数组类型，每一个元素都对应一个 @p HMDISA_hookPair 对象，保存 HOOK 的原始 Class 和 ISA HOOK 创建的 Class
 * @name @p next 下一个 @p HMDISA_hookLinkedArray 的指针
 */
typedef struct HMDISA_hookLinkedArray {
    unsigned int count;
    HMDISA_hookPair pairs[HMDISA_hookArrayCount];
    HMDISA_hookLinkedArrayRef nextArray;
} HMDISA_hookLinkedArray;

/*!@typedef HMDISA_globalHookCount
 * @abstract 全局保存，当前 HOOK 的数量； @b 访问受到 @p HMDISA_rwLock @b 锁的控制，读取需要持有Read或者Write锁，写入需要持有Write锁
 * @discussion 此数据是为了应对线程竞争情况，在访问读取 @p linkedArray 之后，发现当前 Class 没有对应的 ISA HOOK Class；
 * 而且当前的 Class 不是 ISA HOOK Class 那么会进一步去持有 Write 锁，然后创建 Class 对应的 ISA HOOK Class；但是如果在读取时，
 * 持有的是 Read Lock 到切换使用 Write Lock 之间存在多线程竞争 Race Condition，可能在持有 Write Lock 之前，已经有人写入好了数据；
 * 那么通过 hookCount 全局判断是否有新的 HOOK Class Pair 添加，从而解决 Race Condition 问题；那么从 Read Lock 切换到 Write Lock
 * 如果 @p HMDISA_globalHookCount 没有增加，那么无需在扫描一次 @p linkedArray ，如果增加了那么就要判断是否增加的命中了 HOOK Pair
 */
static unsigned int HMDISA_globalHookCount = 0;

/*!@name linkedArray
 * @abstract 全局链表，保存当前 HOOK 信息 @b 访问受到 @p HMDISA_rwLock @b 锁的控制，读取需要持有Read或者Write锁，写入需要持有Write锁
 */
static HMDISA_hookLinkedArrayRef linkedArray = NULL;

/*!@name HMDISA_rwLock
 * @abstract 全局读写锁，用于保护 @p HMDISA_globalHookCount 和 @p linkedArray 信息
 */
static pthread_rwlock_t HMDISA_rwLock = PTHREAD_RWLOCK_INITIALIZER;

/*!@function HMDISA_findHookPairForClass
 * @param aClass 查找的 Class，这个 Class 可能是没有 ISA HOOK 信息的 Class；也可能是有 HOOK 信息的，在有 HOOK 信息的前提下，可能是原始类，或者 ISA HOOK 类
 * @param hookPairResult 查找结果，如果返回值是 true 那么意味着查找到了 ISA HOOK 信息，那么 @p aClass 等于 @p hookPairResult 内的 @p fromClass 或者 @p toClass
 * @param searchTimeHookCount 查找时刻保存的 @p HMDISA_hookCount，用于解决 @p raceCondition，详细见 @p HMDISA_globalHookCount 介绍
 * @return true 如果查找到 @p aClass 相关的 ISA HOOK 信息；false 如果没有找到相关信息
 */
static bool HMDISA_findHookPairForClass(Class _Nonnull aClass,
                                        HMDISA_hookPair * _Nonnull hookPairResult,
                                        unsigned int * _Nonnull searchTimeHookCount);

/*!@function HMDISA_findHookPairForClass_noLock
 * @abstract 这个函数的作用和 @p HMDISA_findHookPairForClass 相同，唯一的区别是它不会尝试获得 @p HMDISA_rwLock 锁，
 * @b 调用者需要保证持有 @p HMDISA_rwLock 锁，read 锁或者 write 锁都行，但是必须持有，不然会有多线程问题
 */
static bool HMDISA_findHookPairForClass_noLock(Class _Nonnull aClass,
                                               HMDISA_hookPair * _Nonnull hookPairResult,
                                               unsigned int * _Nonnull searchTimeHookCount);

/*!@function HMDISA_createEmptyLinkedArray
 * @abstract 创建一个空的 HMDISA_hookLinkedArray, 设置结构成员 nextArray 为 NULL 和 当前存储信息为空
 */
static HMDISA_hookLinkedArrayRef _Nullable HMDISA_createEmptyLinkedArray(void);

/*!@function HMDISA_generateISAHookPair
 * @abstract 尝试创建一个 Class 的 ISA HOOK Class，如果创建失败返回 nil ( 异常情况，不应该发生 )
 * @discussion 当查询和 @p fromClass 相关信息，没有找到任何相关信息之后，会进行的操作；
 * 存在的情况只有两种：
 *      1. @p fromClass 是从来没有被 HOOK 的原始类，那么该函数会创建其 ISA HOOK Class 并且写入全局数据
 *      2. @p fromClass 在查询结束，到调用 @p HMDISA_generateISAHookPair 的时刻，因为 raceCondition
 *        被其他线程 HOOK 成功，那么返回对应的 ISA HOOK Class
 * [ 异常情况 ] 调用此方法时刻，传递的 @p fromClass 属于 ISA HOOK Class，这是极其不应该的
 */
static Class _Nullable HMDISA_generateISAHookPair(Class _Nonnull fromClass,
                                                  Class _Nullable statedClass,
                                                  unsigned int searchTimeHookCount);

/*!@function HMDISA_generateISAHookSubClass
 * @warning ⚠️⚠️⚠️ @b 此方法只能由 @p HMDISA_generateISAHookPair @b 进行调用，其他调用者都是非法的
 * @abstract 创建一个原始类 @p fromClass 的 ISA HOOK Class，并且返回
 */
static Class _Nullable HMDISA_generateISAHookSubClass(Class _Nonnull fromClass,
                                                      Class _Nullable statedClass);

static bool HMDISA_findHookPairForClass_noLock(Class _Nonnull aClass,
                                               HMDISA_hookPair * _Nonnull hookPairResult,
                                               unsigned int * _Nonnull searchTimeHookCount) {
    
    DEBUG_ASSERT(aClass != NULL && hookPairResult != NULL && searchTimeHookCount != NULL);
    
    // initialize searchTimeHookCount anyway even if not needed
    searchTimeHookCount[0] = HMDISA_globalHookCount;
    
    bool result = false;
    HMDISA_hookLinkedArrayRef currentLinkedArray = linkedArray;
    while(currentLinkedArray != NULL) {
        unsigned int count = currentLinkedArray->count;
        DEBUG_ASSERT(count <= HMDISA_globalHookCount);
        
        for(unsigned int index = 0; index < count; index++) {
            Class fromClass = currentLinkedArray->pairs[index].fromClass;
            Class   toClass = currentLinkedArray->pairs[index].  toClass;
            DEBUG_ASSERT(fromClass != nil);
            DEBUG_ASSERT(toClass != nil);
            DEBUG_ASSERT(class_getSuperclass(toClass) == fromClass);
            DEBUG_ASSERT(HMDISA_globalHookCount >= count);
            
            if(fromClass == aClass || toClass == aClass) {
                hookPairResult->fromClass = fromClass;
                hookPairResult->toClass   =   toClass;
                result = true;
                goto exitSearch;
            }
        }
        
        DEBUG_ASSERT(currentLinkedArray->nextArray == NULL ||
                     currentLinkedArray->count     == HMDISA_hookArrayCount);
        
        currentLinkedArray = currentLinkedArray->nextArray;
    }
exitSearch:
    return result;
}

static bool HMDISA_findHookPairForClass(Class _Nonnull aClass,
                                        HMDISA_hookPair * _Nonnull hookPairResult,
                                        unsigned int * _Nonnull searchTimeHookCount) {
    DEBUG_ASSERT(aClass != NULL && hookPairResult != NULL && searchTimeHookCount != NULL);
    bool result;
    pthread_rwlock_rdlock(&HMDISA_rwLock);
    result = HMDISA_findHookPairForClass_noLock(aClass, hookPairResult, searchTimeHookCount);
    pthread_rwlock_unlock(&HMDISA_rwLock);
    return result;
}

static HMDISA_hookLinkedArrayRef _Nullable HMDISA_createEmptyLinkedArray(void) {
    HMDISA_hookLinkedArrayRef result;
    if((result = malloc(sizeof(HMDISA_hookLinkedArray))) != NULL) {
        result->count = 0;
        result->nextArray = NULL;
    }
    return result;
}

static Class _Nullable HMDISA_generateISAHookPair(Class _Nonnull fromClass,
                                                  Class _Nullable statedClass,
                                                  unsigned int searchTimeHookCount) {
    DEBUG_ASSERT(fromClass != NULL);
    
    pthread_rwlock_wrlock(&HMDISA_rwLock);
    
    if(searchTimeHookCount != HMDISA_globalHookCount) {
        DEBUG_LOG("[Heimdallr][UITracker] ISA Hook maybe race condition globally "
                  "when searchTimeHookCount(%u) HMDISA_hookCount(%u) fromClass(%s<%p>)",
                  searchTimeHookCount, HMDISA_globalHookCount, class_getName(fromClass), fromClass);
        
        DEBUG_ASSERT(HMDISA_globalHookCount > 0);
        DEBUG_ASSERT(HMDISA_globalHookCount > searchTimeHookCount);
        
        HMDISA_hookPair hookPairResult;
        unsigned int searchTimeHookCount;
        bool searchResult;
        if((searchResult = HMDISA_findHookPairForClass_noLock(fromClass, &hookPairResult, &searchTimeHookCount))) {
            
            pthread_rwlock_unlock(&HMDISA_rwLock);
            
            DEBUG_LOG("[Heimdallr][UITracker] ISA Hook race condition detected for fromClass(%s<%p>)",
                      class_getName(fromClass), fromClass);
            
            if(hookPairResult.fromClass == fromClass) {
                DEBUG_ASSERT(hookPairResult.toClass != nil &&
                             class_getSuperclass(hookPairResult.toClass) == fromClass);
                return hookPairResult.toClass;
            }
            
            DEBUG_RETURN(nil);      // critical error
        }
    }
    
    Class toClass = nil;
    
    if(linkedArray == NULL) linkedArray = HMDISA_createEmptyLinkedArray();
    DEBUG_ASSERT(linkedArray != NULL);
    
    #ifdef DEBUG
    unsigned int totalHookCount = 0;
    #endif
    
    HMDISA_hookLinkedArrayRef currentLinkedArray = linkedArray;
    while(currentLinkedArray != NULL) {
        const unsigned int count = currentLinkedArray->count;
        #ifdef DEBUG
        totalHookCount += count;
        #endif
        
        if(count < HMDISA_hookArrayCount) {
            DEBUG_ASSERT(totalHookCount == HMDISA_globalHookCount);
            
            if((toClass = HMDISA_generateISAHookSubClass(fromClass, statedClass)) != nil) {
                currentLinkedArray->pairs[count] = (HMDISA_hookPair){
                    .fromClass = fromClass,
                    .toClass   = toClass
                };
                currentLinkedArray->count = count + 1;
                HMDISA_globalHookCount += 1;
                
            } DEBUG_ELSE // critical error
            
            break;
        }
        
        HMDISA_hookLinkedArrayRef _Nullable nextArray = currentLinkedArray->nextArray;
        if(nextArray == NULL) {
            nextArray = HMDISA_createEmptyLinkedArray();
            DEBUG_ASSERT(nextArray != NULL);
            currentLinkedArray->nextArray = nextArray;
        }
        currentLinkedArray = nextArray;
    }
    // <=   break exit
    
    pthread_rwlock_unlock(&HMDISA_rwLock);
    
    return toClass;
}

static Class _Nullable HMDISA_generateISAHookSubClass(Class _Nonnull fromClass,
                                                      Class _Nullable statedClass) {
    DEBUG_ASSERT(fromClass != NULL);
    DEBUG_ASSERT(!class_isMetaClass(fromClass));
    
    const char * _Nonnull fromClassRawName;
    if((fromClassRawName = class_getName(fromClass)) != NULL) {
        
        NSString *fromClassName;
        if((fromClassName = [NSString stringWithUTF8String:fromClassRawName]) != nil) {
            
            static NSString *_hmd_subfix_ = @"_hmd_subfix_";
            NSString *toClassName = [fromClassName stringByAppendingString:_hmd_subfix_];
            
            const char * _Nonnull toClassRawName;
            if((toClassRawName = toClassName.UTF8String) != NULL) {
                
                Class toClass = nil;
                
                if(enable_ISA_swizzle_optimization) {   // ISA Hook Optimization
                    
                    int value = HMDISAHookOptimization_before_objc_allocate_classPair();
                    toClass = objc_allocateClassPair(fromClass, toClassRawName, 0);
                    HMDISAHookOptimization_after_objc_allocate_classPair(value);
                    
                } else {    // fallback to original implementation
                    
                    toClass = objc_allocateClassPair(fromClass, toClassRawName, 0);
                }
                
                if(toClass != nil) {
                    
                    Class toMetaClass = object_getClass(toClass);
                    DEBUG_ASSERT(toMetaClass != nil && object_getClass(toClass) == toMetaClass);
                    
                    if(statedClass != nil) HMD_addClassIMP(statedClass, toClass, toMetaClass);
                    
                    HMD_addLoadViewIMP       (fromClass, toClass);
                    HMD_addViewDidLoadIMP    (fromClass, toClass);
                    HMD_addViewWillAppearIMP (fromClass, toClass);
                    HMD_addViewDidAppearIMP  (fromClass, toClass);
                    HMD_addInitializeIMP     (toClass,   toMetaClass);
                    
                    objc_registerClassPair(toClass);
                    
                    return toClass;
                } DEBUG_ELSE
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    return nil;
}

#pragma mark isa swizzle 部分

- (void)hmd_exchangeViewControllerAllMethod {
    
    Class originalClass = object_getClass(self);
    
    HMDISA_hookPair hookPairResult;
    unsigned int searchTimeHookCount;
    if(HMDISA_findHookPairForClass(originalClass, &hookPairResult, &searchTimeHookCount)) {
        if(originalClass == hookPairResult.fromClass) {
            DEBUG_ASSERT(hookPairResult.toClass != nil &&
                         class_getSuperclass(hookPairResult.toClass) == originalClass);
            object_setClass(self, hookPairResult.toClass);
        } DEBUG_ELSE
        return;
    }
    
    // 初始化为 nil, 传递 nil 给 HMDISA_generateISAHookSubClass
    // 意味着不会创建 +/-[toClass class] 的方法
    Class statedClass = nil;
    
    #ifdef RANGERSAPM
    // RANGERSAPM 是 Heimdallr toB 环境的宏定义
    // [需要对外兼容] 提供 isa 不进行 add +/-[toClass class] method 的方案
    if(!isa_swizzle_dont_add_class_implementation) statedClass = [self class];
    #else
    statedClass = [self class];
    #endif
    
    Class _Nullable toClass = HMDISA_generateISAHookPair(originalClass, statedClass, searchTimeHookCount);
    
    if(toClass != nil) object_setClass(self, toClass);
    DEBUG_ELSE
}

- (void)hmd_old_exchangeViewControllerAllMethod {
    
    Class originalClass = object_getClass(self);
    NSString *objectClassNameString = NSStringFromClass(originalClass);
    
    static NSString *_hmd_subfix_ = @"_hmd_subfix_";
    
    // IF has NOT subfix
    if(![objectClassNameString hasSuffix:_hmd_subfix_]) {
        
        const char *subclassName = [objectClassNameString stringByAppendingString:_hmd_subfix_].UTF8String;
        Class newClass = objc_getClass(subclassName);
        if(newClass == nil) {
            newClass = objc_allocateClassPair(originalClass, subclassName, 0);
            if(newClass == nil) DEBUG_RETURN_NONE;
            
            Class statedClass = [self class];
            Class newMetaClass = object_getClass(newClass);
            /* 关于为什么只 isa swizzle Appear 方法, 但是对于 Disappear 却没有管
                1. 我接手代码的时刻就是这样的逻辑(原代码书写者已离职)
                2. 业务上更关心 appear, 对于 disappear 需求不高
                3. 也并非完全监控不到 disappear (只是某些 override 并且不 call super) 会失效
                4. 性能上能够尽可能的少 isa swizzle 也是必要的需求 */
            
#ifdef RANGERSAPM   // heimdallr toB 代码兼容: 提供 isa 不进行 add class method 的方案
            if(!isa_swizzle_dont_add_class_implementation) HMD_addClassIMP(statedClass, newClass, newMetaClass);
#else
            HMD_addClassIMP(statedClass, newClass, newMetaClass);
#endif
            HMD_addLoadViewIMP(originalClass, newClass);
            HMD_addViewDidLoadIMP(originalClass, newClass);
            HMD_addViewWillAppearIMP(originalClass, newClass);
            HMD_addViewDidAppearIMP(originalClass, newClass);
            HMD_addInitializeIMP(newClass, newMetaClass);
            
            objc_registerClassPair(newClass);
        }
        object_setClass(self, newClass);
    }
}

@end

#pragma mark Isa wizzle 生成方法

CLANG_DIAGNOSTIC_PUSH                       // 这里使用了 result = class_addMethod 判断是否添加方法成功
CLANG_DIAGNOSTIC_IGNORE_UNUSED_VARIABLE     // 该处在 release 模式下会被优化掉, 不会有未使用的变量

static inline void HMD_addLoadViewIMP(Class originClass, Class newClass) {
    IMP loadView_IMP = imp_implementationWithBlock(^(__kindof UIViewController *thisSelf) {
        create_super_info(thisSelf, originClass);
        
        if ([thisSelf hmd_trackEnabled]) {
            [thisSelf hmd_loadViewActionStart];
            LoadView_msgSendSuper(&super_info, @selector(loadView));
            [thisSelf hmd_loadViewActionEnd];
        } else  LoadView_msgSendSuper(&super_info, @selector(loadView));
    });
    validateTypeEncoding(originClass, NO, @selector(loadView), "v@:");
    
    BOOL result = class_addMethod(newClass, @selector(loadView), loadView_IMP, "v@:");
    DEBUG_ASSERT(result);
}

static inline void HMD_addViewDidLoadIMP(Class originClass, Class newClass) {
    IMP viewDidLoad_IMP = imp_implementationWithBlock(^(__kindof UIViewController *thisSelf) {
        create_super_info(thisSelf, originClass);
        
        if ([thisSelf hmd_trackEnabled]) {
            
            [thisSelf hmd_viewDidLoadActionStart];
            
            CFTimeInterval start = HMD_XNUSystemCall_timeSince1970();
            
            ViewDidLoad_msgSendSuper(&super_info, @selector(viewDidLoad));
            
            [thisSelf hmd_viewDidLoadActionEnd];
            
            CFTimeInterval duration = HMD_XNUSystemCall_timeSince1970() - start;
            
            [thisSelf.hmd_trackContext trackableDidLoadWithDuration:duration];
            
        } else ViewDidLoad_msgSendSuper(&super_info, @selector(viewDidLoad));
    });
    validateTypeEncoding(originClass, NO, @selector(viewDidLoad), "v@:");
    
    BOOL result = class_addMethod(newClass, @selector(viewDidLoad), viewDidLoad_IMP, "v@:");
    DEBUG_ASSERT(result);
}

static inline void HMD_addViewWillAppearIMP(Class originClass, Class newClass) {
    
    IMP viewWillAppear_IMP = imp_implementationWithBlock(^(__kindof UIViewController *thisSelf, BOOL animated) {
        create_super_info(thisSelf, originClass);
        
        if ([thisSelf hmd_trackEnabled]) {
            [thisSelf.hmd_trackContext trackableWillAppear];
            
            [thisSelf hmd_viewWillAppearActionStart];
            
            ViewWillAppear_msgSendSuper(&super_info, @selector(viewWillAppear:), animated);
            
            [thisSelf hmd_viewWillAppearActionEnd];
            
        } else ViewWillAppear_msgSendSuper(&super_info, @selector(viewWillAppear:), animated);
    });
    validateTypeEncoding(originClass, NO, @selector(viewWillAppear:), "v@:B");
    
    BOOL result = class_addMethod(newClass, @selector(viewWillAppear:), viewWillAppear_IMP, "v@:B");
    DEBUG_ASSERT(result);
}

static inline void HMD_addViewDidAppearIMP(Class originClass, Class newClass) {
    IMP viewDidAppear_IMP = imp_implementationWithBlock(^(__kindof UIViewController *thisSelf, BOOL animated) {
        create_super_info(thisSelf, originClass);
        
        if ([thisSelf hmd_trackEnabled]) {
            [thisSelf.hmd_trackContext trackableDidAppear];
            
            [thisSelf hmd_viewDidAppearActionStart];
            
            ViewDidAppear_msgSendSuper(&super_info, @selector(viewDidAppear:), animated);
            
            [thisSelf hmd_viewDidAppearActionEnd];
            
        } else ViewDidAppear_msgSendSuper(&super_info, @selector(viewDidAppear:), animated);
        
        if ([[HMDUITracker sharedInstance].delegate respondsToSelector:@selector(didAppearViewController:)]) {
            // 目前 appearVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
            // 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
            // [[HMDUITracker sharedInstance].delegate didAppearViewController:thisSelf];
            [[HMDUITracker sharedInstance].delegate didAppearViewController:nil];
        }
    });
    validateTypeEncoding(originClass, NO, @selector(viewDidAppear:), "v@:B");
    
    BOOL result = class_addMethod(newClass, @selector(viewDidAppear:), viewDidAppear_IMP, "v@:B");
    DEBUG_ASSERT(result);
}

static inline void HMD_addClassIMP(Class statedClass, Class newClass, Class newMetaClass) {
    IMP class_IMP = imp_implementationWithBlock(^(__kindof UIViewController *thisSelf) {
        return statedClass;
    });
    DEBUG_ASSERT(!class_isMetaClass(statedClass));
    DEBUG_ASSERT(!class_isMetaClass(newClass));
    DEBUG_ASSERT(object_getClass(newClass) == newMetaClass);
    validateTypeEncoding(statedClass, NO, @selector(class), "#@:");
    validateTypeEncoding(statedClass, YES, @selector(class), "#@:");
    
    BOOL result1 = class_addMethod(newClass, @selector(class), class_IMP, "#@:");
    BOOL result2 = class_addMethod(object_getClass(newClass), @selector(class), class_IMP, "#@:");
    DEBUG_ASSERT(result1); DEBUG_ASSERT(result2);
}

static inline void HMD_addInitializeIMP(Class newClass, Class newMetaClass) {
    IMP initialize_IMP = imp_implementationWithBlock(^(Class thisClass) {
        /*  关于为什么这里创建了新的 class 的 +initialize 方法但是没有任何实现
            因为 Facebook 相关的 ViewController 代码中, 在 initialize 方法中
            判断和实现了, 是否有 subClass of Facebook ViewController 然后抛出异常
         
            [在这里创建空的实现]
                第一点是: 没有改变原有代码逻辑 Facebook +initialize 方法依然会正常调用, 不会被覆盖掉 (参考OC初始化逻辑)
                第二点嘛: 当然是防止它们搞事情, 抛出异常: (曾经导致 TikTok 海外版 开 Facebook 分享就崩溃)   */
    });
    validateTypeEncoding(newClass, YES, @selector(initialize), "v@:");
    DEBUG_ASSERT(object_getClass(newClass) == newMetaClass);
    
    BOOL result = class_addMethod(newMetaClass, @selector(initialize), initialize_IMP, "v@:");
    DEBUG_ASSERT(result);
}

CLANG_DIAGNOSTIC_POP

#pragma mark - IMP Swizzle 部分

static void HMD_presentViewController(UIViewController __kindof *thisSelf, SEL selector, UIViewController *viewControllerToPresent, BOOL flag, void (^completion)(void)) {
    
    IMP_origin_presentViewController(thisSelf, selector, viewControllerToPresent, flag, completion);
    
    UIViewController *fromViewController = viewControllerToPresent.presentingViewController;
        
    if ([fromViewController isKindOfClass:UINavigationController.class])
        fromViewController = ((UINavigationController *)fromViewController).topViewController;
    
    if ([thisSelf hmd_trackEnabled]) {
        [thisSelf.hmd_trackContext trackableEvent:@"present_controller" info:@{@"from":fromViewController.hmd_defaultTrackName?:@"",
                                                                               @"to":viewControllerToPresent.hmd_defaultTrackName?:@""}];
    }
    if ([[HMDUITracker sharedInstance].delegate respondsToSelector:@selector(hmdSwitchToNewVCFrom:to:)]) {
        // [[HMDUITracker sharedInstance].delegate hmdSwitchToNewVCFrom:fromViewController to:viewControllerToPresent];
        // 目前 fromVC 和 toVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
        // 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
        [[HMDUITracker sharedInstance].delegate hmdSwitchToNewVCFrom:nil to:nil];
    }
}

static void HMD_dismissViewController(UIViewController __kindof *thisSelf, SEL selector, BOOL flag, void (^completion)(void)) {
    
    UIViewController *fromViewController;
    UIViewController *toViewController;
    
    UIViewController *presentedViewController;
    UIViewController *presentingViewController;
    
    BOOL findTransition = YES;
    
    if((presentedViewController = thisSelf.presentedViewController) != nil) {
        fromViewController = presentedViewController;
        toViewController = thisSelf;
    }
    else if((presentingViewController = thisSelf.presentingViewController) != nil) {
        toViewController = presentingViewController;
        fromViewController = thisSelf;
    }
    else findTransition = NO;
    
    // 调用回原有的 +[UIViewController dismissViewController:animated:completion:]
    IMP_origin_dismissViewController(thisSelf, selector, flag, completion);
    
    if(findTransition) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *toVC = toViewController;
            
            if ([toVC isKindOfClass:UINavigationController.class])
                toVC = ((UINavigationController *)toVC).topViewController;
            
            if ([thisSelf hmd_trackEnabled]) {
                [thisSelf.hmd_trackContext trackableEvent:@"dissmiss_controller"
                                                     info:@{@"from":fromViewController.hmd_defaultTrackName?:@"",
                                                            @"to":toVC.hmd_defaultTrackName?:@""}];
            }
        });
    }
}

static void HMD_viewWillDisappear(UIViewController __kindof *thisSelf, SEL selector, BOOL animated) {
    
    if([thisSelf hmd_trackEnabled])
        [thisSelf.hmd_trackContext trackableWillDisappear];
    
    IMP_origin_viewWillDisappear(thisSelf, selector, animated);
}

static void HMD_viewDidDisappear(UIViewController __kindof *thisSelf, SEL selector, BOOL animated) {
    if([thisSelf hmd_trackEnabled])
        [thisSelf.hmd_trackContext trackableDidDisappear];
    
    IMP_origin_viewDidDisappear(thisSelf, selector, animated);
    
    if ([[HMDUITracker sharedInstance].delegate respondsToSelector:@selector(didLeaveViewController:)]) {
        // 目前 leavingVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
        // 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
        // [[HMDUITracker sharedInstance].delegate didLeaveViewController:thisSelf];
        [[HMDUITracker sharedInstance].delegate didLeaveViewController:nil];
    }
}

static UIViewController __kindof *HMD_initWithNibName(UIViewController __kindof *thisSelf, SEL selector, NSString *nibNameOrNil, NSBundle *nibBundleOrNil) {
    
    [thisSelf hmd_initActionStart];
    
    id obj = IMP_origin_initWithNibName(thisSelf, selector, nibNameOrNil, nibBundleOrNil);
    
    if([thisSelf hmd_trackEnabled])
        [thisSelf hmd_exchangeViewControllerAllMethod];
    
    return obj;
}

static UIViewController __kindof *HMD_initWithCoder(UIViewController __kindof *thisSelf, SEL selector, NSCoder *aDecoder) {
    
    [thisSelf hmd_initActionStart];
    
    id obj = IMP_origin_initWithCoder(thisSelf, selector, aDecoder);
    
    if([thisSelf hmd_trackEnabled])
        [thisSelf hmd_exchangeViewControllerAllMethod];
    
    return obj;
}

#pragma mark - ISA Swizzle Optimization

void HMDUITracker_viewController_enable_ISA_swizzle_optimization(bool enable) {
    enable_ISA_swizzle_optimization = enable;
}

#pragma mark - 校验 typeEncoding 没有问题

#ifdef DEBUG

/*!
    @function HMD_validateTypeEncoding
    @param aClass 来自哪个 Class
    @param isClassMethod 当前是判断 +Class 还是 -Instance 方法
    @param selector 这个方法的 SEL 名称
    @param typeEncoding 期望的 typeEncoding
    @discussion 判断某个 Class 的某个方法, 其 typeEncoding 是否符合某个值, 用于检查 swizzle 是否合理
                如果判断失败, HMD_validateTypeEncoding 会引发中断, 所以该方法只能在 DEBUG 模式使用
*/
static void HMD_validateTypeEncoding(Class aClass,
                                     BOOL isClassMethod,
                                     SEL selector,
                                     const char * _Nonnull typeEncoding) {
    DEBUG_ASSERT(aClass != nil && selector != nil && typeEncoding != nil);
    DEBUG_ASSERT(!class_isMetaClass(aClass));
    
    Method method;
    if(isClassMethod) method = class_getClassMethod(aClass, selector);
    else method = class_getInstanceMethod(aClass, selector);
    DEBUG_ASSERT(method != nil);
    
    const char *rawTypeEncoding = method_getTypeEncoding(method);
    DEBUG_ASSERT(rawTypeEncoding != nil);
    
    NSString *compared = [NSString stringWithUTF8String:typeEncoding];
    DEBUG_ASSERT(compared != nil);
    
    NSMutableString *encoding = [NSMutableString string];

    size_t stringLength = strlen(rawTypeEncoding);
    for(size_t index = 0; index < stringLength; index++) {
        if(strchr("1234567890nNoOrRV\"", rawTypeEncoding[index]) != NULL) {
            if(rawTypeEncoding[index] == '"') {
                index++;
                for (;;) {
                    if(rawTypeEncoding[index] == '\0') DEBUG_POINT;
                    if(rawTypeEncoding[index++] == '"') break;
                }
            }
        } else [encoding appendFormat:@"%c", rawTypeEncoding[index]];
    }
    printf("method typeEncoding validate %s[%s %s]\noriginal encoding: %s\n",
           isClassMethod?"+":"-", class_getName(aClass), sel_getName(selector), encoding.UTF8String);
    printf("compared encoding: %s\n", typeEncoding);
    DEBUG_ASSERT([compared isEqualToString:encoding]);
}

#endif /* DEBUG */
