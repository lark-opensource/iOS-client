//
//  HMDUITrackerDelegate.h
//  HMDUITrackerRecreate
//
//  Created by bytedance on 2021/12/2.
//

#import <UIKit/UIKit.h>
#import "HMDUITrackableContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDUITrackerDelegate <NSObject>

- (void)hmdTrackableContext:(HMDUITrackableContext *)context
              eventWithName:(NSString *)event
                 parameters:(NSDictionary *)parameters;

- (void)hmdTrackWithName:(NSString *)name
                   event:(NSString *)event
              parameters:(NSDictionary *)parameters;

- (void)hmdSwitchToNewVCFrom:(UIViewController * _Nullable)fromVC
                          to:(UIViewController * _Nullable)toVC;

- (void)didAppearViewController:(UIViewController * _Nullable)appearVC;

- (void)didLeaveViewController:(UIViewController * _Nullable)leavingVC;

@end

NS_ASSUME_NONNULL_END
