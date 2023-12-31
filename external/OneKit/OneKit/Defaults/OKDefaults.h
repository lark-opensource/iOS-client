//
//  OKDefaults.h
//  OneKit
//
//  Created by bob on 2020/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKDefaults : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;

+ (NSString *)defaultPathForIdentifier:(NSString *)identifier; /// 默认路径 Document/onekit_defaults/identifier

- (instancetype)initWithIdentifier:(NSString *)identifier path:(NSString *)path;

/// path = Document/onekit_defaults/identifier
/// return nil if identifier is "" or nil
+ (nullable instancetype)defaultsWithIdentifier:(NSString *)identifier;

- (BOOL)boolValueForKey:(NSString *)key;
- (double)doubleValueForKey:(NSString *)key;
- (NSInteger)integerValueForKey:(NSString *)key;
- (long long)longlongValueForKey:(NSString *)key;
- (nullable NSString *)stringValueForKey:(NSString *)key;
- (nullable NSDictionary *)dictionaryValueForKey:(NSString *)key;
- (nullable NSArray *)arrayValueForKey:(NSString *)key;

- (void)setDefaultValue:(nullable id)value forKey:(NSString *)key;
- (nullable id)defaultValueForKey:(NSString *)key;
- (void)saveDataToFile;
- (void)clearAllData;

@end

NS_ASSUME_NONNULL_END
