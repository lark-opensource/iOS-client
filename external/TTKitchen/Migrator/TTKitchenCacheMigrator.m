//
//  TTKitchenCacheMigrator.m
//  TTKitchen
//
//  Created by bytedance on 2020/10/21.
//

#import "TTKitchenCacheMigrator.h"
#import "TTKitchenSyncer+SessionDiff.h"
#import "TTKitchenYYCacheDiskCache.h"
#import "TTKitchenMMKVDiskCache.h"
#import "TTKitchenSyncerInternal.h"
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import "TTKitchenKeyReporter.h"

typedef void (^TTKitchenMigrationCallback)(NSError * __nullable error, NSDictionary * __nullable msg);

static NSString * const kTTSettingsMMKVCacheEnabled = @"tt_settings_config.mmkv_cache_enabled";
static NSString * const kTTSettingsMMKVVerificationEnabled = @"tt_settings_config.mmkv_verification_enabled";
static NSString * const kTTSettingsMMKVErrorReportEnabled = @"tt_settings_config.mmkv_error_report_enabled";

static NSString * const kTTKitchenHasMigrated = @"kTTKitchenHasMigrated";

static NSString * const kTTSettingsMMKVMigrationCooldownTime = @"tt_settings_config.mmkv_migration_cooldown_time";
static NSString * const kTTKitchenLastMigrationTime = @"kTTKitchenLastMigrationTime";

@interface TTKitchenCacheMigrator()

// Switches used to start or stop mmkv migration and verification.
@property (nonatomic, assign) BOOL mmkvCacheEnabled;
@property (nonatomic, assign) BOOL mmkvVerificationEnabled;

// Flag used to show migration status.
@property (nonatomic, assign) BOOL hasMigrated;

// StopMigrating would be set YES if mmkv verification failed.
@property (nonatomic, assign) BOOL stopMigrating;

@property (nonatomic, strong) NSNumber *lastMigrationTime;
@property (nonatomic, strong) NSNumber *migrationCooldownTime;

@end


@implementation TTKitchenCacheMigrator

@synthesize mmkvCacheEnabled = _mmkvCacheEnabled;
@synthesize hasMigrated = _hasMigrated;
@synthesize lastMigrationTime = _lastMigrationTime;

TTRegisterKitchenFunction() {
    TTKitchenManager.cacheMigrator = TTKitchenCacheMigrator.new;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        TTKitchenManager.diskCache = (self.mmkvCacheEnabled && self.hasMigrated)? TTKitchenMMKVDiskCache.new : TTKitchenYYCacheDiskCache.new;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSynchronizingFinishedNotification) name:
         TTKitchenRemoteSettingsDidReceiveNotification object:nil];
        self.migrationCooldownTime = @(2 * 60 * 60);
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveSynchronizingFinishedNotification {
    if (self.mmkvCacheEnabled && !self.hasMigrated && !self.stopMigrating) {
        // Start to migrate cache data from YYCache to MMKV.
        // Migration will happen only when MMKV is enabled, migration hasn't been finished and no mmkv error happened.
        BOOL shouldMigrate = self.lastMigrationTime ? (NSDate.date.timeIntervalSince1970 - self.lastMigrationTime.doubleValue > self.migrationCooldownTime.doubleValue) : YES;
        if (shouldMigrate) {
            [self migrateToMMKVDiskCache];
            self.lastMigrationTime = @(NSDate.date.timeIntervalSince1970);
        }
    }
    else if ((self.stopMigrating && self.mmkvCacheEnabled && self.hasMigrated) ||(!self.mmkvCacheEnabled && self.hasMigrated)) {
        // Stop the migration, replace MMKV with YYCache and resynchronize data from Settings.
        // Migration will be stopped only in the following cases.
        // Case 1: MMKV is enabled and migration finished but MMKV verification failed(stopMigration = YES).
        // Case 2: MMKV migration finished but MMKV is not enabled.
        self.hasMigrated = NO;
        [TTKitchenManager.diskCache clearAll];
        TTKitchenManager.diskCache = TTKitchenYYCacheDiskCache.new;
        [TTKitchenManager.diskCache setObject:nil forKey:@"kTTKitchenContextData"];
        [[TTKitchenSyncer sharedInstance] synchronizeSettings];
    }
}

