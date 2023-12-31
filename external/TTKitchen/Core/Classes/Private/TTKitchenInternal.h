//
//  TTKitchenInternal.h
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import "TTKitchenManager.h"
#import <Foundation/Foundation.h>
#import <Gaia/Gaia.h>

typedef NS_OPTIONS(NSUInteger, TTKitchenModelType) {
    TTKitchenModelTypeString = 0, //默认String
    TTKitchenModelTypeBOOL = 1 << 1,
    TTKitchenModelTypeFloat = 1 << 2,
    TTKitchenModelTypeArray = 1 << 3,
    TTKitchenModelTypeDictionary = 1 << 4,
    TTKitchenModelTypeModel = TTKitchenModelTypeDictionary | 1 << 5,
    TTKitchenModelTypeStringArray = TTKitchenModelTypeArray | 1 << 5,
    TTKitchenModelTypeBOOLArray = TTKitchenModelTypeArray | 1 << 6,
    TTKitchenModelTypeFloatArray = TTKitchenModelTypeArray | 1 << 7,
    TTKitchenModelTypeArrayArray = TTKitchenModelTypeArray | 1 << 8,
    TTKitchenModelTypeDictionaryArray = TTKitchenModelTypeArray | 1 << 9,
};

@interface TTKitchenModel : NSObject

@property (nonatomic, copy, nonnull) NSString *key;
@property (nonatomic, copy, nullable) NSString *summary;
@property (nonatomic, assign) TTKitchenModelType type;
@property (nonatomic, strong, nullable) Class modelClass;
/**
 容器类型的 item 是否合法
 */
@property(atomic, strong, nullable) NSNumber *isLegalCollection;

// 默认为NO，YES表示读取后不可更改，保证在整个app声明周期的值不变性 --> 但通过kitchen封装方法可以修改，便于调试
@property (nonatomic, assign) BOOL freezed;
@property (nonatomic, strong, nullable) id defaultValue;
@property (atomic, strong, nullable) id freezedValue; //freezed为YES时，该值有意义

- (void)reset;

@end

#define TTKitchenDiskCacheGaiaKey "TTKitchenDiskCacheGaiaKey"
#define TTKitchenDiskCacheRegisterFunction GAIA_FUNCTION(TTKitchenDiskCacheGaiaKey)

@protocol TTKitchenDiskCacheProtocol <NSObject>

@required
- (nullable id)getObjectOfClass:(Class _Nonnull )cls forKey:(NSString *_Nonnull)key;
- (void)setObject:(nullable NSObject <NSCoding> *)Object forKey:(NSString *_Nonnull)key;

- (BOOL)containsObjectForKey:(NSString *_Nonnull)key;
- (void)removeObjectForKey:(NSString *_Nonnull)key;
- (void)addEntriesFromDictionary:(NSDictionary<NSString *, id<NSCoding>> *_Nullable)dictionary;

- (void)clearAll;

@optional
- (void)cleanCacheLog;

@end

@protocol TTKitchenCacheMigratorProtocol <NSObject>

// Using Settings data to synchronize migration switches and verify MMKV cache data if needed.
- (void)synchronizeAndVerifyCacheWithSettings:(NSDictionary *_Nullable)settings ForKeys:(NSArray<NSString *> *_Nullable)keys;

@end

@interface TTKitchenManager ()

@property (nonatomic, strong, class, nullable) id <TTKitchenDiskCacheProtocol> diskCache;

/**
 CacheMigrator is not required normally !
 CacheMigrator is used to migrate cache data from YYCache to MMKV. Get more informations at https://bytedance.feishu.cn/docs/doccnEGJLSZf6IzD2Uko12o1R6e#xAUvIt.
 */
@property (nonatomic, strong, class, nullable) id <TTKitchenCacheMigratorProtocol> cacheMigrator;

- (TTKitchenModel *_Nullable)kitchenForKey:(NSString *_Nonnull)key;

- (NSArray<TTKitchenModel *> *_Nonnull)allKitchenModels;

- (NSArray<NSString *> *_Nonnull)allKitchenKeys;

- (NSDictionary <NSString *, NSNumber *> *_Nonnull)keyAccessTime;

- (Class _Nullable ) getTypeClassForKey:(NSString *_Nonnull)key;

@end
