//
//  IESSimpleSchemaResolver.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/1.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchSchemaResolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESSimpleSchemaResolver : NSObject<IESPrefetchSchemaResolver>


/// 初始化一个简单的Schema解析器
/// @param hostname 用于过滤Schema，只有host为hostname的Schema会被IESSimpleSchemaResolver拦截
/// @param key 用于提取二级Schema，原Schema中参数名称为key的参数值会被提取出来并decode为最终schema的结果
- (instancetype)initWithHost:(NSString *)hostname keyQuery:(NSString *)key NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
