//
//  BDDYCModuleManager.m
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import "BDDYCModuleManager.h"
#import "BDDYCModule+Internal.h"
#import "BDDYCModelKey.h"
#import "BDDYCModuleModel.h"
#import "BDDFileUtil.h"
#import <pthread/pthread.h>

@interface BDDYCModuleManager ()
{
    pthread_mutex_t _mutableModulesLock;
}
@property (nonatomic, strong) NSMutableDictionary *mutableModulesToRemove;
@property (nonatomic, strong) NSMutableDictionary *mutableModules;
@property (nonatomic, strong) NSMutableArray *failedModules;
@property (nonatomic, strong) NSMutableArray *allLoadedModules;
@property (nonatomic, strong) NSMutableDictionary *mutableModulesDidLoad;

@end

@implementation BDDYCModuleManager

+ (instancetype)sharedManager
{
    static BDDYCModuleManager *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
    });
    return sharedInst;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _mutableModules = [NSMutableDictionary new];
        _mutableModulesToRemove = [NSMutableDictionary new];
        _allLoadedModules = [NSMutableArray array];
        _mutableModulesDidLoad = [NSMutableDictionary new];
        pthread_mutex_init(&_mutableModulesLock, NULL);
    }
    return self;
}

- (void)lockMutableModules {
    pthread_mutex_lock(&_mutableModulesLock);
}

- (void)unlockMutableModules {
    pthread_mutex_unlock(&_mutableModulesLock);
}

- (void)addLoadedModule:(id)aModule {
    if ([aModule isKindOfClass:[BDDYCModuleModel class]]) {
        BDDYCModuleModel *model = (BDDYCModuleModel *)aModule;
        NSDictionary *dic = [model toPropertyListDictionary];
        @synchronized (self.allLoadedModules) {
            [self.allLoadedModules addObject:dic];
        }
    }
}

- (NSArray *)allLoadedQuaterbacks {
    NSArray *patchs = nil;
    @synchronized (self.allLoadedModules) {
        patchs = [self.allLoadedModules copy];
    }
    return patchs;
}

- (void)addModule:(BDBDModule *)aModule
{
    if (!aModule || ![aModule isKindOfClass:[BDBDModule class]] || !aModule.name) return;
    [self lockMutableModules];
    [self.mutableModules setValue:aModule forKey:aModule.name];
    [self.mutableModulesDidLoad setValue:aModule forKey:aModule.name];
    [self unlockMutableModules];
}

- (BDBDModule *)didLoadModuleWithName:(NSString *)name {
    BDBDModule *module = nil;
    [self lockMutableModules];
    module = [self.mutableModulesDidLoad objectForKey:name];
    [self unlockMutableModules];
    return module;
}

+ (NSString *)moduleDirectoryWithModuleName:(NSString *)moduleName {
    return DYCModuleDirectory(moduleName);
}


- (void)addModules:(NSArray *)modules
{
    [modules enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self addModule:obj];
    }];
}

- (BDBDModule *)moduleForName:(NSString *)aModuleName
{
    if (!aModuleName || ![aModuleName isKindOfClass:[NSString class]]) return nil;
    
    BDBDModule *foundModule;
    [self lockMutableModules];
    foundModule = self.mutableModules[aModuleName];
    [self unlockMutableModules];
    return foundModule;
}

- (void)addFailedModule:(id)aModule
{
    if (!aModule) return;
    [self removeModule:aModule];
    [self.failedModules addObject:aModule];
}

- (void)removeModule:(BDBDModule *)aModule
{
    if (!aModule || ![aModule isKindOfClass:[BDBDModule class]] || !aModule.name) return;
    [self lockMutableModules];
    [self.mutableModules removeObjectForKey:aModule.name];
    [self.mutableModulesToRemove setValue:aModule
                                       forKey:aModule.name];
    [self unlockMutableModules];
}

- (void)removeModuleForName:(NSString *)aModuleName
{
    if (!aModuleName) return;
    [self lockMutableModules];
    BDBDModule *foundModule = self.mutableModules[aModuleName];
    if (foundModule) {
        [self.mutableModules removeObjectForKey:foundModule.name];
        [self.mutableModulesToRemove setValue:foundModule
                                        forKey:foundModule.name];
    }
    [self unlockMutableModules];
}

- (NSArray *)allModules
{
    NSArray *modules = nil;
    [self lockMutableModules];
    modules = [[self.mutableModules allValues] copy];
    [self unlockMutableModules];
    return modules;
}

- (NSArray *)allModulesToRemove
{
    return [[_mutableModulesToRemove allValues] copy];
}

