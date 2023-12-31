//
//  TTKitchenManager+Swift.h
//  TTKitchen
//
//  Created by 李琢鹏 on 2020/6/28.
//

#import "TTKitchenManager.h"

NS_ASSUME_NONNULL_BEGIN

// Objective-C 可以通过 TTKitchen 这个宏直接调用实例方法，但 Swift 无法使用宏，将全局 C 函数和 TTKitchenManager 的实例方法在这里统一封装一层
// TTKitchenManager.h 中已经用 NS_SWIFT_NAME(Kitchen) 修饰了 TTKitchenManager, Swift 中可以用类似下面的代码直接调用此类的相关 API, e.g.:
//    let test = Kitchen.getInt("TEST_INT_KEY")
@interface TTKitchenManager (Swift)<TTKitchenSwiftRegister>

+ (void)configBOOL:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(BOOL)defaultValue;
+ (void)configString:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSString *_Nullable)defaultValue;
+ (void)configFloat:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(CGFloat)defaultValue;
+ (void)configInt:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSInteger)defaultValue;
+ (void)configDictionary:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue;

/**
 注册一个 settings model

 @param key key
 @param modelClass 对应的 model 类
 @param summary summary
 @param defaultValue 注意，默认值使用的是 NSDictionary 而不是 model
 */
+ (void)configModel:(TTKitchenKey)key modelClass:(Class _Nonnull)modelClass summary:(NSString *_Nullable)summary defaultValue:( NSDictionary *_Nullable)defaultValue;


/**
 Configure an array of bools.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSNumbers *. In DEBUG mode, non-NSNumber entries will be filtered out.
 */
+ (void)configBOOLArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue;

/**
 Configure an array of string.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSString *. In DEBUG mode, non-NSString entries will be filtered out.
 */
+ (void)configStringArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSString *> *_Nullable)defaultValue;

/**
 Configure an array of Float.
 
 @param key             A string identifier.
 @param summary         A short description for the function of the key.
 @param defaultValue    An array of NSNumber*. In DEBUG mode, non-NSNumber entries will be filtered out.
 */
+ (void)configFloatArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue;

/**
 注册一个 Dictionary 类型的 array, array 中包含的类型不是 NSDictionary 的成员会被过滤
 */
+ (void)configDictionaryArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSDictionary *> *_Nullable)defaultValue;

/**
 注册一个 Array 类型的 array, array 中包含的类型不是 NSArray 的成员会被过滤
 */
+ (void)configArrayArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSArray *> *_Nullable)defaultValue;

+ (void)configFrozenBOOL:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(BOOL)defaultValue;
+ (void)configFrozenString:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSString *_Nullable)defaultValue;
+ (void)configFrozenFloat:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(CGFloat)defaultValue;
+ (void)configFrozenInt:(NSString * _Nonnull)key summary:(NSString *_Nullable)summary defaultValue:(NSInteger)defaultValue;
+ (void)configFrozenDictionary:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue;
+ (void)configFrozenModel:(TTKitchenKey)key modelClass:(Class _Nonnull)modelClass summary:(NSString *_Nullable)summary defaultValue:(NSDictionary *_Nullable)defaultValue;
+ (void)configFrozenBOOLArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue;
+ (void)configFrozenStringArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSString *> *_Nullable)defaultValue;
+ (void)configFrozenFloatArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSNumber *> *_Nullable)defaultValue;
+ (void)configFrozenDictionaryArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSDictionary *> *_Nullable)defaultValue;
+ (void)configFrozenArrayArray:(TTKitchenKey)key summary:(NSString *_Nullable)summary defaultValue:(NSArray<NSArray *> *_Nullable)defaultValue;

