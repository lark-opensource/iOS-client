//
//  ACCConfigProtocol.h
//  CreativeKit-Pods-Aweme
//
//  Created by yangying on 2021/3/9.
//

#ifndef ACCConfigProtocol_h
#define ACCConfigProtocol_h

@protocol ACCConfigGetterProtocol <NSObject>

- (BOOL)boolValueForKeyPath:(NSString *)keyPath defaultValue:(BOOL)defaultValue;

- (double)doubleValueForKeyPath:(NSString *)keyPath defaultValue:(double)defaultValue;

- (NSInteger)intValueForKeyPath:(NSString *)keyPath defaultValue:(NSInteger)defaultValue;

- (nullable NSString *)stringForKeyPath:(NSString *)keyPath defaultValue:(nullable NSString *)defaultValue;

- (nullable NSArray *)arrayForKeyPath:(NSString *)keyPath defaultValue:(nullable NSArray *)defaultValue;

- (nullable NSDictionary *)dictionaryForKeyPath:(NSString *)keyPath defaultValue:(nullable NSDictionary *)defaultValue;

- (nullable id)objectForKeyPath:(NSString *)keyPath defaultValue:(nullable id)defaultValue;


@end

@protocol ACCConfigSetterProtocol <NSObject>

- (void)setBoolValue:(BOOL)boolValue forKey:(NSString *)key;

- (void)setDoubleValue:(double)doubleValue forKey:(NSString *)key;

- (void)setIntValue:(NSInteger)intValue forKey:(NSString *)key;

- (void)setString:(NSString *)string forKey:(NSString *)key;

- (void)setArray:(NSArray *)array forKey:(NSString *)key;

- (void)setDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;

- (void)setObject:(id)object forKey:(NSString *)key;

@end

#endif /* ACCConfigProtocol_h */