- (void)migrateToMMKVDiskCache {
    [self _migrateToMMKVDiskCacheWithCallback:^(NSError * _Nullable error, NSDictionary * _Nullable msg) {
        if (!error) {
            // Migration finished.
            self.hasMigrated = YES;
            TTKitchen.migrateDebugMessage = [NSString stringWithFormat:@"[Migration succeed] migrateTime = %@; checkTime = %@",msg[@"migrateTime"], msg[@"checkTime"]];
            [BDMonitorProtocol hmdTrackService:@"ttkitchen_mmkv_migration"
                                                metric:@{}
                                              category:@{@"status":@1}
                                                 extra:@{}];
        }
        else {
            // Migration failed. Report happened error.
            if (TTKitchenManager.errorReporter && [TTKitchenManager.errorReporter respondsToSelector:@selector(reportMigrationErrorWithMsg:)]) {
                [TTKitchenManager.errorReporter reportMigrationErrorWithMsg:msg];
            }
            TTKitchen.migrateDebugMessage = [NSString stringWithFormat:@"[Migration failed] migrateTime = %@; checkTime = %@; problemKey = %@; originalValue = %@; problemValue = %@",msg[@"migrateTime"], msg[@"checkTime"], msg[@"problemKey"], msg[@"originalValue"], msg[@"problemValue"]];
            [BDMonitorProtocol hmdTrackService:@"ttkitchen_mmkv_migration"
                                                metric:@{}
                                              category:@{@"status":@0}
                                                 extra:@{}];
        }
    }];
}

- (void)_migrateToMMKVDiskCacheWithCallback:(TTKitchenMigrationCallback)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Copy cache data from YYCache to MMKV.
        double migrateStart = [[NSDate date] timeIntervalSince1970];
        TTKitchenMMKVDiskCache *mmkvStorage = TTKitchenMMKVDiskCache.new;
        [[TTKitchenManager sharedInstance].allKitchenKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            Class typeClass = [TTKitchen getTypeClassForKey:key];
            if (typeClass) {
                NSObject <NSCoding> *value = (NSObject <NSCoding> *)[TTKitchenManager.diskCache getObjectOfClass:typeClass forKey:key];
                if (value) {
                    [mmkvStorage setObject:value forKey:key];
                }
            }
        }];
        double migrateEnd = [[NSDate date] timeIntervalSince1970];
        
        // Check MMKV cache data with original YYCache data.
        double checkStart = [[NSDate date] timeIntervalSince1970];
        __block NSString * problemKey = nil;
        __block NSObject <NSCoding> * originalValue = nil;
        __block NSObject <NSCoding> * problemValue = nil;
        [[TTKitchenManager sharedInstance].allKitchenKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            Class typeClass = [TTKitchen getTypeClassForKey:key];
            if (typeClass) {
                NSObject <NSCoding> * originalSchemaValue = (NSObject <NSCoding> *)[TTKitchenManager.diskCache getObjectOfClass:typeClass forKey:key];
                NSObject <NSCoding> * newSchemaValue = (NSObject <NSCoding> *)[mmkvStorage getObjectOfClass:typeClass forKey:key];
                if ((originalSchemaValue && ![originalSchemaValue isEqual:newSchemaValue]) || (!originalSchemaValue & !!newSchemaValue)) {
                    problemKey = key.copy;
                    originalValue = originalSchemaValue.copy;
                    problemValue = newSchemaValue.copy;
                    *stop = YES;
                }
            }
        }];
        double checkEnd = [[NSDate date] timeIntervalSince1970];
        
        NSDictionary * msg = @{
            @"migrateTime" : @(migrateEnd - migrateStart),
            @"checkTime" : @(checkEnd - checkStart),
            @"problemKey" : problemKey ?: @"EMPTY",
            @"originalValue" : originalValue ?: @"EMPTY",
            @"problemValue" : problemValue ?: @"EMPTY"
        };
        NSError * error = problemKey ? [NSError errorWithDomain:@"TTKitchen MMKV 迁移检查到问题" code:-1 userInfo:nil] : nil;
        if (!error) {
            // Use MMKV cache data and clean YYCache data.
            [TTKitchenManager.diskCache clearAll];
            TTKitchenManager.diskCache = mmkvStorage;
        }
        if (callback) {
            callback(error, msg);
        }
    });
}

