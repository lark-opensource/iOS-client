//
//  HMDHeaderLog.h
//  Heimdallr
//
//  Created by 谢俊逸 on 12/3/2018.
//

#import <Foundation/Foundation.h>
#import "HMDLog.h"

#ifdef __cplusplus
extern "C" {
#endif
void hmd_setup_log_header(void); // 初始化header数据
char * _Nullable hmd_log_header(HMDLogType logType); // 获取堆栈header，必须先调用hmd_setup_log_header完成初始化
#ifdef __cplusplus
}  // extern "C"
#endif

@interface HMDHeaderLog : NSObject
+ (NSString * _Nonnull)hmdHeaderLogString:(HMDLogType)logType;
@end
