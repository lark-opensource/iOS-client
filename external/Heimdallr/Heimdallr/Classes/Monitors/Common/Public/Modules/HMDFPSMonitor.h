//
//  HMDFPSMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"
#import "HMDMonitorCallbackObject.h"
#import "HMDMonitorCustomSwitch.h"

extern NSString * _Nonnull const kHMDModuleFPSMonitor;//FPS监控

@interface HMDFPSMonitorConfig : HMDMonitorConfig

@end


@interface HMDFPSMonitor : HMDMonitor <HMDMonitorCustomSwitch>

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

/// 用户自定义 fps 记录 写入
/// @param fpsValue  fps 值
/// @param scene 记录的场景, 为了与 APP 本身的场景区分开, 建议业务方在 scene 的命名上增加自己的标志
/// @param extralValue  额外的信息, key 是自定义的指标名称, value 是指标名字对应的值
- (void)addFPSRecordWithFPSValue:(HMDMonitorRecordValue)fpsValue
                           scene:(NSString * _Nonnull)scene
                     isScrolling:(BOOL)isScrolling
                     extralValue:(NSDictionary <NSString *, NSNumber *> * _Nullable)extralValue;

- (void)enterFluencyCustomSceneWithUniq:(NSString *_Nonnull)scene;
- (void)leaveFluencyCustomSceneWithUniq:(NSString *_Nonnull)scene;

- (void)addFPSMonitorCallback:(HMDMonitorCallback _Nonnull)callback;
- (void)removeFPSMoitorCallback:(HMDMonitorCallback _Nonnull)callback;


/// the method will return a object. if remove the callback from HMDFPSMonitor, please use "removeFPSMonitorCallbackObject:" that parameter is the object returned from this method
/// @param callback get record call back
- (HMDMonitorCallbackObject * _Nullable)addFPSMonitorCallbackObject:(HMDMonitorCallback _Nonnull)callback;

/// remove added callback, use HMDMonitorCallbackObject
/// @param callbackObject the callback info object (HMDMonitorCallbackObject). returned by calling "addFPSMonitorCallbackObject:"
- (void)removeFPSMonitorCallbackObject:(HMDMonitorCallbackObject * _Nullable)callbackObject;

@end
