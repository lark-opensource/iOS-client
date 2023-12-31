//
//  BDRuleParameterBuilderModel+Mock.m
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/21.
//

#import "BDRuleParameterRegistry.h"
#import "BDRuleParameterBuilderModel+Mock.h"
#import "BDRuleEngineMockParametersStore.h"
#import <objc/runtime.h>

@implementation BDRuleParameterBuilderModel (Mock)

+ (void)prepareForMock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod(self, @selector(builder));
        Method myMethod = class_getInstanceMethod(self, @selector(mock_builder));
        method_exchangeImplementations(originalMethod, myMethod);
    });
}


- (BDRuleParameterBuildBlock)mock_builder
{
    if ([BDRuleEngineMockParametersStore enableMock]) {
        id value = [[BDRuleEngineMockParametersStore sharedStore] mockValueForKey:self.key];
        if (value) {
            return ^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
                return value;
            };
        }
    }
    return [self mock_builder];
}

@end
