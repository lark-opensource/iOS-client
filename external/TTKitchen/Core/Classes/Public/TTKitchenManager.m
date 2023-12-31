//
//  TTKitchenManager.m
//  Article
//
//  Created by SongChai on 2017/7/14.
//

#import "TTKitchenManager.h"
#import "TTKitchenInternal.h"
#import "TTKitchenKVCollection.h"
#import <pthread/pthread.h>
#import <BDAssert/BDAssert.h>
#import "TTKitchenLogManager.h"

#define KITCHEN_DIRECTORY_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/TTKitchen"]

static TTKitchenKVCollection<NSString *,TTKitchenModel *> *_TTKitchenKVCollection;

NSNotificationName const kTTKitchenSettingsUpdatedNotification = @"kTTKitchenSettingsUpdatedNotification";

static NSMutableArray<dispatch_block_t> *_TTKitchenConfigBlocks;
static pthread_mutex_t _lock;
static Class<TTKitchenModelizer> _modelizer;
static id<TTKitchenKeyMonitor> _keyMonitor;
static id<TTKitchenKeyErrorReporter> _errorReporter;
static id<TTKitchenDiskCacheProtocol> _diskCache;
static id<TTKitchenCacheMigratorProtocol> _cacheMigrator;

void TTKitchenRegisterBlock(dispatch_block_t block) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _TTKitchenConfigBlocks = [NSMutableArray new];
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &attr);
        pthread_mutexattr_destroy(&attr);
    });
    pthread_mutex_lock(&_lock);
    [_TTKitchenConfigBlocks addObject:block];
    pthread_mutex_unlock(&_lock);
}

@interface TTKitchenManager ()
@property (nonatomic, strong) NSCache *modelCache;
@end

@implementation TTKitchenManager

+ (instancetype)sharedInstance {
    static TTKitchenManager* s_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[TTKitchenManager alloc] init];
        [GAIAEngine startTasksForKey:@TTRegisterKitchenGaiaKey];
        if ([s_instance conformsToProtocol:@protocol(TTKitchenSwiftRegister)] && [s_instance respondsToSelector:@selector(registerSwiftKitchen)]) {
            [(id<TTKitchenSwiftRegister>)s_instance registerSwiftKitchen];
        }
    });
    pthread_mutex_lock(&_lock);
    if (_TTKitchenConfigBlocks.count > 0) {
        for (dispatch_block_t block in _TTKitchenConfigBlocks) {
            block();
        }
        [_TTKitchenConfigBlocks removeAllObjects];
    }
    pthread_mutex_unlock(&_lock);
    return s_instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _modelCache = [[NSCache alloc] init];
        [GAIAEngine startTasksForKey:@TTKitchenDiskCacheGaiaKey];
        if (!_diskCache){
            NSAssert(NO, @"Please use YYCache/MMKV subspec.");
        }
    }
    return self;
}

+ (void)setModelizer:(Class<TTKitchenModelizer>)modelizer {
    BDAssert(_modelizer == nil, @"Modelizer can only be initilized once.");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _modelizer = modelizer;
    });
}

+ (Class<TTKitchenModelizer>)modelizer {
    return _modelizer;
}

+ (void)setKeyMonitor:(id<TTKitchenKeyMonitor>)keyMonitor{
    _keyMonitor = keyMonitor;
}

+ (id<TTKitchenKeyMonitor>)keyMonitor{
    return _keyMonitor;
}

+ (void)setErrorReporter:(id<TTKitchenKeyErrorReporter>)errorReporter{
    _errorReporter = errorReporter;
}

+ (id<TTKitchenKeyErrorReporter>)errorReporter{
    return _errorReporter;
}

