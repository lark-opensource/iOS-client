//
//  UIViewController+HMDUITracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/20.
//

#include <stdbool.h>
#import <UIKit/UIKit.h>
#import "HMDUITrackableContext.h"
#include "HMDPublicMacro.h"

#ifdef RANGERSAPM
/** @function Heimdallr toB 代码兼容，是否在 UIViewController isa swizzle 时刻关闭 add class method
    @param forbiddenClassImplementation 当是 true 的时刻, 不会在 isa swizzle 时刻添加 add class method
    @discussion 详细的信息见 UIViewController+HMDUITracker.m 文件内注释 */
void HMDUITracker_viewController_isa_swizzle(bool forbiddenClassImplementation);
#endif

@interface UIViewController (HMDUITracker)<HMDUITrackable>

+ (void)hmd_startSwizzle;

@end

#pragma mark - ISA Swizzle Optimization

/*!@function @p HMDUITracker_viewController_enable_ISA_swizzle_optimization
   @param enable 是否启用 ISA Swizzle 优化
   @discussion 详细策略可以见 HMDISAHookOptimization 文件, 这里只是做了简单调用
 */
HMD_EXTERN void HMDUITracker_viewController_enable_ISA_swizzle_optimization(bool enable);

