//
//  HMDCrashPreventMachException.h
//  Pods
//
//  Created by bytedance on 2022/5/12.
//

#ifndef HMDCrashPreventMachException_h
#define HMDCrashPreventMachException_h

#include "HMDPublicMacro.h"
#include "HMDCrashPreventMachExceptionDefinition.h"

HMD_EXTERN_SCOPE_BEGIN

/*!@function HMDCrashPreventMachExceptionProtect
   @param scope 保护方法的标识字段

    @b scope命名规范

     1. 公司内项目，无论是否对外 toB 统一使用 @p com.bytedance 开头
     2. 使用点 . 进行分割，全文除去大小写字母，数字，点，下划线，结尾 ‘\0’ 字符以外不允许别的字符存在
     3. 点用于分割字段，如果经过划分后发现有空段、非法字符，视为错误
     4. 同一个 SDK 使用相同的开始标记符号，划分尽可能详细
     5. 字符串总长度请限制在 256 字节以内 ( 包含结尾 ‘\0’ 字符 ) [ 这个限制很宽容的咯 ]
     6. 空字符串不被认为是有效的字段

    例如 VE 视频剪切项目的 AB 实验
    @p com.bytedance.videoEditor.videoCompile.audioGenerate.ABTest.NO_173809.groupB

    例如 TikTok 自拍模块
    @p com.bytedance.TikTok.CameraKit.selfie

    推荐格式
    @p com.公司名.(SDK/APP名称).(细分功能)[.细分功能][.对应的功能开关/实验名]

   @param option 该次处理异常期望使用的功能参数，详细请转跳定义查看
   @param context 该参数若非必要请勿使用，传递默认参数 NULL 即可，使用需要与 Heimdallr 开发人员沟通
   @param block 执行调用的 block，block 包含可能会导致崩溃的代码
   @return 返回参数为 YES，代表发生了 Mach 崩溃；返回为 NO，代表没有发生崩溃
 */
bool HMDCrashPreventMachExceptionProtect(const char * _Nonnull scope,
                                         HMDMachRecoverOption option,
                                         HMDMachRecoverContextRef _Nullable context,
                                         void(^ _Nonnull block)(void)) HMD_NOINLINE HMD_NOT_TAIL_CALLED;

HMD_EXTERN_SCOPE_END

#endif /* HMDCrashPreventMachException_h */