+ (void)setDiskCache:(id<TTKitchenDiskCacheProtocol>)diskCache{
    _diskCache = diskCache;
}
+ (id<TTKitchenDiskCacheProtocol>)diskCache{
    return _diskCache;
}
+ (void)setCacheMigrator:(id<TTKitchenCacheMigratorProtocol>)cacheMigrator{
    _cacheMigrator = cacheMigrator;
}
+ (id<TTKitchenCacheMigratorProtocol>)cacheMigrator{
    return _cacheMigrator;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSMutableArray <NSString *> *updatedKeys = NSMutableArray.new;
    if (self.batchUpdateEnabled) {
        NSMutableDictionary *settingsDic = NSMutableDictionary.dictionary;
        [_TTKitchenKVCollection enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TTKitchenModel * _Nonnull obj, BOOL * _Nonnull stop) {
            id settingValue = nil;
            if ([key containsString:@"."]) {
                @try {
                    settingValue = [dictionary valueForKeyPath:key];
                } @catch (NSException *exception) {
                    BDAssert(NO, @"Unexpected keypath. Check the input dictionary. %@", exception.userInfo);
                }
            } else {
                settingValue = [dictionary objectForKey:key];
            }
            __auto_type setValueBlock = ^(NSMutableDictionary *dic, id value, NSString *key) {
                [dic setValue:value forKey:key];
            };
            if (settingValue) {
                switch (obj.type) {
                        //基本数据类型需要强校验
                    case TTKitchenModelTypeFloat:
                        if ([settingValue respondsToSelector:@selector(doubleValue)]) { //NSString or NSNumber
                            setValueBlock(settingsDic, settingValue, key);
                        }
                        break;
                    case TTKitchenModelTypeBOOL:
                        if ([settingValue respondsToSelector:@selector(integerValue)]) { //NSString or NSNumber
                            setValueBlock(settingsDic, settingValue, key);
                        }
                        break;
                        //String类型一律无脑存储
                    case TTKitchenModelTypeString:
                        if ([settingValue isKindOfClass:[NSString class]]) {
                            setValueBlock(settingsDic, settingValue, key);
                        } else {
                            setValueBlock(settingsDic, [settingValue description], key);
                        }
                        break;
                    case TTKitchenModelTypeArray:
                    case TTKitchenModelTypeStringArray:
                    case TTKitchenModelTypeBOOLArray:
                    case TTKitchenModelTypeFloatArray:
                    case TTKitchenModelTypeArrayArray:
                    case TTKitchenModelTypeDictionaryArray:
                        if ([settingValue isKindOfClass:[NSArray class]]) {
                            TTKitchenModel *model = [self kitchenForKey:key];
                            model.isLegalCollection = nil;
                            setValueBlock(settingsDic, settingValue, key);
                        }
                        break;
                    case TTKitchenModelTypeDictionary:
                    case TTKitchenModelTypeModel:
                        if ([settingValue isKindOfClass:[NSDictionary class]]) {
                            [_modelCache removeObjectForKey:key];
                            setValueBlock(settingsDic, settingValue, key);
                        }
                        break;
                }
            }
        }];
        [updatedKeys addObjectsFromArray:[settingsDic allKeys]];
        [_diskCache addEntriesFromDictionary:settingsDic];
    }
    else {
        [_TTKitchenKVCollection enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TTKitchenModel * _Nonnull obj, BOOL * _Nonnull stop) {
            id settingValue = nil;
            if ([key containsString:@"."]) {
                @try {
                    settingValue = [dictionary valueForKeyPath:key];
                } @catch (NSException *exception) {
                    BDAssert(NO, @"Unexpected keypath in key = %@. Check the input dictionary. %@", key, exception.userInfo);
                }
            } else {
                settingValue = [dictionary objectForKey:key];
            }
            if (settingValue) {
                [updatedKeys addObject:key];
                switch (obj.type) {
                        //基本数据类型需要强校验
                    case TTKitchenModelTypeFloat:
                        if ([settingValue respondsToSelector:@selector(doubleValue)]) { //NSString or NSNumber
                            [self setFloat:[settingValue doubleValue] forKey:key];
                        }
                        break;
                    case TTKitchenModelTypeBOOL:
                        if ([settingValue respondsToSelector:@selector(integerValue)]) { //NSString or NSNumber
                            [self setBOOL:[settingValue integerValue] forKey:key];
                        }
                        break;
                        //String类型一律无脑存储
                    case TTKitchenModelTypeString:
                        if ([settingValue isKindOfClass:[NSString class]]) {
                            [self setString:settingValue forKey:key];
                        } else {
                            [self setString:[settingValue description] forKey:key];
                        }
                        break;
                    case TTKitchenModelTypeArray:
                    case TTKitchenModelTypeStringArray:
                    case TTKitchenModelTypeBOOLArray:
                    case TTKitchenModelTypeFloatArray:
                    case TTKitchenModelTypeArrayArray:
                    case TTKitchenModelTypeDictionaryArray:
                        if ([settingValue isKindOfClass:[NSArray class]]) {
                            [self setArray:settingValue forKey:key];
                        }
                        break;
                    case TTKitchenModelTypeDictionary:
                    case TTKitchenModelTypeModel:
                        if ([settingValue isKindOfClass:[NSDictionary class]]) {
                            [self setDictionary:settingValue forKey:key];
                        }
                        break;
                }
            }
        }];
    }
    if (_cacheMigrator && [_cacheMigrator respondsToSelector:@selector(synchronizeAndVerifyCacheWithSettings:ForKeys:)]){
        [_cacheMigrator synchronizeAndVerifyCacheWithSettings:dictionary ForKeys:updatedKeys];
    }
    [[TTKitchenLogManager sharedInstance] addCurrentLogEntry:dictionary];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTKitchenSettingsUpdatedNotification object:nil];
}

