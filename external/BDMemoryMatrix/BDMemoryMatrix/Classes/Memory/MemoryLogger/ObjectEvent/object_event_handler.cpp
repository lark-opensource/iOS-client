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

#include "object_event_handler.h"
#include "allocation_event_db.h"
#include "nsobject_hook_method.h"
#include "sb_tree.h"
#include <dlfcn.h>
#include "memory_logging_event_config.h"
#include <unordered_map>

#pragma mark -
#pragma mark Types
using namespace std;
static unordered_map<string, const char *> cf_class_name{
    {"CFString (immutable)" , "__NSCFString"},
    {"CFString (mutable)" , "__NSCFString"},
    {"CFSet (immutable)" , "__NSCFSet"},
    {"CFSet (mutable)" , "__NSCFSet"},
    {"CFDictionary (immutable)" , "__NSCFDictionary"},
    {"CFDictionary (mutable)" , "__NSCFDictionary"},
    {"CFArray (immutable)" , "__NSCFArray"},
    {"CFArray (mutable-variable)" , "__NSCFArray"}
};
struct object_type {
    uint32_t type;
    char name[59];
    bool is_nsobject;

    object_type(uint32_t _t, const char *_n = NULL, bool _s = false) : type(_t), is_nsobject(_s) {
        if (_n != NULL) {
            strncpy(name, _n, sizeof(name));
            name[sizeof(name) - 1] = '\0';
        }
    }

    inline bool operator!=(const object_type &another) const { return type != another.type; }

    inline bool operator>(const object_type &another) const { return type > another.type; }
};

struct object_type_db {
    malloc_lock_s lock;

    buffer_source *buffer_source0; // memory
    buffer_source *buffer_source1; // file

    sb_tree<uintptr_t> *object_type_exists;
    sb_tree<object_type> *object_type_list;
};

struct vc_name_type {
    uint8_t index;
    char name[256];

    vc_name_type(uint8_t _t, const char *_n = NULL) : index(_t) {
        if (_n != NULL) {
            strncpy(name, _n, sizeof(name));
            name[sizeof(name) - 1] = '\0';
        }
    }

    inline bool operator!=(const vc_name_type &another) const { return index != another.index; }

    inline bool operator>(const vc_name_type &another) const { return index > another.index; }
};

struct vc_name_db {
    malloc_lock_s lock;

    buffer_source *buffer_source0; // memory
    buffer_source *buffer_source1; // file

    sb_tree<uintptr_t> *vc_name_exists;
    sb_tree<vc_name_type> *vc_name_list;
};

#pragma mark -
#pragma mark Constants/Globals

static object_type_db *s_object_type_db = NULL;
static vc_name_db *s_vc_name_db = NULL;

static uint8_t s_vc_name_index = 0;
static malloc_lock_s s_vc_name_lock;

