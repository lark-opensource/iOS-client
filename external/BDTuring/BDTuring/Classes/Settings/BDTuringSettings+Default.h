//
//  BDTuringSettings+Default.h
//  BDTuring
//
//  Created by bob on 2020/4/9.
//

#import "BDTuringSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringSettings (Default)

- (void)reloadDefaultSettings;
+ (void)registerDefaultSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key;
+ (void)unregisterDefaultSettingBlockForKey:(NSString *)key;
+ (void)registerAppDefaultSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key;
+ (void)unregisterAppDefaultSettingBlockForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
