//
//  ACCMonitorToolProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yebw on 2020/4/8.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS (NSInteger, ACCMonitorToolOptions) {
    ACCMonitorToolOptionModelAlert = 1 << 0,
    ACCMonitorToolOptionCaptureScreen = 1 << 1,
    ACCMonitorToolOptionUploadAlog = 1 << 2,
    ACCMonitorToolOptionReportToQiaoFu = 1 << 3,
    ACCMonitorToolOptionReportOnline = 1 << 4, // discard in debug mode
};

@protocol ACCMonitorToolProtocol <NSObject>

/**
  @discussion extra will not report to kibana with option ACCMonitorToolOptionReportOnline due to kibana's parameter white list, using error to report extra to kibana
 */
+ (void)showWithTitle:(NSString *)title
                error:(nullable NSError *)error
                extra:(nullable NSDictionary *)extra
                owner:(NSString *)owner
              options:(ACCMonitorToolOptions)options;

/**
 message will be aggregated and consumed when publish finished
 */
+ (void)appendMsgWithTitle:(NSString *)title
                     error:(nullable NSError *)error
                     extra:(nullable NSDictionary *)extra
                     owner:(NSString *)owner
                   options:(ACCMonitorToolOptions)options;

@end

FOUNDATION_STATIC_INLINE Class<ACCMonitorToolProtocol> ACCMonitorTool() {
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCMonitorToolProtocol)] class];
}

NS_ASSUME_NONNULL_END



