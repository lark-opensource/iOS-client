//
//  BDREGraphFootPrint.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/17.
//

#import "BDREGraphFootPrint.h"
#import "BDREStrategyGraphNode.h"
#import "BDRuleParameterRegistry.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDREGraphFootPrint ()

@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, assign) NSUInteger minIndex;
@property (nonatomic, assign) BOOL needBreak;

@property (nonatomic, strong) NSMutableArray<BDREStrategyGraphNode *> *hitStrategyNodes;
@property (nonatomic, strong) NSMutableDictionary <NSString *, BDRENodeFootPrint *> *footPrintMap;

@end

@implementation BDREGraphFootPrint

- (instancetype)initWithParams:(NSDictionary *)params needBreak:(BOOL)needBreak
{
    if (self = [super init]) {
        _needBreak = needBreak;
        _params = params;
        _isFirstTravelFinished = NO;
        _minIndex = NSUIntegerMax;
        _hitStrategyNodes = [NSMutableArray array];
        _footPrintMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addHitStrategy:(BDREStrategyGraphNode *)strategyNode
{
    if (!strategyNode) return;
    if ([self.hitStrategyNodes containsObject:strategyNode]) return;
    [self.hitStrategyNodes btd_addObject:strategyNode];
    [self.hitStrategyNodes sortUsingComparator:^NSComparisonResult(BDREStrategyGraphNode *  _Nonnull obj1, BDREStrategyGraphNode *  _Nonnull obj2) {
        if (obj1.minIndex == obj2.minIndex) return NSOrderedSame;
        else if (obj1.minIndex < obj2.minIndex) return NSOrderedAscending;
        else return NSOrderedDescending;
    }];
}

- (BDRENodeFootPrint *)nodeFootPrintWithGraphNodeID:(NSString *)identifier
{
    BDRENodeFootPrint *footPrint = [self.footPrintMap btd_objectForKey:identifier default:nil];
    if (footPrint) return footPrint;
    footPrint = [[BDRENodeFootPrint alloc] init];
    [self.footPrintMap btd_setObject:footPrint forKey:identifier];
    return footPrint;
}

- (id)paramValueForName:(NSString *)name isRegistered:(BOOL)isRegistered
{
    if (!isRegistered) {
        return [self.params btd_objectForKey:name default:nil];
    }
    BDRuleParameterBuilderModel *builderModel = [BDRuleParameterRegistry builderForKey:name];
    if (!builderModel || !builderModel.builder) return nil;
    return builderModel.builder(nil);
}

- (void)updateMinIndex:(NSUInteger)index
{
    _minIndex = MIN(_minIndex, index);
}

- (NSArray<NSString *> *)hitStrategyNames
{
    if (self.needBreak) {
        if (self.hitStrategyNodes.count) {
            NSString *strategyName = [self.hitStrategyNodes btd_objectAtIndex:0].strategyName;
            return strategyName ? @[strategyName] : @[];
        }
    } else {
        NSMutableArray *strategyNames = [NSMutableArray array];
        for (BDREStrategyGraphNode *node in self.hitStrategyNodes) {
            [strategyNames btd_addObject:node.strategyName];
        }
        return strategyNames;
    }
    return @[];
}

@end
