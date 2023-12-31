//
//  HMDThreadMonitorInfo.h
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/7.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadMonitorInfo : NSObject

@property (nonatomic, strong) NSMutableDictionary *allThreadDic;
@property (nonatomic, copy) NSString *mostThread;
@property (nonatomic, assign) NSUInteger mostThreadCount;
@property (nonatomic, assign) thread_t mostThreadID;
@property (nonatomic, assign) NSUInteger allThreadCount;

@end

NS_ASSUME_NONNULL_END
