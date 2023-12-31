//
//  NSObject+Attributes.h
//  KKShopping
//
//  Created by 刘诗彬 on 14/12/9.
//  Copyright (c) 2014年 Nice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+HMDUtilities.h"
#import "NSObject+Attributes.h"

#define HMD_ARRAY(key,value) @[@#key,value]

#define HMD_ATTRIBUTE_MAP_DEFAULT(property,key,default) @#property:HMD_ARRAY(key,default)
#define HMD_ATTRIBUTE_MAP(property,key) @#property:@#key

@interface NSObject (HMDAttributes)

+ (NSString *)hmd_className;

+ (Class)hmd_anstorClass;
/**
 子类需要实现此方法，确定哪个属性是主键
 */

+ (NSString *)hmd_primaryKey;

/**
 返回一个CoreData管理的对象，对象的属性由所给dataDic设置。
 键值对应关系由
 + (NSDictionary*)hmd_attributeMapDictionary;
 确定
 */
+ (instancetype)hmd_objectWithDictionary:(NSDictionary *)dataDic;

+ (NSArray *)hmd_objectsWithDictionaries:(NSArray *)data;

/**
 如果有特殊处理，子类可以继承此方法处理特殊数据
 （建议使用- (void)hmd_setAttributes:(NSDictionary *)dataDic block:(void (^)(SNBaseObject *object,NSDictionary *dataDic))block;处理特殊数据）
 特殊数据不要在mapDictionary中声明
 也可以使用block来处理特殊数据
 */
+ (instancetype)hmd_objectWithDictionary:(NSDictionary *)dataDic block:(void (^)(id object,NSDictionary *dataDic))block;

+ (NSArray *)hmd_objectsWithDictionaries:(NSArray *)dataDics block:(void (^)(id object,NSDictionary *dataDic))block;

/**
 子类必须实现至少一个
 确定dictionary中的键和对象属性名的对应关系
 比如
 @{@"userId":@"uid"}
 其中userId是对象的一个属性，uid是数据字典中的对应键值
 设值时会实现类似object.userId = [dictionary objectForKey:@"uid"];
 */
+ (NSDictionary *)hmd_attributeMapDictionary;
+ (NSDictionary *)hmd_allAttributeMapDictionary;
+ (NSDictionary *)hmd_managedProperties;
/**
 从dataDic数据设置对象属性，对应关系如上所述
 */
- (void)hmd_setAttributes:(NSDictionary*)dataDic;

/**
 如果有特殊处理，子类可以继承此方法处理特殊数据
 特殊数据不要在mapDictionary中声明
 也可以使用block来处理特殊数据
 */
- (void)hmd_setAttributes:(NSDictionary *)dataDic block:(void (^)(NSObject *object,NSDictionary *dataDic))block;

/**
 由对象生成一个dictionary，同时满足以上所述的模式
 只包括attributeMapDictionary中声明过的属性，因为特殊数据无法处理，如果有此需求子类可以继承实现。
 */
- (NSDictionary*)hmd_dataDictionary;

- (NSString *)hmd_customDescription;
@end