- (TTKitchenModel *)kitchenForKey:(TTKitchenKey)key {
    return [_TTKitchenKVCollection objectForKey:key];
}

- (NSArray<TTKitchenModel *> *)allKitchenModels {
    return [_TTKitchenKVCollection allValues];
}

- (NSArray<NSString *> *)allKitchenKeys {
    return [_TTKitchenKVCollection allKeys];
}

- (NSDictionary <NSString *, NSNumber *> *)keyAccessTime {
    return [_TTKitchenKVCollection keyAccessTime];
}

- (void)setFloat:(CGFloat)f forKey:(TTKitchenKey)key {
    [_diskCache setObject:@(f) forKey:key];
}

- (CGFloat)getFloat:(TTKitchenKey)key{
    return [self _getFloat:key];
}

- (CGFloat)_getFloat:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    BOOL isValid = model && model.type == TTKitchenModelTypeFloat;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return 0.f;
    }
    if (model.freezed && model.freezedValue) {
        return [model.freezedValue doubleValue];
    }
    
    NSNumber *number = (NSNumber *)[_diskCache getObjectOfClass:NSNumber.class forKey:key];
    if ([number isKindOfClass:[NSNumber class]]) {
        model.freezedValue = number;
        return number.doubleValue;
    }
    
    NSNumber *defaultValue = model.defaultValue;
    model.freezedValue = defaultValue;
    return defaultValue.doubleValue;
}

- (void)setInt:(NSInteger)i forKey:(TTKitchenKey)key {
    [self setFloat:i forKey:key];
}

- (NSInteger)getInt:(TTKitchenKey)key {
    NSInteger intValue = (NSInteger)[self _getFloat:key];
    return intValue;
}

- (void)setString:(NSString *)str forKey:(TTKitchenKey)key {
    if (str == nil) {
        [_diskCache removeObjectForKey:key];
        return;
    }
    if ([str isKindOfClass:[NSString class]]) {
        [_diskCache setObject:str forKey:key];
    }
}

- (NSString *)getString:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    BOOL isValid = model && model.type == TTKitchenModelTypeString;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return nil;
    }
    if (model.freezed && model.freezedValue) {
        return model.freezedValue;
    }
    
    NSString *str = (NSString *)[_diskCache getObjectOfClass:NSString.class forKey:key];
    if ([str isKindOfClass:[NSString class]]) {
        model.freezedValue = str;
        return str;
    }
    
    NSString *defaultValue = model.defaultValue;
    model.freezedValue = defaultValue;
    return defaultValue;
}

- (void)setBOOL:(BOOL)b forKey:(TTKitchenKey)key {
    [_diskCache setObject:@(b) forKey:key];
}

- (BOOL)getBOOL:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    BOOL isValid = model && model.type == TTKitchenModelTypeBOOL;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return NO;
    }
    if (model.freezed && model.freezedValue) {
        return [model.freezedValue boolValue];
    }
    
    NSNumber *number = (NSNumber *)[_diskCache getObjectOfClass:NSNumber.class forKey:key];
    if ([number isKindOfClass:[NSNumber class]]) {
        model.freezedValue = number;
        return number.boolValue;
    }
    NSNumber *defaultValue = model.defaultValue;
    model.freezedValue = defaultValue;
    return defaultValue.boolValue;
}

