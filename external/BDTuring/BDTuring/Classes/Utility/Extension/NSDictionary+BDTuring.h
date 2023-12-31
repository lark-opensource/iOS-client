//
//  NSDictionary+BDTuring.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (BDTuring)

- (double)turing_doubleValueForKey:(NSString *)key;
- (double)turing_doubleValueForKey:(NSString *)key defaultValue:(double)value;
- (long long)turing_longLongValueForKey:(NSString *)key defaultValue:(long long)defaultValue;
- (BOOL)turing_boolValueForKey:(NSString *)key;
- (NSInteger)turing_integerValueForKey:(NSString *)key;

- (nullable NSString *)turing_stringValueForKey:(NSString *)key;
- (nullable NSDictionary *)turing_dictionaryValueForKey:(NSString *)key;
- (nullable NSMutableDictionary *)turing_mutableDictionaryValueForKey:(NSString *)key;
- (nullable NSArray *)turing_arrayValueForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