static const char *vm_memory_type_names[] = {
    "VM: VM_MEMORY_MALLOC", // #define VM_MEMORY_MALLOC 1
    "VM: VM_MEMORY_MALLOC_SMALL", // #define VM_MEMORY_MALLOC_SMALL 2
    "VM: VM_MEMORY_MALLOC_LARGE", // #define VM_MEMORY_MALLOC_LARGE 3
    "VM: VM_MEMORY_MALLOC_HUGE", // #define VM_MEMORY_MALLOC_HUGE 4
    "VM: VM_MEMORY_SBRK", // #define VM_MEMORY_SBRK 5// uninteresting -- no one should call
    "VM: VM_MEMORY_REALLOC", // #define VM_MEMORY_REALLOC 6
    "VM: VM_MEMORY_MALLOC_TINY", // #define VM_MEMORY_MALLOC_TINY 7
    "VM: VM_MEMORY_MALLOC_LARGE_REUSABLE", // #define VM_MEMORY_MALLOC_LARGE_REUSABLE 8
    "VM: VM_MEMORY_MALLOC_LARGE_REUSED", // #define VM_MEMORY_MALLOC_LARGE_REUSED 9
    "VM: VM_MEMORY_ANALYSIS_TOOL", // #define VM_MEMORY_ANALYSIS_TOOL 10
    "VM: VM_MEMORY_MALLOC_NANO", // #define VM_MEMORY_MALLOC_NANO 11
    "VM: Unkonw", // 12
    "VM: Unkonw", // 13
    "VM: Unkonw", // 14
    "VM: Unkonw", // 15
    "VM: Unkonw", // 16
    "VM: Unkonw", // 17
    "VM: Unkonw", // 18
    "VM: Unkonw", // 19
    "VM: VM_MEMORY_MACH_MSG", // #define VM_MEMORY_MACH_MSG 20
    "VM: VM_MEMORY_IOKIT", // #define VM_MEMORY_IOKIT	21
    "VM: Unkonw", // 22
    "VM: Unkonw", // 23
    "VM: Unkonw", // 24
    "VM: Unkonw", // 25
    "VM: Unkonw", // 26
    "VM: Unkonw", // 27
    "VM: Unkonw", // 28
    "VM: Unkonw", // 29
    "VM: VM_MEMORY_STACK", // #define VM_MEMORY_STACK  30
    "VM: VM_MEMORY_GUARD", // #define VM_MEMORY_GUARD  31
    "VM: VM_MEMORY_SHARED_PMAP", // #define	VM_MEMORY_SHARED_PMAP 32
    /* memory containing a dylib */
    "VM: VM_MEMORY_DYLIB", // #define VM_MEMORY_DYLIB	33
    "VM: VM_MEMORY_OBJC_DISPATCHERS", // #define VM_MEMORY_OBJC_DISPATCHERS 34
    /* Was a nested pmap (VM_MEMORY_SHARED_PMAP) which has now been unnested */
    "VM: VM_MEMORY_UNSHARED_PMAP", // #define	VM_MEMORY_UNSHARED_PMAP	35
    "VM: Unkonw", // 36
    "VM: Unkonw", // 37
    "VM: Unkonw", // 38
    "VM: Unkonw", // 39
    // Placeholders for now -- as we analyze the libraries and find how they
    // use memory, we can make these labels more specific.
    "VM: AppKit", // #define VM_MEMORY_APPKIT 40
    "VM: Foundation", // #define VM_MEMORY_FOUNDATION 41
    "VM: CoreGraphics", // #define VM_MEMORY_COREGRAPHICS 42
    "VM: CoreServices", // #define VM_MEMORY_CORESERVICES 43
    "VM: Java", // #define VM_MEMORY_JAVA 44
    "VM: CoreData", // #define VM_MEMORY_COREDATA 45
    "VM: CoreData ObjectIDs", // #define VM_MEMORY_COREDATA_OBJECTIDS 46
    "VM: Unkonw", // 47
    "VM: Unkonw", // 48
    "VM: Unkonw", // 49
    "VM: ATS", // #define VM_MEMORY_ATS 50
    "VM: CoreAnimation (LayerKit)", // #define VM_MEMORY_LAYERKIT 51
    "VM: CGImage", // #define VM_MEMORY_CGIMAGE 52
    "VM: TCMalloc", // #define VM_MEMORY_TCMALLOC 53
    /* private raster data (i.e. layers, some images, QGL allocator) */
    "VM: CoreGraphics Data", // #define	VM_MEMORY_COREGRAPHICS_DATA	54
    /* shared image and font caches */
    "VM: CoreGraphics Shared", // #define VM_MEMORY_COREGRAPHICS_SHARED	55
    /* Memory used for virtual framebuffers, shadowing buffers, etc... */
    "VM: CoreGraphics FrameBuffers", // #define	VM_MEMORY_COREGRAPHICS_FRAMEBUFFERS	56
    /* Window backing stores, custom shadow data, and compressed backing stores */
    "VM: CoreGraphics BackingStores", // #define VM_MEMORY_COREGRAPHICS_BACKINGSTORES	57
    /* x-alloc'd memory */
    "VM: CoreGraphics XMalloc", // #define VM_MEMORY_COREGRAPHICS_XALLOC 58
    "VM: Unkonw", // 59
    /* memory allocated by the dynamic loader for itself */
    "VM: Dyld", // #define VM_MEMORY_DYLD 60
    /* malloc'd memory created by dyld */
    "VM: Dyld Malloc", // #define VM_MEMORY_DYLD_MALLOC 61
    /* Used for sqlite page cache */
    "VM: SQLite Page Cache", // #define VM_MEMORY_SQLITE 62
    /* JavaScriptCore heaps */
    "VM: JavaScript Core", // #define VM_MEMORY_JAVASCRIPT_CORE 63
    /* memory allocated for the JIT */
    "VM: JavaScript Jit Executable Allocator", // #define VM_MEMORY_JAVASCRIPT_JIT_EXECUTABLE_ALLOCATOR 64
    "VM: JavaScript Jit Register file", //#define VM_MEMORY_JAVASCRIPT_JIT_REGISTER_FILE 65
    /* memory allocated for GLSL */
    "VM: GLSL", // #define VM_MEMORY_GLSL  66
    /* memory allocated for OpenCL.framework */
    "VM: OpenCL", // #define VM_MEMORY_OPENCL    67
    /* memory allocated for QuartzCore.framework */
    "VM: CoreImage", // #define VM_MEMORY_COREIMAGE 68
    /* memory allocated for WebCore Purgeable Buffers */
    "VM: WebCore Purgeable Buffers", // #define VM_MEMORY_WEBCORE_PURGEABLE_BUFFERS 69
    /* ImageIO memory */
    "VM: ImageIO", // #define VM_MEMORY_IMAGEIO	70
    /* CoreProfile memory */
    "VM: CoreProfile", // #define VM_MEMORY_COREPROFILE	71
    /* assetsd / MobileSlideShow memory */
    "VM: AssetSD", // #define VM_MEMORY_ASSETSD	72
    /* libsystem_kernel os_once_alloc */
    "VM: OS Alloc Once", // #define VM_MEMORY_OS_ALLOC_ONCE 73
    /* libdispatch internal allocator */
    "VM: LibDispatch", // #define VM_MEMORY_LIBDISPATCH 74
    /* Accelerate.framework image backing stores */
    "VM: Accelerate", // #define VM_MEMORY_ACCELERATE 75
    /* CoreUI image block data */
    "VM: CoreUI", // #define VM_MEMORY_COREUI 76
    /* CoreUI image file */
    "VM: CoreUI Image File", // #define VM_MEMORY_COREUIFILE 77
    /* Genealogy buffers */
    "VM: Genealogy", // #define VM_MEMORY_GENEALOGY 78
    /* RawCamera VM allocated memory */
    "VM: RawCamera", // #define VM_MEMORY_RAWCAMERA 79
    /* corpse info for dead process */
    "VM: CorpseInfo", // #define VM_MEMORY_CORPSEINFO 80
    /* Apple System Logger (ASL) messages */
    "VM: ASL", // #define VM_MEMORY_ASL 81
    /* Swift runtime */
    "VM: Swift Runtime", // #define VM_MEMORY_SWIFT_RUNTIME 82
    /* Swift metadata */
    "VM: Swift MetaData", // #define VM_MEMORY_SWIFT_METADATA 83
    /* DHMM data */
    "VM: DHMM", // #define VM_MEMORY_DHMM 84
    "VM: Unkonw", // 85
    /* memory allocated by SceneKit.framework */
    "VM: SceneKit", // #define VM_MEMORY_SCENEKIT 86
    /* memory allocated by skywalk networking */
    "VM: Skywalk", // #define VM_MEMORY_SKYWALK 87
    "VM: IOSurface", // #define VM_MEMORY_IOSURFACE 88
    "VM: LibNetwork", // #define VM_MEMORY_LIBNETWORK 89
    "VM: Audio", // #define VM_MEMORY_AUDIO 90
    "VM: VideoBitStream", // #define VM_MEMORY_VIDEOBITSTREAM 91
};

