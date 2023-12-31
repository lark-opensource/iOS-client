//
//  BDAlogTools.hpp
//  BDALog
//
//  Created by liuhan on 2022/11/15.
//

#ifndef BDAlogTools_h
#define BDAlogTools_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

dispatch_queue_t alog_manager(void);

dispatch_queue_t flush_quene(void);

dispatch_queue_t main_thread_async_write_queue(void);

void async_execute_write_log(void (*callback)(void *), void *data);

#ifdef __cplusplus
}
#endif

#endif /* BDAlogTools_h */
