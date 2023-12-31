//
//  NSDictionary+BDRESafe.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (BDRESafe)

- (NSString *)bdre_stringForKey:(id<NSCopying>)key;

- (NSNumber *)bdre_numberForKey:(id<NSCopying>)key;

- (BOOL)bdre_boolForKey:(id<NSCopying>)key;

- (NSDictionary *)bdre_dictForKey:(id<NSCopying>)key;

- (NSArray *)bdre_arrayForKey:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
