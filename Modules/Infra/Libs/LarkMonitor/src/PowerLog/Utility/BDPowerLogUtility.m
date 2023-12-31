//
//  BDPowerLogUtility.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import "BDPowerLogUtility.h"
#import <sys/time.h>
#import "BDPowerLogManager.h"
#import <Heimdallr/HMDGPUUsage.h>
#include <dlfcn.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <objc/runtime.h>
#include <pthread/pthread.h>
#import <Heimdallr/HMDUITrackerTool.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"

long long bd_powerlog_task_cpu_time(void) {
    double task_cpu_time = clock()/(CLOCKS_PER_SEC * 0.001);
    return (long long)task_cpu_time;
}

long long bd_powerlog_current_ts(void) {
    struct timeval time;
    int ret = gettimeofday(&time,NULL);
    if (ret == 0) {
        double ts = (double)time.tv_sec * 1000 + (double)time.tv_usec * .001;
        return (long long)ts;
    }
    return (long long)(CFAbsoluteTimeGetCurrent() * 1000);
}

long long bd_powerlog_current_sys_ts(void) {
    return (long long)(CACurrentMediaTime() * 1000);
}

kern_return_t bd_powerlog_device_cpu_load(host_cpu_load_info_t cpu_load) {
    mach_msg_type_number_t  count = HOST_CPU_LOAD_INFO_COUNT;
    host_cpu_load_info_data_t cpu_load_info;
    mach_port_t host_port = mach_host_self();
    kern_return_t kr = host_statistics(host_port, HOST_CPU_LOAD_INFO, (host_info_t)&cpu_load_info, &count);
    mach_port_deallocate(mach_task_self(), host_port);
    
    if (kr == KERN_SUCCESS) {
        if (cpu_load) {
            *cpu_load = cpu_load_info;
        }
    }
    return kr;
}

NSString *BDPLBase64Decode(NSString *str) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:0];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}
//
//static NSString *base64Encode(NSString *str) {
//    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
//    return [data base64EncodedStringWithOptions:0];
//}

typedef int (*bd_powerlog_proc_rusage_func_type)(int pid, int flavor, rusage_info_t *buffer);
bool bd_powerlog_io_info(bd_powerlog_io_info_data *io_info) {
    struct rusage_info_v4 ru;
    static bd_powerlog_proc_rusage_func_type g_func_ptr;
    bd_powerlog_proc_rusage_func_type func_ptr = g_func_ptr;
    if (!func_ptr) {
        NSString *funcName = BDPLBase64Decode(@"cHJvY19waWRfcnVzYWdl");
        func_ptr = dlsym(RTLD_NEXT, funcName.UTF8String);
        g_func_ptr = func_ptr;
    }
    if (!func_ptr) {
        return false;
    }
    int ret = func_ptr(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&ru);
    if (ret != 0) {
        return false;
    }
    long long ts = bd_powerlog_current_ts();
    uint64_t diskio_bytesread = ru.ri_diskio_bytesread;
    uint64_t diskio_byteswritten = ru.ri_diskio_byteswritten;
    uint64_t logical_writes = ru.ri_logical_writes;
    if (io_info) {
        io_info->ts = ts;
        io_info->diskio_bytesread = diskio_bytesread;
        io_info->diskio_byteswritten = diskio_byteswritten;
        io_info->logical_writes = logical_writes;
    }
    return true;
}

double bd_powerlog_gpu_usage(void) {
    return HMDGPUUsage.gpuUsage * 100;
}

bool bd_powerlog_device_net_info(bd_powerlog_net_info *net_info) {
    struct ifaddrs *ifa_list= NULL, *ifa;
    if (![BDPowerLogManager.delegate respondsToSelector:@selector(getifaddrs:)]) {
        return false;
    }
    if (![BDPowerLogManager.delegate getifaddrs:&ifa_list]) {
        return false;
    }
    if (net_info) {
        *net_info = (bd_powerlog_net_info){0};
    }
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        if (!(ifa->ifa_flags& IFF_UP) &&!(ifa->ifa_flags & IFF_RUNNING))
            continue;
        if (ifa->ifa_data == 0)
            continue;
        if (strcmp(ifa->ifa_name,"en0") == 0) {
            // wifi
            struct if_data *if_data = (struct if_data*)ifa->ifa_data;
            if (net_info) {
                net_info->wifi_recv += if_data->ifi_ibytes;
                net_info->wifi_send += if_data->ifi_obytes;
            }
        }else if (strcmp(ifa->ifa_name, "pdp_ip0") == 0) {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            if (net_info) {
                net_info->cellular_recv += if_data->ifi_ibytes;
                net_info->cellular_send += if_data->ifi_obytes;
            }
        }
    }
    freeifaddrs(ifa_list);
    return true;
}

