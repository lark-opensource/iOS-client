//
//  TTKitchenManager.h
//  Article
//
//  Created by SongChai on 2017/7/14.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Gaia/Gaia.h>

NS_ASSUME_NONNULL_BEGIN

#define KitchenMgr [TTKitchenManager sharedInstance]

#define TTKitchen [TTKitchenManager sharedInstance]

#define TTRegisterKitchenGaiaKey "TTRegisterKitchenKey"
#define TTRegisterKitchenFunction GAIA_FUNCTION(TTRegisterKitchenGaiaKey)
#define TTRegisterKitchenMethod GAIA_METHOD(TTRegisterKitchenGaiaKey);

typedef NSString *TTKitchenKey NS_TYPED_EXTENSIBLE_ENUM;

FOUNDATION_EXTERN NSNotificationName _Nonnull const kTTKitchenSettingsUpdatedNotification;

#pragma mark - Configurations

FOUNDATION_EXTERN void TTKConfigBOOL(TTKitchenKey key, NSString *_Nullable summary, BOOL defaultValue);
FOUNDATION_EXTERN void TTKConfigString(TTKitchenKey key, NSString *_Nullable summary, NSString *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFloat(TTKitchenKey key, NSString *_Nullable summary, CGFloat defaultValue);
FOUNDATION_EXTERN void TTKConfigInt(TTKitchenKey key, NSString *_Nullable summary, NSInteger defaultValue);
FOUNDATION_EXTERN void TTKConfigDictionary(TTKitchenKey key, NSString *_Nullable summary, NSDictionary *_Nullable defaultValue);

/**
 注册一个 settings model

 @param key key
 @param modelClass 对应的 model 类
 @param summary summary
 @param defaultValue 注意，默认值使用的是 NSDictionary 而不是 model
 */
FOUNDATION_EXTERN void TTConfigModel(TTKitchenKey key, Class _Nonnull modelClass, NSString *_Nullable summary, NSDictionary *_Nullable defaultValue);

/**
 Configure an arbitary array.
 
 */
FOUNDATION_EXTERN void TTKConfigArray(TTKitchenKey key, NSString *_Nullable summary, NSArray *_Nullable defaultValue) __deprecated_msg("请使用 TTKConfigBOOLArray/TTKConfigStringArray/TTKConfigFloatArray/TTKConfigDictionaryArray/TTKConfigArrayArray");

/**
 Configure an array of bools.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSNumbers *. In DEBUG mode, non-NSNumber entries will be filtered out.
 */
FOUNDATION_EXTERN void TTKConfigBOOLArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);

/**
 Configure an array of string.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSString *. In DEBUG mode, non-NSString entries will be filtered out.
 */
FOUNDATION_EXTERN void TTKConfigStringArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSString *> *_Nullable defaultValue);

/**
 Configure an array of Float.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSNumber*. In DEBUG mode, non-NSNumber entries will be filtered out.
 */
FOUNDATION_EXTERN void TTKConfigFloatArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);

/**
 Configure an array of Int.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSNumber*. In DEBUG mode, non-NSNumber entries will be filtered out.
 */
FOUNDATION_EXTERN void TTKConfigIntArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);

/**
 注册一个 Dictionary 类型的 array, array 中包含的类型不是 NSDictionary 的成员会被过滤
 */
FOUNDATION_EXTERN void TTKConfigDictionaryArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSDictionary *> *_Nullable defaultValue);

/**
 注册一个 Array 类型的 array, array 中包含的类型不是 NSArray 的成员会被过滤
 */
FOUNDATION_EXTERN void TTKConfigArrayArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSArray *> *_Nullable defaultValue);

