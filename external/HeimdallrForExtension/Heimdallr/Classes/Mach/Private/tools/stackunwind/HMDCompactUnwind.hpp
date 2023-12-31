//
//  HMDCompactUnwind.hpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/21.
//

#ifndef HMDCompactUnwind_hpp
#define HMDCompactUnwind_hpp

#include <dispatch/dispatch.h>
#include "HMDAsyncImageList.h"

#ifdef __cplusplus
extern "C" {
#endif

extern hmd_async_image_list_t shared_image_list;
extern hmd_async_image_list_t shared_app_image_list;
    
void hmd_async_enable_compact_unwind(void);
    
bool hmd_async_can_use_compact_unwind(void);

bool hmd_async_share_image_list_has_setup(void);

void hmd_setup_shared_image_list(void); // used for compact unwind and symbolicate
        
void hmd_setup_shared_image_list_if_need(void);

//enumerate image list
void hmd_enumerate_image_list_using_block(hmd_image_callback_block block);

void hmd_enumerate_app_image_list_using_block(hmd_image_callback_block block);

//async safe
void hmd_async_enumerate_image_list(hmd_image_callback_func callback,void *ctx);

dispatch_queue_t hmd_shared_image_unwind_queue(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCompactUnwind_hpp */