/**
 @brief Update local Kitchen.
 
 @discussion This methods enumerate all configured Kitchen keys and check whether they are available in the passed dictionary. If yes, the corresponding value in the dictionary will be stored inside cache; if no, nothing happens.
 
 @note Only pre-configured key-value pairs will be updated by the passed dictionary.
 
 @example dictionary = @{@"a" : @"aaa", "c" : "CCC"}, kitchen = @{@"a" : @"AAA", @"b" : @"bbb"}.
 After calling this method, kitchen = @{@"a" : @"AAA", @"b" : @"bbb"}
 
 @param dictionary      Key-value pairs to be updated.
 */
+ (void)updateWithDictionary:(NSDictionary *_Nullable)dictionary;



/**
 Set a string value for a given key in the Kitchen cache.

 @param str     a string value. If nil, the value is removed from cache, if not an NSString instance, nothing happens.
 @param key     A string identifier.
 */
+ (void)setString:(NSString *_Nullable)str forKey:(TTKitchenKey)key;
/**
 Returns the string value associated with the given key.

 @param key A string identifier.
 @return The associated string value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a string, nil is returned.
*/
+ (NSString *_Nullable)getString:(TTKitchenKey)key;


/**
 Set a boolean value for a given key in the Kitchen cache.
 */
+ (void)setBOOL:(BOOL)b forKey:(TTKitchenKey)key;
/**
 Returns the boolean value associated with the given key.
 
 @param key A string identifier.
 @return The associated boolean value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to boolean, NO is returned.
*/
+ (BOOL)getBOOL:(TTKitchenKey)key;



/**
 Set a CGFloat value for a given key in the Kitchen cache.
 */
+ (void)setFloat:(CGFloat)f forKey:(TTKitchenKey)key;
/**
 Returns the float value associated with the given key.
 
 @param key A string identifier.
 @return The associated float stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a float, 0.f is returned.
 
 */
+ (CGFloat)getFloat:(TTKitchenKey)key;


/**
 Set an NSInteger value for a given key in the Kitchen cache.
 */
+ (void)setInt:(NSInteger)i forKey:(TTKitchenKey)key;
/**
 Returns the int value associated with the given key.
 
 @param key A string identifier.
 @return The associated int value stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to float/Int, 0 is returned.
 */
+ (NSInteger)getInt:(TTKitchenKey)key;

+ (void)setArray:(NSArray * _Nullable)array forKey:(TTKitchenKey)key;

/**
 Returns the array value associated with the given key.

 @param key A string identifier.
 @return The associated array stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to an array, nil is returned.
*/
+ (NSArray<NSNumber *> *_Nullable)getBOOLArray:(TTKitchenKey)key;
+ (NSArray<NSString *> *_Nullable)getStringArray:(TTKitchenKey)key;
+ (NSArray<NSNumber *> *_Nullable)getFloatArray:(TTKitchenKey)key;
+ (NSArray<NSDictionary *> *_Nullable)getDictionaryArray:(TTKitchenKey)key;
+ (NSArray<NSArray *> *_Nullable)getArrayArray:(TTKitchenKey)key;

+ (void)setDictionary:(NSDictionary *_Nullable)dic forKey:(TTKitchenKey)key;
/**
 Returns the dictionary value associated with the given key.
 
 @param key a string identifier.
 @return The dictionary object stored inside cache, if available, or pre-configured. If the value was not pre-configured or not configured to a dictioanry, nil is returned.
 */
+ (NSDictionary *_Nullable)getDictionary:(TTKitchenKey)key;
+ (id _Nullable)getModel:(TTKitchenKey)key;

+ (void)cleanCacheLog; // 清理临时文件，不会对数据有影响

/**
 Empties the cache. All values are reset to default values.
 This method may blocks the calling thread until file delete finished. Use with caution!
 Can be called when App is crashed and restarts.
 */
+ (void)removeAllKitchen;


/// 获取 Kitchen 缓存的所有数据，此方法在数据较多时耗时可能较长，在主线程中使用时需要谨慎
+ (NSDictionary *_Nonnull)allKitchenRawDictionary;


@end

NS_ASSUME_NONNULL_END
