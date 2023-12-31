//
//  BDPowerLogWebKitMonitor.m
//  Jato
//
//  Created by ByteDance on 2023/4/10.
//

#import "BDPowerLogWebKitMonitor.h"
#import <Stinger/Stinger.h>
#import "BDPowerLogUtility.h"
#import <Heimdallr/HMDMemoryUsage.h>

#define DEBUG_LOG(...) BDPL_DEBUG_LOG_TAG(PL_WK,##__VA_ARGS__)

@interface BDPowerLogWebKitMonitor ()
{
    struct {
        int enable : 1;
        int has_visible_webview_main_thread : 1;
        int begin_cpu_load_valid : 1;
        int end_cpu_load_valid : 1;
        int has_visible_webview_logic : 1;
        int has_visible_webview_real : 1;
    }_flags;
    NSHashTable *_hashTable;

    long long _begin_sys_ts;
    long long _end_sys_ts;
    long long _begin_task_cpu_time;
    long long _end_task_cpu_time;
    
    host_cpu_load_info_data_t _begin_cpu_load;
    host_cpu_load_info_data_t _end_cpu_load;
    
    long long _accumulativeWebKitCPUTime;
    long long _accumulativeWebKitTime;
    int _num_of_cores;
    double _otherProcessMemory;
    
    NSLock *_lock;
    NSMutableArray *_memoryEventArray;
    NSLock *_dataLock;
}
@end

@implementation BDPowerLogWebKitMonitor

+ (BDPowerLogWebKitMonitor *)sharedInstance {
    static BDPowerLogWebKitMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPowerLogWebKitMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _num_of_cores = (int)NSProcessInfo.processInfo.activeProcessorCount;
        if (_num_of_cores <= 0) {
            _num_of_cores = (int)NSProcessInfo.processInfo.processorCount?:1;
        }
        _lock = [[NSLock alloc] init];
        _memoryEventArray = [NSMutableArray array];
        _dataLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)performHook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"WKWebView");
        if (cls) {
            WEAK_SELF
            SEL sel = NSSelectorFromString(@"didMoveToWindow");
            [cls st_hookInstanceMethod:sel withOptions:STOptionBefore usingBlock:^(id<StingerParams> params){
                STRONG_SELF
                if (!strongSelf) return;
                if (!strongSelf->_flags.enable) return;
                UIView *view = params.slf;
                if (![view isKindOfClass:WKWebView.class]) {
                    return;
                }
                if (BDPLisVisibleView(view)) {
#if DEBUG
                    if (![strongSelf->_hashTable containsObject:view]) {
                        DEBUG_LOG(@"WebView become visible %@",view);
                    }
#endif
                    [strongSelf->_hashTable addObject:view];
                } else {
#if DEBUG
                    if ([strongSelf->_hashTable containsObject:view]) {
                        DEBUG_LOG(@"WebView become invisible %@",view);
                    }
#endif
                    [strongSelf->_hashTable removeObject:view];
                }
                if ([strongSelf->_hashTable count] > 0) {
                    if (!strongSelf->_flags.has_visible_webview_main_thread) {
                        DEBUG_LOG(@"webview did start, %@",NSDate.date);
                        strongSelf->_flags.has_visible_webview_main_thread = true;
                        [strongSelf webviewStart];
                    }
                } else {
                    if (strongSelf->_flags.has_visible_webview_main_thread) {
                        DEBUG_LOG(@"webview did stop, %@",NSDate.date);
                        strongSelf->_flags.has_visible_webview_main_thread = false;
                        [strongSelf webviewStop];
                    }
                }
            } error:nil];
        }
    });
}

- (void)webviewStart {
    [_lock lock];
    _flags.has_visible_webview_real = true;
    [self _webviewStart];
    [_lock unlock];
}

