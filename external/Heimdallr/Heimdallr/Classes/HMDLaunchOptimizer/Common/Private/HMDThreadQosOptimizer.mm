//
//  HMDThreadQoSOptimizer.m
//  Pods
//
//  Created by xushuangqing on 2022/1/27.
//

#import "HMDThreadQosOptimizer.h"
#import <BDFishhook/BDFishhook.h>
#import <CoreFoundation/CFRunLoop.h>
#import <mach-o/dyld.h>
#import "HMDALogProtocol.h"
#import "HMDQoSMockerConfig.hpp"
#import "HMDThreadQosCollector.h"
#import "HMDThreadQosMocker.h"
#import "HMDFishhookQueue.h"
#import <atomic>


#pragma mark - fishhook

static dispatch_queue_t launch_mock_queue = NULL;

@interface HMDThreadQosOptimizer ()

@property (nonatomic, strong, class) NSArray *workers;

@end

static void image_add_callback (const struct mach_header *mh, intptr_t vmaddr_slide) {
    if (launch_mock_queue == NULL) {
        return;
    }
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
        return;
    }
    dispatch_async(launch_mock_queue, ^{
        if (HMDThreadQosOptimizer.workers.count > (HMDQosMockerConfigForCurrentLaunch::collectorEnabled ? 1 : 0) + (HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled ? 1 : 0)) {
            return;
        }
        for (id<HMDThreadQosWorkerProtocol> worker in HMDThreadQosOptimizer.workers) {
            [worker fishhookWithRebingBlock:^(struct bd_rebinding *rebindings, size_t rebindings_nel) {
                bd_rebind_symbols_image((void *)mh, vmaddr_slide, rebindings, rebindings_nel);
            }];
        }
    });
}

@implementation HMDThreadQosOptimizer

#pragma mark - Switch

static NSArray *HMDThreadQosOptimizerWorkers = nil;

+ (NSArray *)workers {
    return HMDThreadQosOptimizerWorkers;
}

+ (void)setWorkers:(NSArray *)workers {
    HMDThreadQosOptimizerWorkers = workers;
}

+ (BOOL)shouldOpenLaunchOptimization {
    if ([[NSProcessInfo processInfo] activeProcessorCount] > 2) {
        return NO;
    }
    
    [[HMDQoSMockerConfig sharedConfig] readFromDisk];
    return HMDQosMockerConfigForCurrentLaunch::collectorEnabled || HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled;
}

+ (void)toggleNextLaunchQosMockerEnabled:(BOOL)qosMockerEnabled keyQueueCollectorEnabled:(BOOL)keyQueueCollectorEnabled whiteList:(NSArray<NSString *> *)whiteList {
    [HMDQoSMockerConfig sharedConfig].enableQosMocker = qosMockerEnabled;
    [HMDQoSMockerConfig sharedConfig].enableKeyQueueCollector = keyQueueCollectorEnabled;
    [HMDQoSMockerConfig sharedConfig].whiteListQueueNames = whiteList;
    [[HMDQoSMockerConfig sharedConfig] flush];
}

#pragma mark - +Load

//是否执行 key queue 采集
+ (BOOL)keyQueueCollectorEnabled{
    return HMDQosMockerConfigForCurrentLaunch::collectorEnabled;
}

//是否执行优化
+ (BOOL)threadQoSMockerEnabled {
    return HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled;
}

+ (void)markLaunchFinished {
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished) {
        return;
    }
    HMDQosMockerConfigForCurrentLaunch::launchFinished = true;
    
    for (id<HMDThreadQosWorkerProtocol> worker in self.workers) {
        if ([worker respondsToSelector:@selector(launchDidFinished)]) {
            [worker launchDidFinished];
        }
    }
}

extern "C" NSArray<NSString *>* hmd_launch_optmizer_mark_key_point(NSString *label) {
    if (HMDQosMockerConfigForCurrentLaunch::launchFinished) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray new];
    for (id<HMDThreadQosWorkerProtocol> worker in HMDThreadQosOptimizer.workers) {
        if ([worker respondsToSelector:@selector(markKeyPoint:)]) {
            NSArray<NSString *>*res = [worker markKeyPoint:label];
            [array addObjectsFromArray:res];
        }
    }
    return [array copy];
}

+ (void)observeFirstRenderWithBlock:(dispatch_block_t)block {
    if (@available(iOS 13.0, *)) {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopActivity activities = kCFRunLoopBeforeTimers;
        CFRunLoopObserverRef observer =
            CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                if (activity == kCFRunLoopBeforeTimers) {
                    CFRunLoopRemoveObserver(mainRunloop, observer, kCFRunLoopCommonModes);
                    CFRelease(observer);
                    if (block) {block();}
                }
            });
        CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
    } else {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopPerformBlock(mainRunloop, (CFTypeRef)NSDefaultRunLoopMode, block);
    }
}

+ (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self observeFirstRenderWithBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self markLaunchFinished];
        });
    }];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)load {
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, std::memory_order_acq_rel)) {
        return;
    }
    
    if (![self shouldOpenLaunchOptimization]) {
        return;
    }
    
    NSMutableArray *workers = [NSMutableArray new];
    
    if (HMDQosMockerConfigForCurrentLaunch::collectorEnabled) {
        HMDThreadQosCollector *collector = [HMDThreadQosCollector sharedInstance];
        [workers addObject:collector];
    }
    
    if (HMDQosMockerConfigForCurrentLaunch::qosMockerEnabled) {
        HMDThreadQosMocker *qosMocker = [HMDThreadQosMocker sharedInstance];
        [workers addObject:qosMocker];
    }
    
    self.workers = [workers copy];
    
    open_bdfishhook();
    launch_mock_queue = hmd_fishhook_queue();
    dispatch_async(launch_mock_queue, ^{
        _dyld_register_func_for_add_image(image_add_callback);
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

@end
