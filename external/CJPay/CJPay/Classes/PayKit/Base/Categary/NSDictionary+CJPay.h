//
//  NSDictionary+CJPay.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary(CJPay)

- (id)cj_objectForKey:(NSString *)key;
- (id)cj_objectForKey:(NSString *)key defaultObj:(nullable id)defaultObj;
- (int)cj_intValueForKey:(NSString *)key;
- (NSInteger)cj_integerValueForKey:(NSString *)key;
- (float)cj_floatValueForKey:(NSString *)key;
- (double)cj_doubleValueForKey:(NSString *)key;
- (BOOL)cj_boolValueForKey:(NSString *)key;

- (NSString *)cj_stringValueForKey:(NSString *)key defaultValue:(nullable NSString *)defaultValue;
- (NSString *)cj_stringValueForKey:(NSString *)key;

- (NSArray *)cj_arrayValueForKey:(NSString *)key;
- (NSDictionary *)cj_dictionaryValueForKey:(NSString *)key;
- (NSData *)cj_dataValueForKey:(NSString *)key;

- (int)cj_intValueForKey:(NSString *)key defaultValue:(int)defaultValue;
- (NSDictionary *)cj_mergeDictionary:(NSDictionary *)toMergeDic;

- (nullable NSString *)cj_toStr;

@end

NS_ASSUME_NONNULL_END