- (void)_webviewStart {
    if (!_flags.has_visible_webview_logic) {
        _flags.has_visible_webview_logic = true;
        _begin_sys_ts = bd_powerlog_current_sys_ts();
        _begin_task_cpu_time = bd_powerlog_task_cpu_time();
        _flags.begin_cpu_load_valid = bd_powerlog_device_cpu_load(&_begin_cpu_load) == KERN_SUCCESS;
        _otherProcessMemory = [self calculateOtherProcessMemory];
        DEBUG_LOG(@"webview start, estimate other process memory = %.2f MB",_otherProcessMemory/1024/1024);
    }
}

- (void)webviewStop {
    [_lock lock];
    _flags.has_visible_webview_real = false;
    [self _webviewStop];
    [_lock unlock];
}

- (void)_webviewStop {
    if (_flags.has_visible_webview_logic) {
        _flags.has_visible_webview_logic = false;
        _end_sys_ts = bd_powerlog_current_sys_ts();
        _end_task_cpu_time = bd_powerlog_task_cpu_time();
        _flags.end_cpu_load_valid = bd_powerlog_device_cpu_load(&_end_cpu_load) == KERN_SUCCESS;
        
        if (_flags.begin_cpu_load_valid && _flags.end_cpu_load_valid) {
            _accumulativeWebKitCPUTime += [self calculateWebKitCPUTime:_end_sys_ts - _begin_sys_ts cpu_time:_end_task_cpu_time - _begin_task_cpu_time begin_cpu_load:&_begin_cpu_load end_cpu_load:&_end_cpu_load];
        }
        _accumulativeWebKitTime += _end_sys_ts - _begin_sys_ts;
        DEBUG_LOG(@"webview stop, cpu time = %lld",_accumulativeWebKitCPUTime);
    }
}

- (void)updateWebviewStateWhenAppStateChanged:(BOOL)foreground {
    [_lock lock];
    if (_flags.has_visible_webview_real) {
        if (foreground) {
            if (!_flags.has_visible_webview_logic) {
                [self _webviewStart];
            }
        } else {
            if (_flags.has_visible_webview_logic) {
                [self _webviewStop];
            }
        }
    }
    [_lock unlock];
}

- (long long)calculateWebKitCPUTime:(long long)total_time cpu_time:(long long)app_cpu_time begin_cpu_load:(host_cpu_load_info_t)begin_cpu_load end_cpu_load:(host_cpu_load_info_t)end_cpu_load {
    if (total_time <= 100) {
        return 0;
    }

    natural_t delta_user_cpu = end_cpu_load->cpu_ticks[CPU_STATE_USER] - begin_cpu_load->cpu_ticks[CPU_STATE_USER];
    natural_t delta_system_cpu = end_cpu_load->cpu_ticks[CPU_STATE_SYSTEM] - begin_cpu_load->cpu_ticks[CPU_STATE_SYSTEM];
    natural_t delta_idle_cpu = end_cpu_load->cpu_ticks[CPU_STATE_IDLE] - begin_cpu_load->cpu_ticks[CPU_STATE_IDLE];
    natural_t delta_nice_cpu = end_cpu_load->cpu_ticks[CPU_STATE_NICE] - begin_cpu_load->cpu_ticks[CPU_STATE_NICE];
    
    double device_cpu_usage = 0;
    natural_t total_cpu = delta_user_cpu + delta_system_cpu + delta_idle_cpu + delta_nice_cpu;
    natural_t active = delta_user_cpu + delta_system_cpu + delta_nice_cpu;
    if (total_cpu > 0) {
        device_cpu_usage = (active*100.0)/total_cpu;
    }
    device_cpu_usage = device_cpu_usage * _num_of_cores;
    
    double app_cpu_usage = 0;
    if (total_time > 0) {
        app_cpu_usage = (app_cpu_time * 100.0)/total_time;
    }
    
    double webkit_cpu_usage = device_cpu_usage - app_cpu_usage;
    if (webkit_cpu_usage < 0) {
        return 0;
    }
    
    return total_time * webkit_cpu_usage / 100;
}

