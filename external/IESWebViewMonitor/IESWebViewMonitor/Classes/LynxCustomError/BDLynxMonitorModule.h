//
//  BDLynxMonitorModule.h
//  IESWebViewMonitor
//
//  create a module to register jsb into lynx
//  注册该module时，要传入ContainerID，可参考LynxView+Monitor中的bdlm_initWithBuilderBlock方法
//
//  Created by Paklun Cheng on 2020/9/24.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxModule.h>
NS_ASSUME_NONNULL_BEGIN

@interface BDLynxMonitorModule : NSObject<LynxModule>

@end

NS_ASSUME_NONNULL_END
