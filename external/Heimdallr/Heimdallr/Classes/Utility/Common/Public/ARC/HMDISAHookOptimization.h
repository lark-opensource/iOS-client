//
//  HMDISAHookOptimization.h
//  Pods
//
//  Created by sunrunwang on yesterday
//

#ifndef HMDISAHookOptimization_h
#define HMDISAHookOptimization_h

#include "HMDPublicMacro.h"

/*!@function @p HMDISAHookOptimization_initialization
   @discussion 初始化，要调用以后，后面两个方法才能生效
 */
HMD_EXTERN void HMDISAHookOptimization_initialization(void);

HMD_EXTERN int HMDISAHookOptimization_before_objc_allocate_classPair(void);

HMD_EXTERN void HMDISAHookOptimization_after_objc_allocate_classPair(int before_value);

#endif /* HMDISAHookOptimization_h */
