//
//  BDPowerLogUtility.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+HMDPL.h"

#import <mach/mach.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#define WEAK_SELF __weak typeof(self) weakSelf = self;
#define STRONG_SELF __strong typeof(self) strongSelf = weakSelf;

#ifdef DEBUG
#define BD_POWERLOG_DEBUG 1
#define BDPL_DEBUG_LOG(FORMAT, ...)                                \
  do {                                                                         \
    fprintf(stdout, "[PL.DEBUG] %s\n",                                         \
            [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);        \
  } while (0);
#define BDPL_DEBUG_LOG_TAG(TAG,FORMAT, ...)                                \
  do {                                                                         \
    fprintf(stdout, "[PL.DEBUG][%s] %s\n",                                         \
            #TAG,[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);        \
  } while (0);
#else
#define BDPL_DEBUG_LOG(...)
#define BDPL_DEBUG_LOG_TAG(...)
#endif


#define BD_POWERLOG_DEFAULT_INTERVAL 20     //20s采集一次
#define BD_POWERLOG_MAX_INTERVAL 60     //最大60s采集一次
#define BD_POWERLOG_MIN_INTERVAL 5 //最小间隔5s采集一次

#define BD_POWERLOG_SESSION_MAX_TIME 300 //session最长5分钟
#define BD_POWERLOG_MAX_ITEMS (BD_POWERLOG_SESSION_MAX_TIME/BD_POWERLOG_MIN_INTERVAL)+1  //最大数据条数

#define BD_DICT_SET(dict,key,val) \
do{\
[dict bdpl_setObject:val forKey:key];\
}while(0);

#define BD_DICT_GET(dict,key) \
({\
id ret = [dict bdpl_objectForKey:key];\
ret;\
})

#define BD_DICT_GET_CLS(dict,key,aclass) \
({\
id ret = [dict bdpl_objectForKey:key cls:aclass.class];\
ret;\
})

#define BD_ARRAY_ADD(array,val) \
do{\
if(val)[array addObject:val];\
}while(0);

#define BD_SET_ADD BD_ARRAY_ADD

#ifdef __cplusplus
extern "C" {
#endif

//long long bd_powerlog_task_cpu_time(void);

long long hmd_powerlog_current_ts(void);

long long hmd_powerlog_current_sys_ts(void);

//kern_return_t bd_powerlog_device_cpu_load(host_cpu_load_info_t cpu_load);

typedef struct hmd_powerlog_io_info_data {
    long long ts;
    uint64_t diskio_bytesread;
    uint64_t diskio_byteswritten;
    uint64_t logical_writes;
}hmd_powerlog_io_info_data;

bool hmd_powerlog_io_info(hmd_powerlog_io_info_data *io_info);

double hmd_powerlog_gpu_usage(void);

/*
typedef struct {
    uint64_t wifi_send;
    uint64_t wifi_recv;
    uint64_t cellular_send;
    uint64_t cellular_recv;
}bd_powerlog_net_info;

bool bd_powerlog_device_net_info(bd_powerlog_net_info *net_info);

double bd_powerlog_instant_cpu_usage(void);

NSString *BDPLBase64Decode(NSString *str);
 */

API_AVAILABLE(ios(11.0))
NSString *HMDPowerLogThermalStateName(NSProcessInfoThermalState thermalState);

int HMDPowerLogThermalState(NSString *name);

NSString *HMDPowerLogBatteryStateName(UIDeviceBatteryState batteryState);

void HMDPowerLogPerformOnMainQueue(dispatch_block_t block);

void HMDPowerLogInfo(NSString *format,...);

void HMDPowerLogWarning(NSString *format,...);

void HMDPowerLogError(NSString *format,...);

/*
void BDPLSetAssociation(id object,NSString *key,id _Nullable value,objc_AssociationPolicy policy);

id BDPLGetAssociation(id object,NSString *key);

void bd_pl_set_imp_for_sel(Class cls,SEL sel,IMP imp);

void bd_pl_set_imp_for_class_sel(Class cls,SEL sel,IMP imp);

void bd_pl_set_block_for_sel(Class cls,SEL sel,id block);

void bd_pl_set_block_for_class_sel(Class cls,SEL sel,id block);

IMP _Nullable bd_pl_get_imp_for_sel(Class cls,SEL sel);

IMP _Nullable bd_pl_get_imp_for_class_sel(Class cls,SEL sel);

uint64_t bd_pl_get_current_thread_cpu_time(void);

void bd_pl_update_main_thread_id(void);

uint64_t bd_pl_get_current_thread_id(void);

bool bd_pl_is_main_thread(thread_t t);

UIViewController *BDPLTopViewControllerForController(UIViewController *rootViewController);

UIViewController *BDPLTopViewController(void);

NSArray *BDPLVisibleWindows(void);

BOOL BDPLisVisibleView(UIView *view);
*/

#ifdef __cplusplus
} // extern "C"
#endif

NS_ASSUME_NONNULL_END
