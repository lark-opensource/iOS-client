//
//  thread_biz_scope.h
//  ByteView
//
//  Created by liujianlong on 2023/4/4.
//

#ifndef thread_biz_scope
#define thread_biz_scope

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

typedef enum ByteViewThreadBizScope: int64_t {
ByteViewThreadBizScope_Unknown = 0,
ByteViewThreadBizScope_VideoConference = 1,
ByteViewThreadBizScope_RTC = 2,
} ByteViewThreadBizScope;

void byteview_setup_thread_api(void);

ByteViewThreadBizScope byteview_get_current_biz_scope(void);

ByteViewThreadBizScope byteview_set_current_biz_scope(ByteViewThreadBizScope scope);

ByteViewThreadBizScope byteview_get_thread_scope(uint64_t tid);

#ifdef __cplusplus
}
#endif //__cplusplus

#endif /* thread_biz_scope */
