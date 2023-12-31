//
//  BDRLSceneListViewModel.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRLSceneListViewModel.h"
#import "BDRLStrategyListViewModel.h"

@interface BDRLSceneListViewModel ()

@property (nonatomic, strong) NSArray<NSString *> *titles;
@property (nonatomic, strong) NSDictionary *json;
@property (nonatomic, strong) NSArray<NSDictionary *> *jsons;

@end

@implementation BDRLSceneListViewModel

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
    viewModel = [[BDRLStrategyListViewModel alloc] initWithJson:self.jsons[indexPath.section]];
    return viewModel;
}

- (instancetype)initWithJson:(NSDictionary *)json
{
    if (self = [super init]) {
        self.json = json;
        [self __setup];
    }
    return self;
}

- (void)__setup
{
    NSMutableArray *mutableJsons = [NSMutableArray array];

    _titles = [[self.json.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]copy];
    for (NSString *key in _titles) {
        [mutableJsons addObject:self.json[key]];
    }

    _jsons = [mutableJsons copy];
}
@end
