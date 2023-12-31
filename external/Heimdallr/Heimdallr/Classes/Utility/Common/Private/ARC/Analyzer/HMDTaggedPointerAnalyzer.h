//
//  HMDTaggedPointerAnalyzer.h
//  iOS
//
//  Created by sunrunwang on 2022/11/16.
//

#ifndef HMDTaggedPointerAnalyzer_h
#define HMDTaggedPointerAnalyzer_h

#include <stdbool.h>
#import "HMDClassAnalyzer.h"
#import "HMDObjectAnalyzer.h"
#import "HMDMacro.h"

/*!@function @p HMDTaggedPointerAnalyzer_initialization
 * @abstract 初始化 HMDTaggedPointerAnalyzer 只有初始化过后，HMDTaggedPointerAnalyzer 的方法才可以调用喔
 * @note 可能会初始化失败，初始化失败时刻会返回 false
 */
HMD_EXTERN bool HMDTaggedPointerAnalyzer_initialization(void);

/*!@function @p HMDTaggedPointerAnalyzer_isInitialized
 * @abstract 测试 HMDTaggedPointerAnalyzer 是否已经初始化完成
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 */
HMD_EXTERN bool HMDTaggedPointerAnalyzer_isInitialized(void);

#pragma mark - 需要在 HMDTaggedPointerAnalyzer_initialization 调用返回 YES 后可调用

/*!@function @p HMDTaggedPointerAnalyzer_isTaggedPointer
 * @abstract 返回是否是 taggedPointer
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 * @note 需要在 @p HMDTaggedPointerAnalyzer_initialization 调用返回 @p YES 后可调用
 */
HMD_EXTERN bool HMDTaggedPointerAnalyzer_isTaggedPointer(const HMDUnsafeObject _Nullable object);

/*!@function @p HMDTaggedPointerAnalyzer_taggedPointerGetClass
 * @abstract 返回 taggedPointer 的 Class
 * @note crash-safe 当前方法在崩溃发生的时刻，依然可以安全的调用
 * @note Class 可能因为数据不正确被写坏
 * @note 需要在 @p HMDTaggedPointerAnalyzer_initialization 调用返回 @p YES 后可调用
 */
HMD_EXTERN HMDUnsafeClass _Nullable HMDTaggedPointerAnalyzer_taggedPointerGetClass(const HMDUnsafeObject _Nullable object);

#endif /* HMDTaggedPointerAnalyzer_h */
