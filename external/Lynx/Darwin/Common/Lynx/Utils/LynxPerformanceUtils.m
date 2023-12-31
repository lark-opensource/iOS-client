//
//  LynxPerformanceUtils.m
//  Indexer
//
//  Created by bytedance on 2021/12/6.
//

#import "LynxPerformanceUtils.h"
#import <mach/mach.h>
#import <os/proc.h>
#import <sys/sysctl.h>

@implementation LynxPerformanceUtils

// host_statistics64 will block on multithread invoke on ios11
// detail info -->
// https://stackoverflow.com/questions/46657484/host-statistics64-become-blocking-under-ios-11
// static pthread_mutex_t _memoryUsageLockForIOS11;

static bool _isIOS11(void) {
  static bool isIOS11 = false;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (@available(iOS 12.0, *)) {
      // great or equal to ios12
    } else if (@available(iOS 11.0, *)) {
      // ios 11.0 ..< ios12
      isIOS11 = true;
      // pthread_mutex_init(&_memoryUsageLockForIOS11, NULL);
    } else {
      // ..< ios 11
    }
  });
  return isIOS11;
}

+ (NSDictionary *)memoryStatus {
  // 内存总大小
  NSString *memory_total_size = [NSString
      stringWithFormat:@"%lld", [[NSProcessInfo processInfo] physicalMemory] / (1024 * 1024)];
  // 内存可用大小
  NSString *memory_available_size = [NSString stringWithFormat:@"%lld", [self availableMemory]];
  return @{
    @"memory_total_size" : memory_total_size ?: @"",
    @"memory_available_size" : memory_available_size ?: @"",
    @"extra_memory_log" : [self extraMemoryLog] ?: @""
  };
}

+ (uint64_t)availableMemory {
  vm_size_t page_size = 0;
  mach_port_t mach_port = 0;
  mach_msg_type_number_t count = 0;
  vm_statistics64_data_t vm_stat = {0};

  mach_port = mach_host_self();
  count = HOST_VM_INFO64_COUNT;
  kern_return_t ret;
  host_page_size(mach_port, &page_size);

  if (_isIOS11()) {
    ret = 0;
    // DO NOTHING in iOS 11 DUE TO WATCHDOG ISSUE
    // pthread_mutex_lock(&_memoryUsageLockForIOS11);
    // ret = host_statistics64(mach_port, HOST_VM_INFO64, (host_info64_t)&vm_stat, &count);
    // pthread_mutex_unlock(&_memoryUsageLockForIOS11);
  } else {
    ret = host_statistics64(mach_port, HOST_VM_INFO64, (host_info64_t)&vm_stat, &count);
  }
  if (ret == KERN_SUCCESS) {
    return (vm_stat.free_count + vm_stat.purgeable_count + vm_stat.external_page_count) *
           page_size / 1024.0 / 1024.0;
  }
  return 0;
}

+ (NSString *)extraMemoryLog {
#if defined(OS_IOS)
  // https://developer.apple.com/documentation/os/3191911-os_proc_available_memory?language=objc
  if (@available(iOS 13.0, *)) {
    size_t availableMemory = os_proc_available_memory();
    return [NSString stringWithFormat:@"%.1f", availableMemory / 1024. / 1024];
  }
#endif
  return @"0";
}

@end