- (NSArray *)allToReportModules
{
    NSArray *modules;
    [self lockMutableModules];
        modules = [self.mutableModules allValues];
    [self unlockMutableModules];
    NSMutableArray *resultModules = [NSMutableArray array];
    [modules enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [obj toReportDicitonary];
        if (dict) [resultModules addObject:dict];
    }];
    return [resultModules copy];
}

- (NSArray *)allToLogModules {
    NSArray *modules;
    [self lockMutableModules];
        modules = [self.mutableModules allValues];
    [self unlockMutableModules];
    NSMutableArray *resultModules = [NSMutableArray array];
    [modules enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [obj toLogDicitonary];
        if (dict) [resultModules addObject:dict];
    }];
    return [resultModules copy];
}

#pragma mark - Setter/Getter

- (NSMutableArray *)failedModules
{
    if (!_failedModules) {
        _failedModules = [NSMutableArray new];
    }
    return _failedModules;
}

@end



#pragma mark -

@implementation BDDYCModuleManager (FileManager)

+ (NSString *)alphaMainDirectory
{
    return DYCModuleAlphaMainDirectory();
}

+ (NSString *)historyRecordsFilePath
{
    return [NSString stringWithFormat:@"%@/%@.json", DYCModuleHistoryMainDirectory(), BDDYC_MODULE_PLIST_FILE];
}

+ (NSArray<BDBDModule *> *)allModules
{
    if ([[NSFileManager defaultManager] subpathsAtPath:[self alphaMainDirectory]].count == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self historyRecordsFilePath]]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:[self historyRecordsFilePath] error:&error];
        }
        return nil;
    }
    
#if BDDYC_ARCHIVE == 1
    NSArray *dataList = [NSKeyedUnarchiver unarchiveObjectWithFile:[self historyRecordsFilePath]];
#else
    NSArray *dataList = [[NSArray alloc] initWithContentsOfFile:[self historyRecordsFilePath]];
#endif
    
    NSMutableArray *aDYCModuleArray = [NSMutableArray new];
    [dataList enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        BDBDModule *aDYCMdl = [[BDBDModule alloc] initWithPropertyDictionary:obj];
        if (aDYCMdl) [aDYCModuleArray addObject:aDYCMdl];
    }];
    return [aDYCModuleArray copy];
}

- (void)saveToFile
{
    [self.class saveToFileWithModules:[[BDDYCModuleManager sharedManager] allModules]];
}

+ (BOOL)saveToFileWithModules:(NSArray<BDBDModule *> *)allModules
{
    NSMutableArray *propertyArray = [NSMutableArray new];
    
    [allModules enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [obj toPropertyListDictionary];
        if (dict) [propertyArray addObject:dict];
    }];
    
#if BDDYC_ARCHIVE == 1
    return [NSKeyedArchiver archiveRootObject:propertyArray toFile:[self historyRecordsFilePath]];
#endif
    return [propertyArray writeToFile:[self historyRecordsFilePath] atomically:YES];
}

+ (BOOL)appendToFileWithModules:(NSArray<BDBDModule *> *)allModules
{
    if (!allModules || allModules.count == 0) return YES;
    
    NSMutableArray *propertyArray = [NSMutableArray new];
#if BDDYC_ARCHIVE == 1
    NSArray *oldDataList = [NSKeyedUnarchiver unarchiveObjectWithFile:[self historyRecordsFilePath]];
#else
    NSArray *oldDataList = [[NSArray alloc] initWithContentsOfFile:[self historyRecordsFilePath]];
#endif
    [propertyArray addObjectsFromArray:oldDataList];
    
    [allModules enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *dict = [obj toPropertyListDictionary];
        if (dict) [propertyArray addObject:dict];
    }];
    
#if BDDYC_ARCHIVE == 1
    return [NSKeyedArchiver archiveRootObject:propertyArray toFile:[self historyRecordsFilePath]];
#endif
    return [propertyArray writeToFile:[self historyRecordsFilePath] atomically:YES];
}

+ (void)clearAllLocalQuaterback {
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self _clearAllLocalQuaterback];
        });
    } else {
        [self _clearAllLocalQuaterback];
    }
}

+ (void)_clearAllLocalQuaterback {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:DYCGetRootDirectory() error:&error];
    if (!error) {
        [[[BDDYCModuleManager sharedManager] allModules] enumerateObjectsUsingBlock:^(BDBDModule *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[BDDYCModuleManager sharedManager] removeModule:obj];
        }];
    }
}

+ (BOOL)clearLocalQuaterbackWithModule:(BDBDModule *)module {

//    kBDDYCQuaterbackModuleDirectory(aModel.name)
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:kBDDYCQuaterbackModuleDirectory(module.name) error:&error];
    if (!error) {
        [[BDDYCModuleManager sharedManager] removeModule:module];
        [[BDDYCModuleManager sharedManager] saveToFile];
    }

    return !error;
}

@end
