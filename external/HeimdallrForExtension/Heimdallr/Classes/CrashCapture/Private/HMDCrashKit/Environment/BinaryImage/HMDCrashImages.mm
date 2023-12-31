//
//  HMDCrashBinaryImage.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import "HMDCrashImages.h"
#include <libgen.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include "HMDCrashHeader.h"
#include "pthread_extended.h"
#import "HMDCrashEnviroment.h"
#import "HMDCrashSDKLog.h"
#include "HMDAsyncMachOImage.h"
#include <atomic>
#include <dlfcn.h>
#include <mach-o/dyld_images.h>
#import "HMDAsyncImageList.h"
#import <mach-o/loader.h>
#import "HMDCrashFileBuffer.h"
#include "HMDCompactUnwind.hpp"
#include "HMDCrashImagesState.h"
#import <dispatch/queue.h>
#import "HMDInfo+DeviceInfo.h"

using namespace std;

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide);
static void image_remove_callback (const struct mach_header *mh, intptr_t vmaddr_slide);
static void image_add_usr_lib_dyld ();

static int image_fd = -1;
static dispatch_queue_t binary_image_queue;

void setupWithFD() {
    if (image_fd < 0) {
        SDKLog("image fd = %d", image_fd);
        return;
    }
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        binary_image_queue = dispatch_queue_create("com.hmd.binaryimage", DISPATCH_QUEUE_SERIAL);
        _dyld_register_func_for_add_image(image_add_callback);
        _dyld_register_func_for_remove_image(image_remove_callback);
        image_add_usr_lib_dyld();
        hmd_setup_shared_image_list();
        dispatch_async(binary_image_queue, ^{
            HMDCrashMarkImagesFinish();
        });
    }
}

void setImageFD(int fd) {
    image_fd = fd;
}

static void binary_image_load(hmd_async_image_t *image, char *string, int strLen) {
    if (image == NULL) {
        return;
    }
    const char *image_path = image->macho_image.name;
    if (!image_path) {
        image_path = "";
    }
    hmd_vm_address_t base = image->macho_image.header_addr;
    hmd_vm_size_t size = image->macho_image.text_segment.size;
    const char *uuid = image->macho_image.uuid;
    if (!uuid) {
        uuid = "";
    }
    char *arch = hmd_cpu_arch(hmd_async_macho_cpu_type(&image->macho_image),hmd_async_macho_cpu_subtype(&image->macho_image));
    BOOL isMain = hmd_async_macho_is_executable(&image->macho_image)?YES:NO;
    // begin write file
    snprintf(string, strLen, "{\"load\":{\"base\":%lu,\"size\":%lu,\"is_main\":%s,\"path\":\"%s\",\"uuid\":\"%s\",\"arch\":\"%s\",\"segments\":[",base, size, (isMain?"true":"false"), image_path, uuid, arch);
    if (arch) {
        free(arch);
        arch = NULL;
    }
    for (int i = 0; i < image->macho_image.segment_count; i++) {
        char segString[100];
        memset(segString, 0, 100);
        hmd_async_segment *segment = &image->macho_image.segments[i];
        const char *segmentName = segment->seg_name;
        if (!segmentName) {
            segmentName = "";
        }
        hmd_vm_address_t segAddr = segment->range.addr;
        hmd_vm_size_t segSize = segment->range.size;
        snprintf(segString, 100, "{\"seg_name\":\"%s\",\"base\":%lu,\"size\":%lu}%s",segmentName, segAddr, segSize, (i != image->macho_image.segment_count-1)?",":"");
        size_t len = strlen(string);
        strncpy(string+len, segString, strLen-len);
    }
    size_t len = strlen(string);
    strncpy(string+len, "]}}\n", strLen-len);
    write(image_fd, string, strlen(string));
}

#define IMAGESTRINGLEN 4096

