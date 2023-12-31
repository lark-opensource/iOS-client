//
//  HMDGCD.h
//  Pods
//
//  Created by 白昆仑 on 2020/5/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
    
    void hmd_safe_dispatch_async(dispatch_queue_t queue, dispatch_block_t block);

    void hmd_safe_dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);
    
#ifdef __cplusplus
}
#endif


NS_ASSUME_NONNULL_END
