//
//  ACCLangRegionLisener.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/8/24.
//

#import "ACCLangRegionLisener.h"
#import "ACCI18NConfigProtocol.h"
#import <CreativeKit/ACCMacros.h>
#import <KVOController/NSObject+FBKVOController.h>

#define ACC_I18NCONFIG_OBJ_LANG_KEY @"currentLanguage"
#define ACC_I18NCONFIG_OBJ_REGION_KEY @"currentRegion"


@implementation ACCLangRegionLisener

+ (instancetype)shareInstance {
    static ACCLangRegionLisener* lisener = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lisener = [[ACCLangRegionLisener alloc] init];
    });
    return lisener;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.KVOController observe:ACCI18NConfig() keyPath:ACC_I18NCONFIG_OBJ_LANG_KEY options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            acc_dispatch_main_async_safe(^{
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACC_LANGUAGE_CHANGE_NOTIFICATION object:nil];
            });
        }];
        [self.KVOController observe:ACCI18NConfig() keyPath:ACC_I18NCONFIG_OBJ_REGION_KEY options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            acc_dispatch_main_async_safe(^{
                 [[NSNotificationCenter defaultCenter] postNotificationName:ACC_REGION_CHANGE_NOTIFICATION object:nil];
            });
         }];
    }
    return self;
}

- (NSString *)languageChangedNotification {
    return @"ACC_LANGUAGE_CHANGE_NOTIFICATION";
}

- (NSString *)regionChangedNotification {
    return @"ACC_REGION_CHANGE_NOTIFICATION";
}

@end
