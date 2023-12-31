//
//  BDREGraphFootPrint.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import <Foundation/Foundation.h>

#import "BDRENodeFootPrint.h"

NS_ASSUME_NONNULL_BEGIN

@class BDREStrategyGraphNode;

@interface BDREGraphFootPrint : NSObject

@property (nonatomic, assign) BOOL isFirstTravelFinished;
@property (nonatomic, assign, readonly) NSUInteger minIndex;
@property (nonatomic, assign, readonly) BOOL needBreak;

- (instancetype)initWithParams:(NSDictionary *)params needBreak:(BOOL)needBreak;

- (void)addHitStrategy:(BDREStrategyGraphNode *)strategyNode;
- (BDRENodeFootPrint *)nodeFootPrintWithGraphNodeID:(NSString *)identifier;

- (id)paramValueForName:(NSString *)name isRegistered:(BOOL)isRegistered;

- (NSArray<NSString *> *)hitStrategyNames;

- (void)updateMinIndex:(NSUInteger)index;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