static void register_image_with_address_and_path(const struct mach_header *mh, const char *path){
    hmd_async_image_t image = {0};
    char string[IMAGESTRINGLEN];
    memset(string, 0, IMAGESTRINGLEN);
    if (hmd_nasync_macho_init(&image.macho_image, path, (hmd_vm_address_t)mh) == HMD_ESUCCESS) {
        binary_image_load(&image, string, IMAGESTRINGLEN);
        hmd_nasync_macho_free(&image.macho_image);
    }
}

static void binary_image_unload(uintptr_t base) {
    char string[100];
    memset(string, 0, 100);
    snprintf(string, 100, "{\"unload\":{\"base\":%lu}}\n", base);
    write(image_fd, string, strlen(string));
}

static void image_add_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(binary_image_queue, ^{
        Dl_info info;
        if (dladdr(mh, &info) == 0) {
    #ifdef DEBUG
            printf("%s: dladdr(%p, ...) failed", __FUNCTION__, mh);
    #endif
            return;
        }
            
        register_image_with_address_and_path(mh, info.dli_fname);
    });
}

static void image_remove_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    dispatch_async(binary_image_queue, ^{
        binary_image_unload((uintptr_t)mh);
    });
}

static void image_add_usr_lib_dyld () {
    dispatch_async(binary_image_queue, ^{
        kern_return_t kr;
        task_flavor_t flavor = TASK_DYLD_INFO;
        task_dyld_info dyld_info;
        mach_msg_type_number_t task_info_outCnt = TASK_DYLD_INFO_COUNT;
        kr = task_info(mach_task_self(), flavor, (task_info_t) &dyld_info, &task_info_outCnt);
        if (kr != KERN_SUCCESS) {
            return;
        }
        struct dyld_all_image_infos *allImageInfos = (struct dyld_all_image_infos *) dyld_info.all_image_info_addr;
        
        if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_9_x_Max) {
            const char* dyldPath = "/usr/lib/dyld";
            register_image_with_address_and_path(allImageInfos->dyldImageLoadAddress, dyldPath);
        }
        else
        {
            register_image_with_address_and_path(allImageInfos->dyldImageLoadAddress, allImageInfos->dyldPath);
        }
    });
}


static uintptr_t hmdFirstCmdAfterHeader(const struct mach_header* const header)
{
    switch(header->magic)
    {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            return 0;
    }
}

const char *hmd_CrashImage_cpu_arch(cpu_type_t majorCode, cpu_subtype_t minorCode) {
    minorCode = minorCode & ~CPU_SUBTYPE_MASK;
    switch(majorCode) {
        case CPU_TYPE_ARM: {
            switch (minorCode) {
                case CPU_SUBTYPE_ARM_V6:
                    return "armv6";
                case CPU_SUBTYPE_ARM_V7:
                    return "armv7";
                case CPU_SUBTYPE_ARM_V7F:
                    return "armv7f";
                case CPU_SUBTYPE_ARM_V7K:
                    return "armv7k";
                #ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S:
                    return "armv7s";
                #endif
          }
          return "arm";
        }
    #ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64: {
            switch (minorCode) {
                #ifdef CPU_SUBTYPE_ARM64E
                case CPU_SUBTYPE_ARM64E:
                    return "arm64e";
                #endif
                #ifdef CPU_SUBTYPE_ARM64_ALL
                case CPU_SUBTYPE_ARM64_ALL:
                    return "arm64";
                #endif
                #ifdef CPU_SUBTYPE_ARM64_V8
                    case CPU_SUBTYPE_ARM64_V8:
                        return "arm64v8";
                #endif
                default:
                    return "arm64";
          }
        }
    #endif
        case CPU_TYPE_X86:
            return "i386";
        case CPU_TYPE_X86_64:
            return "x86_64";
    }
    return "unknown";
}

void uuidToStr(uint8_t *uuid, char *uuidStr) {
    static char hex_table[] = "0123456789abcdef";
    for(size_t index = 0; index < 16; index++) {
        unsigned char current = (unsigned char)uuid[index];
        uuidStr[index * 2] = hex_table[(current >> 4) & 0xF];
        uuidStr[index * 2 + 1] = hex_table[current & 0xF];
    }
    uuidStr[32] = 0;
}

