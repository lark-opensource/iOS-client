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

#include <assert.h>
#include <dlfcn.h>
#include <unistd.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <pthread/pthread.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/mman.h>

#include "dyld_image_info.h"
#include "bundle_name_helper.h"

#pragma mark -
#pragma mark Constants/Globals

static dyld_image_info_db *s_image_info_db = NULL;

extern bool matrix_stop_logging;

int skip_max_stack_depth;
int skip_min_malloc_size;

static dyld_image_info_mem app_image_info = { 0 }; // Infos of all app images including embeded frameworks
static dyld_image_info_mem mmap_func_info = { 0 };

static const char *g_app_bundle_name = NULL;
static const char *g_app_name = NULL;

#pragma mark -
#pragma mark DYLD

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

static void __save_to_file() {
    if (s_image_info_db->fd < 0) {
        return;
    }

    memcpy(s_image_info_db->buff, s_image_info_db, sizeof(dyld_image_info_db));
    msync(s_image_info_db->buff, s_image_info_db->fs, MS_SYNC);
}

static void __add_info_for_image(const struct mach_header *header, intptr_t slide) {
    __malloc_lock_lock(&s_image_info_db->lock);

    if (s_image_info_db->count >= DYLD_IMAGE_MACOUNT) {
        __malloc_lock_unlock(&s_image_info_db->lock);
        return;
    }

    dyld_image_info_mem image_info = { 0 };
    image_info.slide = (uint64_t)slide;
    
    bool is_current_app_image = false;

    segment_command_t *cur_seg_cmd = NULL;
    segment_command_t *linkedit_segment = NULL;
    struct symtab_command *symtab_cmd = NULL;
    uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    for (int i = 0; i < header->ncmds; ++i, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *)cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit_segment = cur_seg_cmd;
            } else if (strcmp(cur_seg_cmd->segname, SEG_TEXT) == 0) {
                image_info.vm_str = slide + cur_seg_cmd->vmaddr;
                image_info.vm_end = image_info.vm_str + cur_seg_cmd->vmsize;
                image_info.fileoff = cur_seg_cmd->fileoff;
                image_info.filesize = cur_seg_cmd->filesize;
            } else if (strcmp(cur_seg_cmd->segname, MACHO_RENAMED_SEG_TEXT) == 0) {
                image_info.vm_str_renamed = slide + cur_seg_cmd->vmaddr;
                image_info.vm_end_renamed = image_info.vm_str_renamed + cur_seg_cmd->vmsize;
                image_info.fileoff_renamed = cur_seg_cmd->fileoff;
                image_info.filesize_renamed = cur_seg_cmd->filesize;
            }
        } else if (cur_seg_cmd->cmd == LC_UUID) {
            const char hexStr[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
            uint8_t *uuid = ((struct uuid_command *)cur_seg_cmd)->uuid;

            for (int i = 0; i < 16; ++i) {
                image_info.uuid[i * 2] = hexStr[uuid[i] >> 4];
                image_info.uuid[i * 2 + 1] = hexStr[uuid[i] & 0xf];
            }
            image_info.uuid[32] = 0;

            Dl_info info = { 0 };
            if (dladdr(header, &info) != 0 && info.dli_fname) {
                if (strlen(info.dli_fname) > strlen(g_app_name)
                    && !memcmp(info.dli_fname + strlen(info.dli_fname) - strlen(g_app_name), g_app_name, strlen(g_app_name))) {
                    is_current_app_image = true;
                }
                if (strrchr(info.dli_fname, '/') != NULL) {
                    strncpy(image_info.image_name, strrchr(info.dli_fname, '/') + 1, sizeof(image_info.image_name));
                }

                image_info.is_app_image = (strstr(info.dli_fname, g_app_bundle_name) != NULL);
            }
        } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command *)cur_seg_cmd;
        }
    }

    // Sort list
    int i = 0;
    for (; i < s_image_info_db->count; ++i) {
        if (s_image_info_db->list[i].is_same(image_info)) {
            __malloc_lock_unlock(&s_image_info_db->lock);
            return;
        } else if (s_image_info_db->list[i].after(image_info)) {
            for (int j = s_image_info_db->count - 1; j >= i; --j) {
                s_image_info_db->list[j + 1] = s_image_info_db->list[j];
            }
            break;
        }
    }
    s_image_info_db->list[i] = image_info;
    s_image_info_db->count++;

    if (image_info.is_app_image) {
        app_image_info.vm_str = (app_image_info.vm_str == 0 ? image_info.vm_str : MIN(app_image_info.vm_str, image_info.vm_str));
        app_image_info.vm_end = (app_image_info.vm_end == 0 ? image_info.vm_end : MAX(app_image_info.vm_end, image_info.vm_end));
        if (is_current_app_image) {
            memcpy(app_image_info.uuid, image_info.uuid, sizeof(image_info.uuid));
        }
    }

    __save_to_file();

    __malloc_lock_unlock(&s_image_info_db->lock);
}

