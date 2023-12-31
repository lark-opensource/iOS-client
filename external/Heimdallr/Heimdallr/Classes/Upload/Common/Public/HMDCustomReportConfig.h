//
//  HMDReportConfig.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/7/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, HMDCustomReportMode) {
    HMDCustomReportModeSizeLimit = 1,   // 定义定量上报模式
    HMDCustomReportModeActivelyTrigger  // 业务主动触发上报模式
};

NS_ASSUME_NONNULL_BEGIN

@interface HMDCustomReportConfig : NSObject

/// 自定义上报模式
@property (atomic, assign, readonly) HMDCustomReportMode customReportMode;

/// 上报大小限制，单位为byte;
/// 取值范围限制在 100B ~ 2M，超过范围取临近边界值
/// 仅在sizelimited模式生效（暂时）
/// sizeLimited模式下，按照thresholdSize限制上报size，不设置默认为2kb;
/// ActivelyTrigger模式下，设置该值，按照thresholdSize限制上报size；不设置thresholdSize按照最大上报日志数200条作为限制（同常规上报模式）；
@property (atomic, assign) NSInteger thresholdSize;

///上报间隔，单位为second；
///取值范围限制在 5s ~ 10min，超过范围取临近边界值
///sizeLimited模式下，按照该interval执行上报，不设置默认5s；
///ActivelyTrigger模式下，用于检验手动触发上报频次，不设置默认使用远端配置；
@property (atomic, assign) NSInteger uploadInterval;

- (instancetype _Nonnull)initConfigWithMode:(HMDCustomReportMode)mode;
- (id _Nullable)init __attribute__((unavailable("please use initConfigWithMode: method")));
+ (instancetype _Nullable)new __attribute__((unavailable("please use initConfigWithMode: method")));

@end

NS_ASSUME_NONNULL_END

