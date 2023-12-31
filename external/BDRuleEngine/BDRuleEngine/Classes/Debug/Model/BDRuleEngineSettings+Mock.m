//
//  BDRuleEngineSettings+Mock.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import "BDRuleEngineSettings+Mock.h"
#import "BDRuleEngineMockConfigStore.h"
#import <objc/runtime.h>

@implementation BDRuleEngineSettings (Mock)

+ (void)prepareForMock
{
    Method originalMethod = class_getClassMethod(self, @selector(config));
    Method myMethod = class_getClassMethod(self, @selector(mock_config));
    method_exchangeImplementations(originalMethod, myMethod);
}

+ (NSDictionary *)mock_config
{
    if ([BDRuleEngineMockConfigStore enableMock]) {
        NSDictionary *config = [[BDRuleEngineMockConfigStore sharedStore] mockConfig];
        if (config) {
            return config;
        }
    }
    return [self mock_config];
}

@end
