//
//  HMDCrashEnvironmentBinaryImages.m
//  iOS
//
//  Created by someone on 2023/1/27.
//

#include <dlfcn.h>
#include <sched.h>
#include <pthread.h>
#include <stdatomic.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/dyld_images.h>

#import  <Foundation/Foundation.h>

#include "HMDCrashSDKLog.h"
#include "HMDCrashFileBuffer.h"
#include "HMDAsyncMachOImage.h"
#include "HMDCrashEnvironmentBinaryImages.h"

#import "NSString+HMDJSON.h"
#import "HMDDeviceTool.h"
#if !SIMPLIFYEXTENSION
#import "HMDInfo+DeviceEnv.h"
#include "HMDCrashLoadSync_LowLevel.h"
#import "HMDCrashBinaryImage.h"
#endif

/*! @code 数据存储格式
{
  "load": {
    "base": 4345528320,
    "size": 32768,
    "is_main": false,
    "path": "/usr/lib/libBacktraceRecording.dylib",
    "uuid": "1e8a0973611b3121a299aa626c44bb34",
    "arch": "arm64",
    "segments": [
      {
        "seg_name": "__TEXT",
        "base": 4345528320,
        "size": 32768
      },
      {
        "seg_name": "__DATA_CONST",
        "base": 4345561088,
        "size": 16384
      },
      {
        "seg_name": "__DATA",
        "base": 4345577472,
        "size": 16384
      },
      {
        "seg_name": "__LINKEDIT",
        "base": 4345593856,
        "size": 32768
      }
    ]
  }
}
 
{
  "unload": {
    "base": 4345528320
  }
}
 
*/

typedef struct task_dyld_info task_dyld_info;

// 共享当前存储路径
static NSString * _Nullable shared_current_directory = nil;

// 异步线程
typedef void * _Nullable (*image_dispatch_function_t)(void * _Nullable);
static void dispatch_thread(image_dispatch_function_t _Nonnull function);

// 主文件数据写入 (mainFile)
static NSString * _Nonnull const mainFileName = @"image.main";
static HMDCrashFileBuffer mainFile_fd = HMDCrashFileBufferInvalid;
static dispatch_queue_t dyld_image_callback_queue = nil;
static void * _Nullable mainFile_save_thread_entrance(void * _Nullable context);
static void dyld_image_add_callback(const struct mach_header *header, intptr_t slide);
static void dyld_image_remove_callback(const struct mach_header *header, intptr_t slide);
static void dyld_callback_add_usr_lib_dyld(void);
static void dyld_callback_mark_most_finished(void);
static atomic_bool is_mainFile_mostly_finished = false;

// 副文件数据写入 (loadCommandFile)
static NSString * _Nonnull const loadCommandFileName = @"image.loadCommand";
/*
static HMDCrashFileBuffer loadCommandFile_fd = HMDCrashFileBufferInvalid;
static void * _Nullable loadCommandFile_save_thread_entrance(void * _Nullable context);
 */
static void write_image_load_info_from_task_dyld_info_to_file(task_dyld_info * _Nonnull dyld_info, int file_descriptor, bool need_crash_safe);

// 及时文件写入 (realTimeFile)
static NSString * _Nonnull const realTimeFileName = @"image.realTime";
static HMDCrashFileBuffer realTimeFile_fd = HMDCrashFileBufferInvalid;
static atomic_bool realTimeFile_preparation_complete = false;
static void realTimeFile_save_entrance(void);

// 基础文件写入
static void write_binary_image_load_info_to_file(const struct mach_header * _Nonnull header, const char * _Nonnull path, int file_descriptor);
static void write_binary_image_load_info_to_file_internal(hmd_async_macho_t *macho_image, int file_descriptor);
static void write_binary_image_unload_info_to_file(uintptr_t base, int file_descriptor);
static void write_dyld_image_from_task_info_to_file(task_dyld_info *dyld_info, int file_descriptor, bool need_crash_safe);
static void write_binary_image_load_info_to_file_crash_safe(const struct mach_header * _Nonnull header, const char * _Nonnull path, int file_descriptor);

// dyld 数据查询
static bool get_task_dyld_info_nonBlock(task_dyld_info * _Nonnull info);

#pragma mark - Save Binary Images

#pragma mark - [1] Exported Interface
// 外部接口, 设置存储位置, 启用 binaryImage 信息存储

#pragma mark Directory

void HMDCrashEnvironmentBinaryImages_initWithDirectory(NSString * _Nonnull directory) {
    // once flag check
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        DEBUG_ASSERT([directory isEqualToString:shared_current_directory]);
        return;
    }
    
    shared_current_directory = directory.copy;
}

