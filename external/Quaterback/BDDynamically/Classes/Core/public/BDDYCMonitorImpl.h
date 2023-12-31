//
//  BDDYCMonitor.h
//  BDDynamically
//
//  Created by hopo on 2019/1/31.
//

#import <Foundation/Foundation.h>
#import "BDDYCMonitor.h"


#if BDAweme
__attribute__((objc_runtime_name("AWECFCougar")))
#elif BDNews
__attribute__((objc_runtime_name("TTDWeed")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDBigMonkey")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDBabyBokchoy")))
#endif
@interface BDDYCMonitorImpl : NSObject<BDBDMonitorClass>

+ (void)trackData:(NSDictionary *)data
       logTypeStr:(NSString *)logType;

+ (void)trackData:(NSDictionary *)data;

@end