double bd_powerlog_instant_cpu_usage(void) {
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;

    double total_cpu_usage = 0;
    kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr == KERN_SUCCESS) {
        mach_msg_type_number_t thread_basic_info_count = THREAD_BASIC_INFO_COUNT;
        thread_basic_info_data_t thread_basic_info;
                
        kern_return_t kr;
        
        for (int idx = 0; idx < (int)thread_count; idx++) {
            thread_t thread_mach_port = thread_list[idx];
            kr = thread_info(thread_mach_port, THREAD_BASIC_INFO, (thread_info_t)&thread_basic_info, &thread_basic_info_count);
            if (kr != KERN_SUCCESS) {
                continue;
            }
            if (!(thread_basic_info.flags & TH_FLAGS_IDLE)) {
                double thread_cpu_usage_instant = thread_basic_info.cpu_usage / (float)TH_USAGE_SCALE;
                total_cpu_usage += thread_cpu_usage_instant;
            }
        }

        for(size_t index = 0; index < thread_count; index++)
            mach_port_deallocate(mach_task_self(), thread_list[index]);
        vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
        return total_cpu_usage * 100;
    }

    return -1;
}

API_AVAILABLE(ios(11.0))
NSString *BDPowerLogThermalStateName(NSProcessInfoThermalState thermalState) {
    NSString *name;
    switch (thermalState) {
        case NSProcessInfoThermalStateNominal:
            name = @"nominal";
            break;
        case NSProcessInfoThermalStateFair:
            name = @"fair";
            break;
        case NSProcessInfoThermalStateSerious:
            name = @"serious";
            break;
        case NSProcessInfoThermalStateCritical:
            name = @"critical";
            break;
        default:
            name = @"unknown";
            break;
    }
    return name;
}

int BDPowerLogThermalState(NSString *name) {
    if ([name isEqualToString:@"nominal"]) {
        return 0;
    }
    if ([name isEqualToString:@"fair"]) {
        return 1;
    }
    if ([name isEqualToString:@"serious"]) {
        return 2;
    }
    if ([name isEqualToString:@"critical"]) {
        return 3;
    }
    return -1;
}

NSString *BDPowerLogBatteryStateName(UIDeviceBatteryState batteryState) {
    NSString *name;
    switch (batteryState) {
        case UIDeviceBatteryStateFull:
        case UIDeviceBatteryStateCharging:
            name = @"charging";
            break;
        case UIDeviceBatteryStateUnplugged:
            name = @"unplugged";
            break;
        case UIDeviceBatteryStateUnknown:
        default:
            name = @"unknown";
            break;
    }
    return name;
}

