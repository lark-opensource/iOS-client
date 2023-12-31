//
//  BDPAPIPluginDelegate.h
//  Timor
//
//  Created by lixiaorui on 2020/12/25.
//

#ifndef BDPAPIPluginDelegate_h
#define BDPAPIPluginDelegate_h

#import "BDPBasePluginDelegate.h"

@class OPAPIFeatureConfig;

@protocol BDPAPIPluginDelegate <BDPBasePluginDelegate>

- (nullable NSDictionary *)bdp_getAPIDispatchConfig;

- (OPAPIFeatureConfig *)bdp_getAPIDispatchConfig:(nullable NSDictionary *)config forAppType:(OPAppType)appType apiName:(NSString *)apiName;

@end


#endif /* BDPAPIPluginDelegate_h */
