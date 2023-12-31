//  Copyright 2023 The Lynx Authors. All rights reserved.

NS_ASSUME_NONNULL_BEGIN

@interface LynxDevtoolUtils : NSObject

+ (void)setDevtoolEnv:(BOOL)value forKey:(NSString *)key;

+ (BOOL)getDevtoolEnv:(NSString *)key withDefaultValue:(BOOL)value;

+ (void)setDevtoolEnv:(NSSet *)newGroupValues forGroup:(NSString *)groupKey;

+ (NSSet *)getDevtoolEnvWithGroupName:(NSString *)groupKey;

@end

NS_ASSUME_NONNULL_END
