//
//  BDPMemoryMonitor.h
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <Foundation/Foundation.h>

#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^actionBlock)(void);
/// 内存的监控
@interface BDPMemoryMonitor : NSObject

+ (CGFloat)currentMemoryUsageInBytes;
//系统可用内存
+ (double)avaliableMemory;


+ (void)didReceiveMemoryWarning;

+ (void)registerMemoryWarningTimerWithUniqueID:(BDPUniqueID*)uniqueID warningBlock:(actionBlock)warningBlock killBlock:(actionBlock)killBlock;

+ (void)unregisterMemoryWarningTimerWithUniqueID:(BDPUniqueID*)uniqueID;
@end

NS_ASSUME_NONNULL_END
