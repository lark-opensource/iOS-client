
/*!@header HMDCrashPreventMachRestartableDefinition.h
 * @abstract Mach Restartable 防护的参数
 *
 * @discussion [ 业务使用方 ] 使用请参考注释，若提及不可使用，请与 Heimdallr 开发讨论，务必严格准守
 *             [ Heimdallr 维护者 ] 该文档需要和 HMDMachRestartableDeclaration.h 文件参数相同对应，请 double check 它们的关系
 */

#ifndef HMDMachRestartableDeclaration_h
#define HMDMachRestartableDeclaration_h

#include <stdint.h>
#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

#pragma mark - Public Declaration

/*!
 * @const @p HMD_MACH_RESTARTABLE_OFFSET_MAX
 * The maximum value @p length or @p recovery_offs can have.
 */
#ifndef HMD_MACH_RESTARTABLE_OFFSET_MAX
#define HMD_MACH_RESTARTABLE_OFFSET_MAX  UINT64_C(0x1000)
#endif

/*!@struct @p HMDMachRestartable_range
   @code 当且仅当，PC 位置处于 [location, location + length - 1] 范围时，
         发生崩溃才会把 PC 移动到 location + recovery_offs 位置
 */
struct HMDMachRestartable_range {
    uint64_t   location;
    uint64_t   length;
    uint64_t   recovery_offs;
    uint64_t   unused;  // pass zero currently
};

typedef struct HMDMachRestartable_range HMDMachRestartable_range;

typedef HMDMachRestartable_range * HMDMachRestartable_range_ref;

HMD_EXTERN_SCOPE_END

#endif /* HMDMachRestartableDeclaration_h */
