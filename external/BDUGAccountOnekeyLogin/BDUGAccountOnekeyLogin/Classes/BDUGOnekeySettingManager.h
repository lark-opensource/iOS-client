//
//  BDUGSettingManager.h
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDUGOnekeySettingManager : NSObject

+ (instancetype)sharedInstance;

- (void)saveSettings:(NSDictionary *)settings;

- (NSDictionary *)currentSettings;

/// 是否使用iOS13API
- (BOOL)useNewAPIGetCarrier;

@end


@interface NSDictionary (BDUGAccountHelper)

- (NSString *)bdugAccount_stringForKey:(NSObject<NSCopying> *)key;

- (NSDictionary *)bdugAccount_dictionaryForKey:(NSObject<NSCopying> *)key;

- (BOOL)bdugAccount_boolForKey:(NSObject<NSCopying> *)key;

- (BOOL)bdugAccount_boolForKey:(NSObject<NSCopying> *)key defaultValue:(BOOL)defaultValue;

- (NSInteger)bdugAccount_integerForKey:(NSObject<NSCopying> *)key defaultValue:(NSInteger)defaultValue;
@end

NS_ASSUME_NONNULL_END
