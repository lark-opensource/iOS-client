//
//  BDAutoTrackETService.h
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN
/*！ET埋点验证服务
 供Lark等内部业务埋点验证用。
 服务类型: BDAutoTrackLogService
 请求接口: app_log_test
 上报场景: 默认每200ms上报一次。上报间隔支持本地配置修改。
 */
@interface BDAutoTrackETService : BDAutoTrackService<BDAutoTrackLogService>
/// 单位：毫秒
@property (nonatomic) long long ETReportTimeInterval;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)sendEvent:(NSDictionary *)event key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