void BDPowerLogPerformOnMainQueue(dispatch_block_t block) {
    if (NSThread.isMainThread) {
        if (block) {
            block();
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void BDPowerLogInfo(NSString *format,...) {
    if ([BDPowerLogManager.delegate respondsToSelector:@selector(printInfoLog:)]) {
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        [BDPowerLogManager.delegate printInfoLog:log];
    }
}

void BDPowerLogWarning(NSString *format,...) {
    if ([BDPowerLogManager.delegate respondsToSelector:@selector(printWarningLog:)]) {
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        [BDPowerLogManager.delegate printWarningLog:log];
    }
}

void BDPowerLogError(NSString *format,...) {
    if ([BDPowerLogManager.delegate respondsToSelector:@selector(printErrorLog:)]) {
        va_list args;
        va_start(args, format);
        NSString *log = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        [BDPowerLogManager.delegate printErrorLog:log];
    }
}

void BDPLSetAssociation(id object,NSString *key,id value,objc_AssociationPolicy policy) {
    objc_setAssociatedObject(object, key.UTF8String, value, policy);
}

id BDPLGetAssociation(id object,NSString *key) {
    return objc_getAssociatedObject(object, key.UTF8String);
}

static IMP _Nullable _bd_pl_get_imp_for_sel(Class cls,SEL sel,bool isClassSel) {
    NSCAssert(sel, @"The sel cannot be NULL");
    NSCAssert(cls, @"The cls cannot be NULL");
    if (sel == NULL || cls == NULL)return NULL;

    IMP currentIMP = nil;
    Method method = nil;
    if (isClassSel) {
      method = class_getClassMethod(cls, sel);
    } else {
      method = class_getInstanceMethod(cls, sel);
    }
    
    NSCAssert(method, @"%@ %@ method doesn't exist", NSStringFromClass(cls), NSStringFromSelector(sel));
    if (method == nil) return nil;
    
    currentIMP = method_getImplementation(method);
    NSCAssert(currentIMP, @"%@ %@ IMP doesn't exist", NSStringFromClass(cls), NSStringFromSelector(sel));

    return currentIMP;
}

static void _bd_pl_set_imp_for_sel(Class cls,SEL sel,bool isClassSel,IMP imp) {
    NSCAssert(sel, @"The sel cannot be NULL");
    NSCAssert(cls, @"The cls cannot be NULL");
    NSCAssert(imp, @"The imp cannot be NULL");
    if (sel == NULL || cls == NULL || imp == NULL)return;

    Class resolvedClass = cls;
    Method method = nil;
    if (isClassSel) {
        method = class_getClassMethod(cls, sel);
        resolvedClass = object_getClass(cls);
    } else {
        method = class_getInstanceMethod(cls, sel);
    }
    NSCAssert(method, @"%@ %@ method doesn't exist", NSStringFromClass(resolvedClass), NSStringFromSelector(sel));
    if (method == NULL)return;
    
    const char *typeEncoding = method_getTypeEncoding(method);
    __unused IMP originalImpOfClass = class_replaceMethod(resolvedClass, sel, imp, typeEncoding);
    NSCAssert(imp == _bd_pl_get_imp_for_sel(cls, sel, isClassSel), @"%@ %@ replace method failed",NSStringFromClass(resolvedClass), NSStringFromSelector(sel));
    BDPL_DEBUG_LOG(@"hook class = %@ sel = %@ is_class_sel = %d imp = %p",NSStringFromClass(cls),NSStringFromSelector(sel),isClassSel,imp);
}

void bd_pl_set_imp_for_sel(Class cls,SEL sel,IMP imp) {
    _bd_pl_set_imp_for_sel(cls, sel, false, imp);
}

void bd_pl_set_imp_for_class_sel(Class cls,SEL sel,IMP imp) {
    _bd_pl_set_imp_for_sel(cls, sel, true, imp);
}

void bd_pl_set_block_for_sel(Class cls,SEL sel,id block) {
    NSCAssert(block, @"The block cannot be NULL");
    if (block == NULL)return;
    IMP newImp = imp_implementationWithBlock(block);
    _bd_pl_set_imp_for_sel(cls, sel, false, newImp);
}

void bd_pl_set_block_for_class_sel(Class cls,SEL sel,id block) {
    NSCAssert(block, @"The block cannot be NULL");
    if (block == NULL)return;
    IMP newImp = imp_implementationWithBlock(block);
    _bd_pl_set_imp_for_sel(cls, sel, true, newImp);
}

IMP _Nullable bd_pl_get_imp_for_sel(Class cls,SEL sel) {
    return _bd_pl_get_imp_for_sel(cls, sel, false);
}

IMP _Nullable bd_pl_get_imp_for_class_sel(Class cls,SEL sel) {
    return _bd_pl_get_imp_for_sel(cls, sel, true);
}

uint64_t bd_pl_get_current_thread_cpu_time(void) {
    uint64_t thread_cpu_time = 0;
    thread_t thread_self = mach_thread_self();
    mach_msg_type_number_t thread_basic_info_count = THREAD_BASIC_INFO_COUNT;
    thread_basic_info_data_t thread_basic_info;
    kern_return_t kr = thread_info(thread_self, THREAD_BASIC_INFO, (thread_info_t)&thread_basic_info, &thread_basic_info_count);
    if (kr == KERN_SUCCESS) {
        thread_cpu_time = thread_basic_info.user_time.seconds * 1000 + thread_basic_info.user_time.microseconds/1000 + thread_basic_info.system_time.seconds * 1000 + thread_basic_info.system_time.microseconds/1000;
    }
    mach_port_deallocate(mach_task_self(), thread_self);
    return thread_cpu_time;
}

uint64_t bd_pl_get_current_thread_id(void) {
    uint64_t tid = 0;
    pthread_threadid_np(NULL, &tid);
    return tid;
}

static uint64_t _main_thread_id;
void bd_pl_update_main_thread_id(void) {
    if (NSThread.isMainThread) {
        _main_thread_id = bd_pl_get_current_thread_id();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            _main_thread_id = bd_pl_get_current_thread_id();
        });
    }
}

uint64_t bd_pl_get_thread_id(thread_t t) {
    pthread_t pth = pthread_from_mach_thread_np(t);
    uint64_t tid = 0;
    if (pth) {
        pthread_threadid_np(pth, &tid);
    }
    return tid;
}

bool bd_pl_is_main_thread(thread_t t) {
    uint64_t tid = bd_pl_get_thread_id(t);
    NSCAssert(_main_thread_id != 0, @"main thread id is 0");
    return _main_thread_id == tid;
}

static UIViewController *findTopChildViewControllers(NSArray *viewControllers) {
    NSMutableArray *array = [NSMutableArray array];
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.isViewLoaded && !obj.view.hidden) {
            [array addObject:obj];
        }
    }];
    [array sortUsingComparator:^NSComparisonResult(UIViewController *  _Nonnull obj1, UIViewController *  _Nonnull obj2) {
        CGRect rect1 = [obj1.view convertRect:obj1.view.bounds toView:obj1.view.window];
        CGRect rect2 = [obj2.view convertRect:obj2.view.bounds toView:obj2.view.window];
        rect1 = CGRectIntersection(rect1, obj1.view.window.bounds);
        rect2 = CGRectIntersection(rect2, obj2.view.window.bounds);
        double square1 = CGRectGetWidth(rect1) * CGRectGetHeight(rect1);
        double square2 = CGRectGetWidth(rect2) * CGRectGetHeight(rect2);
        if (square1 < square2) {
            return NSOrderedAscending;
        } else if (square1 > square2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return [array lastObject];
}

UIViewController *BDPLTopViewControllerForController(UIViewController *rootViewController)
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return BDPLTopViewControllerForController([navigationController.viewControllers lastObject]);
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootViewController;
        return BDPLTopViewControllerForController(tabController.selectedViewController);
    }
    if (rootViewController.presentedViewController) {
        return BDPLTopViewControllerForController(rootViewController.presentedViewController);
    }
    if (rootViewController.childViewControllers.count) {
        UIViewController *childVC = findTopChildViewControllers(rootViewController.childViewControllers);
        if (childVC && childVC != rootViewController) return BDPLTopViewControllerForController(childVC);
    }
    return rootViewController;
}

