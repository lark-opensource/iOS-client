//
//  BDStrategyUpdateProtocol.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDStrategyUpdateProtocol <NSObject>

- (void)preprocessStrategy:(nonnull NSDictionary *)strategy;

@end

NS_ASSUME_NONNULL_END