#pragma mark mainFile

void HMDCrashEnvironmentBinaryImages_save_async_blocked_mainFile(void) {
    
    // once flag check
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) DEBUG_RETURN_NONE;
    
    NSString * _Nullable current_directory = shared_current_directory;
    if(current_directory == nil) DEBUG_RETURN_NONE;
    
    NSString * _Nullable mainFilePath = [current_directory stringByAppendingPathComponent:mainFileName];
    if(mainFilePath == nil) DEBUG_RETURN_NONE;
    
    // mainFile_fd opened sync on main thread
    if((mainFile_fd = hmd_file_open_buffer(mainFilePath.UTF8String)) == HMDCrashFileBufferInvalid) {
        SDKLog_error("open image mainFile failed");
        DEBUG_RETURN_NONE;
    }
    
    dispatch_thread(mainFile_save_thread_entrance);
}

bool HMDCrashEnvironmentBinaryImages_is_mainFile_mostly_finished(void) {
    return atomic_load_explicit(&is_mainFile_mostly_finished, memory_order_acquire);
}

#pragma mark loadCommandFile

void HMDCrashEnvironmentBinaryImages_save_async_nonBlocked_loadCommandFile(void) {
//    // once flag check
//    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
//    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) DEBUG_RETURN_NONE;
//    
//    // delay loadCommandFile_fd open to child thread
//    
//    dispatch_thread(loadCommandFile_save_thread_entrance);
}

#pragma mark realTimeFile

void HMDCrashEnvironmentBinaryImages_prepare_for_realTimeFile(void) {
    
    // once flag check
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    NSString * _Nullable current_directory = shared_current_directory;
    if(current_directory == nil) DEBUG_RETURN_NONE;
    
    NSString * _Nullable realTimeFilePath = [current_directory stringByAppendingPathComponent:realTimeFileName];
    if(realTimeFilePath == nil) DEBUG_RETURN_NONE;
    
    // realTimeFile_fd opened sync on main thread
    if((realTimeFile_fd = hmd_file_open_buffer(realTimeFilePath.UTF8String)) == HMDCrashFileBufferInvalid) {
        SDKLog_error("open image realTimeFile failed");
        DEBUG_RETURN_NONE;
    }
    
    atomic_store_explicit(&realTimeFile_preparation_complete, true, memory_order_release);
}

void HMDCrashEnvironmentBinaryImages_save_sync_nonBlocked_realTimeFile(void) {
    
    // once flag check
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) DEBUG_RETURN_NONE;
    
    // check for preparation
    bool preparation_complete = atomic_load_explicit(&realTimeFile_preparation_complete, memory_order_acquire);
    if(!preparation_complete) DEBUG_RETURN_NONE;
    
    realTimeFile_save_entrance();
}

#pragma mark - [2] Thread Dispatch
// 下接接口, 同步异步处理, 负责创建记录线程等

static void dispatch_thread(image_dispatch_function_t _Nonnull function) {
    DEBUG_ASSERT(function != NULL);
    
    pthread_attr_t attribute;
    pthread_attr_init(&attribute);
    pthread_attr_setdetachstate(&attribute, PTHREAD_CREATE_DETACHED);
    
    struct sched_param param;
    pthread_attr_getschedparam(&attribute, &param);
    
    int policy; // SCHED_OTHER: Default Linux time-sharing scheduling
    pthread_attr_getschedpolicy(&attribute, &policy);
    
    int priority_min = sched_get_priority_min(policy);
    int priority_max = sched_get_priority_max(policy);
    
    int priority_decided = (priority_max + priority_min) / 2;
    
    param.sched_priority = priority_decided;
    
    pthread_attr_setschedparam(&attribute, &param);
    
    pthread_t thread;
    pthread_create(&thread, &attribute, function, NULL);
    
    pthread_attr_destroy(&attribute);
}

#pragma mark - [3] Fetch Dyld Info
// 同步异步接口调用实际位置, 调用访问 dyld 的接口, 获取 binaryImage 信息

#pragma mark mainFile

static void * _Nullable mainFile_save_thread_entrance(void * _Nullable context) {
    DEBUG_ASSERT(!pthread_main_np());
    
    pthread_setname_np("com.hmd.image.mainFile.entrance");
    
    dyld_image_callback_queue = dispatch_queue_create("com.hmd.image.mainFile.save", DISPATCH_QUEUE_SERIAL);
    if(dyld_image_callback_queue == nil) DEBUG_RETURN(NULL);
    
    _dyld_register_func_for_add_image(dyld_image_add_callback);
    _dyld_register_func_for_remove_image(dyld_image_remove_callback);
    
    dyld_callback_add_usr_lib_dyld();
    
    dyld_callback_mark_most_finished();
   
    return NULL;
}

