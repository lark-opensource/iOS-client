//
//  BDRuleEngineDelegate.h
//  Pods
//
//  Created by Chengmin Zhang on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDRuleEngineReportDataSource <NSObject>

- (NSDictionary *)metric;
- (NSDictionary *)category;
- (NSDictionary *)extra;

@end

typedef id<BDRuleEngineReportDataSource> _Nonnull (^BDRuleEngineReportDataBlock)(void);

@protocol BDRuleEngineDelegate <NSObject>

- (void)report:(NSString *)event
          tags:(NSDictionary *)tags
         block:(BDRuleEngineReportDataBlock)block;

- (nullable NSDictionary *)ruleEngineConfig;

@end

NS_ASSUME_NONNULL_END
