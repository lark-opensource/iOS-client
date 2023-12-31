//
//  BDUGOnekeyLoginTracker.h
//  Pods
//
//  Created by xunianqiang on 2020/6/17.
//

#import <Foundation/Foundation.h>
#import "BDUGAccountOneKeyDef.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDUGOnekeyLoginTracker : NSObject

+ (NSString *)trackNetworkTypeOfService:(BDUGAccountNetworkType)networkType;

+ (NSString *)trackServiceOfService:(NSString *)service;

+ (void)trackerEvent:(NSString *)event params:(NSDictionary *_Nullable)params;

@end

NS_ASSUME_NONNULL_END
