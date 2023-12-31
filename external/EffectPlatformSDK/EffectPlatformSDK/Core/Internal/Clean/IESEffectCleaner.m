//
//  IESEffectCleaner.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import "IESEffectCleaner.h"
#import <EffectPlatformSDK/IESEffectConfig.h>
#import <EffectPlatformSDK/IESManifestManager.h>
#import <EffectPlatformSDK/NSFileManager+IESEffectManager.h>
#import <EffectPlatformSDK/IESEffectLogger.h>

@interface IESEffectCleaner ()

@property (nonatomic, strong) IESEffectConfig *config;

@property (nonatomic, strong) IESManifestManager *manifestManager;

@property (atomic, assign) BOOL cleaningEffectsDirectoryFlag;
@property (atomic, assign) BOOL cleaningAlgorithmDirectoryFlag;
@property (atomic, assign) BOOL cleaningTmpDirectoryFlag;

@property (nonatomic, strong) NSMutableSet<NSString *> *allowPanelList;

@end

@implementation IESEffectCleaner

- (instancetype)initWithConfig:(IESEffectConfig *)config manifestManager:(IESManifestManager *)manifestManager {
    if (self = [super init]) {
        NSParameterAssert(config);
        NSParameterAssert(manifestManager);
        _config = config;
        _manifestManager = manifestManager;
        _cleaningEffectsDirectoryFlag = NO;
        _cleaningAlgorithmDirectoryFlag = NO;
        _cleaningTmpDirectoryFlag = NO;
        _allowPanelList = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)addAllowListForEffectUnClean:(NSArray<NSString *> *)allowPanelList {
    [self.allowPanelList addObjectsFromArray:allowPanelList];
}

- (void)cleanEffectsDirectoryWithPolicy:(IESEffectCleanPolicy)policy completion:(void (^ _Nullable)(void))completion {
    if (self.cleaningEffectsDirectoryFlag) {
        if (completion) {
            completion();
        }
        return;
    }
    self.cleaningEffectsDirectoryFlag = YES;
    
    const NSString *effectsDirectory = self.config.effectsDirectory;
    if (self.allowPanelList.count > 0) {
        [self cleanEffectsDirectoryWithUnCleanPanelList:[self.allowPanelList allObjects]
                                                 policy:policy
                                             completion:completion];
        return;
    }
    
    
    if (IESEffectCleanPolicyRemoveAll == policy) {
        [[IESEffectLogger logger] logEvent:@"ep_begin_clean_effects_directory" params:@{@"policy": @"remove_all"}];
        [self.manifestManager removeAllEffectsWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSError *error = nil;
                    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:effectsDirectory error:&error];
                    if (contents && contents.count > 0) {
                        [contents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *path = [effectsDirectory stringByAppendingPathComponent:obj];
                            NSError *removeError = nil;
                            if ([[NSFileManager defaultManager] removeItemAtPath:path error:&removeError]) {
                                IESEffectLogInfo(@"Remove %@ from effectsDirectory success.", obj);
                                [[IESEffectLogger logger] logEvent:@"ep_clean_effects_directory" params:@{@"policy": @"remove_all",
                                                                                                          @"product_name": obj ?: @"",
                                                                                                          @"success": @(1),
                                }];
                            } else {
                                IESEffectLogError(@"Remove %@ from effectsDirectory failed with error: %@.", obj, removeError);
                                [[IESEffectLogger logger] logEvent:@"ep_clean_effects_directory" params:@{@"policy": @"remove_all",
                                                                                                          @"product_name": obj ?: @"",
                                                                                                          @"success": @(0),
                                                                                                          @"error" : removeError.description ?: @"",
                                }];
                            }
                        }];
                    }
                    if (error) {
                        IESEffectLogError(@"Get contents of effectsDirectory failed with error: %@", error);
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.cleaningEffectsDirectoryFlag = NO;
                        if (completion) {
                            completion();
                        }
                    });
                });
            } else {
                IESEffectLogError(@"Remove all effects failed with error: %@", error);
                self.cleaningEffectsDirectoryFlag = NO;
                if (completion) {
                    completion();
                }
            }
        }];
    } else if (IESEffectCleanPolicyRemoveByQuota == policy) {
        const unsigned long long totalSize = [self.manifestManager totalSizeOfEffectsAllocated];
        const unsigned long long quota = self.config.effectsDirectoryQuota;
        if (totalSize > quota) {
            [[IESEffectLogger logger] logEvent:@"ep_begin_clean_effects_directory" params:@{@"policy": @"remove_by_quota"}];
            [self.manifestManager removeAllEffectsNotLockedWithCompletion:^(BOOL success, NSError * _Nullable error, NSArray<NSString *> * _Nonnull effectMD5s) {
                if (success && effectMD5s.count > 0) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [effectMD5s enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSString *path = [effectsDirectory stringByAppendingPathComponent:obj];
                            NSError *removeError = nil;
                            if ([[NSFileManager defaultManager] removeItemAtPath:path error:&removeError]) {
                                IESEffectLogInfo(@"Remove %@ from effectsDirectory success.", obj);
                                [[IESEffectLogger logger] logEvent:@"ep_clean_effects_directory" params:@{@"policy": @"remove_by_quota",
                                                                                                          @"product_name": obj ?: @"",
                                                                                                          @"success": @(1),
                                }];
                            } else {
                                IESEffectLogError(@"Remove %@ from effectsDirectory failed with error: %@.", obj, removeError);
                                [[IESEffectLogger logger] logEvent:@"ep_clean_effects_directory" params:@{@"policy": @"remove_by_quota",
                                                                                                          @"product_name": obj ?: @"",
                                                                                                          @"success": @(0),
                                                                                                          @"error" : removeError.description ?: @"",
                                }];
                            }
                        }];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.cleaningEffectsDirectoryFlag = NO;
                            if (completion) {
                                completion();
                            }
                        });
                    });
                } else {
                    self.cleaningEffectsDirectoryFlag = NO;
                    if (completion) {
                        completion();
                    }
                }
            }];
        } else {
            self.cleaningEffectsDirectoryFlag = NO;
            if (completion) {
                completion();
            }
        }
    }
}

