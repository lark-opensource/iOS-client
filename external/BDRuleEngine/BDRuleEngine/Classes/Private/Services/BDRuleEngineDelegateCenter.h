//
//  BDRuleEngineDelegateCenter.h
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import <Foundation/Foundation.h>

#import "BDRuleEngineDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineDelegateCenter : NSObject
 
+ (BOOL)setDelegate:(id<BDRuleEngineDelegate>)delegate;

+ (id<BDRuleEngineDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
