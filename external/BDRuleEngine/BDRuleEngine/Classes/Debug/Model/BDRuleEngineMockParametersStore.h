//
//  BDRuleEngineMockParametersStore.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineMockParametersStore : NSObject

+ (BDRuleEngineMockParametersStore *)sharedStore;

+ (BOOL)enableMock;

+ (void)setEnableMock:(BOOL)enable;

- (void)saveMockValue:(id)value
               forKey:(NSString *)key;


- (id)mockValueForKey:(NSString *)key;

- (void)resetMock;

@end

NS_ASSUME_NONNULL_END
