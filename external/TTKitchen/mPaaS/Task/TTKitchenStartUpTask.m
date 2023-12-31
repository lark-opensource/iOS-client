//
//  BDSettingsStartUpTask.m
//  BDStartUp
//
//  Created by bob on 2020/1/16.
//

#import "TTKitchenStartUpTask.h"
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDApplicationInfo.h>

#import "TTKitchen.h"
#import "TTKitchenSyncer.h"
#import <BDUGContainer/BDUGContainer.h>
#import <BDUGSettingsInterface/BDUGSettingsInterface.h>
#import <BDGaiaExtension/GAIAEngine+BDExtension.h>

NSString * const BDStartUpSettingsDidReturnNotification = @"BDStartUpSettingsDidReturnNotification";

BDAppAddStartUpTaskFunction() {
    BDUG_BIND_CLASS_PROTOCOL([TTKitchenStartUpTask class], BDUGSettingsInterface);
    [[TTKitchenStartUpTask sharedInstance] scheduleTask];
}

@interface TTKitchenStartUpTask ()<BDUGSettingsInterface>

@end

@implementation TTKitchenStartUpTask

+ (instancetype)sharedInstance {
    static TTKitchenStartUpTask *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.group = BDStartUpTaskGroupLaunchAsync;
        self.priority = BDStartUpTaskPriorityHigh;
    }
    
    return self;
}

- (void)startWithApplication:(UIApplication *)application
                    delegate:(id<UIApplicationDelegate>)delegate
                     options:(NSDictionary *)launchOptions {
    [TTKitchenSyncer sharedInstance].synchronizeInterval = 60 * 60;
    [self synchronizeSettings];
}

- (id)objectForKeyPath:(NSString *)keyPath defaultValue:(id)defaultValue stable:(BOOL)stable {
    return [TTKitchen getDictionary:keyPath] ?: defaultValue;
}

- (void)synchronizeSettings {
    NSMutableDictionary * parameters = [NSMutableDictionary new];
    [parameters setValue:@(1) forKey:@"app"];
    
    BDApplicationInfo *info = [BDApplicationInfo sharedInstance];
    if (info.isInhouseApp) {
        [parameters setValue:@(1) forKey:@"inhouse"];
    }
    [parameters addEntriesFromDictionary:[info commonURLParameters]];
    
    [[TTKitchenSyncer sharedInstance] synchronizeSettingsWithParameters:parameters
                                                                URLHost:self.settingsHost
                                                                 header:nil
                                                               callback:^(NSError *error, NSDictionary *settings) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BDStartUpSettingsDidReturnNotification
                                                            object:nil];
        [GAIAEngine mpaas_didUpdateTTKitchen];
    }];
}

@end
