//
//  HMDCrashAsyncContainer.hpp
//  Pods
//
//  Created by yuanzhangjing on 2019/12/8.
//

#ifndef HMDCrashAsyncContainer_hpp
#define HMDCrashAsyncContainer_hpp

#ifdef __cplusplus
#include "HMDAsyncSafeLinkedList.hpp"
extern "C" {
#endif

typedef struct hmd_async_dict_entry {
    char *key;
    char *value;
} hmd_async_dict_entry;

typedef struct hmd_async_dict {
#ifdef __cplusplus
    hmd::async_safe::linked_list<hmd_async_dict_entry> *_dict;
#else
    void *_dict;
#endif
} hmd_async_dict;

void hmd_nasync_dict_init(hmd_async_dict *dict,bool lock_free); //若lock_free为true，需要外部保证线程安全
void hmd_nasync_dict_free(hmd_async_dict *dict);
    
void hmd_nasync_dict_update(hmd_async_dict *dict, const char *key, const char *value);
void hmd_nasync_dict_remove(hmd_async_dict *dict, const char *key);

typedef void (*hmd_async_dict_callback)(hmd_async_dict_entry entry,int index,bool *stop,void *ctx);
void hmd_async_enumerate_entries(hmd_async_dict *dict, hmd_async_dict_callback callback, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashAsyncContainer_hpp */