- (void)setArray:(NSArray *)array forKey:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    model.isLegalCollection = nil;
    if (array == nil) {
        [_diskCache removeObjectForKey:key];
        return;
    }
    if ([array isKindOfClass:[NSArray class]]) {
        [_diskCache setObject:array forKey:key];
    }
}

- (NSArray *)getArray:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    BOOL isValid = model && model.type & TTKitchenModelTypeArray;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return nil;
    }
    return [self _getArray:key model:model];
}

- (NSArray *)_getArray:(TTKitchenKey)key model:(TTKitchenModel *)model {
    if (model.freezed && model.freezedValue) {
        return model.freezedValue;
    }
    
    NSArray *array = (NSArray *)[_diskCache getObjectOfClass:NSArray.class forKey:key];
    if ([array isKindOfClass:[NSArray class]]) {
        model.freezedValue = array;
        return array;
    }
    NSArray *defaultValue = model.defaultValue;
    if ([defaultValue isKindOfClass:[NSArray class]]) {
        model.freezedValue = defaultValue;
        return defaultValue;
    }
    return nil;
}

- (NSArray *)_getArray:(TTKitchenKey)key type:(TTKitchenModelType)type clazz:(Class)clazz {
    TTKitchenModel *model = [self kitchenForKey:key];
    BOOL isValid = model && model.type == type;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return nil;
    }
    __auto_type array = [self _getArray:key model:model];
    if (model.isLegalCollection != nil) {
        return array;
    }
    else {
        NSMutableArray *mutableArray = nil;
        for (id item in array) {
            if (![item isKindOfClass:clazz]) {
                BDAssert(NO, @"Kitchen(key:%@) item inside array is unmatched with class %@", key, NSStringFromClass(clazz));
                if (!mutableArray) {
                    mutableArray = array.mutableCopy;
                }
                [mutableArray removeObject:item];
            }
        }
        if(mutableArray) {
            array = mutableArray.copy;
            [self setArray:array forKey:key];
        }
        model.isLegalCollection = @(YES);
        return array;
    }
}

- (NSArray<NSNumber *> *)getBOOLArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeBOOLArray clazz:NSNumber.class];
}

- (NSArray<NSString *> *)getStringArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeStringArray clazz:NSString.class];
}

- (NSArray<NSNumber *> *)getFloatArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeFloatArray clazz:NSNumber.class];
}

- (NSArray<NSNumber *> *)getIntArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeFloatArray clazz:NSNumber.class];
}

- (NSArray<NSDictionary *> *)getDictionaryArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeDictionaryArray clazz:NSDictionary.class];
}

- (NSArray<NSArray *> *)getArrayArray:(TTKitchenKey)key {
    return [self _getArray:key type:TTKitchenModelTypeArrayArray clazz:NSArray.class];
}

- (void)setDictionary:(NSDictionary *)dic forKey:(TTKitchenKey)key {
    [_modelCache removeObjectForKey:key];
    if (dic == nil) {
        [_diskCache removeObjectForKey:key];
        return;
    }
    if ([dic isKindOfClass:[NSDictionary class]]) {
        [_diskCache setObject:dic forKey:key];
    }
}

- (NSDictionary *)getDictionary:(TTKitchenKey)key {
    TTKitchenModel *model = [self kitchenForKey:key];
    //如果是以 model 的方式注册， 无法直接获取 dictionary
    if (model.modelClass) {
        return nil;
    }
    return [self _getDictionary:key model:model];
}

- (NSDictionary *)_getDictionary:(TTKitchenKey)key model:(TTKitchenModel *)model {
    BOOL isValid = model && model.type & TTKitchenModelTypeDictionary;
    BDAssert(isValid, @"Kitchen(key:%@) is undefined or unmatched with configuration.", key);
    if (!isValid) {
        return nil;
    }
    if (model.freezed && model.freezedValue) {
        return model.freezedValue;
    }
    
    NSDictionary *dic = (NSDictionary *)[_diskCache getObjectOfClass:NSDictionary.class forKey:key];
    if ([dic isKindOfClass:[NSDictionary class]]) {
        model.freezedValue = dic;
        return dic;
    }
    NSDictionary *defaultValue = model.defaultValue;
    if ([defaultValue isKindOfClass:[NSDictionary class]]) {
        model.freezedValue = defaultValue;
        return defaultValue;
    }
    return nil;
}