static void __dyld_image_add_callback(const struct mach_header *header, intptr_t slide) {
    if (matrix_stop_logging == true) return;
    __add_info_for_image(header, slide);
}

static void __init_image_info_list() {
    if (s_image_info_db == NULL) {
        g_app_bundle_name = bundleHelperCopyAppBundleName();
        g_app_name = bundleHelperCopyAppName();

        s_image_info_db = (dyld_image_info_db *)inter_malloc(sizeof(dyld_image_info_db));

        s_image_info_db->fd = -1;
        s_image_info_db->buff = NULL;
        s_image_info_db->count = 0;
        s_image_info_db->lock = __malloc_lock_init();

        _dyld_register_func_for_add_image(__dyld_image_add_callback);
    }
}

#pragma mark -
#pragma mark Public Interface

dyld_image_info_db *prepare_dyld_image_logger(const char *event_dir) {
    __init_image_info_list();

    dyld_image_info_db *db_context = dyld_image_info_db_open_or_create(event_dir);
    if (db_context != NULL) {
        s_image_info_db->fd = db_context->fd;
        s_image_info_db->fs = db_context->fs;
        s_image_info_db->buff = db_context->buff;

        __malloc_lock_lock(&s_image_info_db->lock);
        __save_to_file();
        __malloc_lock_unlock(&s_image_info_db->lock);

        inter_free(db_context);

        return s_image_info_db;
    } else {
        return NULL;
    }
}

bool is_stack_frames_should_skip(uintptr_t *frames, int32_t count, uint64_t malloc_size) {
    if (count < 2) {
        return true;
    }

    if (malloc_size >= skip_min_malloc_size) {
        return false;
    }

    // check whether there's any symbol not in this APP
    for (int i = MIN(count - 1, skip_max_stack_depth); i >= 1; --i) {
        if (frames[i] >= app_image_info.vm_str && frames[i] < app_image_info.vm_end) {
            return false;
        }
    }

    // skip this stack
    return true;
}

const char *app_uuid() {
    __init_image_info_list();
    return app_image_info.uuid;
}

dyld_image_info_db *dyld_image_info_db_open_or_create(const char *event_dir) {
    int fd = open_file(event_dir, "image_infos.dat");
    int fs = (int)round_page(sizeof(dyld_image_info_db));
    dyld_image_info_db *db_context = (dyld_image_info_db *)inter_malloc(sizeof(dyld_image_info_db));

    if (fd < 0) {
        err_code = MS_ERRC_DI_FILE_OPEN_FAIL;
        goto init_fail;
    } else {
        struct stat st = { 0 };
        if (fstat(fd, &st) == -1) {
            err_code = MS_ERRC_DI_FILE_SIZE_FAIL;
            goto init_fail;
        }
        if (st.st_size == 0 || st.st_size != fs) {
            // new file
            if (ftruncate(fd, fs) != 0) {
                err_code = MS_ERRC_DI_FILE_TRUNCATE_FAIL;
                goto init_fail;
            }

            void *buff = inter_mmap(NULL, fs, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
            if (buff == MAP_FAILED) {
                err_code = MS_ERRC_DI_FILE_MMAP_FAIL;
                goto init_fail;
            }

            memset(db_context, 0, sizeof(dyld_image_info_db));
            db_context->fd = fd;
            db_context->fs = fs;
            db_context->buff = buff;
        } else {
            void *buff = inter_mmap(NULL, fs, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
            if (buff == MAP_FAILED) {
                err_code = MS_ERRC_DI_FILE_MMAP_FAIL;
                goto init_fail;
            }

            memcpy(db_context, buff, sizeof(dyld_image_info_db));
            db_context->fd = fd;
            db_context->fs = fs;
            db_context->buff = buff;

            if (db_context->count < 0 || db_context->count > sizeof(db_context->list) / sizeof(dyld_image_info_mem)) {
                // dirty data
                db_context->count = 0;
                memset(db_context->list, 0, sizeof(db_context->list));
            }
        }
    }
    db_context->lock = __malloc_lock_init();

    return db_context;

init_fail:
    if (fd >= 0)
        close(fd);
    inter_free(db_context);
    return NULL;
}

void dyld_image_info_db_close(dyld_image_info_db *db_context) {
    if (db_context == NULL) {
        return;
    }

    inter_munmap(db_context->buff, db_context->fs);
    close(db_context->fd);
    inter_free(db_context);
}
