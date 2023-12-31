//
//  BTDDispatch.h
//  ByteDanceKit
//
//  Created by 曾凯 on 2019/10/21.
//

#import <Foundation/Foundation.h>

/// 在主线程调用时，同步等待block执行结束或者超时，超时时间通过参数timeout_seconds配置，传入0则使用默认值0.3。子线程不支持超时，会直接在当前线程执行block。
/// 如果在指定的超时时间内完成block执行则返回0，否则返回-1
long
bd_dispatch_block_sync_global_queue_wait(NSTimeInterval timeout_seconds, dispatch_block_t block);
