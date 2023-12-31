//
//  BDLynxCustomErrorMonitor.h
//  IESWebViewMonitor
//
//  report lynx js error when frontend use jsb to send an error to native
//
//  Created by Paklun Cheng on 2020/9/23.
//

#import <Foundation/Foundation.h>
#import "BDHybridBaseMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxView;
@interface BDLynxCustomErrorMonitor : BDHybridBaseMonitor
@property (nonatomic, class, assign) BOOL customErrorEnable;
+ (BOOL)customErrorEnable;
+ (void)lynxView:(LynxView *)view didRecieveError:(NSError *)error;
@end

NS_ASSUME_NONNULL_END
