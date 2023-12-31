//
//  HMDThreadQosMocker.cpp
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/5/11.
//

#import "HMDThreadQosMocker.h"
#import "HMDQoSMockerConfig.hpp"
#import "HMDALogProtocol.h"
#import <BDFishhook/BDFishhook.h>

#if defined(__GNUC__)
#define WEAK_FUNC     __attribute__((weak))
#elif defined(_MSC_VER) && !defined(_LIB)
#define WEAK_FUNC __declspec(selectany)
#else
#define WEAK_FUNC
#endif

extern "C" dispatch_qos_class_t WEAK_FUNC
override_updated_qos_class_for_queue_during_launch(dispatch_queue_t queue, dispatch_qos_class_t origin_qos, dispatch_qos_class_t updated_qos) {
    return updated_qos;
}

static dispatch_qos_class_t
update_qos_class_for_queue_during_launch(dispatch_queue_t queue, dispatch_qos_class_t origin_qos) {
    dispatch_qos_class_t updated_qos = origin_qos;
    
    bool inWhite = false;
    std::string name = std::string(dispatch_queue_get_label(queue));
    for (const std::string &whiteName : *HMDQosMockerConfigForCurrentLaunch::whiteListQueue) {
        if (name.find(whiteName) != std::string::npos) {
            inWhite = true;
            break;
        }
    }
    
    if (origin_qos == QOS_CLASS_UNSPECIFIED && !inWhite) {
        updated_qos = QOS_CLASS_UTILITY;
    }
    
    return override_updated_qos_class_for_queue_during_launch(queue, origin_qos, updated_qos);
}

static void (*orig_dispatch_async)(dispatch_queue_t queue, dispatch_block_t block);
static void hooked_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
    @autoreleasepool {
        if (HMDQosMockerConfigForCurrentLaunch::launchFinished == true) {
            orig_dispatch_async(queue, block);
            return;
        }
        qos_class_t originQos = dispatch_queue_get_qos_class(queue, NULL);
        qos_class_t nQos = update_qos_class_for_queue_during_launch(queue, originQos);
        if (originQos == nQos) {
            orig_dispatch_async(queue, block);
        }
        else {
            dispatch_block_t qos_block;
            qos_block = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_ENFORCE_QOS_CLASS, nQos, 0, ^{
                block();
            });
            orig_dispatch_async(queue, qos_block);
        }
    }
}

@implementation HMDThreadQosMocker

#define HOOKED(func) hooked_##func
#define ORIG(func) orig_##func
#define REBINDING(func) \
    {#func, (void *)&HOOKED(func), (void **)&ORIG(func)}

+ (instancetype)sharedInstance {
    static HMDThreadQosMocker* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)fishhookWithRebingBlock:(void (^)(struct bd_rebinding *, size_t))rebindingBlock {
    struct bd_rebinding r[] = {
        REBINDING(dispatch_async)
    };
    if (rebindingBlock) {
        rebindingBlock(r, sizeof(r)/sizeof(struct bd_rebinding));
    }
}

- (void)launchDidFinished {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSMutableArray<NSString *> *whiteNameArray = [[NSMutableArray alloc] init];
        for (const std::string &whiteName : *HMDQosMockerConfigForCurrentLaunch::whiteListQueue) {
            NSString *whiteString = [NSString stringWithCString:whiteName.c_str() encoding:NSUTF8StringEncoding];
            [whiteNameArray addObject:whiteString];
        }
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[LaunchOptimizer] HMDThreadQoSMocker White List Used: %@", whiteNameArray);
    });
}

@end
