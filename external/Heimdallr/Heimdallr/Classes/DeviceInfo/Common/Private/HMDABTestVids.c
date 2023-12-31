//
//  HMDABTestVids.c
//  Heimdallr
//
//  Created by ByteDance on 2023/7/20.
//
#include <ctype.h>
#include <mach/mach.h>
#include <stdatomic.h>

#include "HMDABTestVids.h"
#include "pthread_extended.h"

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

static hmd_ab_test_vids_t *vid_info;

static void hmd_discard_old_vids_for_limit_no_lock(int count) {
    
    if (count >= vid_info->vid_count) {
        vid_info->vid_count = 0;
        vid_info->offset = 0;
        return;
    }

    
    int old_vid_index = 0;
    char *save_vids = vid_info->vids;
    
    while (old_vid_index < count) {
        if(save_vids[0] == ',') {
            old_vid_index++;
        }
        save_vids++;
    }
    
    vid_info->offset = vid_info->offset-(save_vids - vid_info->vids);
    memmove(vid_info->vids, save_vids, vid_info->offset);
    vid_info->vid_count = vid_info->vid_count - count;
    //write \0
    vid_info->vids[vid_info->offset] = '\0';
}

// "vid1","vid2"
static int hmd_contain_hit_vid_no_lock(const char *vid) {
    //"vid1"
    int current_vid_start_offset = 1;
    int current_vid_length = 0;
    
    int index = 0;
    
    while (current_vid_start_offset < vid_info->offset && index <= vid_info->offset) {
        current_vid_length++;
        if (vid_info->vids[index] == ',' || index == vid_info->offset) {
            //cmp "vid1", or "vidn"\0 with vid1
            if (current_vid_start_offset < vid_info->offset && current_vid_length > 3) {
                if (strncmp(vid_info->vids + current_vid_start_offset, vid, current_vid_length -3) == 0) {
                    return 1;
                }
            }
            
            //,"vid2" skip ,"
            current_vid_start_offset = index + 2;
            current_vid_length = 0;
        }
        index++;
    }
    return 0;
}

hmd_ab_test_vids_t * hmd_init_ab_test_vids(void) {
    
    vm_address_t address = 0x0;
    vm_size_t allocation_size = 2 * 16 * 1024;
    kern_return_t kr = vm_allocate(mach_task_self(), &address, allocation_size, VM_FLAGS_ANYWHERE);
    if(kr == KERN_SUCCESS && address) {
        vid_info = (hmd_ab_test_vids_t *)address;
    }
    
    if (vid_info) {
        vid_info->vid_count = 0;
        vid_info->offset = 0;
        vid_info->vids[0] = '\0';
    }
    return vid_info;
}

hmd_ab_test_vids_t * hmd_get_vid_info(void) {
    return vid_info;
}


hmd_ab_test_return_t hmd_add_hit_vid(const char *vid) {
    
    if (!vid) {
        return HMD_AB_TEST_NULL_VID;
    }
    
    size_t vid_len = strlen(vid);
    
    for (int i=0; i<vid_len; i++) {
        if (!isalnum(vid[i])) {
            return HMD_AB_TEST_INVALID_VID;
        }
    }
    
    if (vid_len > 60) {
        return HMD_AB_TEST_INVALID_VID;
    }
    
    mutex_lock(lock);
    
    if (!vid_info) {
        mutex_unlock(lock);
        return HMD_AB_TEST_INIT_ERR;
    }
    
    if (hmd_contain_hit_vid_no_lock(vid)) {
        mutex_unlock(lock);
        //vid has been written
        return HMD_AB_TEST_SUCCESS;
    }
    
    if (vid_info && vid_info->vid_count < HMD_MAX_VID_COUNT && vid_info->offset + vid_len + 3 < HMD_MAX_VID_LIST_LENGTH-1) {
        size_t temp_offset = vid_info->offset;
        if (vid_info->vid_count > 0) {
            //write ,
            vid_info->vids[temp_offset] = ',';
            temp_offset++;
        }
        
        //write "
        vid_info->vids[temp_offset] = '"';
        temp_offset++;
        
        //write vid
        strncpy(vid_info->vids + temp_offset, vid, vid_len);
        vid_info->vid_count++;
        temp_offset += vid_len;
        
        //write "
        vid_info->vids[temp_offset] = '"';
        temp_offset++;
        
        //write \0
        vid_info->vids[temp_offset] = '\0';
        
        atomic_thread_fence(memory_order_acq_rel);
        
        vid_info->offset = temp_offset;
       
        
    }else{
        hmd_discard_old_vids_for_limit_no_lock(300);
        mutex_unlock(lock);
        return HMD_AB_TEST_LIMIT;
    }
    mutex_unlock(lock);
    return HMD_AB_TEST_SUCCESS;
}






