//
//  TTVideoEngineReportHelper.h
//  TTVideoEngine
//
//  Created by haocheng on 2021/1/11.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineEventManager.h"
#ifndef __TTVIDEOENGINE__REPORT_HELPER
#define __TTVIDEOENGINE__REPORT_HELPER

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineReportHelper : NSObject
@property (nonatomic, assign) BOOL enableAutoReportLog;

+ (instancetype)sharedManager;
- (void)autoReportEventlogIfNeededV1:(TTVideoEngineEventManager *)eventManager;
- (void)autoReportEventlogIfNeededV1WithParams:(NSDictionary *)params;
- (void)autoReportEventlogIfNeededV2WithEventName:(NSString *)eventName
                                           params:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END

#endif