static void dyld_image_add_callback(const struct mach_header *header, intptr_t slide) {
    dispatch_async(dyld_image_callback_queue, ^{
        Dl_info info;
        if(dladdr(header, &info) == 0) DEBUG_RETURN_NONE;
        
        write_binary_image_load_info_to_file(header, info.dli_fname, mainFile_fd);
    });
}

static void dyld_image_remove_callback(const struct mach_header *header, intptr_t slide) {
    dispatch_async(dyld_image_callback_queue, ^{
        
        write_binary_image_unload_info_to_file((uintptr_t)header, mainFile_fd);
    });
}

static void dyld_callback_add_usr_lib_dyld(void) {
    dispatch_async(dyld_image_callback_queue, ^{
        task_dyld_info dyld_info;
        if(get_task_dyld_info_nonBlock(&dyld_info)) {
            write_dyld_image_from_task_info_to_file(&dyld_info, mainFile_fd, false);
        } DEBUG_ELSE
    });
}

static void dyld_callback_mark_most_finished(void) {
    dispatch_async(dyld_image_callback_queue, ^{
        atomic_store_explicit(&is_mainFile_mostly_finished, true, memory_order_release);
    });
}

#pragma mark loadCommandFile
/*
static void * _Nullable loadCommandFile_save_thread_entrance(void * _Nullable context) {
    DEBUG_ASSERT(!pthread_main_np());
    
    pthread_setname_np("com.hmd.image.LCFile.entrance");
    
    NSString * _Nullable current_directory = shared_current_directory;
    if(current_directory == nil) DEBUG_RETURN(NULL);
    
    NSString * _Nullable loadCommandFilePath = [current_directory stringByAppendingPathComponent:loadCommandFileName];
    if(loadCommandFilePath == nil) DEBUG_RETURN(NULL);
    
    if((loadCommandFile_fd = hmd_file_open_buffer(loadCommandFilePath.UTF8String)) == HMDCrashFileBufferInvalid) {
        SDKLog_error("open image loadCommandFile failed");
        DEBUG_RETURN(NULL);
    }
    
    task_dyld_info dyld_info;
    if(get_task_dyld_info_nonBlock(&dyld_info)) {
        write_image_load_info_from_task_dyld_info_to_file(&dyld_info, loadCommandFile_fd, false);
        write_dyld_image_from_task_info_to_file(&dyld_info, loadCommandFile_fd, false);
    } DEBUG_ELSE
    
    hmd_file_close_buffer(loadCommandFile_fd);
    
    loadCommandFile_fd = HMDCrashFileBufferInvalid;
    
    return NULL;
}
 */

static void write_image_load_info_from_task_dyld_info_to_file(task_dyld_info * _Nonnull dyld_info, int file_descriptor, bool need_crash_safe) {
    DEBUG_ASSERT(dyld_info != NULL && file_descriptor >= 0);
    
    // dyld.__DATA_DIRTY.__all_image_info
    struct dyld_all_image_infos * _Nullable all_image_info = (struct dyld_all_image_infos *)dyld_info->all_image_info_addr;
    mach_vm_size_t all_image_info_size = dyld_info->all_image_info_size;
    
    if(all_image_info == NULL || all_image_info_size < offsetof(struct dyld_all_image_infos, notification))
        DEBUG_RETURN_NONE;
    
    const struct dyld_image_info *infoArray = all_image_info->infoArray;
    uint32_t infoArrayCount = all_image_info->infoArrayCount;
    
    for(uint32_t index = 0; index < infoArrayCount; index++) {
        const struct mach_header *header = infoArray[index].imageLoadAddress;
        const char *path = infoArray[index].imageFilePath;
        
        if(need_crash_safe) write_binary_image_load_info_to_file_crash_safe(header, path, file_descriptor);
        else write_binary_image_load_info_to_file(header, path, file_descriptor);
    }
}

#pragma mark realTimeFile

static void realTimeFile_save_entrance(void) {
    if(realTimeFile_fd == HMDCrashFileBufferInvalid) DEBUG_RETURN_NONE;
    
    task_dyld_info dyld_info;
    if(get_task_dyld_info_nonBlock(&dyld_info)) {
        write_image_load_info_from_task_dyld_info_to_file(&dyld_info, realTimeFile_fd, true);
        write_dyld_image_from_task_info_to_file(&dyld_info, realTimeFile_fd, true);
    } DEBUG_ELSE
}

