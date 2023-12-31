//
//  HMDCrashAsyncContainer.cpp
//  Pods
//
//  Created by yuanzhangjing on 2019/12/8.
//

#include "HMDCrashAsyncContainer.hpp"
#include <string.h>
using namespace hmd::async_safe;

static void free_entry(hmd_async_dict_entry entry) {
    if (entry.key) {
        free(entry.key);
        entry.key = NULL;
    }
    if (entry.value) {
        free(entry.value);
        entry.value = NULL;
    }
}

void hmd_nasync_dict_init(hmd_async_dict *dict,bool lock_free) {
    dict->_dict = new hmd::async_safe::linked_list<hmd_async_dict_entry>(lock_free);
    dict->_dict->set_free_func(free_entry);
}

void hmd_nasync_dict_free(hmd_async_dict *dict) {
    delete dict->_dict;
}
    
void hmd_nasync_dict_update(hmd_async_dict *dict, const char *key, const char *value) {
    if (!key) {
        return;
    }
    
    hmd_async_dict_entry entry = {
        .key = strdup(key),
        .value = value?strdup(value):NULL
    };
    
    dict->_dict->lock();
    
    hmd::async_safe::linked_list<hmd_async_dict_entry>::node *found = NULL;
    hmd::async_safe::linked_list<hmd_async_dict_entry>::node *node = NULL;
    while ((node = dict->_dict->next_while_lock(node)) != NULL) {
        if (node->value().key && strcmp(key, node->value().key) == 0) {
            found = node;
            break;
        }
    }
    
    if (found) {
        dict->_dict->remove_node_while_lock(found);
    }
    dict->_dict->append_while_lock(entry);

    dict->_dict->unlock();
}

void hmd_nasync_dict_remove(hmd_async_dict *dict, const char *key) {
    if (!key) {
        return;
    }
    
    dict->_dict->lock();
    
    hmd::async_safe::linked_list<hmd_async_dict_entry>::node *found = NULL;
    hmd::async_safe::linked_list<hmd_async_dict_entry>::node *node = NULL;
    while ((node = dict->_dict->next_while_lock(node)) != NULL) {
        if (node->value().key && strcmp(key, node->value().key) == 0) {
            found = node;
            break;
        }
    }
    
    if (found) {
        dict->_dict->remove_node_while_lock(found);
    }

    dict->_dict->unlock();
}

void hmd_async_enumerate_entries(hmd_async_dict *dict, hmd_async_dict_callback callback, void *ctx) {
    if (dict == NULL || callback == NULL) {
        return;
    }
    dict->_dict->async_enumerate_node(callback, ctx);
}
