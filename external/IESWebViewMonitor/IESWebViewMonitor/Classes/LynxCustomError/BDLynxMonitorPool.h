//
//  BDLynxMonitorPool.h
//  IESWebViewMonitor
//
//  store lynxView according to their container id
//
//  Created by Paklun Cheng on 2020/9/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class LynxView;
@interface BDLynxMonitorPool : NSObject

+ (LynxView * _Nullable)lynxViewForContainerID:(NSString *)containerID;

+ (void)setLynxView:(LynxView * _Nullable)view forContainerID:(NSString *)containerID;

+ (void)removeforContainerID:(NSString *)containerID;
@end

NS_ASSUME_NONNULL_END
