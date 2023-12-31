//
//  BDPLLogMonitor.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/24.
//

#import <Foundation/Foundation.h>
#import "BDPLLogMonitorConfig.h"

NS_ASSUME_NONNULL_BEGIN
@class BDPLLogMonitor;
@protocol BDPLLogMonitorDelegate <NSObject>

- (void)onHighFrequentEvents:(BDPLLogMonitor *)monitor
                   deltaTime:(long long)deltaTime
                       count:(long long)count
                 counterDict:(NSDictionary *)counterDict;

@end

@interface BDPLLogMonitor : NSObject

@property (nonatomic, copy, readonly)NSString *type;

@property (nonatomic, copy, readonly)BDPLLogMonitorConfig *config;

@property (nonatomic, weak) id<BDPLLogMonitorDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL enable;

@property (nonatomic, assign, readonly) long long totalLogCount;

+ (instancetype)monitorWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config;

- (instancetype)initWithType:(NSString *)type config:(BDPLLogMonitorConfig *)config;

- (void)start;

- (void)stop;

- (void)addLog:(NSString *)category;

- (NSDictionary *)totalCounterDict;

@end

NS_ASSUME_NONNULL_END
