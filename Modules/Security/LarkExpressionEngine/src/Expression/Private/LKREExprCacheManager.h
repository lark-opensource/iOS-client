//
//  LKREExprCacheManager.h
//  LKRuleEngine-Pods-AwemeCore
//
//  Created by bytedance on 2021/12/17.
//

#import <Foundation/Foundation.h>
#import "LKRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREExprCacheManager : NSObject

+ (LKREExprCacheManager *)sharedManager;

- (void)addCache:(NSArray<LKRECommand *> *)commandStack forExpr:(NSString *)expr;

- (NSArray<LKRECommand *> *)findCacheForExpr:(NSString *)expr;

@end

NS_ASSUME_NONNULL_END