FOUNDATION_EXTERN void TTKConfigFreezedBOOL(TTKitchenKey key, NSString *_Nullable summary, BOOL defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedString(TTKitchenKey key, NSString *_Nullable summary, NSString *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedFloat(TTKitchenKey key, NSString *_Nullable summary, CGFloat defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedInt(TTKitchenKey key, NSString *_Nullable summary, NSInteger defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedDictionary(TTKitchenKey key, NSString *_Nullable summary, NSDictionary *_Nullable defaultValue);
FOUNDATION_EXTERN void TTConfigFreezedModel(TTKitchenKey key, Class _Nonnull modelClass, NSString *_Nullable summary, NSDictionary *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedArray(TTKitchenKey key, NSString *_Nullable summary, NSArray *_Nullable defaultValue) __deprecated_msg("请使用 TTKConfigFreezedBOOLArray/TTKConfigFreezedStringArray/TTKConfigFreezedFloatArray/TTKConfigFreezedDictionaryArray/TTKConfigFreezedArrayArray");
FOUNDATION_EXTERN void TTKConfigFreezedBOOLArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedStringArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSString *> *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedFloatArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedIntArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSNumber *> *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedDictionaryArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSDictionary *> *_Nullable defaultValue);
FOUNDATION_EXTERN void TTKConfigFreezedArrayArray(TTKitchenKey key, NSString *_Nullable summary, NSArray<NSArray *> *_Nullable defaultValue);

FOUNDATION_EXTERN void TTKitchenRegisterBlock(dispatch_block_t _Nonnull block);

#pragma mark -

/**
 TTKitchenManager 在调用 getModel: 方法时会使用实现了这个协议的类做 model 化
 */
@protocol TTKitchenModelizer <NSObject>

+ (id _Nullable)modelWithDictionary:(NSDictionary *_Nonnull)dictionary modelClass:(Class _Nonnull)modelClass error:(NSError **)error;

@end

@protocol TTKitchenSwiftRegister <NSObject>

- (void)registerSwiftKitchen;

@end

/**
监听 TTKitchen 对 Settings Key 的各种动作
*/
@protocol TTKitchenKeyMonitor <NSObject>

- (void)kitchenWillGetKey:(NSString *)key;

@end

@protocol TTKitchenKeyErrorReporter <NSObject>

- (void)reportMigrationErrorWithMsg:(NSDictionary *)msg;
- (void)reportMMKVErrorWithMsg:(NSDictionary *)msg;

@end

NS_SWIFT_NAME(Kitchen)
@interface TTKitchenManager : NSObject

@property(atomic, assign) BOOL batchUpdateEnabled;

/**
 在调用 getModel: 方法时会使用设置的 modelizer 做 model 化
 */
@property(nonatomic, strong, class, nullable) Class<TTKitchenModelizer> modelizer;

@property(nonatomic, strong, class, nullable) id<TTKitchenKeyMonitor> keyMonitor;
@property(nonatomic, strong, class, nullable) id<TTKitchenKeyErrorReporter> errorReporter;

@property(nonatomic, copy) NSString * migrateDebugMessage;
@property(nonatomic, copy) NSString * updateDebugMessage;

@property (nonatomic, assign) BOOL shouldSaveKeyAccessTimeBeforeResigning;

+ (instancetype _Nonnull)sharedInstance;

/**
 @brief Update local Kitchen.
 
 @discussion This methods enumerate all configured Kitchen keys and check whether they are available in the passed dictionary. If yes, the corresponding value in the dictionary will be stored inside cache; if no, nothing happens.
 
 @note Only pre-configured key-value pairs will be updated by the passed dictionary.
 
 @example dictionary = @{@"a" : @"aaa", "c" : "CCC"}, kitchen = @{@"a" : @"AAA", @"b" : @"bbb"}.
 After calling this method, kitchen = @{@"a" : @"AAA", @"b" : @"bbb"}
 
 @param dictionary      Key-value pairs to be updated.
 */
- (void)updateWithDictionary:(NSDictionary *_Nullable)dictionary;



/**
 Set a string value for a given key in the Kitchen cache.

 @param str     a string value. If nil, the value is removed from cache, if not an NSString instance, nothing happens.
 @param key     A string identifier.
 */
- (void)setString:(NSString *_Nullable)str forKey:(TTKitchenKey)key;
/**
 Returns the string value associated with the given key. 

 @param key A string identifier. 
 @return The associated string value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a string, nil is returned. 
*/
- (NSString *_Nullable)getString:(TTKitchenKey)key;


/**
 Set a boolean value for a given key in the Kitchen cache.
 */
- (void)setBOOL:(BOOL)b forKey:(TTKitchenKey)key;
/**
 Returns the boolean value associated with the given key.
 
 @param key A string identifier.
 @return The associated boolean value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to boolean, NO is returned.
*/
- (BOOL)getBOOL:(TTKitchenKey)key;



/**
 Set a CGFloat value for a given key in the Kitchen cache.
 */
- (void)setFloat:(CGFloat)f forKey:(TTKitchenKey)key;
/**
 Returns the float value associated with the given key.
 
 @param key A string identifier.
 @return The associated float stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a float, 0.f is returned.
 
 */
- (CGFloat)getFloat:(TTKitchenKey)key;


/**
 Set an NSInteger value for a given key in the Kitchen cache.
 */
- (void)setInt:(NSInteger)i forKey:(TTKitchenKey)key;
/**
 Returns the int value associated with the given key.
 
 @param key A string identifier.
 @return The associated int value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to float/Int, 0 is returned.
 */
- (NSInteger)getInt:(TTKitchenKey)key;

- (void)setArray:(NSArray * _Nullable)array forKey:(TTKitchenKey)key;

/**
 Returns the array value associated with the given key. 

 @param key A string identifier. 
 @return The associated array stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to an array, nil is returned. 
*/
- (NSArray *_Nullable)getArray:(TTKitchenKey)key  __deprecated_msg("请使用 getBOOLArray/getStringArray/getFloatArray/getDictionaryArray/getArrayArray");
- (NSArray<NSNumber *> *_Nullable)getBOOLArray:(TTKitchenKey)key;
- (NSArray<NSString *> *_Nullable)getStringArray:(TTKitchenKey)key;
- (NSArray<NSNumber *> *_Nullable)getFloatArray:(TTKitchenKey)key;
- (NSArray<NSNumber *> *_Nullable)getIntArray:(TTKitchenKey)key;
- (NSArray<NSDictionary *> *_Nullable)getDictionaryArray:(TTKitchenKey)key;
- (NSArray<NSArray *> *_Nullable)getArrayArray:(TTKitchenKey)key;

- (void)setDictionary:(NSDictionary *_Nullable)dic forKey:(TTKitchenKey)key;
/**
 Returns the dictionary value associated with the given key.
 
 @param key a string identifier.
 @return The dictionary object stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a dictioanry, nil is returned.
 */
- (NSDictionary *_Nullable)getDictionary:(TTKitchenKey)key;
- (id _Nullable)getModel:(TTKitchenKey)key;

/// Return YES if the value of the key has been set or fetched from settings.
- (BOOL)hasCacheForKey:(TTKitchenKey)key;

- (void)cleanCacheLog; // 清理临时文件，不会对数据有影响

/**
 Remove some specific cached data
 @param key String identifier
 @return return YES if key exists and then the whole pair is deleted, otherwise return NO
 */
- (BOOL)removeCacheWithKey:(TTKitchenKey)key;

/**
 Empties the cache. All values are reset to default values.
 This method may blocks the calling thread until file delete finished. Use with caution!
 Can be called when App is crashed and restarts.
 */
- (void)removeAllKitchen;

/**
 Record all kitchen data to a file. File path: /Documents/TTKitchen/allKitchen
 This method can be used to record all settings data when crash happened.
 Then We can know whether the crash is caused by some settings values or not according to the record file.
 */
- (void)recordAllKitchenAsync;


/// 获取 Kitchen 缓存的所有数据，此方法在数据较多时耗时可能较长，在主线程中使用时需要谨慎
- (NSDictionary *_Nonnull)allKitchenRawDictionary;

@end

NS_ASSUME_NONNULL_END
