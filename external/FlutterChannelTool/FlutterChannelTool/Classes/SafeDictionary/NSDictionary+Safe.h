//
//  NSDictionary+Safe.h
//  
//
//  Created by zhangtianfu on 2019/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  NSDictionary安全访问接口
 */
@interface NSDictionary (Safe)
    
- (NSString *)flutter_stringValueForKey:(NSString *)key;
    
- (NSNumber *)flutter_numberValueForKey:(NSString *)key;

- (NSArray *)flutter_arrayValueForKey:(NSString *)key;

- (NSDictionary *)flutter_dictionaryValueForKey:(NSString *)key;

- (id)flutter_objectOfClass:(Class)theClass forKey:(NSString *)key;
    
@end

NS_ASSUME_NONNULL_END
