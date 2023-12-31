
/*!@file HMDCrashDynamicSavedFiles.c
 */

#include <stdlib.h>
#include <stdbool.h>
#include <stddef.h>
#include "HMDMacro.h"
#include "HMDCrashDynamicSavedFiles.h"

#define HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT 8

/// @code shared_paths 是固定分配好长度的 array, 如果没有分配，或者暂时被拿出来的话为 NULL
/// 否则是个长度为 HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT + 1 的 array
///   [path] [path] [path] ... [NULL] [NULL]
/// 使用 NULL 标记结尾位置，肯定至少有一个 NULL
/// 每个 [path] 指向一个 const char * 字符串, 每个字符串会 strdup, 释放的时刻需要 free

static const char * _Nonnull * _Nullable shared_paths = NULL;

static const char * _Nonnull * _Nullable fetch_shared_paths(bool allocate_if_not_exist);
static void give_back_shared_paths(const char * _Nonnull * _Nonnull paths);

#pragma mark - Dynamic Saved Files API

void HMDCrashDynamicSavedFiles_registerFilePath(const char * _Nonnull path) {
    if(path == NULL) DEBUG_RETURN_NONE;
    
    const char * _Nonnull * _Nullable current = fetch_shared_paths(true);
    if(current == NULL) DEBUG_RETURN_NONE;
    
    size_t index;
    for(index = 0; index < HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT; index++) {
        if(current[index] == NULL)
            break;
    }
    
    if(index >= HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT)
        goto clean_give_back;
    
    path = strdup(path);
    DEBUG_ASSERT(path != NULL);
    current[index] = path;
    
clean_give_back:
    give_back_shared_paths(current);
}

void HMDCrashDynamicSavedFiles_unregisterFilePath(const char * _Nonnull path) {
    if(path == NULL) DEBUG_RETURN_NONE;
    
    const char * _Nonnull * _Nullable current = fetch_shared_paths(true);
    if(current == NULL) DEBUG_RETURN_NONE;
    

    bool found_match_index = false;
    size_t match_index = SIZE_MAX;
    
    for(size_t index = 0; index < HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT; index++) {
        if(current[index] == NULL) break;
        
        if(strcmp(current[index], path) == 0) {
            found_match_index = true;
            match_index = index;
            break;
        }
    }
    
    if(!found_match_index)
        goto clean_give_back;
    
    DEBUG_ASSERT(match_index < HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT);
    
    char *need_free_string = (char *)current[match_index];
    
    // 因为至少分配了 HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT + 1 的空间
    current[HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT] = NULL;
    
    for(size_t index = match_index; index < HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT; index++) {
        current[index] = current[index + 1];
    }
    
    free(need_free_string);
    
clean_give_back:
    give_back_shared_paths(current);
}

void HMDCrashDynamicSavedFiles_getCurrentFiles(const char * _Nonnull * _Nullable * _Nonnull paths,
                                               size_t * _Nonnull count) HMD_PRIVATE {
    DEBUG_ASSERT(paths != NULL && count != NULL);
    
    const char * _Nonnull * _Nullable current = fetch_shared_paths(false);
    
    size_t current_count = 0;
    
    if(current == NULL) goto write_result;
    
    for(size_t index = 0; index < HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT; index++)
        if(current[index] != NULL) current_count++;
  
write_result:
    
    paths[0] = current;
    count[0] = current_count;
}

#pragma mark - Tools

static const char * _Nonnull * _Nullable fetch_shared_paths(bool allocate_if_not_exist) {
    
    const char * _Nonnull * _Nullable current = __atomic_exchange_n(&shared_paths, NULL, __ATOMIC_ACQ_REL);
    
    DEBUG_ASSERT(current == NULL || VM_ADDRESS_CONTAIN(current));
    
    if(current != NULL && VM_ADDRESS_CONTAIN(current))
        return current;
    
    if(!allocate_if_not_exist) return NULL;
    
    current = calloc(HMD_CRASH_DYNAMIC_SAVED_FILES_MAX_COUNT + 1, sizeof(const char *));
    if(current == NULL) return NULL;
    
    return current;
}

static void give_back_shared_paths(const char * _Nonnull * _Nonnull paths) {
    if(paths == NULL) DEBUG_RETURN_NONE;
    
    const char * _Nonnull * _Nullable expect_null = NULL;
    
    bool result = __atomic_compare_exchange_n(&shared_paths, &expect_null, paths, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
    
    // 如果出现极其意外的情况，我们清空 shared_paths, 并且拒绝释放内存
    DEBUG_ASSERT(result);
    if(!result) __atomic_store_n(&shared_paths, NULL, __ATOMIC_RELEASE);
}
