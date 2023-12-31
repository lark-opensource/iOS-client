//
//  LarkPowerOptimizeConfig.h
//  LarkMonitor-LarkMonitorAuto
//
//  Created by ByteDance on 2023/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LarkPowerOptimizeConfig : NSObject

@property (nonatomic,assign,class,readonly) BOOL enableOptimizeCALayerCrash;

+ (void)updateConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