#ifndef MEMORY_IGNORE_VMALLOCATE
// void (*__CFObjectAllocSetLastAllocEventNameFunction)(void *, const char *) = NULL;
static void (**object_set_last_allocation_event_name_funcion)(void *, const char *);
static bool *object_record_allocation_event_enable; // bool __CFOASafe = false;
#endif

extern void __memory_event_update_object(uint64_t address, uint32_t new_type);
extern bool matrix_stop_logging;
#pragma mark -
#pragma mark OC Event Logging

inline size_t object_string_hash(const char *str) {
    size_t seed = 131; // 31 131 1313 13131 131313 etc..
    size_t hash = 0;
    while (*str) {
        hash = hash * seed + (*str++);
    }
    return (hash | 0x1);
}

void object_set_last_allocation_event_name(void *ptr, const char *classname) {
    if (matrix_stop_logging) {
        return;
    }
    
    if (!ptr) {
        return;
    }

    if (!classname) {
        classname = "(no class)";
    }
    
    string ss = classname;
    if (cf_class_name.find(ss) != cf_class_name.end()) {
        classname = cf_class_name[classname];
    }
    
    uint32_t type = 0;
    
    size_t str_hash = object_string_hash(classname);
    
    __malloc_lock_lock(&s_object_type_db->lock);

    if (s_object_type_db->object_type_exists->exist(str_hash) == false) {
        type = s_object_type_db->object_type_list->size() + 300;
        s_object_type_db->object_type_exists->insert(str_hash);
        s_object_type_db->object_type_list->insert(object_type(type, classname));
    } else {
        type = s_object_type_db->object_type_exists->foundIndex() + 299;
    }

    __malloc_lock_unlock(&s_object_type_db->lock);

    __memory_event_update_object((uint64_t)ptr, type);
}

