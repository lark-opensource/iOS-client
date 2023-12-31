//
//  hmd_mach.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/2/23.
//

#ifndef hmd_mach_h
#define hmd_mach_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <dlfcn.h>
#include <mach/vm_region.h>

#ifdef __LP64__
typedef struct vm_region_basic_info_64 hmd_vm_region_basic_info;
#else
typedef struct vm_region_basic_info    hmd_vm_region_basic_info;
#endif
typedef hmd_vm_region_basic_info * hmd_vm_region_basic_info_t;

/** Get the name of a mach exception.
 *
 * @param exceptionType The exception type.
 *
 * @return The exception's name or NULL if not found.
 */
const char * _Nullable hmdmach_exceptionName(int64_t exceptionType);

const char * _Nullable hmdmach_codeName(int64_t exceptionType, int64_t code);

/** Get the name of a mach kernel return code.
 *
 * @param returnCode The return code.
 *
 * @return The code's name or NULL if not found.
 */
const char * _Nullable hmdmach_kernelReturnCodeName(int64_t returnCode);

/** Get the signal equivalent of a mach exception.
 *
 * @param exception The mach exception.
 *
 * @param code The mach exception code.
 *
 * @return The matching signal, or 0 if not found.
 */
int hmdmach_signalForMachException(int exception, int64_t code);

/** Get the mach exception equivalent of a signal.
 *
 * @param signal The signal.
 *
 * @return The matching mach exception, or 0 if not found.
 */
int hmdmach_machExceptionForSignal(int signal);
    
/*
 * only image info returned
 */
bool hmd_dladdr(const uintptr_t address, Dl_info * _Nonnull const info) __deprecated;


/*! @function hmd_vm_region_query_basic_info
 *
 *  @param address 传入参数为当前请求的内存状态的地址，如果查询成功，会更改为包含该地址的分配空间起始位置 ( 当然也就页对齐了 0x1000 )
 *  @param size 可以为 NULL，传入值是多少并没有价值，如果查询成功，那么会更改为包含地址的分配空间的大小
 *  @param info 查询的结果，包含权限等信息
 *  @return true 如果查询成功，false 如果查询失败 ( 一般由于该地址不可访问 )，注意查询成功也不意味着该地址可读写等，这取决于权限
 *  @example 假设判断 void *unsafePointer 指向的空间是否可读写，那么应该
 *      void *address = unsafePointer;
 *      vm_size_t size;
 *      CA_vm_region_basic_info info;
 *      bool result = CA_vm_region_query_basic_info(&address, &size, &info);
 *      if(result) {
 *         查询成功的条件下, address 会更改为当前 region 的起始位置，假设 unsafePointer 是 0xEF123，那么 address 会更改为 0xEF000 ( 页对齐 )，或者更早的页，例如 0xEE000，0xEC000 等
 *         然后 size 会更改为当前 region 的大小，无论如何更新后的 address 和 size 值，所形成的区间 [address, address + size) 会包含 unsafePointer 的地址
 *      }
 */
bool hmd_vm_region_query_basic_info(void * _Nullable * _Nonnull address, vm_size_t * _Nullable size, hmd_vm_region_basic_info_t _Nonnull info);

#ifdef __cplusplus
}
#endif
#endif /* hmd_mach_h */
