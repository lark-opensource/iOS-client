//
//  BDModelFacade.h
//  BDModel
//
//  Created by 马钰峰 on 2019/3/28.
//

#import <Foundation/Foundation.h>
#import "BDModelMappingDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDModel : NSObject

/**
 将JSON映射成指定类型对象
 
 @param cls 指定类型
 @param json JSON结构
 @return 指定类型对象，可能为空
 */
+ (nullable id)model:(Class)cls withJSON:(id)json;

/**
 将JSON映射成指定类型对象
 
 @param cls 指定类型
 @param json JSON结构
 @param options 映射处理选项
 @return 指定类型对象，可能为空
 */
+ (nullable id)model:(Class)cls withJSON:(id)json options:(BDModelMappingOptions)options;

/**
 将字典映射成指定类型对象
 
 @param cls 指定类型
 @param dictionary 字典
 @return 指定类型对象，可能为空
 */
+ (nullable id)model:(Class)cls withDictonary:(NSDictionary *)dictionary;

/**
 将对象映射成JSON
 
 @param model 对象
 @return JSON结构，可能为空
 */
+ (nullable id)toJSONObjectWithModel:(id)model;

/**
 将对象映射成JSON二进制Data
 
 @param model 对象
 @return JSON二进制Data，可能为空
 */
+ (nullable NSData *)toJSONDataWithModel:(id)model;

/**
 将对象映射成JSON字符串
 
 @param model 对象
 @return JSON字符串，可能为空
 */
+ (nullable NSString *)toJSONStringWithModel:(id)model;

@end

NS_ASSUME_NONNULL_END
