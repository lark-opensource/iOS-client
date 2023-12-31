//
//  HMDReportDowngrador.h
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 1/8/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
bool hmd_downgrade_performance_aid(NSString *logType, NSString *aid);
bool hmd_downgrade_performance(NSString *logType);

#ifdef __cplusplus
} // extern "C"
#endif


@interface HMDReportDowngrador : NSObject

@property (atomic, assign) BOOL enabled;

+ (instancetype)sharedInstance;

- (BOOL)needUploadWithLogType:(NSString * _Nonnull)logType serviceName:(NSString * _Nullable)serviceName aid:(NSString * _Nonnull)aid;

- (BOOL)needUploadWithLogType:(NSString * _Nonnull)logType serviceName:(NSString * _Nullable)serviceName aid:(NSString * _Nonnull)aid currentTime:(CFTimeInterval)currentTime;

- (void)updateDowngradeRule:(NSDictionary * _Nullable)info;
- (void)updateDowngradeRule:(NSDictionary * _Nullable)info forAid:(NSString *_Nullable)aid;

@end

NS_ASSUME_NONNULL_END