#pragma mark - [4] Image Info Write
// 负责写入 binaryImage 的通用格式

static void write_binary_image_load_info_to_file(const struct mach_header * _Nonnull header, const char * _Nonnull path, int file_descriptor) {
    DEBUG_ASSERT(header != NULL && path != NULL && file_descriptor >= 0);
    
    hmd_async_macho_t macho_image;
    if(hmd_nasync_macho_init(&macho_image, path, (hmd_vm_address_t)header) == HMD_ESUCCESS) {
        write_binary_image_load_info_to_file_internal(&macho_image, file_descriptor);
        hmd_nasync_macho_free(&macho_image);
    } DEBUG_ELSE
}

static void write_binary_image_load_info_to_file_internal(hmd_async_macho_t *macho_image, int file_descriptor) {
    
    if(macho_image == NULL || file_descriptor < 0) DEBUG_RETURN_NONE;
    
    const char *image_path = macho_image->name;
    if(image_path == NULL) image_path = "";
    
    hmd_vm_address_t base = macho_image->header_addr;
    hmd_vm_size_t size = macho_image->text_segment.size;
    
    const char *uuid = macho_image->uuid;
    if (uuid == NULL) uuid = "";
    
    char * _Nullable arch = hmd_cpu_arch(hmd_async_macho_cpu_type(macho_image),
                                         hmd_async_macho_cpu_subtype(macho_image), false);
    
    bool is_main_executable = hmd_async_macho_is_executable(macho_image);
    
    #define MAX_IMAGE_STRING_COUNT 4096
    
    char string[MAX_IMAGE_STRING_COUNT];
    
    // begin write file
    int needLength = snprintf(string, MAX_IMAGE_STRING_COUNT, "{\"load\":{\"base\":%lu,\"size\":%lu,\"is_main\":%s,\"path\":\"%s\",\"uuid\":\"%s\",\"arch\":\"%s\",\"segments\":[",base, size, (is_main_executable?"true":"false"), image_path, uuid, arch);
    
    if(needLength >= MAX_IMAGE_STRING_COUNT || needLength <= 0) {
        SDKLog_error("save image failed for %s", image_path);
        DEBUG_RETURN_NONE;
    }
    
    size_t next_written_index = needLength;
    
    int segment_count = macho_image->segment_count;
    
    for (int i = 0; i < segment_count; i++) {
        
        DEBUG_ASSERT(next_written_index < MAX_IMAGE_STRING_COUNT);
        if(next_written_index + 1 >= MAX_IMAGE_STRING_COUNT) break;
        
        hmd_async_segment *segment = macho_image->segments + i;
        
        const char *segmentName = segment->seg_name;
        if(segmentName == NULL) segmentName = "";
        
        hmd_vm_address_t segmentAddress = segment->range.addr;
        hmd_vm_size_t segmentSize = segment->range.size;
        
        DEBUG_ASSERT(MAX_IMAGE_STRING_COUNT > next_written_index);
        
        DEBUG_ASSERT(strlen(string) == next_written_index);
        size_t count_left = MAX_IMAGE_STRING_COUNT - next_written_index;
        
        DEBUG_ASSERT(MAX_IMAGE_STRING_COUNT - strlen(string) == count_left);
        DEBUG_ASSERT(count_left >= 1);
        
        bool is_last_segment = (i + 1 == segment_count);
        
        needLength = snprintf(string + next_written_index, count_left,
                              "{\"seg_name\":\"%s\",\"base\":%lu,\"size\":%lu}%s",
                              segmentName, segmentAddress, segmentSize, is_last_segment ? "" : ",");
        
        if(needLength >= count_left || needLength <= 0) break;
        
        next_written_index += needLength;
    }
    
    DEBUG_ASSERT(strlen(string) == next_written_index);
    DEBUG_ASSERT(next_written_index < MAX_IMAGE_STRING_COUNT);
    
    size_t count_left = MAX_IMAGE_STRING_COUNT - next_written_index;
    
    DEBUG_ASSERT(strlen("]}}\n") == 4);
    
    if(count_left < 5) DEBUG_RETURN_NONE;
    strncpy(string + next_written_index, "]}}\n", count_left);
    next_written_index += 4;
    
    DEBUG_ASSERT(strlen(string) == next_written_index);
    
    write(file_descriptor, string, next_written_index);
}

