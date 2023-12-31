//
//  BDRuleEngineLogger.h
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nonnull (^BDREDescBlock)(void);

@interface BDRuleEngineLogger : NSObject

+ (void)error:(BDREDescBlock)block;

+ (void)warn:(BDREDescBlock)block;

+ (void)info:(BDREDescBlock)block;

+ (void)debug:(BDREDescBlock)block;

@end

NS_ASSUME_NONNULL_END