UIViewController *BDPLTopViewController(void) {
    return BDPLTopViewControllerForController([HMDUITrackerTool keyWindow].rootViewController);
}

static BOOL BDPLIsSceneSupport(void) {
    static BOOL support = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        support = [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIApplicationSceneManifest"] != nil;
    });
    return support;
}

NSArray *BDPLVisibleWindows(void) {
    NSMutableArray *ret = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        if (BDPLIsSceneSupport()) {
            NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
            [scenes enumerateObjectsUsingBlock:^(UIScene  *_Nonnull scene, BOOL * _Nonnull stop) {
                if ([scene isKindOfClass:UIWindowScene.class] && scene.activationState != UISceneActivationStateUnattached) {
                    [[(UIWindowScene *)scene windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (!window.isHidden) {
                            [ret addObject:window];
                        }
                    }];
                }
            }];
            [ret sortUsingComparator:^NSComparisonResult(UIWindow *_Nonnull obj1, UIWindow *_Nonnull obj2) {
                UISceneActivationState state1 = UISceneActivationStateBackground;
                if (obj1.windowScene) {
                    state1 = obj1.windowScene.activationState;
                }
                UISceneActivationState state2 = UISceneActivationStateBackground;
                if (obj2.windowScene) {
                    state2 = obj2.windowScene.activationState;
                }
                if (state1 < state2) {
                    return NSOrderedAscending;
                }
                if (state1 == state2) {
                    return NSOrderedSame;
                }
                return NSOrderedDescending;
            }];
            return ret;
        }
    }
    NSArray *windows = [UIApplication sharedApplication].windows;
    [windows enumerateObjectsUsingBlock:^(UIWindow *_Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!window.isHidden) {
            [ret addObject:window];
        }
    }];
    return ret;
}

BOOL BDPLisVisibleView(UIView *view) {
    if (view.window == nil || view.window.isHidden) {
        return NO;
    }
    int counter = 0;
    UIView *v = view;
    while (v) {
        if (v.isHidden)
            return NO;
        v = v.superview;
        counter++;
        if (counter > 100) { //防止死循环，增加一个遍历的上限
            return YES;
        }
    }
    return YES;
}
