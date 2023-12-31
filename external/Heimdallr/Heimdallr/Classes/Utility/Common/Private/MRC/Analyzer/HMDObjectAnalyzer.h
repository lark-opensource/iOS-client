//
//  HMDObjectAnalyzer.h
//  Heimdallr
//
//  Created by xushuangqing on 2022/8/15.
//

#ifndef HMDObjectAnalyzer_h
#define HMDObjectAnalyzer_h

#include <stdint.h>
#include <stdbool.h>
#import <Foundation/Foundation.h>
#import "HMDMacro.h"
#import "HMDClassAnalyzer.h"

/*!@function @p HMDObjectAnalyzer_objectIsDeallocating
 * @abstract 获取 object 是否在释放过程中，如果没有把握会返回 @p false
 * @note crash-unsafe 并非崩溃安全
 * @note memory-safe ( with data race ) 内存访问安全，但是可能存在多线程问题
 */
HMD_EXTERN bool HMDObjectAnalyzer_objectIsDeallocating(__unsafe_unretained NSObject * _Nullable object);

/*!@function @p HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe
 * @abstract 获取 object 是否在释放过程中，如果没有把握会返回 @p false
 * @note crash-unsafe 并非崩溃安全
 * @note memory-unsafe 内存访问不安全
 */
HMD_EXTERN bool HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe(void * _Nullable object);

#pragma mark - 需要在 HMDObjectAnalyzer_initialization 调用返回 YES 后可调用

/*!@function @p HMDObjectAnalyzer_initialization
 * @abstract 初始化 HMDObjectAnalyzer 只有初始化过后，HMDObjectAnalyzer 的方法才可以调用喔
 * @note 可能会初始化失败，初始化失败时刻会返回 false
 */
HMD_EXTERN bool HMDObjectAnalyzer_initialization(void);

/*!@function @p HMDObjectAnalyzer_isInitialized
 * @abstract 测试 HMDObjectAnalyzer 是否已经初始化完成
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 */
HMD_EXTERN bool HMDObjectAnalyzer_isInitialized(void);

/*!@typedef @P HMDUnsafeObject
 * @abstract 不安全的 Object 指针类型，并不保证该对象指向的内存有效
 */
typedef void *HMDUnsafeObject;

/*!@function @p HMDObjectAnalyzer_objectGetClass
 * @abstract 获取对象 @p object 的 @p class, 但是 @p class 不一定是正确的
 * @note 需要在 @p HMDObjectAnalyzer_initialization 调用返回 @p YES 后可调用
 * @note crash-safe 崩溃安全
 */
HMD_EXTERN HMDUnsafeClass _Nullable HMDObjectAnalyzer_unsafeObjectGetClass(HMDUnsafeObject _Nullable object);

/*!@function @p HMDObjectAnalyzer_objectGetClassName
 * @abstract 获取对象 @p object 的 @p className, 但是不一定是正确的
 * @note 需要在 @p HMDObjectAnalyzer_initialization 调用返回 @p YES 后可调用
 * @note crash-safe 崩溃安全
 */
HMD_EXTERN bool HMDObjectAnalyzer_unsafeObjectGetClassName(HMDUnsafeObject _Nonnull object, uint8_t * _Nonnull name, size_t length);

#endif /* HMDObjectAnalyzer_h */
