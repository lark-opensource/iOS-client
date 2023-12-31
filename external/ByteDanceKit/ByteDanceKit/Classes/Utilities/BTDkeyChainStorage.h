//
//  BTDkeyChainStorage.h
//  Article
//
//  Created by Dianwei on 13-5-9.
//
//

#import <Foundation/Foundation.h>

@interface BTDkeyChainStorage : NSObject

/**
 @return 从keychain中根据key返回一个对象
 */
+ (nullable id)objectForKey:(nonnull NSString *)key;

/**
 将对象按照key-value存储到keychain中
 
 @return 成功返回YES,否则返回NO
 */
+ (BOOL)setObject:(nonnull id)value key:(nonnull NSString *)key;

/**
 根据key从keychain中删除对象

 @return 成功返回YES,否则返回NO
 */
+ (BOOL)removeValueForKey:(nonnull NSString *)key;

@end
