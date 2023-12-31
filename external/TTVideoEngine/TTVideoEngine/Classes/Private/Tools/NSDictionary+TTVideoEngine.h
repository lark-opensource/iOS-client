//
//  NSDictionary+TTVideoEngine.h
//  Pods
//
//  Created by guikunzhi on 16/12/22.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TTVideoEngine)

- (NSDictionary *)ttVideoEngineDictionaryValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue;

- (NSArray *)ttVideoEngineArrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue;

- (int)ttVideoEngineIntValueForKey:(NSString *)key defaultValue:(int)defaultValue;

- (NSString *)ttVideoEngineStringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

- (BOOL)ttVideoEngineBoolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;

- (NSString *)ttvideoengine_jsonString;

- (CGFloat)ttVideoEngineFloatValueForKey:(NSString *)key defalutValue:(CGFloat)defaultValue;

- (NSInteger)ttVideoEngineIntegerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

@end


@interface NSMutableDictionary(TTVideoEngine)

/// safe setObject:forKey:
- (void)ttvideoengine_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

/// safe objectForKey:
- (id)ttvideoengine_objectForKey:(id)aKey;

@end
