//
//  BDRuleEngineMockConfigStore.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineMockConfigStore : NSObject

+ (BDRuleEngineMockConfigStore *)sharedStore;

+ (BOOL)enableMock;

+ (void)setEnableMock:(BOOL)enable;

- (BOOL)saveMockConfigValue:(NSDictionary *)value;

- (NSDictionary *)mockConfig;

- (void)resetMockConfig;

@end

NS_ASSUME_NONNULL_END
