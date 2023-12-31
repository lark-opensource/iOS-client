//
//  BDPowerLogManager+Private.h
//  Jato
//
//  Created by yuanzhangjing on 2022/7/27.
//

#import "BDPowerLogManager.h"
#import "BDPowerLogDataListener.h"
NS_ASSUME_NONNULL_BEGIN
@class BDPowerLogNetMetrics;
@interface BDPowerLogManager (Private)

+ (NSInteger)currentUserInterfaceStyle;

+ (void)queryDataFrom:(long long)fromTS to:(long long)toTS
           completion:(void(^)(NSDictionary *data))completion;

+ (BDPowerLogNetMetrics *)currentNetMetrics;

+ (void)addDataListener:(id<BDPowerLogDataListener>)listener;

@end

NS_ASSUME_NONNULL_END
