//
//  DYOpenKVInterface.h
//  Timor
//
//  Created by gejunchen.ChenJr on 2021/11/9.
//

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DYOpenKVStorageType) {
    DYOpenKVStorageTypeUnknown         = 0,
    DYOpenKVStorageTypeMMKV            = 1,
    DYOpenKVStorageTypeDB              = 2,
    DYOpenKVStorageTypeCustom          = 3
};

@protocol DYOpenKVInterface <NSObject>

@property (nonatomic, strong, readonly) NSString *name;

+ (instancetype)shareInstance;

- (instancetype)initWithStorageID:(NSString *)storageID rootPath:(NSString *)rootPath;

- (BOOL)containsKey:(NSString *)key;

- (BOOL)setBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)setInt32:(int32_t)value forKey:(NSString *)key;
- (BOOL)setInt64:(int64_t)value forKey:(NSString *)key;
- (BOOL)setDouble:(double)value forKey:(NSString *)key;
- (BOOL)setObject:(id)object forKey:(NSString *)key;

- (BOOL)getBoolForKey:(NSString *)key;
- (int32_t)getInt32ForKey:(NSString *)key;
- (int64_t)getInt64ForKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;
- (nullable id)getObjectOfClass:(Class)cls forKey:(NSString *)key;

- (BOOL)removeObjectForKey:(NSString *)key;

- (BOOL)removeAllObjects;

- (void)enumerateKeys:(void (^)(NSString *key, BOOL *stop))block;
- (NSArray *)allKeys;

- (size_t)getCount;

- (int32_t)storageSizeInBytes;
- (int32_t)limitSize;
- (void)close;

- (DYOpenKVStorageType)type;

- (BOOL)dropStorage;

@end

NS_ASSUME_NONNULL_END
