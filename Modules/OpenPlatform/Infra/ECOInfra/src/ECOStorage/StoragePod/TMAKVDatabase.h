//
//  TMAKVStorage.h
//  Timor
//
//  Created by muhuai on 2018/4/11.
//

#import <Foundation/Foundation.h>

@interface TMAKVItem : NSObject

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id value;

@end

@class FMDatabaseQueue;

@interface TMAKVStorage : NSObject

@property (nonatomic, strong, readonly) NSString *name;

/// 获取KV存储表格，如果没有则新建
/// @param name 表格名称
/// @param dbQueue 数据库队列
+ (TMAKVStorage *)storageForName:(NSString *)name dbQueue:(FMDatabaseQueue *)dbQueue;

/// 存储键值对
/// @param object 值
/// @param key 键
- (BOOL)setObject:(id)object forKey:(NSString *)key;

/// 获取键值对
/// @param key 键
- (id)objectForKey:(NSString *)key;

/// 获取键值对对象
/// @param objectId 键
- (TMAKVItem *)KVItemForKey:(NSString *)objectId;

/// 获取所有键
- (NSArray<NSString*>*)allKeys;

/// 获取存储的键值对数量
- (NSUInteger)getCount;

/// 移除键值对
/// @param key 键
- (BOOL)removeObjectForKey:(NSString *)key;

/// 移除所有键值对
- (BOOL)removeAllObjects;

/// 存储大小，单位为byte
- (NSUInteger)storageSizeInBytes;

/// 存储限额，单位为byte，目前固定为10MB
- (NSUInteger)limitSize;

@end

@interface TMAKVDatabase : NSObject

/// 基于指定路径创建数据库
/// @param dbPath 数据库路径
- (id)initWithDBWithPath:(NSString *)dbPath;

/// 获取KV存储表格，如果没有则新建
/// @param name 表格名称
- (TMAKVStorage *)storageForName:(NSString *)name;

/// 删除KV存储表格
/// @param storage KV存储表格实例
- (BOOL)dropStorage:(TMAKVStorage *)storage;

/// 关闭数据库
- (void)close;

@end
