//
//  HMDCrashFileBuffer.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashFileBuffer_h
#define HMDCrashFileBuffer_h

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

typedef int HMDCrashFileBuffer;

#define                    HMDCrashFileBufferInvalid -1
#define  FileBuffer        HMDCrashFileBuffer
#define  FileBufferInvalid HMDCrashFileBufferInvalid

#ifdef __cplusplus
extern "C" {
#endif
    
    /**
     Open a write buffer for writing data
     Suppose that you have already create all directory along the path for the file
     
     @param path an url specify the path of the file
     @return return HMDCrashFileBufferInvalid indicate failure
     */
    FileBuffer hmd_file_open_buffer(const char *path);
    
    /**
     Write a str to buffer
     
     @param str a null-terminated string
     @return true if write success, false to log SDK
     */
    bool hmd_file_write_string(FileBuffer buffer, const char *str);
    
    
    /**
     Pump a stream of octal into the buffer
     
     @return true if write success, false to log SDK
     */
    bool hmd_file_write_block(FileBuffer buffer, const void *data, ssize_t bytes);
    
    /**
     Close a writing buffer
     
     @param buffer a buffer returned from OpenBuffer
     @return true if success, false to log SDK
     */
    bool hmd_file_close_buffer(FileBuffer buffer);
    
    bool hmd_file_write_bool(FileBuffer fd, bool val);

    bool hmd_file_write_int64(FileBuffer fd, int64_t val);

    bool hmd_file_write_uint64(FileBuffer fd, uint64_t val);

    bool hmd_file_write_uint64_hex(FileBuffer fd, uint64_t val);

    bool hmd_file_write_hex(FileBuffer fd, const char *val);

    bool hmd_file_write_key(FileBuffer fd, const char *s);

    bool hmd_file_write_hex_string_value(FileBuffer fd, const char *val);

    bool hmd_file_write_string_value(FileBuffer fd, const char *s);

    bool hmd_file_begin_json_array(FileBuffer fd);

    bool hmd_file_end_json_array(FileBuffer fd);

    bool hmd_file_begin_json_object(FileBuffer fd);

    bool hmd_file_end_json_object(FileBuffer fd);

    bool hmd_file_write_key_and_bool(FileBuffer fd, const char *key, bool val);

    bool hmd_file_write_key_and_hex(FileBuffer fd, const char *key, const char *val);

    bool hmd_file_write_key_and_string(FileBuffer fd, const char *key, const char *val);

    bool hmd_file_write_key_and_int64(FileBuffer fd, const char *key, int64_t val);

    bool hmd_file_write_key_and_uint64(FileBuffer fd, const char *key, uint64_t val);

    
#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashFileBuffer_h */
