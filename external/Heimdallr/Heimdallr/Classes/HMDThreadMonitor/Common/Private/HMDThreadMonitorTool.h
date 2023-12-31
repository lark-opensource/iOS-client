//
//  HMDThreadMonitorTool.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/10/9.
//

#import <Foundation/Foundation.h>
#import "HMDThreadMonitorInfo.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDTHREADCOUNTEXCEPTION;
extern NSString *const kHMDSPECIALTHREADCOUNTEXCEPTION;

#ifdef __cplusplus
extern "C" {
#endif

dispatch_queue_t hmd_get_thread_monitor_queue(void);
void dispatch_on_thread_monitor_queue(dispatch_block_t block);

#ifdef __cplusplus
}
#endif

@interface HMDThreadMonitorTool : NSObject

+ (nonnull instancetype)shared;

+ (nullable NSString *)stringFromDictionary:(NSDictionary *)threadDic;

+ (NSString *)getSpecialThreadLevel:(NSUInteger)count;

- (void)updateWithBussinessList:(NSArray *)list;

- (nullable HMDThreadMonitorInfo *)getAllThreadInfo;

+ (NSString *)getInAppTimeLevel:(NSTimeInterval)inAppTime;

+ (NSString *)preProcessThreadName:(const char *)cThreadName;

@end

NS_ASSUME_NONNULL_END