void writeSegments(const struct mach_header* header, uintptr_t cmdPtr, const hmd_async_byteorder_t *byteorder, hmd_vm_off_t vmaddr_slide) {
    hmd_file_begin_json_array(image_fd);
    bool isWriteDot = NO;
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++)
    {
        struct load_command* loadCmd = (struct load_command*)cmdPtr;
        hmd_vm_address_t addr = 0;
        hmd_vm_size_t size = 0;
        char seg_name[16] = {0};
        if (loadCmd->cmd == LC_SEGMENT || loadCmd->cmd == LC_SEGMENT_64) {
            if (loadCmd->cmd == LC_SEGMENT) {
                struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                if (strcmp(segCmd->segname, SEG_PAGEZERO) == 0) {
                    cmdPtr += loadCmd->cmdsize;
                    continue;
                }
                addr = (hmd_vm_address_t)byteorder->swap32(segCmd->vmaddr) + vmaddr_slide;
                size = (hmd_vm_size_t)byteorder->swap32(segCmd->vmsize);
                memcpy(seg_name, segCmd->segname, sizeof(seg_name));
            }
            else {
                struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                if (strcmp(segCmd->segname, SEG_PAGEZERO) == 0) {
                    cmdPtr += loadCmd->cmdsize;
                    continue;
                }
                addr = (hmd_vm_address_t)byteorder->swap64(segCmd->vmaddr) + vmaddr_slide;
                size = (hmd_vm_size_t)byteorder->swap64(segCmd->vmsize);
                memcpy(seg_name, segCmd->segname, sizeof(seg_name));
            }
            if (isWriteDot) {
                hmd_file_write_string(image_fd, ",");
            }
            isWriteDot = YES;
            hmd_file_begin_json_object(image_fd);
            hmd_file_write_key_and_string(image_fd, "seg_name", seg_name);//kk
            hmd_file_write_string(image_fd, ",");
            hmd_file_write_key_and_uint64(image_fd, "base", addr);
            hmd_file_write_string(image_fd, ",");
            hmd_file_write_key_and_uint64(image_fd, "size", size);
            hmd_file_end_json_object(image_fd);
        }
        else {
            break;
        }
        cmdPtr += loadCmd->cmdsize;
    }
    hmd_file_end_json_array(image_fd);
}

