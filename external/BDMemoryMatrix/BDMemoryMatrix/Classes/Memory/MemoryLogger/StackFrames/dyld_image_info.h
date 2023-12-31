/*
 * Tencent is pleased to support the open source community by making wechat-matrix available.
 * Copyright (C) 2019 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the BSD 3-Clause License (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef dyld_image_info_h
#define dyld_image_info_h

#include <mach/vm_types.h>
#include "logger_internal.h"

/**
 * Types
 */
#define DYLD_IMAGE_MACOUNT (512 + 256)
#define MACHO_RENAMED_SEG_TEXT "__BD_TEXT" /* renamed text segment */

struct dyld_image_info_mem {
    uint64_t slide;

    uint64_t vm_str; /* the start address of __TEXT */
    uint64_t vm_end; /* the end address of __TEXT */
    uint64_t fileoff; /* file offset of this segment */
    uint64_t filesize; /* amount to map from the file */
    
    uint64_t vm_str_renamed; /* the start address of renamed __TEXT */
    uint64_t vm_end_renamed; /* the end address of renamed __TEXT */
    uint64_t fileoff_renamed; /*  file offset of renamed __TEXT */
    uint64_t filesize_renamed; /* amount to map from the file renamed __TEXT */
    
    char uuid[33]; /* the 128-bit uuid */
    char image_name[30]; /* name of shared object */
    bool is_app_image; /* whether this image is belong to the APP */

    dyld_image_info_mem(uint64_t _vs = 0, uint64_t _ve = 0) {
        slide = 0;
        
        vm_str = _vs;
        vm_end = _ve;
        fileoff = 0;
        fileoff = 0;
        
        vm_str_renamed = 0;
        vm_end_renamed = 0;
        fileoff_renamed = 0;
        fileoff_renamed = 0;
        
        uuid[0] = 0;
        image_name[0] = 0;
        is_app_image = false;
    }

    inline bool is_same(const dyld_image_info_mem &another) const {
        return another.vm_str >= vm_str && another.vm_str < vm_end;
    }
    
    inline bool contain_address(uint64_t address) const {
        return address >= vm_str && address < vm_end;
    }
    
    inline bool contain_address_renamed(uint64_t address) const {
        if (vm_str_renamed > 0) {
            return address >= vm_str_renamed && address < vm_end_renamed;
        }
        return false;
    }

    inline bool after(const dyld_image_info_mem &another) const {
        return vm_str > another.vm_str;
    }
};

struct dyld_image_info_db {
    int fd;
    int fs;
    int count;
    void *buff;
    malloc_lock_s lock;
    dyld_image_info_mem list[DYLD_IMAGE_MACOUNT];
};

/**
 * The filtering strategy of the stack
 *
 * If the malloc size more than 'skipMinMallocSize', the stack will be saved.
 * Otherwise if the stack contains App's symbols in the last 'skipMaxStackDepth' address,
 * the stack also be saved.
 */
extern int skip_max_stack_depth;
extern int skip_min_malloc_size;


dyld_image_info_db *prepare_dyld_image_logger(const char *event_dir);
bool is_stack_frames_should_skip(uintptr_t *frames, int32_t count, uint64_t malloc_size);
const char *app_uuid();

dyld_image_info_db *dyld_image_info_db_open_or_create(const char *event_dir);
void dyld_image_info_db_close(dyld_image_info_db *db_context);


#endif /* dyld_image_info_h */