- (double)calculateOtherProcessMemory {
    bool invalid = false;
    double otherProcessMemory = 0;
    [_dataLock lock];
    if (_memoryEventArray.count) {
        double sum = 0;
        int count = 0;
        for (NSDictionary *memoryEvent in _memoryEventArray) {
            uint64_t app_memory = [[memoryEvent bdpl_objectForKey:@"app_memory" cls:NSNumber.class] unsignedLongLongValue];
            uint64_t device_memory = [[memoryEvent bdpl_objectForKey:@"device_memory" cls:NSNumber.class] unsignedLongLongValue];
            sum += device_memory - app_memory;
            count += 1;
        }
        otherProcessMemory = sum/count;
    } else {
        invalid = true;
    }
    
    [_dataLock unlock];
    
    if (invalid)
        return -1;
    
    if (otherProcessMemory < 0)
        otherProcessMemory = 0;

    return otherProcessMemory;
}


- (void)start {
    _flags.enable = true;
    [self performHook];
}

- (void)stop {
    _flags.enable = false;
}

- (void)addMemoryEvent:(NSDictionary *)memoryEvent {
    if (!_flags.enable)
        return;
    
    [_lock lock];
    bool in_webview = _flags.has_visible_webview_logic;
    [_lock unlock];
    
    if (in_webview)
        return;
    
    [_dataLock lock];
    
    [_memoryEventArray addObject:memoryEvent];
    
    __block NSUInteger index = NSNotFound;
    [_memoryEventArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (memoryEvent.sys_ts - obj.sys_ts <= 60000) {
            *stop = YES;
        }
        index = idx;
    }];

    if (index != NSNotFound && index > 0) {
        [_memoryEventArray removeObjectsInRange:NSMakeRange(0, MIN(index, _memoryEventArray.count))];
    }
    
    if (_memoryEventArray.count > 10) {
        [_memoryEventArray removeObjectsInRange:NSMakeRange(0, _memoryEventArray.count - 10)];
    }

    [_dataLock unlock];
}

- (long long)currentWebKitCPUTime {
    if (!_flags.enable)
        return 0;
    [_lock lock];
    long long webkitCPUTime = _accumulativeWebKitCPUTime;
    if (_flags.has_visible_webview_logic) {
        long long end_sys_ts = bd_powerlog_current_sys_ts();
        long long end_task_cpu_time = bd_powerlog_task_cpu_time();
        host_cpu_load_info_data_t end_cpu_load;
        bool end_cpu_load_valid = bd_powerlog_device_cpu_load(&end_cpu_load) == KERN_SUCCESS;
        if (_flags.begin_cpu_load_valid && end_cpu_load_valid) {
            webkitCPUTime += [self calculateWebKitCPUTime:end_sys_ts - _begin_sys_ts cpu_time:end_task_cpu_time - _begin_task_cpu_time begin_cpu_load:&_begin_cpu_load end_cpu_load:&end_cpu_load];
        }
    }
    [_lock unlock];
    DEBUG_LOG(@"webkit cpu time = %lld",webkitCPUTime);
    return webkitCPUTime;
}

- (long long)currentWebKitTime {
    if (!_flags.enable)
        return 0;
    [_lock lock];
    long long webkitTime = _accumulativeWebKitTime;
    if (_flags.has_visible_webview_logic) {
        long long end_sys_ts = bd_powerlog_current_sys_ts();
        webkitTime += end_sys_ts - _begin_sys_ts;
    }
    [_lock unlock];
    return webkitTime;
}

- (double)currentWebKitMemory {
    if (!_flags.enable)
        return 0;
    [_lock lock];
    double webkitMemory = 0;
    if (_flags.has_visible_webview_logic && _otherProcessMemory >= 0) {
        hmd_MemoryBytes memory = hmd_getMemoryBytes();
        uint64_t appMemory = memory.appMemory;
        uint64_t deviceMemory = memory.usedMemory;
        webkitMemory = deviceMemory - appMemory - _otherProcessMemory;
        if (webkitMemory < 0)
            webkitMemory = 0;
    }
    [_lock unlock];
    return webkitMemory;
}

- (void)updateAppState:(BOOL)foreground {
    
    [self updateWebviewStateWhenAppStateChanged:foreground];
    
    [_dataLock lock];
            
    [_memoryEventArray removeAllObjects];
    
    [_dataLock unlock];
}

@end