static void write_binary_image_unload_info_to_file(uintptr_t base, int file_descriptor) {
    #define MAX_UNLOAD_LENGTH 128
    char string[MAX_UNLOAD_LENGTH];
    int needLength = snprintf(string, MAX_UNLOAD_LENGTH, "{\"unload\":{\"base\":%" PRIuPTR "}}\n", base);
    if(needLength >= MAX_UNLOAD_LENGTH || needLength <= 0) DEBUG_RETURN_NONE;

    write(file_descriptor, string, needLength);
}

static void write_dyld_image_from_task_info_to_file(task_dyld_info *dyld_info, int file_descriptor, bool need_crash_safe) {
    DEBUG_ASSERT(dyld_info != NULL && file_descriptor >= 0);
    
    struct dyld_all_image_infos *all_image_info = (struct dyld_all_image_infos *)dyld_info->all_image_info_addr;
    mach_vm_size_t all_image_info_size = dyld_info->all_image_info_size;
    
    if(all_image_info == NULL || all_image_info_size < offsetof(struct dyld_all_image_infos, jitInfo))
        DEBUG_RETURN_NONE;
    
    const char * _Nullable maybeDyldPath = NULL;
    
    if(all_image_info_size >= offsetof(struct dyld_all_image_infos, notifyPorts))
        maybeDyldPath = all_image_info->dyldPath;
    
    if(maybeDyldPath == NULL) maybeDyldPath = "/usr/lib/dyld";
    
    if(need_crash_safe)
         write_binary_image_load_info_to_file_crash_safe(all_image_info->dyldImageLoadAddress, maybeDyldPath, file_descriptor);
    else write_binary_image_load_info_to_file(all_image_info->dyldImageLoadAddress, maybeDyldPath, file_descriptor);
}

#pragma mark - [5] image write crash safe