- (id)getModel:(TTKitchenKey)key {
    id model = [self.modelCache objectForKey:key];
    if (model) {
        return model;
    }
    TTKitchenModel *metaModel = [self kitchenForKey:key];
    __auto_type dictionary = [self _getDictionary:key model:metaModel];
    if (dictionary) {
        if (metaModel && self.class.modelizer && [self.class.modelizer respondsToSelector:@selector(modelWithDictionary:modelClass:error:)]) {
            model = [self.class.modelizer modelWithDictionary:dictionary modelClass:metaModel.modelClass error:NULL];
        }
        if (model) {
            [self.modelCache setObject:model forKey:key];
        }
    }
    return model;
}

- (BOOL)hasCacheForKey:(NSString *_Nonnull)key{
    return [_diskCache containsObjectForKey:key];
}


- (void)cleanCacheLog {
    if ([_diskCache respondsToSelector:@selector(cleanCacheLog)]) {
        [_diskCache cleanCacheLog];
    }
}

- (BOOL)removeCacheWithKey:(NSString * _Nonnull)key {
    if (![self hasCacheForKey:key]) {
        return NO;
    }
    else {
        [_diskCache removeObjectForKey:key];
        return YES;
    }
}

- (void)removeAllKitchen {
    [_diskCache clearAll];
    [_TTKitchenKVCollection enumerateKeysAndObjectsUsingBlock:^(NSString *key, TTKitchenModel *obj, BOOL *stop) {
        [obj reset];
    }];
}

- (void)recordAllKitchenAsync {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<TTKitchenModel *> *allModels = TTKitchen.allKitchenModels;
        NSMutableString *allKitchenString = NSMutableString.new;
        [allModels enumerateObjectsUsingBlock:^(TTKitchenModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            [allKitchenString appendString:[self _valueStringForModel:model]];
        }];
        
        BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:KITCHEN_DIRECTORY_PATH isDirectory:nil];
        if (!dirExists) {
            [[NSFileManager defaultManager] createDirectoryAtPath:KITCHEN_DIRECTORY_PATH withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        [allKitchenString writeToFile:[KITCHEN_DIRECTORY_PATH stringByAppendingPathComponent:@"allKitchen"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    });
}

- (NSString *)_valueStringForModel:(TTKitchenModel *)model {
    NSString * valueString = nil;
    if (model.type == TTKitchenModelTypeBOOL) {
        valueString = [TTKitchen getBOOL:model.key] ?@"true": @"false";
    } else if (model.type == TTKitchenModelTypeFloat) {
        valueString = [NSString stringWithFormat:@"%.f", [TTKitchen getFloat:model.key]];;
    } else if (model.type == TTKitchenModelTypeString) {
        valueString =  [TTKitchen getString:model.key];
    } else if (model.type & TTKitchenModelTypeDictionary) {
        NSDictionary *dict = [TTKitchen getDictionary:model.key];
        if ([NSJSONSerialization isValidJSONObject:dict]) {
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&parseError];
            if (jsonData && !parseError) {
                valueString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            valueString = [dict description];
        }
    } else if (model.type & TTKitchenModelTypeArray) {
        NSArray *array = [TTKitchen getArray:model.key];
        if ([NSJSONSerialization isValidJSONObject:array]) {
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:kNilOptions error:&parseError];
            if (jsonData && !parseError) {
                valueString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        } else {
            valueString = [array description];
        }
    }
    return [NSString stringWithFormat:@"%@:%@\n",model.key, valueString];
}

- (NSDictionary *)allKitchenRawDictionary {
    __block NSMutableDictionary *settingsDic = NSMutableDictionary.dictionary;
    
    __auto_type valueForKeyBlock =  ^id(TTKitchenModel *model, NSString *key) {
        if (model.freezed && model.freezedValue) {
             return model.freezedValue;
         }
        Class typeClass = [self getTypeClassForKey:key];
        if (typeClass){
            __auto_type value = (NSObject *)[_diskCache getObjectOfClass:typeClass forKey:key];
            if (value) {
                return value;
            }
        }
         
         NSString *defaultValue = model.defaultValue;
         model.freezedValue = defaultValue;
         return defaultValue;
    };
    [_TTKitchenKVCollection enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TTKitchenModel * _Nonnull obj, BOOL * _Nonnull stop) {
        __auto_type keyComponents = [key componentsSeparatedByString:@"."];
        if (keyComponents.count > 1) {
            __block NSMutableDictionary *tempDic = settingsDic;
            [keyComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *dic = tempDic[obj];
                if (!dic) {
                    tempDic[obj] = NSMutableDictionary.dictionary;
                }
                else if ([dic isKindOfClass:NSDictionary.class] && ![dic isKindOfClass:NSMutableDictionary.class]) {
                    tempDic[obj] = [dic mutableCopy];
                }
                tempDic = tempDic[obj];
                if (idx == keyComponents.count - 2) {
                    *stop = YES;
                }
            }];
        }

        if (keyComponents.count > 1) {
            [settingsDic setValue:valueForKeyBlock(obj, key) forKeyPath:key];
        }
        else {
            [settingsDic setValue:valueForKeyBlock(obj, key) forKey:key];
        }
    }];
    return settingsDic.copy;
}

