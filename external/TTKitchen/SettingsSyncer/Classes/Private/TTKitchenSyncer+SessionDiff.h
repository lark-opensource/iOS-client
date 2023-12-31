//
//  TTKitchenSyncer+SessionDiff.h
//  TTKitchen-Browser-Core-SettingsSyncer-Swift
//
//  Created by Peng Zhou on 2020/7/7.
//

#import "TTKitchenSyncer.h"
#import "TTKitchenInternal.h"

extern NSString * const kTTKitchenSettingsDiffs;
extern NSString * const kTTKitchenSettingsDiffTimestamps;

@interface TTKitchenSyncer (SessionDiff)

@property (nonatomic, strong) NSTimer *accessTimeInjectTimer;

- (void)injectSettingsDiffsIfNeeded;

- (NSDictionary *)generateSessionDiffWithSettingsIfNeeded:(NSDictionary *)settings;

@end