- (void)cleanEffectsDirectoryWithUnCleanPanelList:(NSArray<NSString *> *)uncleanPanelList
                                           policy:(IESEffectCleanPolicy)policy
                                       completion:(void (^)(void))completion {
    
    if (IESEffectCleanPolicyRemoveByQuota == policy) {
        const unsigned long long totalSizeExcept = [self.manifestManager totalSizeOfEffectsAllocatedExceptWith:uncleanPanelList];
        const unsigned long long quota = self.config.effectsDirectoryQuota;
        if (totalSizeExcept <= quota) {
            self.cleaningEffectsDirectoryFlag = NO;
            if (completion) {
                completion();
            }
            return;
        }
    }
    
    [self.manifestManager removeEffectsWithAllowUnCleanList:uncleanPanelList
                                                 completion:^(NSError * _Nullable error, NSArray<NSString *> * _Nullable uncleanMD5s) {
        if (!error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *fileError = nil;
                NSString *effectsDirectory = self.config.effectsDirectory;
                NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:effectsDirectory error:&fileError];
                if (fileError) {
                    IESEffectLogError(@"Get contents of effects Directory failed: %@", fileError);
                }
                if (contents.count > 0) {
                    [contents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (uncleanMD5s.count <= 0 || ![uncleanMD5s containsObject:obj]) {
                            NSString *path = [effectsDirectory stringByAppendingPathComponent:obj];
                            NSError *removeError = nil;
                            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&removeError]) {
                                IESEffectLogError(@"Remove content %@ from effects Directory failed: %@", obj, removeError);
                            }
                        }
                    }];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cleaningEffectsDirectoryFlag = NO;
                    if (completion) {
                        completion();
                    }
                });
            });
        } else {
            IESEffectLogError(@"removeEffectsWithAllowUnCleanList completion error:%@", error);
            self.cleaningEffectsDirectoryFlag = NO;
            if (completion) {
                completion();
            }
        }
    }];
}

