
/*!@header HMDMachRecoverDeclaration.h
 * @abstract Mach 异常防护的参数，改变异常防护的行为
 *
 * @discussion [ 业务使用方 ] 使用请参考注释，若提及不可使用，请与 Heimdallr 开发讨论，务必严格准守
 *             [ Heimdallr 维护者 ] 该文档需要和 HMDCrashPreventMachExceptionDefinition.h 文件参数相同对应，请 double check 它们的关系
 */

#ifndef HMDMachRecoverDeclaration_h
#define HMDMachRecoverDeclaration_h

#include <stdint.h>
#include "HMDFrameRecoverPublicMacro.h"

HMDFC_EXTERN_SCOPE_BEGIN

#pragma mark - Public Declaration

typedef enum : uint64_t {
    
    // [1] ExceptionType [当前需要保护的崩溃类型]
    HMDMachRecoverOptionExceptionType_EXC_BAD_ACCESS      = 1 << 0,     // 保护 EXC_BAD_ACCESS      类型崩溃
    HMDMachRecoverOptionExceptionType_EXC_BREAKPOINT      = 1 << 1,     // 保护 EXC_BREAKPOINT      类型崩溃
    HMDMachRecoverOptionExceptionType_EXC_BAD_INSTRUCTION = 1 << 2,     // 保护 EXC_BAD_INSTRUCTION 类型崩溃
    HMDMachRecoverOptionExceptionType_EXC_ARITHMETIC      = 1 << 3,     // 保护 EXC_ARITHMETIC      类型崩溃
    HMDMachRecoverOptionExceptionType_ALL                 = 0xF,        // 保护 当前所有可支持类型崩溃
    HMDMachRecoverOptionExceptionType_MASK                = 0x1FFF,     // 保留区间 indexed within 0-12
    
    // [2] ScopeCheckType [是否保护检查]
    HMDMachRecoverOptionScopeCheckType_disableCheck       = 1 << 13,    // ⚠️ 使用该参数需要与 Heimdallr 开发沟通
    HMDMachRecoverOptionScopeCheckType_checkWhenCrash     = 1 << 14,    // ⚠️ 使用该参数需要与 Heimdallr 开发沟通
    
    // [3] Extension [扩展功能]
    HMDMachRecoverOptionExtension_backtraceDepth          = 1 << 15,    // 指明栈回溯最大深度, 大于此回溯深度的崩溃, 并不会被恢复
    HMDMachRecoverOptionExtension_strictExceptionCheck    = 1 << 16,    // 强制崩溃类型校验, 目前崩溃类型校验会比较"宽容", 详细见文档
    
    HMDMachRecoverOptionImpossible,                                     // 非 Heimdallr 内部请勿使用该参数
} HMDMachRecoverOption;

struct HMDMachRecoverContext {
    uint64_t context_size;          // 请传递参数 .context_size = sizeof(HMDMachRecoverContext)  [validate]
    uint64_t reserved0;             // checksum     [force calculate]
    uint64_t reserved1;             // option       [force assign]
    uint64_t reserved2;             // scope        [force assign]
    uint64_t reserved3;             // reserved     [whatever]
    uint64_t reserved4;             // reserved     [whatever]
    uint64_t backtrace_depth;       //              [whatever]
    uint64_t scope_length;          //              [whatever]
    
    /* HMDMachRecoverContext_version 0 end */
    
} HMDFC_PACKED HMDFC_ALIGNED(8);

typedef struct HMDMachRecoverContext  HMDMachRecoverContext;
typedef struct HMDMachRecoverContext *HMDMachRecoverContextRef;

HMDFC_EXTERN_SCOPE_END

#endif /* HMDMachRecoverDeclaration_h */
