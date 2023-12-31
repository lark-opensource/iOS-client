//
//  HMDCrashException_dynamicData.c
//  Pods
//
//  Created by someone on 2022/1/5.
//

#include <unistd.h>
#include "HMDMacro.h"
#include "HMDCrashDynamicData.h"
#include "HMDCrashException_dynamicData.h"
#include "HMDCrashDirectory_LowLevel.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashExtraDynamicData.h"
#include "HMDCrashGameScriptStack.h"
#include "HMDCrashDynamicSavedFiles.h"
#include "HMDABTestVids.h"

static FileBuffer dynamic_buffer = FileBufferInvalid;

bool hmd_exception_dynamic_create_file(void) {
    
    const char *dynamic_path = HMDCrashDirectory_dynamic_data_path();
    
    dynamic_buffer = hmd_file_open_buffer(dynamic_path);
    
    if(dynamic_buffer == FileBufferInvalid)
        return false;
    
    return true;
}

bool hmd_exception_close_dynamic_data_file(void) {
    if(dynamic_buffer == FileBufferInvalid)
        DEBUG_RETURN(false);
    
    return hmd_file_close_buffer(dynamic_buffer);
}

#pragma mark - write dynamic

//          {
//              "dynamic":{
//                  "key1": "hex_encoded_string1",
//                  "key2": "hex_encoded_string2"
//              }
//          }

static void dynamic_data_enumerate_callback(hmd_async_dict_entry entry,
                                            int index, bool *stop, void *ctx);

void hmd_exception_dynamic_write_dynamic_info(void) {
    hmd_file_begin_json_object(dynamic_buffer);
    hmd_file_write_key(dynamic_buffer, "dynamic");
    hmd_file_write_string(dynamic_buffer, ":");
    hmd_file_begin_json_object(dynamic_buffer);
    
    bool first_entry = true;
    hmd_crash_async_enumerate_entries(dynamic_data_enumerate_callback, &first_entry);

    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_write_string(dynamic_buffer, "\n");
}

static void dynamic_data_enumerate_callback(hmd_async_dict_entry entry,int index,bool *stop,void *ctx) {
    bool *is_first_entry = ctx;
    bool write_dot = true;
    if (is_first_entry) {
        if (*is_first_entry) {
            write_dot = false;
        }
        *is_first_entry = false;
    }
    if (write_dot) {
        hmd_file_write_string(dynamic_buffer, ",");
    }
    hmd_file_write_key_and_hex(dynamic_buffer, entry.key, entry.value);
}

#pragma mark - write extra dynamic


//          {
//              "extra_dynamic":{
//                  "key1": "hex_encoded_string1",
//                  "key2": "hex_encoded_string2"
//              }
//          }

static void extra_dynamic_data_enumerate_callback(const char *key, const char *value, void *ctx);

void hmd_exception_dynamic_write_extra_dynamic_info(uint64_t crash_time,
                                                    uint64_t fault_address,
                                                    thread_t current_thread,
                                                    thread_t crash_thread) {
    if(!hmd_crash_has_extra_dynamic_data_callback()) return;
    
    hmd_file_begin_json_object(dynamic_buffer);
    hmd_file_write_key(dynamic_buffer, "extra_dynamic");
    hmd_file_write_string(dynamic_buffer, ":");
    hmd_file_begin_json_object(dynamic_buffer);
    
    bool first_entry = true;
    hmd_crash_async_enumerate_extra_dynamic_data(crash_time, fault_address, current_thread, crash_thread,  extra_dynamic_data_enumerate_callback, &first_entry);

    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_write_string(dynamic_buffer, "\n");
}

//!     vid-info->vids input is @p "7777777","7777778" and is checked within character range a-z 0-9 by input module
//          {
//              "vid":["7777777","7777778"]
//          }

void hmd_exception_dynamic_write_vid(uint64_t crash_time,
                                    uint64_t fault_address,
                                    thread_t current_thread,
                                    thread_t crash_thread) {
    
    hmd_ab_test_vids_t *vid_info = hmd_get_vid_info();
    if (vid_info && vid_info->vid_count >0 && vid_info->offset < HMD_MAX_VID_LIST_LENGTH) {
        hmd_file_begin_json_object(dynamic_buffer);
        hmd_file_write_key(dynamic_buffer, "vids");
        hmd_file_write_string(dynamic_buffer, ":");
        hmd_file_begin_json_array(dynamic_buffer);
        const uint8_t * buf = (uint8_t *)vid_info->vids;
        hmd_file_write_block(dynamic_buffer, buf, vid_info->offset);
        hmd_file_end_json_array(dynamic_buffer);
        hmd_file_end_json_object(dynamic_buffer);
        hmd_file_write_string(dynamic_buffer, "\n");
    }
}

static void extra_dynamic_data_enumerate_callback(const char *key, const char *value, void *ctx) {
    bool *is_first_entry = ctx;
    bool write_dot = true;
    if (is_first_entry) {
        if (*is_first_entry) {
            write_dot = false;
        }
        *is_first_entry = false;
    }
    if (write_dot) {
        hmd_file_write_string(dynamic_buffer, ",");
    }
    hmd_file_write_key_and_hex(dynamic_buffer, key, value);
}

#pragma mark - save files

//          {
//              "save_files":[
//                  "relative_path",    最终会拼接 NSHomeDirectory
//                  "relative_path"
//              ]
//          }

void hmd_exception_dynamic_write_save_files(void) {
    const char * _Nonnull * _Nullable paths = NULL;
    size_t count = 0;
    
    HMDCrashDynamicSavedFiles_getCurrentFiles(&paths, &count);
    if(paths == NULL || count == 0) return;
    
    hmd_file_begin_json_object(dynamic_buffer);
    hmd_file_write_key(dynamic_buffer, "save_files");
    hmd_file_write_string(dynamic_buffer, ":");
    hmd_file_begin_json_array(dynamic_buffer);
    
    for(size_t index = 0; index < count; index++) {
        if(index != 0) hmd_file_write_string(dynamic_buffer, ",");
        hmd_file_write_string_value(dynamic_buffer, paths[index]);
    }
    
    hmd_file_end_json_array(dynamic_buffer);
    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_write_string(dynamic_buffer, "\n");
}

#pragma mark - game script stack

//           {
//               "game_script_stack": "hex_encoded_game_script_stack"
//           }

void hmd_exception_dynamic_write_game_script_stack(uint64_t crash_time,
                                                   uint64_t fault_address,
                                                   thread_t current_thread,
                                                   thread_t crash_thread) {
    HMDCrashGameScriptCallback _Nullable callback =
        HMDCrashGameScriptStack_currentCallback();
    
    if(callback == NULL) return;
    
    char * _Nullable crash_data = NULL;
    
    callback(&crash_data, crash_time, fault_address, current_thread, crash_thread);
    if(crash_data == NULL) return;
    
    hmd_file_begin_json_object(dynamic_buffer);
    hmd_file_write_key_and_hex(dynamic_buffer, "game_script_stack", crash_data);
    hmd_file_end_json_object(dynamic_buffer);
    hmd_file_write_string(dynamic_buffer, "\n");
}
