//
//  BDTuringSettings.h
//  BDTuring
//
//  Created by bob on 2020/4/8.
//

#import "BDTuringService.h"


NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDTuringSettings;

typedef void (^BDTuringCustomSettingBlock)(BDTuringSettings *settings);

@interface BDTuringSettings : BDTuringService

@property (nonatomic, assign, readonly) BOOL isUpdatingSettings;

+ (nullable instancetype)settingsForConfig:(BDTuringConfig *)config;
+ (nullable instancetype)settingsForAppID:(NSString *)appID;

- (void)loadLocalSettings;
- (void)checkAndFetchSettingsWithCompletion:(nullable dispatch_block_t)completion;

- (nullable NSString *)requestURLForPlugin:(NSString *)plugin
                                   URLType:(NSString *)URLType
                                    region:(NSString *)region;

- (nullable id)settingsForPlugin:(NSString *)plugin
                             key:(NSString *)key
                    defaultValue:(nullable id)defaultValue;

- (void)addPlugin:(NSString *)plugin
             key1:(NSString *)key1
           region:(nullable NSString *)region
            value:(nullable id)value;
- (void)addPlugin:(NSString *)plugin
             key1:(NSString *)key1
           region:(nullable NSString *)region
            value:(nullable id)value
        forceUpdate:(BOOL)forceUpdate;

- (void)cleanSettings;

@end

NS_ASSUME_NONNULL_END