static void write_binary_image_load_info_to_file_crash_safe(const struct mach_header * _Nonnull header, const char * _Nonnull path, int file_descriptor) {

    if(header == NULL || path == NULL) DEBUG_RETURN_NONE;
    
    uintptr_t firstCommandPointer;
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            firstCommandPointer = (uintptr_t)(header + 1);
            break;
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            firstCommandPointer = (uintptr_t)(((struct mach_header_64*)header) + 1);
            break;
        default:
            DEBUG_RETURN_NONE;
    }

    // search for TEXT segment
    
    uint64_t image_TEXT_vmsize = 0;
    hmd_vm_address_t image_TEXT_vmaddr = 0;
    uint8_t * _Nullable image_uuid = NULL;
    
    uintptr_t commandPointer = firstCommandPointer;
    for(uint32_t commandIndex = 0; commandIndex < header->ncmds; commandIndex++) {
        
        struct load_command* eachLoadCommand = (struct load_command*)commandPointer;
        
        switch(eachLoadCommand->cmd) {
                
            case LC_SEGMENT: {
                struct segment_command *segmentCommand = (struct segment_command *)commandPointer;
                if(strcmp(segmentCommand->segname, SEG_TEXT) == 0) {
                    image_TEXT_vmsize = segmentCommand->vmsize;
                    image_TEXT_vmaddr = segmentCommand->vmaddr;
                }
                break;
            }
                
            case LC_SEGMENT_64: {
                struct segment_command_64 *segmentCommand = (struct segment_command_64 *)commandPointer;
                if(strcmp(segmentCommand->segname, SEG_TEXT) == 0) {
                    image_TEXT_vmsize = segmentCommand->vmsize;
                    image_TEXT_vmaddr = segmentCommand->vmaddr;
                }
                break;
            }
                
            case LC_UUID: {
                struct uuid_command* uuidCommand = (struct uuid_command*)commandPointer;
                image_uuid = uuidCommand->uuid;
                break;
            }
            default:
                break;
        }
        
        commandPointer += eachLoadCommand->cmdsize;
    }

    // vmaddr_slide
    
    hmd_vm_off_t vmaddr_slide = 0;
    
    if (image_TEXT_vmaddr < (hmd_vm_address_t)header) {
        vmaddr_slide = (hmd_vm_address_t)header - image_TEXT_vmaddr;
    } else if (image_TEXT_vmaddr > (hmd_vm_address_t)header) {
        vmaddr_slide = -((hmd_vm_off_t)(image_TEXT_vmaddr - (hmd_vm_address_t)header));
        DEBUG_POINT;    // 这种情况其实根本不会发生 (参考 dyld 源码, 人家直接就不考虑负向 slide)
    }

    hmd_vm_address_t base = (hmd_vm_address_t)header;
    hmd_vm_size_t size = image_TEXT_vmsize;
    
    #define UUID_LENGTH_COUNT 16
    
    char uuidStr[UUID_LENGTH_COUNT * 2 + 1];
    
    COMPILE_ASSERT(sizeof(uuid_t) == UUID_LENGTH_COUNT);

    if (image_uuid != NULL) {
        static char hex_table[] = "0123456789abcdef";
        for(size_t index = 0; index < UUID_LENGTH_COUNT; index++) {
            unsigned char current = (unsigned char)image_uuid[index];
            uuidStr[index * 2] = hex_table[(current >> 4) & 0xF];
            uuidStr[index * 2 + 1] = hex_table[current & 0xF];
        }
    }
    
    uuidStr[sizeof(uuidStr) - 1] = '\0';
    
    
    const hmd_async_byteorder_t *byteorder = &hmd_async_byteorder_direct;
    if (header->magic == MH_CIGAM || header->magic == MH_CIGAM_64)
        byteorder = &hmd_async_byteorder_swapped;
    
    char * _Nullable arch = hmd_cpu_arch(byteorder->swap32(header->cputype),
                                         byteorder->swap32(header->cpusubtype),
                                         false);
    
    
    BOOL isMain = (byteorder->swap32(header->filetype) == MH_EXECUTE);
    
    // begin write file
    hmd_file_begin_json_object(file_descriptor);
    hmd_file_write_key(file_descriptor, "load");
    hmd_file_write_string(file_descriptor, ":");

    hmd_file_begin_json_object(file_descriptor);
    hmd_file_write_key_and_uint64(file_descriptor, "base", base);
    hmd_file_write_string(file_descriptor, ",");
    hmd_file_write_key_and_uint64(file_descriptor, "size", size);
    hmd_file_write_string(file_descriptor, ",");
    if (isMain) {
        hmd_file_write_key_and_bool(file_descriptor, "is_main", isMain);
        hmd_file_write_string(file_descriptor, ",");
    }
    hmd_file_write_key_and_string(file_descriptor, "path", path);
    hmd_file_write_string(file_descriptor, ",");
    hmd_file_write_key_and_string(file_descriptor, "uuid", uuidStr);
    hmd_file_write_string(file_descriptor, ",");
    hmd_file_write_key_and_string(file_descriptor, "arch", arch?:"");
    hmd_file_write_string(file_descriptor, ",");
    hmd_file_write_key(file_descriptor, "segments");
    hmd_file_write_string(file_descriptor, ":");

    {   // segments
        
        hmd_file_begin_json_array(file_descriptor);
        
        uintptr_t commandPointer = firstCommandPointer;
        
        bool needWriteSeparator = false;
        for(uint32_t commandIndex = 0; commandIndex < header->ncmds; commandIndex++)
        {
            struct load_command* loadCommand = (struct load_command *)commandPointer;
            hmd_vm_address_t addr = 0;
            hmd_vm_size_t size = 0;
            char seg_name[16] = {0};
            if (loadCommand->cmd == LC_SEGMENT || loadCommand->cmd == LC_SEGMENT_64) {
                
                if (loadCommand->cmd == LC_SEGMENT) {
                    struct segment_command *segmentCommand = (struct segment_command *)commandPointer;
                    if (strcmp(segmentCommand->segname, SEG_PAGEZERO) == 0) {
                        commandPointer += loadCommand->cmdsize;
                        continue;
                    }
                    addr = (hmd_vm_address_t)byteorder->swap32(segmentCommand->vmaddr) + vmaddr_slide;
                    size = (hmd_vm_size_t)byteorder->swap32(segmentCommand->vmsize);
                    memcpy(seg_name, segmentCommand->segname, sizeof(seg_name));
                } else {
                    struct segment_command_64* segCmd = (struct segment_command_64*)commandPointer;
                    if (strcmp(segCmd->segname, SEG_PAGEZERO) == 0) {
                        commandPointer += loadCommand->cmdsize;
                        continue;
                    }
                    addr = (hmd_vm_address_t)byteorder->swap64(segCmd->vmaddr) + vmaddr_slide;
                    size = (hmd_vm_size_t)byteorder->swap64(segCmd->vmsize);
                    memcpy(seg_name, segCmd->segname, sizeof(seg_name));
                }
                
                seg_name[sizeof(seg_name) - 1] = '\0';
                
                if(needWriteSeparator) hmd_file_write_string(file_descriptor, ",");
                needWriteSeparator = true;
                
                hmd_file_begin_json_object(file_descriptor);
                hmd_file_write_key_and_string(file_descriptor, "seg_name", seg_name);//kk
                hmd_file_write_string(file_descriptor, ",");
                hmd_file_write_key_and_uint64(file_descriptor, "base", addr);
                hmd_file_write_string(file_descriptor, ",");
                hmd_file_write_key_and_uint64(file_descriptor, "size", size);
                hmd_file_end_json_object(file_descriptor);
            } else {
                // other command
                break;      // segment command first ?
            }
            
            commandPointer += loadCommand->cmdsize;
        }
        hmd_file_end_json_array(file_descriptor);
    }
    
    hmd_file_end_json_object(file_descriptor);
    hmd_file_end_json_object(file_descriptor);
    hmd_file_write_string(file_descriptor, "\n");
}

