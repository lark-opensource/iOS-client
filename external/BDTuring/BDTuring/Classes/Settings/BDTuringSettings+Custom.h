//
//  BDTuringSettings+Custom.h
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuringSettings.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDTuringSettings (Custom)

- (void)reloadCustomSettings;

+ (void)registerCustomSettingBlock:(BDTuringCustomSettingBlock)block forKey:(NSString *)key;
+ (void)unregisterCustomSettingBlockForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
