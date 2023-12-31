//
//  AppMonitorInfoPrivate.h
//  LarkPerf
//
//  Created by qihongye on 2020/6/23.
//

//#ifndef AppMonitorInfoPrivate_h
//#define AppMonitorInfoPrivate_h

#include <stdint.h>

#if __GNUC__ >= 4
    #define LOCAL  __attribute__ ((visibility ("hidden")))
#else
    #define LOCAL
#endif

#ifdef __cplusplus
extern "C"{
#endif

LOCAL const double app_monitor_get_startup_timestamp();

LOCAL void app_monitor_set_startup_timestamp(const double timeStamp);

LOCAL const double app_monitor_get_enter_foreground_timestamp(void);

LOCAL void app_monitor_set_enter_foreground_timestamp(const double timeStamp);

#ifdef __cplusplus
}
#endif

//#endif /* AppMonitorInfoPrivate_h */