#pragma mark - [6] dyld synchronized tool
// 某些读取 dyld 信息的功能有些重复, 这里统一到一起

static bool get_task_dyld_info_nonBlock(task_dyld_info * _Nonnull info) {
    
    if(info == NULL) DEBUG_RETURN(false);
    
    // 全局判断标志
    static bool shared_decided = false;
    
    // 全局结果存储
    static bool fetch_success = false;
    static task_dyld_info dyld_info = { 0 };
    
    // 当前全局是否已经判断完成
    bool current_decided = __atomic_load_n(&shared_decided, __ATOMIC_ACQUIRE);
    
    // 如果全局已经判断完成，返回全局判断结果
    if(current_decided) {
        if(fetch_success) info[0] = dyld_info;
        return fetch_success;
    }
    
    // 当前查询结果
    task_flavor_t flavor = TASK_DYLD_INFO;
    task_dyld_info current_info;
    mach_msg_type_number_t task_info_count = TASK_DYLD_INFO_COUNT;
    kern_return_t kr = task_info(mach_task_self(), flavor, (task_info_t)&current_info, &task_info_count);
    
    // 写入全局判断结果
    if(kr == KERN_SUCCESS) {
        fetch_success = true;
        dyld_info = current_info;
    } else fetch_success = false;
    
    // 写入全局是否判断
    __atomic_store_n(&shared_decided, true, __ATOMIC_RELEASE);
    
    // 返回当前查询结果
    if(kr == KERN_SUCCESS) info[0] = current_info;
    return kr == KERN_SUCCESS;
}

#pragma mark - Load Binary Images

#if !SIMPLIFYEXTENSION

#define HMD_IMAGE_LOADER_MIAN_FILE_VALID_COUNT 64

typedef enum : uint64_t {
    HMDImageOpaqueImageFromNone             = 0,
    HMDImageOpaqueImageFromMainFile         = 1 << 0,
    HMDImageOpaqueImageFromLoadCommandFile  = 1 << 1,
    HMDImageOpaqueImageFromRealTimeFile     = 1 << 2,
} HMDImageOpaqueImageFrom;

@interface HMDImageOpaqueLoader ()

@property(nonatomic, readwrite) BOOL envAbnormal;

@end

@implementation HMDImageOpaqueLoader {
    NSString * _directory;
    NSMutableSet<HMDCrashBinaryImage *> * _Nonnull  _mainFileSet;
    NSMutableSet<HMDCrashBinaryImage *> * _Nullable _loadCommandFileSet;
    NSMutableSet<HMDCrashBinaryImage *> * _Nullable _realTimeFileSet;
    HMDImageOpaqueImageFrom _fileLoaded;
}

@dynamic currentlyUsedImages, currentlyImageCount;

- (instancetype _Nullable)init {
    DEBUG_RETURN(nil);
}

- (instancetype _Nullable)initWithDirectory:(NSString * _Nonnull)directory {
    if(directory == nil) DEBUG_RETURN(nil);
    
    if(self = [super init]) {
        _directory = directory;
        // _fileLoaded = HMDImageOpaqueImageFromNone;
        
        [self loadMain];
        DEBUG_ASSERT(_mainFileSet != nil);
        
        if(_mainFileSet.count <= HMD_IMAGE_LOADER_MIAN_FILE_VALID_COUNT)
            [self loadExternal];
        
        
    }
    return self;
}

- (NSUInteger)currentlyImageCount {
    return _mainFileSet.count;
}

- (void)loadMain {
    DEBUG_ASSERT(_directory != nil);
    
    if(_fileLoaded & HMDImageOpaqueImageFromMainFile) return;
    
    NSString *mainFilePath = [_directory stringByAppendingPathComponent:mainFileName];
    _mainFileSet = [self loadImageFile:mainFilePath error:nil];
    
    DEVELOP_DEBUG_ASSERT(_mainFileSet != nil || HMDCrashLoadSync_starting());
    
    if(_mainFileSet == nil) {
        // backward compact
        // 很早之前的文件名称叫做 "binary_image", 没有拆分三个文件
        // 如果不需要向前兼容, 直接删掉这个 if 内的所有内容即可
        
        NSString * _Nonnull backwardFileName = @"binary_image";
        NSString *backwardFilePath = [_directory stringByAppendingPathComponent:backwardFileName];
        _mainFileSet = [self loadImageFile:backwardFilePath error:nil];
    }
    
    if(_mainFileSet == nil) _mainFileSet = NSMutableSet.set;
    
    _fileLoaded |= HMDImageOpaqueImageFromMainFile;
}

