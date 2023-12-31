//
//  BDREExprCacheManager.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by bytedance on 2021/12/17.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREExprCacheManager : NSObject

+ (BDREExprCacheManager *)sharedManager;

- (void)addCache:(NSArray<BDRECommand *> *)commandStack forExpr:(NSString *)expr;

- (NSArray<BDRECommand *> *)findCacheForExpr:(NSString *)expr;

@end

NS_ASSUME_NONNULL_END