void writeBinaryImage(const struct mach_header *header, const char *image_path) {
    if (!header || !image_path) {
        return;
    }
    
    uintptr_t firstCmdPtr = hmdFirstCmdAfterHeader(header);
    if(firstCmdPtr == 0)
    {
        return;
    }
    
    // Look for the TEXT segment to get the image size.
    // Also look for a UUID command.
    uint64_t imageSize = 0;
    hmd_vm_address_t imageVmaddr = 0;
    uint8_t* uuid = NULL;
    uintptr_t cmdPtr = firstCmdPtr;
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++)
    {
        struct load_command* loadCmd = (struct load_command*)cmdPtr;
        switch(loadCmd->cmd)
        {
            case LC_SEGMENT:
            {
                struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                if(strcmp(segCmd->segname, SEG_TEXT) == 0)
                {
                    imageSize = segCmd->vmsize;
                    imageVmaddr = segCmd->vmaddr;
                }
                break;
            }
            case LC_SEGMENT_64:
            {
                struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                if(strcmp(segCmd->segname, SEG_TEXT) == 0)
                {
                    imageSize = segCmd->vmsize;
                    imageVmaddr = segCmd->vmaddr;
                }
                break;
            }
            case LC_UUID:
            {
                struct uuid_command* uuidCmd = (struct uuid_command*)cmdPtr;
                uuid = uuidCmd->uuid;
                break;
            }
        }
        cmdPtr += loadCmd->cmdsize;
    }
    
    /* Compute the vmaddr slide */
    hmd_vm_off_t vmaddr_slide = 0;
    if (imageVmaddr < (hmd_vm_address_t)header) {
        vmaddr_slide = (hmd_vm_address_t)header - imageVmaddr;
    } else if (imageVmaddr > (hmd_vm_address_t)header) {
        vmaddr_slide = -((hmd_vm_off_t)(imageVmaddr - (hmd_vm_address_t)header));
    }
    
    hmd_vm_address_t base = (hmd_vm_address_t)header;
    hmd_vm_size_t size = imageSize;
    char uuidStr[40];
    
    if (uuid) {
        uuidToStr(uuid, uuidStr);
    }
    const hmd_async_byteorder_t *byteorder = &hmd_async_byteorder_direct;
    if (header->magic == MH_CIGAM || header->magic == MH_CIGAM_64) {
        byteorder = &hmd_async_byteorder_swapped;
    }
    const char *arch = hmd_CrashImage_cpu_arch(byteorder->swap32(header->cputype),byteorder->swap32(header->cpusubtype));
    BOOL isMain = (byteorder->swap32(header->filetype) == MH_EXECUTE);
    // begin write file
    hmd_file_begin_json_object(image_fd);
    hmd_file_write_key(image_fd, "load");
    hmd_file_write_string(image_fd, ":");
    
    hmd_file_begin_json_object(image_fd);
    hmd_file_write_key_and_uint64(image_fd, "base", base);
    hmd_file_write_string(image_fd, ",");
    hmd_file_write_key_and_uint64(image_fd, "size", size);
    hmd_file_write_string(image_fd, ",");
    if (isMain) {
        hmd_file_write_key_and_bool(image_fd, "is_main", isMain);
        hmd_file_write_string(image_fd, ",");
    }
    hmd_file_write_key_and_string(image_fd, "path", image_path);
    hmd_file_write_string(image_fd, ",");
    hmd_file_write_key_and_string(image_fd, "uuid", uuidStr);
    hmd_file_write_string(image_fd, ",");
    hmd_file_write_key_and_string(image_fd, "arch", arch?:"");
    hmd_file_write_string(image_fd, ",");
    hmd_file_write_key(image_fd, "segments");
    hmd_file_write_string(image_fd, ":");
    writeSegments(header, firstCmdPtr, byteorder, vmaddr_slide);
    hmd_file_end_json_object(image_fd);
    hmd_file_end_json_object(image_fd);
    hmd_file_write_string(image_fd,"\n");
}

void writeDyldImage(void) {
    kern_return_t kr;
    task_flavor_t flavor = TASK_DYLD_INFO;
    task_dyld_info dyld_info;
    mach_msg_type_number_t task_info_outCnt = TASK_DYLD_INFO_COUNT;
    kr = task_info(mach_task_self(), flavor, (task_info_t) &dyld_info, &task_info_outCnt);
    if (kr != KERN_SUCCESS) {
        return;
    }
    struct dyld_all_image_infos *allImageInfos = (struct dyld_all_image_infos *) dyld_info.all_image_info_addr;
    
    if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_9_x_Max) {
        const char* dyldPath = "/usr/lib/dyld";
        writeBinaryImage(allImageInfos->dyldImageLoadAddress, dyldPath);
    }
    else
    {
        writeBinaryImage(allImageInfos->dyldImageLoadAddress, allImageInfos->dyldPath);
    }
}

void writeImageOnCrash(void) {
    if (image_fd < 0) {
        SDKLog("image fd = %d", image_fd);
        return;
    }
    const uint32_t imageCount = _dyld_image_count();
    for(uint32_t iImg = 0; iImg < imageCount; iImg++)
    {
        const struct mach_header* header = _dyld_get_image_header(iImg);
        if(header == NULL)
        {
            continue;;
        }
        //image_path
        Dl_info info;
        if (dladdr(header, &info) == 0) {
            continue;;
        }
        const char *image_path = info.dli_fname;
        if (!image_path) {
            image_path = "";
        }
        writeBinaryImage(header, image_path);
    }
    writeDyldImage();
}
