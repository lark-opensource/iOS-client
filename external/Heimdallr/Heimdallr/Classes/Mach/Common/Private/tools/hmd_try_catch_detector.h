//
//  hmd_try_catch_detector.h
//  Pods-Heimdallr_Example
//
//  Created by 白昆仑 on 2020/3/9.
//

#import <stdio.h>
#import <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif
// 检测当前调用栈路径是否被@try-catch包含
// ⚠️注意⚠️：
// 1、在@catch Block中调用此方法，若存在@finally，则返回true
// 2、过滤_dispatch_client_callout 和 CFRunLoopRunSpecific 中 try-catch逻辑
// 3、此方法耗时，请谨慎使用
// ignore_depth：进行栈回溯时，忽略的栈深度，可以通过设置该参数跳过指定层数的栈
extern bool hmd_check_in_try_catch(unsigned int ignore_depth);

#ifdef __cplusplus
}
#endif
