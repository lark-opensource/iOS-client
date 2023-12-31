//
//  IESLynxMonitor.h
//  IESLiveKit
//
//  Created by 小阿凉 on 2020/2/26.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxViewClient.h>
#import "LynxView+Monitor.h"

NS_ASSUME_NONNULL_BEGIN

@class IESLynxMonitorConfig;
@class IESLiveDefaultSettingModel;

@interface IESLynxMonitor : NSObject <LynxViewLifecycle>

@property (nonatomic, readonly) IESLynxMonitorConfig *config;
@property (nonatomic, readonly) NSMutableDictionary *classSettingMap;

+ (void)startMonitor;
+ (void)startMonitorWithSettingModel:(IESLiveDefaultSettingModel *)settingModel;

+ (instancetype)sharedMonitor;

- (instancetype)initWithConfig:(IESLynxMonitorConfig *)config;

- (void)trackStart:(LynxView *)view;

// Lynx JS上报的Lynx监控(旧)
- (void)lynxMonitor:(NSDictionary *)data;
// Lynx JS上报的Lynx监控(新)
- (void)lynxMonitor:(NSDictionary *)data lynxView:(LynxView *)view;
// Lynx JS 抛出异常（旧）
- (void)sendJSError:(NSString *)jsError;

// 客户端上报的 Lynx 自定义监控
// 旧接口，只有非单例monitor使用！！！！
- (void)trackLynxService:(NSString *)service status:(NSInteger)status duration:(CFTimeInterval)duration extra:(NSDictionary *)extraInfo;
// 新接口，单例monitor使用
- (void)trackLynxService:(NSString *)service status:(NSInteger)status duration:(CFTimeInterval)duration extra:(NSDictionary *)extraInfo config:(IESLynxMonitorConfig *)config lynxView:(nullable LynxView *)view;

@end

NS_ASSUME_NONNULL_END