- (void)cleanAlgorithmDirectory:(void(^)(NSError *error))completion {
    if (self.cleaningAlgorithmDirectoryFlag) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    self.cleaningAlgorithmDirectoryFlag = YES;
    
    NSString *algorithmsDirectory = self.config.algorithmsDirectory;
    BOOL shouldClean = YES;
    
    [self.manifestManager removeAllAlgorithmsWithCompletion:^(NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error = nil;
                NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:algorithmsDirectory error:&error];
                if (contents && contents.count > 0) {
                    [contents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSString *path = [algorithmsDirectory stringByAppendingPathComponent:obj];
                        NSError *removeError = nil;
                        if ([[NSFileManager defaultManager] removeItemAtPath:path error:&removeError]) {
                            IESEffectLogInfo(@"Remove %@ from algorithmsDirectory success.", obj);
                        } else {
                            IESEffectLogError(@"Remove %@ from algorithmsDirectory failed with error: %@.", obj, removeError);
                        }
                    }];
                }
                if (error) {
                    IESEffectLogError(@"Get contents of algorithmsDirectory failed: %@", error);
                }
                
                self.cleaningAlgorithmDirectoryFlag = NO;
            });
        } else {
            self.cleaningAlgorithmDirectoryFlag = NO;
        }
        
        if (completion) {
            completion(error);
        }
    }];
}

- (void)cleanTmpDirectoryWithPolicy:(IESEffectCleanPolicy)policy completion:(void (^)(void))completion {
    if (self.cleaningTmpDirectoryFlag) {
        if (completion) {
            completion();
        }
        return;
    }
    self.cleaningTmpDirectoryFlag = YES;
    
    const NSString *tmpDirectory = self.config.tmpDirectory;
    const unsigned long long quota = self.config.tmpDirectoryQuota;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL shouldClean = NO;
        
        // Clean only when size over quota
        if (IESEffectCleanPolicyRemoveByQuota == policy) {
            unsigned long long tmpDirectorySize = 0;
            NSError *error = nil;
            if ([NSFileManager ieseffect_getAllocatedSize:&tmpDirectorySize
                                         ofDirectoryAtURL:[NSURL fileURLWithPath:tmpDirectory]
                                                    error:&error]) {
                if (tmpDirectorySize > quota) {
                    IESEffectLogInfo(@"Clean contents of tmpDirectory (size: %@), quota (size: %@)", @(tmpDirectorySize), @(quota));
                    shouldClean = YES;
                }
            } else {
                IESEffectLogError(@"Compute tmpDirectory size failed: %@", error);
            }
        } else if (IESEffectCleanPolicyRemoveAll == policy) {
            // Force clean all tmp files
            shouldClean = YES;
        }
        
        if (shouldClean) {
            NSError *error = nil;
            NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDirectory error:&error];
            if (contents && contents.count > 0) {
                [contents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSString *path = [tmpDirectory stringByAppendingPathComponent:obj];
                    NSError *removeError = nil;
                    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&removeError]) {
                        IESEffectLogError(@"Remove %@ from tmpDirectory failed: %@", obj, removeError);
                    }
                }];
            }
            if (error) {
                IESEffectLogError(@"Get contents of tmpDirectory failed: %@", error);
            }
        }
        
        // Mark as finish
        self.cleaningTmpDirectoryFlag = NO;
        
        // Callback
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)vacuumDatabaseFile {
    unsigned long long quota = self.config.effectManifestQuota;
    NSString *filePath = self.config.effectManifestPath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        unsigned long long dbFileSize = 0;
        if ([NSFileManager ieseffect_getFileSize:&dbFileSize filePath:filePath error:&error]) {
            if (dbFileSize > quota) {
                [self.manifestManager vacuumDatabaseFileWithCompletion:^(BOOL success, NSError * _Nullable error) {
                    if (success) {
                        unsigned long long dbFileSize2 = 0;
                        [NSFileManager ieseffect_getFileSize:&dbFileSize2 filePath:filePath error:&error];
                        IESEffectLogInfo(@"Vacuum database file size (%@) to size (%@), quota (size: %@)", @(dbFileSize), @(dbFileSize2), @(quota));
                    } else {
                        IESEffectLogError(@"Vacuum database file (size: %@), quota (size: %@) with error: %@", @(dbFileSize), @(quota), error);
                    }
                }];
            }
        }
    });
}

@end
