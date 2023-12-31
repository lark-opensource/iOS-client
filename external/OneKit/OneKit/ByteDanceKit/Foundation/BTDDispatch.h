//
//  BTDDispatch.h
//  ByteDanceKit
//
//  Created by zengkai on 2019/10/21.
//

#import <Foundation/Foundation.h>

/// When the function is called in main thread, it will execute the block and wait until the end of the block's execution or the timeout. When the param timeout_seconds is 0, it will be set as 0.01 by default. The function will not support the timeout and execute the block immediately when it is called in child thread.
/// The function will return 0 if the block's execution is over. Otherwise it will return -1.
long
bd_dispatch_block_sync_global_queue_wait(NSTimeInterval timeout_seconds, dispatch_block_t block);