- (Class _Nullable ) getTypeClassForKey:(NSString *_Nonnull)key {
    TTKitchenModel * model = [_TTKitchenKVCollection objectForKey:key];
    if (!model) {
        return nil;
    }
    switch (model.type) {
        case TTKitchenModelTypeString:
            return NSString.class;
        case TTKitchenModelTypeBOOL:
            return NSNumber.class;
        case TTKitchenModelTypeFloat:
            return NSNumber.class;
        case TTKitchenModelTypeModel:
            return TTKitchenModel.class;
        case TTKitchenModelTypeDictionary:
            return NSDictionary.class;
        default:
            return NSArray.class;
    }
}

- (void)setShouldSaveKeyAccessTimeBeforeResigning:(BOOL)shouldSaveKeyAccessTimeBeforeResigning {
    _TTKitchenKVCollection.shouldSaveKeyAccessTimeBeforeResigning = shouldSaveKeyAccessTimeBeforeResigning;
}

- (BOOL)shouldSaveKeyAccessTimeBeforeResigning {
    return _TTKitchenKVCollection.shouldSaveKeyAccessTimeBeforeResigning;
}

@end

/**
 配置单条数据
 
 @param key 外界存取使用。如果有Service Settings，务必保证一致。
 @param summary 该值的用途，请简单明了描述
 @param type 数值的检查类型
 @param defaultValue 默认值，在settings没下发时或者本地数据损坏，读取的值
 @param modelClass 当 type 为 TTKitchenModelTypeModel 时需要指定 model 的类型
 @return TTKitchenModel，单数据model，返回后可以再配置freezed，保证内存不变性
 */
TTKitchenModel * TTKitchenModelFactory(NSString *key, NSString *summary, TTKitchenModelType type, id defaultValue, Class modelClass) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _TTKitchenKVCollection = [TTKitchenKVCollection new];
    });
    
    TTKitchenModel *result = [_TTKitchenKVCollection.dictionary objectForKey:key];
    if (result) {
        BDAssert(NO, @"Configuration for Kitchen(key:%@) is duplicated", key);
        return result;
    }
    
#if DEBUG
    NSString *typeString = @"NSString";
    BOOL valid = YES;
    switch (type) {
        case TTKitchenModelTypeString:
            valid = [defaultValue isKindOfClass:[NSString class]];
            break;
        case TTKitchenModelTypeBOOL:
            valid = [defaultValue isKindOfClass:[NSNumber class]];
            typeString = @"BOOL";
            break;
        case TTKitchenModelTypeFloat:
            valid = [defaultValue isKindOfClass:[NSNumber class]];
            typeString = @"CGFloat";
            break;
        case TTKitchenModelTypeArray:
        case TTKitchenModelTypeBOOLArray:
        case TTKitchenModelTypeStringArray:
        case TTKitchenModelTypeFloatArray:
        case TTKitchenModelTypeDictionaryArray:
        case TTKitchenModelTypeArrayArray:
            valid = [defaultValue isKindOfClass:[NSArray class]];
            typeString = @"NSArray";
            break;
        case TTKitchenModelTypeDictionary:
        case TTKitchenModelTypeModel:
            valid = [defaultValue isKindOfClass:[NSDictionary class]];
            typeString = @"NSDictionary";
            break;
          
        default:
            break;
    }
    
    BDAssert(valid || defaultValue == nil,
             @"Default value for Kitchen(key:%@) = %@ is not an instance of %@",
             key, defaultValue, typeString);