- (void)synchronizeAndVerifyCacheWithSettings:(NSDictionary *)settings ForKeys:(NSArray<NSString *> *)keys{
    // Using Settings data to synchronize migration switches.
    self.mmkvCacheEnabled = [[settings valueForKeyPath:kTTSettingsMMKVCacheEnabled] boolValue];
    self.mmkvVerificationEnabled = [[settings valueForKeyPath:kTTSettingsMMKVVerificationEnabled] boolValue];
    self.migrationCooldownTime = [settings valueForKeyPath:kTTSettingsMMKVMigrationCooldownTime];
    
    if (self.mmkvCacheEnabled) {
        BOOL errorReportEnabled = [[settings valueForKeyPath:kTTSettingsMMKVErrorReportEnabled] boolValue];
        if (errorReportEnabled) {
            TTKitchenManager.errorReporter = [TTKitchenKeyReporter sharedReporter];
        }
    }
    
    // Verify MMKV cache data When MMKV is enabled, migration finished and MMKV verification is enabled.
    if (self.mmkvCacheEnabled && self.hasMigrated && self.mmkvVerificationEnabled) {
        [self _verifyMMKVCacheWithSettings:settings ForKeys:keys callback:^(NSError * _Nullable error, NSDictionary * _Nullable msg) {
            if (error) {
                // MMKV verification failed(stopMigration = YES). Stop the migration and report happened error.
                self.stopMigrating = YES;
                if (TTKitchenManager.errorReporter && [TTKitchenManager.errorReporter respondsToSelector:@selector(reportMMKVErrorWithMsg:)]) {
                    [TTKitchenManager.errorReporter reportMMKVErrorWithMsg:msg];
                }
                TTKitchen.updateDebugMessage = [NSString stringWithFormat:@"[校验失败] checkTime = %@; problemKey = %@; originalValue = %@; problemValue = %@",msg[@"checkTime"], msg[@"problemKey"], msg[@"originalValue"], msg[@"problemValue"]];
                [BDMonitorProtocol hmdTrackService:@"ttkitchen_mmkv_verification"
                                            metric:@{}
                                            category:@{@"status":@0}
                                                extra:@{}];
            }
            else {
                // MMKV verification finished.
                TTKitchen.updateDebugMessage = [NSString stringWithFormat:@"[校验成功] checkTime = %@",msg[@"checkTime"]];
                [BDMonitorProtocol hmdTrackService:@"ttkitchen_mmkv_verification"
                                            metric:@{}
                                            category:@{@"status":@1}
                                                extra:@{}];
            }
        }];
    }
}

- (void)_verifyMMKVCacheWithSettings:(NSDictionary *)settings ForKeys:(NSArray<NSString *> *)keys callback:(TTKitchenMigrationCallback)callback {
    double checkStart = [[NSDate date] timeIntervalSince1970];
    __block NSString * problemKey = nil;
    __block NSObject <NSCoding> * originalValue = nil;
    __block NSObject <NSCoding> * problemValue = nil;
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        Class typeClass = [TTKitchen getTypeClassForKey:key];
        if (typeClass) {
            NSObject <NSCoding> *storageValue = (NSObject <NSCoding> *) [TTKitchenManager.diskCache getObjectOfClass:typeClass forKey:key];
            NSObject <NSCoding> *settingsValue = [key containsString:@"."] ? [settings valueForKeyPath:key] : [settings objectForKey:key];
            if (![storageValue isEqual:settingsValue]) {
                problemKey = key;
                originalValue = [settingsValue copy];
                problemValue = [storageValue copy];
                *stop = YES;
            }
        }
    }];
    double checkEnd = [[NSDate date] timeIntervalSince1970];
    NSDictionary *msg = @{
        @"checkTime" : @(checkEnd - checkStart),
        @"problemKey" : problemKey ?: @"EMPTY",
        @"originalValue" : originalValue ?: @"EMPTY",
        @"problemValue" : problemValue ?: @"EMPTY"
    };
    NSError * error = problemKey ? [NSError errorWithDomain:@"MMKV存储方案检查到问题" code:-2 userInfo:nil] : nil;
    if (callback) {
        callback(error, msg);
    }
}

- (BOOL)mmkvCacheEnabled {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _mmkvCacheEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kTTSettingsMMKVCacheEnabled];
    });
    return _mmkvCacheEnabled;
}

- (void)setMmkvCacheEnabled:(BOOL)migrationEnabled {
    _mmkvCacheEnabled = migrationEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:migrationEnabled forKey:kTTSettingsMMKVCacheEnabled];
}

- (BOOL)hasMigrated {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hasMigrated = [[NSUserDefaults standardUserDefaults] boolForKey:kTTKitchenHasMigrated];
    });
    return _hasMigrated;
}

- (void)setHasMigrated:(BOOL)hasMigrated {
    _hasMigrated = hasMigrated;
    [[NSUserDefaults standardUserDefaults] setBool:hasMigrated forKey:kTTKitchenHasMigrated];
}

- (NSNumber *)lastMigrationTime{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lastMigrationTime = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:kTTKitchenLastMigrationTime];
    });
    return _lastMigrationTime;
}
- (void)setLastMigrationTime:(NSNumber *)lastMigrationTime{
    _lastMigrationTime = lastMigrationTime;
    [[NSUserDefaults standardUserDefaults] setObject:lastMigrationTime forKey:kTTKitchenLastMigrationTime];
}

- (void)setMigrationCooldownTime:(NSNumber *)migrationCooldownTime{
    if (!migrationCooldownTime) {
        return;
    }
    _migrationCooldownTime = migrationCooldownTime;
}

@end
