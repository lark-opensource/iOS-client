//
//  IESGurdResourceMetadataStorage.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/2/3.
//

#import "IESGurdResourceMetadataStorage+Private.h"

#import "IESGurdKit+Experiment.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdAppLogger.h"
#import "IESGurdFilePaths.h"
#import "IESGurdEventTraceManager+Message.h"
#import "IESGurdFileMetaManager+Private.h"
#import "IESGurdResourceMetadataCache.h"

@interface IESGurdResourceMetadataStorage ()

@property (class, nonatomic, strong) IESGurdResourceMetadataCache<IESGurdInactiveCacheMeta *> *inactiveMetadataCache;

@property (class, nonatomic, strong) IESGurdResourceMetadataCache<IESGurdActivePackageMeta *> *activeMetadataCache;

@end

@implementation IESGurdResourceMetadataStorage

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupMetadata];
    });
}

#pragma mark - Access

+ (IESGurdInactiveCacheMeta * _Nullable)inactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        return self.inactiveMetadataCache[accessKey][channel];
    }
}

+ (IESGurdActivePackageMeta * _Nullable)activeMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        return self.activeMetadataCache[accessKey][channel];
    }
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdInactiveCacheMeta *> *> *)copyInactiveMetadataDictionary;
{
    @synchronized (self) {
        return [self.inactiveMetadataCache copyMetadataDictionary];
    }
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, IESGurdActivePackageMeta *> *> *)copyActiveMetadataDictionary
{
    @synchronized (self) {
        return [self.activeMetadataCache copyMetadataDictionary];
    }
}

#pragma mark - Action

+ (void)saveInactiveMeta:(IESGurdInactiveCacheMeta *)meta
{
    @synchronized (self) {
        [self.inactiveMetadataCache saveMetadata:meta];
    }
}

+ (void)saveActiveMeta:(IESGurdActivePackageMeta *)meta
{
    @synchronized (self) {
        [self.activeMetadataCache saveMetadata:meta];
    }
}

+ (void)deleteInactiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        [self.inactiveMetadataCache deleteMetadataForAccessKey:accessKey channel:channel];
    }
}

+ (void)deleteActiveMetaForAccessKey:(NSString *)accessKey channel:(NSString *)channel
{
    @synchronized (self) {
        [self.activeMetadataCache deleteMetadataForAccessKey:accessKey channel:channel];
    }
}

+ (void)clearAllMetadata
{
    @synchronized (self) {
        [self.inactiveMetadataCache clearAllMetadata];
        [self.activeMetadataCache clearAllMetadata];
    }
}

#pragma mark - Private

+ (void)setupMetadata
{
    self.inactiveMetadataCache = [self metadataCacheWithPath:IESGurdFilePaths.inactiveMetadataPath
                                            metadataCapacity:512
                                               metadataClass:[IESGurdInactiveCacheMeta class]
                                              enableIndexLog:NO];
   
    self.activeMetadataCache = [self metadataCacheWithPath:IESGurdFilePaths.activeMetadataPath
                                          metadataCapacity:1024
                                             metadataClass:[IESGurdActivePackageMeta class]
                                            enableIndexLog:IESGurdKit.enableMetadataIndexLog];
    [self migrateMetadataIfNeeded];
}

+ (BOOL)migrateMetadataIfNeeded
{
    if (![IESGurdFileMetaManager shouldMigrate]) {
        return NO;
    }
    
    GURD_TIK;
    [IESGurdFileMetaManager enumerateInactiveMetaUsingBlock:^(IESGurdInactiveCacheMeta * _Nonnull meta) {
        [self.inactiveMetadataCache saveMetadata:meta];
    }];
    [IESGurdFileMetaManager enumerateActiveMetaUsingBlock:^(IESGurdActivePackageMeta * _Nonnull meta) {
        [self.activeMetadataCache saveMetadata:meta];
    }];
    [IESGurdFileMetaManager cleanCacheMetaData];
    NSInteger duration = GURD_TOK;
    
    [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeMetadata
                                  subtype:IESGurdAppLogEventSubtypeMetadataMigrate
                                   params:@{ @"duration" : @(duration) }
                                extraInfo:nil
                             errorMessage:nil];
    
    [IESGurdEventTraceManager traceEventWithMessage:@"Gurd did migrate metadata." hasError:NO shouldLog:YES];
    
    return YES;
}

+ (IESGurdResourceMetadataCache *)metadataCacheWithPath:(NSString *)path
                                       metadataCapacity:(int)metadataCapacity
                                          metadataClass:(Class<IESGurdMetadataProtocol>)metadataClass
                                         enableIndexLog:(BOOL)enableIndexLog
{
    IESMetadataStorageConfiguration *configuration = [IESMetadataStorageConfiguration configurationWithFilePath:path];
    configuration.metadataCapacity = metadataCapacity;
    configuration.logLevel = IESMetadataLogLevelWarning;
    configuration.enableIndexLog = enableIndexLog;
    return [IESGurdResourceMetadataCache metadataCacheWithConfiguration:configuration metadataClass:metadataClass];
}

#pragma mark - Accessor

static IESGurdResourceMetadataCache<IESGurdInactiveCacheMeta *> *kInactiveMetadataCache = nil;
+ (IESGurdResourceMetadataCache<IESGurdInactiveCacheMeta *> *)inactiveMetadataCache
{
    return kInactiveMetadataCache;
}

+ (void)setInactiveMetadataCache:(IESGurdResourceMetadataCache<IESGurdInactiveCacheMeta *> *)inactiveMetadataCache
{
    kInactiveMetadataCache = inactiveMetadataCache;
}

static IESGurdResourceMetadataCache<IESGurdActivePackageMeta *> *kActiveMetadataCache = nil;
+ (IESGurdResourceMetadataCache<IESGurdActivePackageMeta *> *)activeMetadataCache
{
    return kActiveMetadataCache;
}

+ (void)setActiveMetadataCache:(IESGurdResourceMetadataCache<IESGurdActivePackageMeta *> *)activeMetadataCache
{
    kActiveMetadataCache = activeMetadataCache;
}

@end
