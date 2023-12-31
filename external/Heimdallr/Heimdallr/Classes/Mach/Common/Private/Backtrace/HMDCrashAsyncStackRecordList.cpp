//
//  HMDCrashAsyncStackRecordList.cpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/10/20.
//

#include "HMDCrashAsyncStackRecordList.h"

using namespace hmd::async_safe;

static void free_value(hmd_async_stack_record_t *value) {
    if (value) {
        free(value);
    }
}

void hmd_nasync_stack_record_list_init(hmd_async_stack_record_list *list) {
    if (list == NULL) {
        return;
    }
    list->_list = new linked_list<hmd_async_stack_record_t *>();
    list->_main_thread_list = new linked_list<hmd_async_stack_record_t *>(true);
    list->_list->set_free_func(free_value);
    list->_main_thread_list->set_free_func(free_value);
}

void hmd_nasync_stack_record_free(hmd_async_stack_record_list *list) {
    if (list == NULL) {
        return;
    }
    
    delete list->_list;
    delete list->_main_thread_list;
}
    
void* hmd_nasync_stack_record_append(hmd_async_stack_record_list *list, hmd_async_stack_record_t *record) {
    if (list == NULL) {
        return NULL;
    }
    
    if (pthread_main_np() == 0) {
        return list->_list->append(record);
    } else {
        return list->_main_thread_list->append(record);
    }
}

void hmd_nasync_stack_record_remove(hmd_async_stack_record_list *list, hmd_async_stack_record_t *record) {
    if (list == NULL) {
        return;
    }
    
    if (pthread_main_np() == 0) {
        list->_list->remove(record);
    } else {
        list->_main_thread_list->remove(record);
    }
}

void hmd_nasync_stack_record_remove_node(hmd_async_stack_record_list *list, void *node) {
    if (list == NULL) {
        return;
    }
    
    if (pthread_main_np() == 0) {
        list->_list->remove_node((linked_list<hmd_async_stack_record_t *>::node *)node);
    } else {
        list->_main_thread_list->remove_node((linked_list<hmd_async_stack_record_t *>::node *)node);
    }
}

void hmd_async_stack_record_list_set_reading(hmd_async_stack_record_list *list, bool enable) {
    if (list == NULL) {
        return;
    }
    list->_list->set_reading(enable);
    list->_main_thread_list->set_reading(enable);
}

hmd_async_stack_record_t *hmd_async_stack_record_with_mach_thread(hmd_async_stack_record_list *list, thread_t thread) {
    if (list == NULL) {
        return NULL;
    }
    __block hmd_async_stack_record_t *record = NULL;
    list->_main_thread_list->enumerate_node_with_lock(^(hmd_async_stack_record_t *value, int index, bool *stop) {
        if (value->thread == thread) {
            record = value;
            *stop = true;
        }
    });
    if (record) return record;
    
    list->_list->enumerate_node_with_lock(^(hmd_async_stack_record_t *value, int index, bool *stop) {
        if (value->thread == thread) {
            record = value;
            *stop = true;
        }
    });
    return record;
}

hmd_async_stack_record_t *hmd_async_stack_record_with_pthread(hmd_async_stack_record_list *list, pthread_t pthread) {
    if (list == NULL) {
        return NULL;
    }
    __block hmd_async_stack_record_t *record = NULL;
    list->_main_thread_list->enumerate_node_with_lock(^(hmd_async_stack_record_t *value, int index, bool *stop) {
        if (value->pthread == pthread) {
            record = value;
            *stop = true;
        }
    });
    if (record) return record;
    
    list->_list->enumerate_node_with_lock(^(hmd_async_stack_record_t *value, int index, bool *stop) {
        if (value->pthread == pthread) {
            record = value;
            *stop = true;
        }
    });
    return record;
}

hmd_async_stack_record_t *hmd_async_stack_record_with_current_thread(hmd_async_stack_record_list *list) {
    if (list == NULL) {
        return NULL;
    }
    pthread_t pthread = pthread_self();
    return hmd_async_stack_record_with_pthread(list, pthread);
}
