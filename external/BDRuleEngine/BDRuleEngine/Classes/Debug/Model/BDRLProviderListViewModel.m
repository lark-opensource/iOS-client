//
//  BDRLProviderListViewModel.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRLProviderListViewModel.h"
#import "BDStrategyCenter+Debug.h"
#import "BDRLRawJsonViewModel.h"
#import "BDStrategyProvider.h"
#import "BDRLSceneListViewModel.h"
#import "BDStrategyCenterConstant.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRLProviderListViewModel ()

@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSArray<NSDictionary *> *jsons;
@property (nonatomic, strong) NSArray<NSNumber *> *types;

@end

@implementation BDRLProviderListViewModel

- (NSUInteger)count
{
    return self.titles.count;
}

- (NSString *)titleAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > [self count]) return nil;
    return self.titles[indexPath.section];
}

- (BDRLStrategyViewModel *)viewModelAtIndexPath:(NSIndexPath *)indexPath
{
    BDRLStrategyViewModel *viewModel;
    switch ([self.types[indexPath.section] integerValue]) {
        case BDRLStrategyPresentTypeRaw:
            viewModel = [[BDRLRawJsonViewModel alloc] initWithJson:self.jsons[indexPath.section]];
            break;
        case BDRLStrategyPresentTypeDetail:
            viewModel = [[BDRLSceneListViewModel alloc] initWithJson:[self.jsons[indexPath.section] btd_dictionaryValueForKey:BDStrategySetKey]];
            break;
        default:
            viewModel = [[BDRLStrategyViewModel alloc] init];
    }
    return viewModel;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self __setup];
    }
    return self;
}

- (void)__setup
{
    NSMutableArray *mutableTitles = [NSMutableArray array];
    NSMutableArray *mutableJsons = [NSMutableArray array];
    NSMutableArray *mutableTypes = [NSMutableArray array];
    for (id<BDStrategyProvider> provider in [BDStrategyCenter providers]) {
        NSString *providerName = NSStringFromClass([provider class]);
        if ([provider respondsToSelector:@selector(displayName)]) {
            providerName = [provider displayName];
        }
        [mutableTitles addObject:providerName];
        [provider strategies] ? [mutableJsons addObject:[provider strategies]] : [mutableJsons addObject:[NSDictionary dictionary]];
        [mutableTypes addObject:@(BDRLStrategyPresentTypeRaw)];
    }
    NSString *signature = [[BDStrategyCenter mergedStrategies] btd_stringValueForKey:BDStrategySignatureKey default:@""];
    NSString *finalTitle = [NSString stringWithFormat:@"Final Strategy (%@)", signature];
    [mutableTitles addObject:finalTitle];
    
    [mutableJsons addObject:[BDStrategyCenter mergedStrategies]];
    [mutableTypes addObject:@(BDRLStrategyPresentTypeDetail)];

    _titles = [mutableTitles copy];
    _jsons = [mutableJsons copy];
    _types = [mutableTypes copy];
}

@end