void nsobject_set_last_allocation_event_name(void *ptr, const char *classname) {
    if (!ptr) {
        return;
    }

    if (!classname) {
        classname = "(no class)";
    }
    
    uint32_t type = 0;
    
    size_t str_hash = object_string_hash(classname);
    
    __malloc_lock_lock(&s_object_type_db->lock);
    
    if (s_object_type_db->object_type_exists->exist(str_hash) == false) {
        type = s_object_type_db->object_type_list->size() + 300;
        s_object_type_db->object_type_exists->insert(str_hash);
        s_object_type_db->object_type_list->insert(object_type(type, classname, true));
    } else {
        type = s_object_type_db->object_type_exists->foundIndex() + 299;
    }

    __malloc_lock_unlock(&s_object_type_db->lock);

    __memory_event_update_object((uint64_t)ptr, type);
}

#pragma mark -
#pragma mark Public Interface

object_type_db *prepare_object_event_logger(const char *log_dir) {
    s_object_type_db = object_type_db_open_or_create(log_dir);
    if (s_object_type_db == NULL) {
        return NULL;
    }

    // Insert vm memory type names
    for (int i = 0; i < sizeof(vm_memory_type_names) / sizeof(char *); ++i) {
        uintptr_t str_hash = object_string_hash(vm_memory_type_names[i]);
        uint32_t type = s_object_type_db->object_type_list->size() + 1;
        s_object_type_db->object_type_exists->insert(str_hash);
        s_object_type_db->object_type_list->insert(object_type(type, vm_memory_type_names[i]));
    }
    s_object_type_db->object_type_exists->insert(object_string_hash("VM: webkit malloc"));
    s_object_type_db->object_type_list->insert(object_type(201, "VM: webkit malloc"));//跳过201，将vm:tcmalloc的tag(53)修改为201,和memorygraph匹配
    s_object_type_db->object_type_exists->insert(object_string_hash("VM: mmap"));
    s_object_type_db->object_type_list->insert(object_type(255, "VM: mmap"));

#ifndef MEMORY_IGNORE_VMALLOCATE
    if (memory_event_is_enable_vmalloc()) {
        
        std::string name2;
        memory_event_get_name_two(name2);
        
        std::string name3;
        memory_event_get_name_three(name3);
        
        // __CFObjectAllocSetLastAllocEventNameFunction
        object_set_last_allocation_event_name_funcion = (void (**)(void *, const char *))dlsym(RTLD_DEFAULT, name2.c_str());
        if (object_set_last_allocation_event_name_funcion != NULL) { //image lookup
            *object_set_last_allocation_event_name_funcion = object_set_last_allocation_event_name;
        }

        // __CFOASafe
        object_record_allocation_event_enable = (bool *)dlsym(RTLD_DEFAULT, name3.c_str());
        if (object_record_allocation_event_enable != NULL) {
            *object_record_allocation_event_enable = true;
        }
    }
#endif

    nsobject_hook_alloc_method();

    return s_object_type_db;
}

void disable_object_event_logger() {
#ifndef MEMORY_IGNORE_VMALLOCATE
    if (object_set_last_allocation_event_name_funcion != NULL) {
        *object_set_last_allocation_event_name_funcion = NULL;
    }
    if (object_record_allocation_event_enable != NULL) {
        *object_record_allocation_event_enable = false;
    }
#endif
}

object_type_db *object_type_db_open_or_create(const char *event_dir) {
    object_type_db *db_context = (object_type_db *)inter_calloc(1,sizeof(object_type_db));
    db_context->lock = __malloc_lock_init();
    db_context->buffer_source0 = new buffer_source_memory();
    db_context->buffer_source1 = new buffer_source_file(event_dir, "object_types.dat");

    if (db_context->buffer_source1->init_fail()) {
        // should not be happened
        err_code = MS_ERRC_OE_FILE_OPEN_FAIL;
        goto init_fail;
    } else {
        db_context->object_type_list = new sb_tree<object_type>(1 << 10, db_context->buffer_source1);
    }

    db_context->object_type_exists = new sb_tree<uintptr_t>(1 << 10, db_context->buffer_source0);
    return db_context;

init_fail:
    object_type_db_close(db_context);
    return NULL;
}