#endif
    
    result = [[TTKitchenModel alloc] init];
    result.key = key;
    result.summary = summary;
    result.type = type;
    result.modelClass = modelClass;
    result.defaultValue = defaultValue;
    
    [_TTKitchenKVCollection.dictionary setObject:result forKey:key];
    return result;
}

void TTKConfigBOOL(TTKitchenKey key, NSString *summary, BOOL defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeBOOL, @(defaultValue), nil);
}
void TTKConfigString(TTKitchenKey key, NSString *summary, NSString *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeString, defaultValue, nil);
}
void TTKConfigFloat(TTKitchenKey key, NSString *summary, CGFloat defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloat, @(defaultValue), nil);
}
void TTKConfigDictionary(TTKitchenKey key, NSString *summary, NSDictionary *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeDictionary, defaultValue, nil);
}

void TTKConfigInt(TTKitchenKey key, NSString *summary, NSInteger defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloat, @(defaultValue), nil);
}

void TTConfigModel(TTKitchenKey key, Class modelClass, NSString *summary, NSDictionary *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeModel, defaultValue, modelClass);
}
void TTKConfigArray(TTKitchenKey key, NSString *summary, NSArray *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeArray, defaultValue, nil);
}
void TTKConfigBOOLArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeBOOLArray, defaultValue, nil);
}
void TTKConfigStringArray(TTKitchenKey key, NSString *summary, NSArray<NSString *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeStringArray, defaultValue, nil);
}
void TTKConfigFloatArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloatArray, defaultValue, nil);
}
void TTKConfigIntArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloatArray, defaultValue, nil);
}
void TTKConfigDictionaryArray(TTKitchenKey key, NSString *summary, NSArray<NSDictionary *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeDictionaryArray, defaultValue, nil);
}
void TTKConfigArrayArray(TTKitchenKey key, NSString *summary, NSArray<NSArray *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeArrayArray, defaultValue, nil);
}

void TTKConfigFreezedBOOL(TTKitchenKey key, NSString *summary, BOOL defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeBOOL, @(defaultValue), nil).freezed = YES;
}
void TTKConfigFreezedString(TTKitchenKey key, NSString *summary, NSString *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeString, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedFloat(TTKitchenKey key, NSString *summary, CGFloat defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloat, @(defaultValue), nil).freezed = YES;
}
void TTKConfigFreezedInt(TTKitchenKey key, NSString *summary, NSInteger defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloat, @(defaultValue), nil).freezed = YES;
}
void TTKConfigFreezedDictionary(TTKitchenKey key, NSString *summary, NSDictionary *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeDictionary, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedArray(TTKitchenKey key, NSString *summary, NSArray *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeArray, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedBOOLArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeBOOLArray, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedStringArray(TTKitchenKey key, NSString *summary, NSArray<NSString *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeStringArray, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedFloatArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloatArray, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedIntArray(TTKitchenKey key, NSString *summary, NSArray<NSNumber *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeFloatArray, defaultValue, nil).freezed = YES;
}
void TTKConfigFreezedDictionaryArray(TTKitchenKey key, NSString *summary, NSArray<NSDictionary *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeDictionaryArray, defaultValue, nil).freezed = YES;
}
void TTConfigFreezedModel(TTKitchenKey key, Class _Nonnull modelClass, NSString *_Nullable summary, NSDictionary *_Nullable defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeModel, defaultValue, modelClass).freezed = YES;
}
void TTKConfigFreezedArrayArray(TTKitchenKey key, NSString *summary, NSArray<NSArray *> *defaultValue) {
    TTKitchenModelFactory(key, summary, TTKitchenModelTypeArrayArray, defaultValue, nil).freezed = YES;
}
