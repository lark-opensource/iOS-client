//
//  TTVideoEngine+Tracker.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/1/11.
//

#import "TTVideoEngine.h"
#import "TTVideoEngineEventManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineReporterProtocol <NSObject>

@property (nonatomic, assign) BOOL enableAutoReportLog;

+ (instancetype)sharedManager;
- (void)autoReportEventlogIfNeededV1:(TTVideoEngineEventManager *)eventManager;
- (void)autoReportEventlogIfNeededV1WithParams:(NSDictionary *)params;
- (void)autoReportEventlogIfNeededV2WithEventName:(NSString *)eventName
                                           params:(NSDictionary *)params;

@end

@interface TTVideoEngine (Tracker)

+ (void)setAutoTraceReportOpen:(BOOL)isOpen;

+ (Class<TTVideoEngineReporterProtocol>)reportHelperClass;

@end

NS_ASSUME_NONNULL_END
