//
//  BDPowerLogNetCollector.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/12.
//

#import <Foundation/Foundation.h>
#import "BDPowerLogNetEvent.h"
#import "BDPowerLogNetMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogNetCollector : NSObject

@property (nonatomic,assign) BOOL enable;

@property (nonatomic,assign) BOOL enableURLSessionMetrics;

- (NSDictionary *_Nullable)collect;

- (BDPowerLogNetMetrics *)currentNetMetrics;

@end

NS_ASSUME_NONNULL_END
