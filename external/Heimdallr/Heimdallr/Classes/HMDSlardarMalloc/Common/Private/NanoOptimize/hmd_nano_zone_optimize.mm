//
//  hmd_nano_zone_optimize.c
//  Heimdallr
//
//  Created by zhouyang11 on 2023/10/25.
//

#import <Foundation/Foundation.h>
#include "hmd_nano_zone_optimize.h"
#import "HMDThreadSuspender.h"
#import "hmd_vm_remap_util.h"
#import <mach/vm_region.h>
#import <mach/mach_init.h>
#import <mach/task_info.h>
#import <mach/task.h>
#import <mach/vm_map.h>
#import <mach/vm_statistics.h>
#import <utility>
#import <sys/mman.h>
#import <sys/time.h>
#import "hmd_memory_logger.h"

@interface HMDNanoZoneOptimize:NSObject
@end

@implementation HMDNanoZoneOptimize
@end

static vm_address_t const nano_region_base_address = 0x280000000;
static size_t const nano_mb = 1024*1024;
static size_t const nano_region_size = 512*nano_mb;

struct hmd_nano_region_base_info {
    unsigned int user_tag;
    vm_address_t base_address;
    vm_size_t size;
    unsigned int pages_resident;
};

static uint64_t current_time(void) {
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_sec*1000 + time.tv_usec/1000.0;
}

static hmd_nano_region_base_info vm_region_from_address(vm_address_t addr){
    vm_map_t task_self = mach_task_self();
    vm_address_t original_address = (vm_address_t)addr;
    vm_address_t address = original_address;
    
    mach_port_t        object_name;
    vm_region_extended_info_data_t info;
    mach_msg_type_number_t  count;
    vm_size_t        size;
    kern_return_t kr = 0;
    count = VM_REGION_EXTENDED_INFO_COUNT;
    
    kr = vm_region_64(task_self, &address, &size, VM_REGION_EXTENDED_INFO, (vm_region_info_t)&info,
                   &count, &object_name);
    if (kr == KERN_SUCCESS) {
        return {info.user_tag, address, size, info.pages_resident};
    }else {
        return {0, 0, 0, 0};
    }
}

HMDNanoOptimizeResult hmd_nano_zone_optimize_invoke(hmd_nanozone_optimize_config config, uint64_t* duration) {
    hmd_nano_region_base_info nano_region_info = vm_region_from_address(nano_region_base_address);
    if (nano_region_info.user_tag != VM_MEMORY_MALLOC_NANO ||
        nano_region_info.size != nano_region_size ||
        nano_region_info.base_address != nano_region_base_address) {
        return HMDNanoOptimizeResultNanoVersionNotMatch;
    }
    
    NSString* nanozone_optimize_tmp_filepath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"slardar_nanozone_tmp_file"];
    
    int m_fd = open(nanozone_optimize_tmp_filepath.UTF8String, O_CREAT|O_RDWR|O_TRUNC, S_IRUSR|S_IWUSR);
    if (m_fd == -1) {
        return HMDNanoOptimizeResultFileOperateFail;
    }
    size_t optimize_size = config.optimize_size*nano_mb;
    
    if (ftruncate(m_fd, optimize_size) != 0) {
        return HMDNanoOptimizeResultFileOperateFail;
    }
    
    void* tmpPtr = mmap(NULL, optimize_size, PROT_READ | PROT_WRITE,MAP_SHARED | MAP_FILE, m_fd, 0);
    if (tmpPtr == (void*)-1) {
        return HMDNanoOptimizeResultMmapFail;
    }
    close(m_fd);
    
    uint64_t microsecond_before_suspend = 0;
    uint64_t microsecond_after_suspend = 0;
    
    if (duration != NULL) {
        microsecond_before_suspend = current_time();
    }
    /*
     mincore use kernel_page_size not PAGESIZE
    size_t page_size = vm_kernel_page_size;

    char *vec = (char*)malloc((optimize_size/page_size)*sizeof(unsigned char));
    if (vec == nullptr) {
        return false;
    }
    */
    void* remap_ptr = (void*)nano_region_base_address;
    __block bool res = false;
    __block int memcmp_max_count = 10;
    __block int memcmp_cur_count = 0;
    dispatch_sync(dispatch_get_main_queue(), ^{
        HMDThreadSuspender::ThreadSuspender thread_suspender;
        if (thread_suspender.is_suspended) {
            while (1) {
                memcmp_cur_count++;
                memcpy(tmpPtr, remap_ptr, optimize_size);
                /*
                 if (mincore((const char*)nano_region_base_address, optimize_size, vec) == -1) {
                 thread_suspender.resume();
                 free(vec);
                 return false;
                 }
                 size_t page_count = optimize_size/page_size;
                 off_t start = 0;
                 off_t index = 0;
                 for (index = 0; index < page_count; index++) {
                 if ((vec[index]&1)==1) {
                 continue;
                 }else {
                 if (index > 0 && start != index) {
                 memcpy((void*)((uintptr_t)tmpPtr+start*page_size), (void*)(nano_region_base_address+start*page_size), (index-start)*page_size);
                 }
                 start = index+1;
                 }
                 }
                 if (start != index) {
                 memcpy((void*)((uintptr_t)tmpPtr+start*page_size), (void*)(nano_region_base_address+start*page_size), (index-start)*page_size);
                 }
                 */
                if (memcmp(remap_ptr, tmpPtr, optimize_size) == 0 || memcmp_cur_count >= memcmp_max_count) {
                    break;
                }
                usleep(50000);
            }
            
            if (memcmp_cur_count < memcmp_max_count) {
                res = hmd_vm_remap(remap_ptr, tmpPtr, optimize_size);
                if (!res) {
                    HMDLog(@"memcmp success but remap fail with memcmp %d times\n", memcmp_cur_count);
                }else {
                    HMDLog(@"memcmp and remap success with memcmp %d times\n", memcmp_cur_count);
                }
            }
        }
    });
    if (duration != NULL) {
        microsecond_after_suspend = current_time();
    }
    if (microsecond_before_suspend != 0 &&
        microsecond_after_suspend != 0) {
        *duration = microsecond_after_suspend - microsecond_before_suspend;
    }
    munmap(tmpPtr, optimize_size);
    if (memcmp_cur_count >= memcmp_max_count) {
        return HMDNanoOptimizeResultMemcmpFail;
    }
    if (res && config.need_mlock) {
        mlock(remap_ptr, optimize_size);
    }
    /*
    free(vec);
     */
    return res?HMDNanoOptimizeResultSuccess:HMDNanoOptimizeResultRemapFail;
}
