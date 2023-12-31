//
//  BDStrategyProvider.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDStrategyProvider <NSObject>

@required
- (NSInteger)priority;

- (NSDictionary *)strategies;

@optional
// Debug 工具可能会用到，用来展示策略 Provider 名字
- (NSString *)displayName;

@end

NS_ASSUME_NONNULL_END
