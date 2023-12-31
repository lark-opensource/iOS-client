/*! @header HMDCrashDynamicSavedFiles.h
    @note 注册上报的 Saved Files 内容
 */

#ifndef HMDCrashDynamicSavedFiles_h
#define HMDCrashDynamicSavedFiles_h

#include <mach/mach.h>
#include <stdint.h>
#include "HMDPublicMacro.h"

/// 单个文件最大上传大小是 5MB
#define HMD_CRASH_DYNAMIC_SAVED_FILE_MAX_SIZE UINT64_C(0x500000)

/// 总共文件上传的累积大小是 10MB
/// 若后续上传大小会大于 10MB，那么会直接开始丢弃
#define HMD_CRASH_DYNAMIC_SAVED_FILES_TOTAL_SIZE_LIMIT UINT64_C(0x1000000)

HMD_EXTERN_SCOPE_BEGIN

/*!@function @p HMDCrashDynamicSavedFiles_registerFilePath
   @param path 需要保存文件的  @b 沙盒相对路径 , heimdallr 内部会 strdup 路径，所以没有必要保存
   @warning ⚠️⚠️⚠️ HMDCrashDynamicSavedFiles 应该在单一线程调用
 

   @example @code
   NSString *path = xxx;   // 你获取路径的方式
   path = [path stringByStandardizingPath];
   HMDCrashDynamicSavedFiles_registerFilePath(path.UTF8String);
   \@endcode
 */
void HMDCrashDynamicSavedFiles_registerFilePath(const char * _Nonnull path);

void HMDCrashDynamicSavedFiles_unregisterFilePath(const char * _Nonnull path);

#pragma mark - Private

void HMDCrashDynamicSavedFiles_getCurrentFiles(const char * _Nonnull * _Nullable * _Nonnull paths,
                                               size_t * _Nonnull count) HMD_PRIVATE;

HMD_EXTERN_SCOPE_END

#endif /* HMDCrashDynamicSavedFiles_h */
