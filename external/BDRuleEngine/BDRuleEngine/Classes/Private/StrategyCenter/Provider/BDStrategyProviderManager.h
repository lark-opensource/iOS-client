//
//  BDStrategyProviderManager.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

@protocol BDStrategyProvider;
@protocol BDStrategyUpdateProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyProviderManager : NSObject

@property (nonatomic, weak) id<BDStrategyUpdateProtocol> delegate;

- (void)registerStrategyProvider:(id<BDStrategyProvider>)provider;

- (nonnull NSDictionary *)fetchStrategy;

@end

NS_ASSUME_NONNULL_END