void object_type_db_close(object_type_db *db_context) {
    if (db_context == NULL) {
        return;
    }

    delete db_context->object_type_list;
    delete db_context->object_type_exists;
    delete db_context->buffer_source0;
    delete db_context->buffer_source1;
    inter_free(db_context);
}

const char *object_type_db_get_object_name(object_type_db *db_context, uint32_t type) {
    const char *name = NULL;

    __malloc_lock_lock(&db_context->lock);

    if (db_context->object_type_list->exist(type)) {
        name = db_context->object_type_list->find().name;
    }

    __malloc_lock_unlock(&db_context->lock);

    return name;
}

bool object_type_db_is_nsobject(object_type_db *db_context, uint32_t type) {
    bool is_nsobject = false;

    __malloc_lock_lock(&db_context->lock);

    if (db_context->object_type_list->exist(type)) {
        is_nsobject = db_context->object_type_list->find().is_nsobject;
    }

    __malloc_lock_unlock(&db_context->lock);

    return is_nsobject;
}
#pragma mark Public Interface -- vc_name_db

void vc_name_db_close(vc_name_db *db_context) {
    if (db_context == NULL) {
        return;
    }

    delete db_context->vc_name_list;
    delete db_context->vc_name_exists;
    delete db_context->buffer_source0;
    delete db_context->buffer_source1;
    inter_free(db_context);
}

vc_name_db *vc_name_db_open_or_create(const char *event_dir) {
    vc_name_db *db_context = (vc_name_db *)inter_calloc(1,sizeof(vc_name_db));
    db_context->lock = __malloc_lock_init();
    db_context->buffer_source0 = new buffer_source_memory();
    db_context->buffer_source1 = new buffer_source_file(event_dir, "vc_name.dat");

    if (db_context->buffer_source1->init_fail()) {
        // should not be happened
        err_code = MS_ERRC_OE_FILE_OPEN_FAIL;
        goto init_fail;
    } else {
        db_context->vc_name_list = new sb_tree<vc_name_type>(1 << 10, db_context->buffer_source1);
    }

    db_context->vc_name_exists = new sb_tree<uintptr_t>(1 << 10, db_context->buffer_source0);
    return db_context;

init_fail:
    vc_name_db_close(db_context);
    return NULL;
}

uint8_t vc_name_db_get_count(vc_name_db *db_context) {
    return db_context->vc_name_list->size();
}

const char *vc_name_db_get_name(vc_name_db *db_context, uint8_t index) {
    const char *name = NULL;

    __malloc_lock_lock(&db_context->lock);

    if (db_context->vc_name_list->exist(index)) {
        name = db_context->vc_name_list->find().name;
    }

    __malloc_lock_unlock(&db_context->lock);

    return name;
}

uint8_t vc_name_db_set_name(const char *vc_name) {
    //not init
    if (!s_vc_name_db || &s_vc_name_db->lock == NULL) {
        return 0;
    }
    
    if (!vc_name) {
        vc_name = "(no class)";
    }

    uint8_t index = 0;
    
    size_t str_hash = object_string_hash(vc_name);

    __malloc_lock_lock(&s_vc_name_db->lock);
    
    if (s_vc_name_db->vc_name_exists->exist(str_hash) == false) {
        index = s_vc_name_db->vc_name_list->size() + 1;
        s_vc_name_db->vc_name_exists->insert(str_hash);
        s_vc_name_db->vc_name_list->insert(vc_name_type(index, vc_name));
    } else {
        index = s_vc_name_db->vc_name_exists->foundIndex();
    }

    __malloc_lock_unlock(&s_vc_name_db->lock);
    
    return index;
}

vc_name_db *prepare_vc_name_logger(const char *log_dir) {
    s_vc_name_db = vc_name_db_open_or_create(log_dir);
    s_vc_name_lock = __malloc_lock_init();
    return s_vc_name_db;
}

//This function can be called in any thread and anywhere
void set_current_vc_name(const char * vc_name) {
    __malloc_lock_lock(&s_vc_name_lock);
    if (matrix_stop_logging) {
        __malloc_lock_unlock(&s_vc_name_lock);
        return;
    }
    s_vc_name_index = vc_name_db_set_name(vc_name);

    __malloc_lock_unlock(&s_vc_name_lock);
}

uint8_t get_current_vc_name_index() {
    uint8_t tmp_index = s_vc_name_index;
    return tmp_index;
}
