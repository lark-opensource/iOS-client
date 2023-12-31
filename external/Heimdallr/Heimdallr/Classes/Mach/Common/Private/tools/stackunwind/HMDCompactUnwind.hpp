/*!@header HMDCompactUnwind.hpp
 
    @name this file has nothing to do with its name @p compact_unwind, actual name
          should be @p shared_image_list or something like that
 
    @note because I don't want to rename file, so let it be like that
 */

#ifndef HMDCompactUnwind_hpp
#define HMDCompactUnwind_hpp

#include <dispatch/dispatch.h>
#include "HMDAsyncImageList.h"
#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

#pragma mark shared images

extern hmd_async_image_list_t shared_image_list;
extern hmd_async_image_list_t shared_app_image_list;

#pragma mark setup lists

void hmd_setup_shared_image_list_if_need(void);

void hmd_setup_shared_image_list(void);

/// 是否开始初始化，注意初始化是异步到子线程的，所以开始了并不等于完成
bool hmd_async_share_image_list_has_setup(void);

/// 是否结束了初始化，意味着大部分镜像信息是可用状态
bool hmd_async_share_image_list_finished_setup(void);

// a version number use to check whether image list has been updated
int hmd_async_share_image_list_version(void);

#pragma mark Image list enumerate

void hmd_enumerate_image_list_using_block(hmd_image_callback_block _Nonnull block);

void hmd_enumerate_app_image_list_using_block(hmd_image_callback_block _Nonnull block);

void hmd_async_enumerate_image_list(hmd_image_callback_func _Nonnull callback, void * _Nullable ctx);

#pragma mark image queue (metric kit)

dispatch_queue_t _Nullable hmd_shared_binary_image_queue(void);

#pragma mark register finish callback (crash prevent)

typedef void (*hmd_image_finish_callback)(void);

// 我知道这个接口有点没扩展性，但是目前就 CrashPrevent 会强需求该接口，整复杂感觉意义不大
// 该文件是 Private 其实还好，如果后续要扩展可以参考 HMDCrashExtraDynamicData 文件进行进化
void hmd_shared_binary_image_register_finish_callback(hmd_image_finish_callback _Nonnull callback);

HMD_EXTERN_SCOPE_END

#endif /* HMDCompactUnwind_hpp */
