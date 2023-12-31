//
//  BDRuleUnitExecutor.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/26.
//

#import <Foundation/Foundation.h>
#import "BDREExprEnv.h"

NS_ASSUME_NONNULL_BEGIN

@class BDRuleParameterFetcher;

@interface BDRuleUnitExecutor : NSObject

- (instancetype)initWithCel:(NSString *)cel
                   commands:(NSArray *)commands
                        env:(id<BDREExprEnv>)env
                       uuid:(nonnull NSString *)uuid;

- (BOOL)evaluate:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
