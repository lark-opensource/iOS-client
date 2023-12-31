//
//  HMDLaunchOptimizer.h
//  Heimdallr-1f4902a4
//
//  Created by xushuangqing on 2022/2/21.
//

#import "HeimdallrModule.h"
#import "HMDModuleConfig.h"


#ifdef __cplusplus
extern "C" {
#endif

dispatch_qos_class_t override_updated_qos_class_for_queue_during_launch(dispatch_queue_t queue, dispatch_qos_class_t origin_qos, dispatch_qos_class_t updated_qos);

dispatch_qos_class_t override_qos_class_for_queue_during_launch(dispatch_queue_t queue, dispatch_qos_class_t origin_qos) __attribute__((deprecated("please use override_updated_qos_class_for_queue_during_launch(dispatch_queue_t, dispatch_qos_class_t, dispatch_qos_class_t)")));

NSArray<NSString *> *hmd_launch_optmizer_mark_key_point(NSString *label);

#ifdef __cplusplus
} // extern "C"
#endif

typedef NS_ENUM(NSUInteger, HMDLaunchOptimizerFeature) {
    HMDLaunchOptimizerFeatureNone,
    HMDLaunchOptimizerFeatureThreadQoSMocker = 1 << 0,
    HMDLaunchOptimizerFeatureKeyQueueCollector = 1 << 1,
    HMDLaunchOptimizerFeatureDylibPreload = 1 << 2,
};

typedef NS_ENUM(NSUInteger, HMDQosMockerCustomSwitch) {
    HMDQosMockerCustomSwitchNone = 0, //use Slardar's performance_modules#launch_optimizer#enable_thread_qos_mocker
    HMDQosMockerCustomSwitchOpen = 1,
    HMDQosMockerCustomSwitchClose = 2,
};

@interface HMDLaunchOptimizer : HeimdallrModule

@property (atomic, assign, readonly) HMDQosMockerCustomSwitch qosMockerCustomSwitch;

+ (instancetype)sharedOptimizer;
- (void)markLaunchFinished;
- (HMDLaunchOptimizerFeature)appliedLaunchOptimizerFeature;
- (void)updateQoSMockerCustomSwitch:(HMDQosMockerCustomSwitch)qosMockerCustomSwitch;

@end

