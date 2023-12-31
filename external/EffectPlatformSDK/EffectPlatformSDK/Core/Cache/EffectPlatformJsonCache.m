//
//  EffectPlatformJsonCache.m
//  EffectPlatformSDK
//
//  Created by 琨王 on 2019/2/22.
//

#import "EffectPlatformJsonCache.h"
#import "IESEffectPlatformResponseModel.h"
#import "IESEffectPlatformNewResponseModel.h"
#import "NSArray+EffectPlatformUtils.h"
#import "NSDictionary+EffectPlatfromUtils.h"

@interface EffectPlatformJsonCache()
@property (nonatomic, assign) BOOL enableMemoryCache;
@property (nonatomic, strong) NSMutableDictionary *objectDic;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, copy) NSString *accessKey;
@end
@implementation EffectPlatformJsonCache

- (instancetype)initWithAccessKey:(NSString *)accessKey
{
    self = [super init];
    if (self) {
        _accessKey = accessKey;
        _objectDic = [[NSMutableDictionary alloc] init];
        _enableMemoryCache = YES;
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)clearMemory
{
    [_lock lock];
    [_objectDic removeAllObjects];
    [_lock unlock];
}

- (void)clear {
    [_lock lock];
    [_objectDic removeAllObjects];
    [_lock unlock];
    NSString *directory = IESEffectListJsonPathWithAccessKey(self.accessKey);
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
}

- (void)clearJsonAndObjectForKey:(NSString *)key
{
    [_lock lock];
    [_objectDic removeObjectForKey:key];
    [_lock unlock];
    
    NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
}

- (nullable IESEffectModel *)effectWithKey:(nonnull NSString *)key {
    [_lock lock];
    IESEffectModel *model = _objectDic[key];
    [_lock unlock];
    if (!model) {
        NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
            model = [MTLJSONAdapter modelOfClass:[IESEffectModel class] fromJSONDictionary:dict error:nil];
            [_lock lock];
            _objectDic[key] = model;
            [_lock unlock];
        }
    }
    return model;
}

- (nullable IESEffectPlatformResponseModel *)objectWithKey:(nonnull NSString *)key {
    [_lock lock];
    IESEffectPlatformResponseModel *model = _objectDic[key];
    [_lock unlock];
    if (!model) {
        NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
            model = [MTLJSONAdapter modelOfClass:[IESEffectPlatformResponseModel class]
                                                                      fromJSONDictionary:dict
                                                                                   error:nil];
            [model preProcessEffects];
            [_lock lock];
            _objectDic[key] = model;
            [_lock unlock];
        }
    }
    return model;
}

- (void)setEnableMemoryCache:(BOOL)enable
{
    [_lock lock];
    _enableMemoryCache = enable;
    [_lock unlock];
}

- (nullable IESEffectPlatformNewResponseModel *)newResponseWithKey:(nonnull NSString *)key {
    [_lock lock];
    IESEffectPlatformNewResponseModel *model = _objectDic[key];
    [_lock unlock];
    if (!model) {
        NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
            model = [MTLJSONAdapter modelOfClass:[IESEffectPlatformNewResponseModel class]
                              fromJSONDictionary:dict
                                           error:nil];
            [model preProcessEffects];
            [_lock lock];
            _objectDic[key] = model;
            [_lock unlock];
        }
    }
    return model;
}

- (void)setJson:(NSDictionary *)json effect:(IESEffectModel *)object forKey:(NSString *)key
{
    json = [json dictionaryByRemoveNULL];
    [_lock lock];
    if (_enableMemoryCache) {
        _objectDic[key] = object;
    }
    [_lock unlock];
    NSString *directory = IESEffectListJsonPathWithAccessKey(self.accessKey);
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [json writeToFile:filePath atomically:YES];
    });
}

- (void)setJson:(NSDictionary *)json object:(IESEffectPlatformResponseModel *)object forKey:(NSString *)key
{
    json = [json dictionaryByRemoveNULL];
    [_lock lock];
    if (_enableMemoryCache) {
        _objectDic[key] = object;
    }
    [_lock unlock];
    NSString *directory = IESEffectListJsonPathWithAccessKey(self.accessKey);
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [json writeToFile:filePath atomically:YES];
    });
}

- (void)setJson:(NSDictionary *)json newResponse:(IESEffectPlatformNewResponseModel *)object forKey:(NSString *)key
{
    json = [json dictionaryByRemoveNULL];
    [_lock lock];
    if (_enableMemoryCache) {
        _objectDic[key] = object;
    }
    [_lock unlock];
    NSString *directory = IESEffectListJsonPathWithAccessKey(self.accessKey);
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [json writeToFile:filePath atomically:YES];
    });
}

- (NSDictionary *)modelDictWithKey:(NSString *)key {
    NSDictionary *modelDict = nil;
    [_lock lock];
    if (key) {
        modelDict = _objectDic[key];
    }
    [_lock unlock];
    if (!modelDict) {
        NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            modelDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
            [_lock lock];
            if (key) {
                _objectDic[key] = modelDict;
            }
            [_lock unlock];
        }
    }
    return modelDict;
}

- (void)setJson:(NSDictionary *)json forKey:(NSString *)key {
    json = [json dictionaryByRemoveNULL];
    [_lock lock];
    if (_enableMemoryCache) {
        if (key) {
            _objectDic[key] = json;
        }
    }
    [_lock unlock];
    NSString *directory = IESEffectListJsonPathWithAccessKey(self.accessKey);
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (key) {
        NSString *filePath = [IESEffectListJsonPathWithAccessKey(self.accessKey) stringByAppendingPathComponent:key];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL success = [json writeToFile:filePath atomically:YES];
        });
    }
}

@end
