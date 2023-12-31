//
//  HMDClassAnalyzer.h
//  iOS
//
//  Created by sunrunwang on 2022/11/17.
//

#ifndef HMDClassAnalyzer_h
#define HMDClassAnalyzer_h

#include <stdint.h>
#include <stdbool.h>
#include "HMDMacro.h"

/*!@typedef @P HMDUnsafeClass
 * @abstract 不安全的 Class 类型，并不保证返回的 Class 类型是安全的数据
 */
typedef void *HMDUnsafeClass;

/*!@function @p HMDClassAnalyzer_unsafeClassGetName
 * @abstract 获取 Class 对应的名称
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 */
HMD_EXTERN bool HMDClassAnalyzer_unsafeClassGetName(HMDUnsafeClass _Nonnull aClass, uint8_t * _Nonnull name, size_t length);

/*!@function @p HMDClassAnalyzer_unsafeClassGetSuperClass
 * @abstract 获取 Class 对应的 superClass
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 */
HMD_EXTERN bool HMDClassAnalyzer_unsafeClassGetSuperClass(HMDUnsafeClass _Nonnull aClass, HMDUnsafeClass _Nullable  * _Nonnull superClass);

#endif /* HMDClassAnalyzer_h */