- (void)loadExternal {
    DEBUG_ASSERT(_directory != nil);
    
    if(!(_fileLoaded & HMDImageOpaqueImageFromLoadCommandFile)) {
        NSString *loadCommandFilePath = [_directory stringByAppendingPathComponent:loadCommandFileName];
        _loadCommandFileSet = [self loadImageFile:loadCommandFilePath error:nil];
        
        _fileLoaded |= HMDImageOpaqueImageFromLoadCommandFile;
    }
    
    if(!(_fileLoaded & HMDImageOpaqueImageFromRealTimeFile)) {
        NSString *realTimeFilePath = [_directory stringByAppendingPathComponent:realTimeFileName];
        _realTimeFileSet = [self loadImageFile:realTimeFilePath error:nil];
        
        _fileLoaded |= HMDImageOpaqueImageFromRealTimeFile;
    }
}

- (HMDCrashBinaryImage * _Nullable)imageForAddress:(uintptr_t)address {
    DEBUG_ASSERT(_mainFileSet != nil);
    
    __block HMDCrashBinaryImage * _Nullable foundImage = nil;
    
    [_mainFileSet enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull eachImage, BOOL * _Nonnull stop) {
        if([eachImage containingAddress:address]) {
            foundImage = eachImage;
            stop[0] = YES;
        }
    }];
    
    if(foundImage != nil) return foundImage;
    
    [self loadExternal];
    
    if(_loadCommandFileSet != nil) [_loadCommandFileSet enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull eachImage, BOOL * _Nonnull stop) {
        if([eachImage containingAddress:address]) {
            foundImage = eachImage;
            stop[0] = YES;
        }
    }];
    
    if(foundImage != nil) {
        [_mainFileSet addObject:foundImage];
        return foundImage;
    }
    
    if(_realTimeFileSet != nil) [_realTimeFileSet enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull eachImage, BOOL * _Nonnull stop) {
        if([eachImage containingAddress:address]) {
            foundImage = eachImage;
            stop[0] = YES;
        }
    }];
    
    if(foundImage != nil) {
        [_mainFileSet addObject:foundImage];
        return foundImage;
    }
   
    return nil;
}

- (NSArray<HMDCrashBinaryImage *> * _Nullable)currentlyUsedImages {
    return [_mainFileSet allObjects];
}

- (NSMutableSet<HMDCrashBinaryImage *> * _Nullable)loadImageFile:(NSString * _Nonnull)filePath
                                                           error:(NSError * __autoreleasing _Nullable * _Nullable)error{
    DEBUG_ASSERT(filePath != nil);
    
    if(filePath == nil) DEBUG_RETURN(nil);
    
    NSString *content = [NSString stringWithContentsOfFile:filePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:error];
    
    NSUInteger contentLength = content.length;
    if(contentLength == 0) return nil;
    
    NSArray<NSString *> *imageStrings = [content componentsSeparatedByString:@"\n"];
    
    NSMutableSet<HMDCrashBinaryImage *> *binaryImages = [NSMutableSet setWithCapacity:imageStrings.count];
    
    [imageStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull eachLineString, NSUInteger idx, BOOL * _Nonnull stop) {
        if(eachLineString.length == 0) return;
        
        NSDictionary * _Nullable jsonDictionary = [eachLineString hmd_jsonDict];
        if(jsonDictionary.count == 0) return;
        
        HMDCrashBinaryImage * _Nullable binaryImage = [HMDCrashBinaryImage objectWithDictionary:jsonDictionary];
        
        if(binaryImage == nil) return;
        
        if(binaryImage.isEnvAbnormal) self.envAbnormal = YES;
        
        // image load
        if(binaryImage.load) {
            [binaryImages addObject:binaryImage];
            return;
        }
        
        uint64_t unloadImageBase = binaryImage.base;
        
        // image unload
        if(unloadImageBase == 0) return;

        [binaryImages removeObject:binaryImage];
    }];
    
    return binaryImages;
}

@end

#endif /* !SIMPLIFYEXTENSION */
