//
//  ACCAdvancedRecordSettingConfigManager.h
//  Indexer
//
//  Created by Shichen Peng on 2021/11/9.
//

#import <Foundation/Foundation.h>

#import <CameraClient/ACCAdvancedRecordSettingItem.h>

@interface ACCAdvancedRecordSettingConfigManager : NSObject

- (NSUInteger)getIndexSettingsOf:(ACCAdvancedRecordSettingType)type;
- (BOOL)getBoolSettingsOf:(ACCAdvancedRecordSettingType)type;

+ (void)saveSettingIntegerValue:(NSUInteger)value withType:(ACCAdvancedRecordSettingType)type;
+ (void)saveSettingBoolValue:(NSUInteger)value withType:(ACCAdvancedRecordSettingType)type;
+ (BOOL)isSwitchType:(ACCAdvancedRecordSettingType)type;
+ (NSString *)typeToKey:(ACCAdvancedRecordSettingType)type;
+ (BOOL)isLocalChanged:(ACCAdvancedRecordSettingType)type;

@end
